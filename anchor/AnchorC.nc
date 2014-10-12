#include "Timer.h"

module AnchorC
{
	uses interface Timer<TMilli> as Timer0;
	uses interface Leds;
	uses interface Boot;

	uses interface Pulser;

	uses {
		interface GlobalTime<T32khz>;
		interface TimeSyncInfo;
		interface Receive as ReqReceive;

		interface AMSend as RFSend;
		interface Packet;
		interface PacketTimeStamp<T32khz,uint32_t>;
		interface SplitControl as RadioControl;		
	}

	uses interface Random;
}
implementation
{
	message_t sendBuf;

	bool sendBusy = FALSE;

	uint32_t Xpos;
	uint32_t Ypos;

	req_msg_t lastReq;

	void report_req_received() { call Leds.led0Toggle(); }
	void report_rfus_sent() { call Leds.led1Toggle(); }
	void report_problem() { call Leds.led2Toggle(); }

	event void Boot.booted() {
		call RadioControl.start();
		call Pulser.Init();

		lastReq.id = 0xFF;

		Xpos = 0;
		Ypos = 0;
	}

	/******************************
				Response			
	******************************/
	event message_t* ReqReceive.receive(message_t* msgPtr, void* payload, uint8_t len) {  	

		if (!sendBusy) {
			if(lastReq.id == 0xFF) {
				
				req_msg_t* req_msg = (req_msg_t*)call RFSend.getPayload(msgPtr, sizeof(req_msg_t));

				lastReq.id = req_msg->id;
				lastReq.t = req_msg->t;

				// wait for (10+rand) ms
				//call Timer0.startOneShot((uint32_t)(10U+(call Random.rand16()&0x0F)*10U));

				// wait for some period according to your ID
				call Timer0.startOneShot( (TOS_NODE_ID-4) * 300);
			}

		}
		report_req_received();
		return msgPtr;
	}
	event void Timer0.fired() {
		uint32_t PulseTime;

		if (!sendBusy && sizeof(rf_msg_t) <= call RFSend.maxPayloadLength())
		{
			rf_msg_t* rf_msg = (rf_msg_t*)call Packet.getPayload(&sendBuf, sizeof(rf_msg_t));

			call Pulser.SendPulse(&PulseTime);
			call GlobalTime.local2Global(&PulseTime);

			rf_msg->id = TOS_NODE_ID;
			rf_msg->reply_id = lastReq.id;
			rf_msg->t = PulseTime;
			rf_msg->x = Xpos;
			rf_msg->y = Ypos;

			// reply to which seq_no?
			rf_msg->t_received = lastReq.t;

			if (call RFSend.send(AM_BROADCAST_ADDR, &sendBuf, sizeof(rf_msg_t)) == SUCCESS)
				sendBusy = TRUE;
		}
		if (!sendBusy)
			report_problem();

		lastReq.id = 0xFF;
		report_rfus_sent();
	}

	event void RFSend.sendDone(message_t* ptr, error_t success) {
		sendBusy = FALSE;
		return;
	}

	event void RadioControl.startDone(error_t err) {

		// id'lere gore konumlarini belirtme
		if(TOS_NODE_ID == 5) {
			Xpos = 0;
			Ypos = 0;
		} else if(TOS_NODE_ID == 6) {
			Xpos = 50;
			Ypos = 0;
		} else if(TOS_NODE_ID == 7) {
			Xpos = 0;
			Ypos = 50;
		}

	}

	event void RadioControl.stopDone(error_t error){}
}