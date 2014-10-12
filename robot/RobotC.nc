#include "Timer.h"

module RobotC
{
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface Leds;
	uses interface Boot;

	uses interface Detector;

	uses {
		interface GlobalTime<T32khz>;
		interface TimeSyncInfo;
		interface Receive as RFReceive;
		interface AMSend as ReqSend;
		//interface AMSend as NeighborSend;
		interface Packet;
		interface PacketTimeStamp<T32khz,uint32_t>;
		interface SplitControl as RadioControl;		
	}
	uses interface Neighbors;
}
implementation 
{
	message_t sendBuf;
	bool sendBusy = FALSE;

	uint32_t TlastUS;
	uint32_t TlastRF;

	uint32_t Xpos;
	uint32_t Ypos;

	uint32_t seq_no=0;

	rf_msg_t lastRF;
	
	uint8_t state;

	// parameters of the system
	enum {
		REQUEST_PERIOD	= 5000,				// request period in ms
		TIMEOUT_PERIOD  = 20,				// timeout for US or RF signal to become outdated
											// must be tuned carefully! possibly depends on network busyness
		AVT_ID_X = 100,
		AVT_ID_Y = 101,
	};
	enum {
		STATE_CALC = 0x04,
		STATE_WAIT_US = 0x02,
		STATE_WAIT_RF = 0x01,
		STATE_INIT = 0x00,
	};

	/* neghbor info . need to be global for easy use from function and chained NeighborMsgs*/
	/* [0-2]: 3 neighbors [3-4]: x,y [5-6]: unadj x, unadj u */
	uint16_t id[7] = {0};
	float unadjR[7] = {0};
	float r[7] = {0};
	float x[7] = {0};
	float y[7] = {0};		
	float d[7] = {0};
	uint32_t t[7] = {0};

	uint8_t curNeighborI=0;

	void report_req_sent() { call Leds.led0Toggle();  }
	void report_rfus_received() { call Leds.led1Toggle(); }
    void report_problem() { call Leds.led2Toggle(); }

	event void Boot.booted() {	
		call RadioControl.start();

		TlastUS = 0;

		Xpos = 0;
		Ypos = 0;
		
	}

	/******************************
				Request	& Detect		
	******************************/
	/*
	nx_uint16_t id;
	nx_uint32_t timestamp;
	nx_uint32_t unadjVal;
	nx_uint32_t adjVal;
	nx_uint32_t delta;
	*/
	void sendReq() {
		if (!sendBusy && sizeof(req_msg_t) <= call ReqSend.maxPayloadLength())
		{
			req_msg_t* req_msg = (req_msg_t*)call Packet.getPayload(&sendBuf, sizeof(req_msg_t));

			req_msg->id = TOS_NODE_ID;
			req_msg->x = Xpos;
			req_msg->y = Ypos;
			req_msg->t = seq_no;

			if (call ReqSend.send(AM_BROADCAST_ADDR, &sendBuf, sizeof(req_msg_t)) == SUCCESS)
				sendBusy = TRUE;
		}
		if (!sendBusy)
			report_problem();

		report_req_sent();
	}
	/*
	void sendNeighborInfo(uint8_t i) {
		if (!sendBusy && sizeof(neighbor_msg_t) <= call NeighborSend.maxPayloadLength())
		{
			neighbor_msg_t* neighbor_msg = (neighbor_msg_t*)call NeighborSend.getPayload(&sendBuf, sizeof(neighbor_msg_t));

			neighbor_msg->id = id[i];
			neighbor_msg->unadjVal = (uint32_t) (unadjR[i] * 1000);
			neighbor_msg->adjVal = (uint32_t) (r[i] * 1000);
			neighbor_msg->delta = (uint32_t) (d[i] * 1000);
			neighbor_msg->timestamp = t[i];

			if (call NeighborSend.send(AM_BROADCAST_ADDR, &sendBuf, sizeof(neighbor_msg_t)) == SUCCESS)
				sendBusy = TRUE;
		}
		if (!sendBusy)
			report_problem();
	}
	*/	
	/*
	event void NeighborSend.sendDone(message_t* ptr, error_t success) {
		sendBusy = FALSE;

		curNeighborI++;
		if(curNeighborI < 7) {
			sendNeighborInfo(curNeighborI);
		} else {
			curNeighborI = 0;
			sendReq();
		}

		return;
	}
	*/

	event void Neighbors.sendNeighborInfoDone() {
		sendReq();
	}

	event void Timer0.fired() {
		uint8_t k = 0;
		uint8_t i = 0;
		/* temporary variables for extraction neighbor info and copying to array */
		uint16_t singleId;
		float singleUnadjR;
		float singleR;
		float singleX;
		float singleY;
		float singleDelta;
		uint32_t singleT;

		float a11,a12,a21,a22;
		float b1,b2;
		float detA;

		// slack variable for getting positions from AVT
		float val = 0;
		float tempFloat = 0;
		uint32_t tempInt = 0;

		/* remove neighbors with expired timestamp */
		/* here, remove old ones each request period */
		call Neighbors.neighborhoodUpdate(seq_no);

		// find most recent info
		for(i = 0; i < 8; i++) {
			if(call Neighbors.getInfoTimestamp(i, &singleId, &singleT) == SUCCESS) {
				if( (singleId != AVT_ID_X) && (singleId != AVT_ID_Y) ) {
					if(singleT > t[0]) {
						id[2] = id[1];
						t[2] = t[1];

						id[1] = id[0];
						t[1] = t[0];

						id[0] = singleId;
						t[0] = singleT;

						if(k<1) { k=1; }/* all conditions provided => we have at least one neighbour */
					} else if(singleT > t[1]) {
						id[2] = id[1];
						t[2] = t[1];

						id[1] = singleId;
						t[1] = singleT;

						if(k<2) k=2; /* all conditions provided => we have at least two neighbour */
					} else if(singleT > t[2]) {
						id[2] = singleId;
						t[2] = singleT;

						if(k<3) k=3; /* all conditions provided => we have at least three neighbour */
					}
				}
			}
		}

		if(k == 3) {
			for(i = 0; i < 3; i++) {
				if(call Neighbors.getInfoId(id[i], &singleUnadjR, &singleR, &singleX, &singleY, &singleDelta, &singleT) == SUCCESS) {
					unadjR[i] = singleUnadjR;
					r[i] = singleR;
					x[i] = singleX;
					y[i] = singleY;
					d[i] = singleDelta;
				} else {
					id[i] = 1000;
					t[i] = 0;
					x[i] = 333;
				}
			}
		}     
		// if we have x,y,r of 3 neighbors
		if(k == 3) {
			// trilateration
			report_problem();
			a11 = 2.0f*(x[2] - x[0]);
			a12 = 2.0f*(y[2] - y[0]);
			a21 = 2.0f*(x[2] - x[1]);
			a22 = 2.0f*(y[2] - y[1]);
			b1 = ( (r[0]*r[0] - r[2]*r[2]) - (x[0]*x[0] - x[2]*x[2]) - (y[0]*y[0] - y[2]*y[2]) );
			b2 = ( (r[1]*r[1] - r[2]*r[2]) - (x[1]*x[1] - x[2]*x[2]) - (y[1]*y[1] - y[2]*y[2]) );

			detA = 1.0f/(a11*a22 - a12*a21);

			// wrong definition of inverse of 2x2 matrix!!!
			/*
			a11 = detA * a11;
			a12 = detA * a12;
			a21 = detA * a21;
			a22 = detA * a22;
			*/			
			a11 = detA * a22;
			a12 = - (detA * a12);
			a21 = - (detA * a21);
			a22 = detA * a11;

			//X = (a11*b1+a12*b2);
			//Y = (a21*b1+a22*b2);
			// save position to AVT. Store X at harcoded id=0, Y at id=1			
			call Neighbors.storeInfo(AVT_ID_X, (a11*b1+a12*b2), 0, 0, seq_no);
			call Neighbors.storeInfo(AVT_ID_Y, (a21*b1+a22*b2), 0, 0, seq_no);

			/* --trilateration with unadjusted distances */
			b1 = ( (unadjR[0]*unadjR[0] - unadjR[2]*unadjR[2]) - (x[0]*x[0] - x[2]*x[2]) - (y[0]*y[0] - y[2]*y[2]) );
			b2 = ( (unadjR[1]*unadjR[1] - unadjR[2]*unadjR[2]) - (x[1]*x[1] - x[2]*x[2]) - (y[1]*y[1] - y[2]*y[2]) );

			call Neighbors.storeInfo(AVT_ID_X-10, (a11*b1+a12*b2), 0, 0, seq_no);
			call Neighbors.storeInfo(AVT_ID_Y-10, (a21*b1+a22*b2), 0, 0, seq_no);

			/*
			id[5] = AVT_ID_X-10;
			unadjR[5] = (a11*b1+a12*b2);

			id[6] = AVT_ID_Y-10;
			unadjR[6] = (a21*b1+a22*b2);
			*/
			/* --trilateration with unadjusted distances */
		}
		
		if(call Neighbors.getInfoId(AVT_ID_X,  &singleUnadjR, &val, &tempFloat, &tempFloat, &singleDelta, &singleT) == SUCCESS) {
			Xpos = (uint32_t) val;
			/*
			id[3] = AVT_ID_X;
			unadjR[3] = singleUnadjR;
			r[3] = val;
			d[3] = singleDelta;
			t[3] = singleT;
			*/
		} else {Xpos = 0;}
		if(call Neighbors.getInfoId(AVT_ID_Y, &singleUnadjR, &val, &tempFloat, &tempFloat,  &singleDelta, &tempInt) == SUCCESS) {
			Ypos = (uint32_t) val;
			/*
			id[4] = AVT_ID_Y;
			unadjR[4] = singleUnadjR;
			r[4] = val;
			d[4] = singleDelta;
			t[4] = singleT;
			*/
		} else {Ypos = 0;}

		seq_no++;
		/* send Req message */ 

		//all calculations done, neighbor info can be broadcasted now
		//sendNeighborInfo(curNeighborI);
		call Neighbors.startSendNeighborInfo();
	}

	/*****************************

	*****************************/
	void saveRF(message_t* msgPtr) {
		rf_msg_t* rf_msg = (rf_msg_t*)call Packet.getPayload(msgPtr, sizeof(rf_msg_t));

		lastRF.id = rf_msg->id;
		lastRF.t = rf_msg->t;
		lastRF.x = rf_msg->x;
		lastRF.y = rf_msg->y;

		lastRF.t_received = rf_msg->t_received;

		// no more need for local time when packet was received
		//TlastRF = call PacketTimeStamp.timestamp(msgPtr);
	}

	void saveUS(uint32_t DetectionTime) {
		TlastUS = DetectionTime;
	}

	void initState() {
		state = STATE_INIT;
		// enable interrupt for a single pulse, e.g. only for first square
		call Detector.EnableInt(TRUE);
	}

	void calculate() {
		float distance;
		uint32_t dt;	

		call Timer1.stop();

		call GlobalTime.local2Global(&TlastUS);
		dt = (TlastUS - lastRF.t) - 6; /* 6 is offset */
		distance = 0.0330f*((float)(dt<<5)); // multiply by 32 (shift left 5 times) to get time in us. v_US = 0.033 cm/us

		call Neighbors.storeInfo(lastRF.id, distance, (float) lastRF.x, (float) lastRF.y, lastRF.t_received);

		initState();
	}


	event message_t* RFReceive.receive(message_t* msgPtr, void* payload, uint8_t len) {
		if(state == STATE_INIT) {
			saveRF(msgPtr);
			state = STATE_WAIT_US;

			call Timer1.startOneShot(TIMEOUT_PERIOD);
			} else if(state == STATE_WAIT_RF) {
				state = STATE_CALC;
				saveRF(msgPtr);
				calculate();
			}
		return msgPtr;
	}

	async event void Detector.PulseDetected(uint32_t DetectionTime) {
		report_rfus_received();
		if(state == STATE_INIT) {
			call Detector.DisableInt();
			saveUS(DetectionTime);
			state = STATE_WAIT_RF;

			call Timer1.startOneShot(TIMEOUT_PERIOD);
			} else if(state == STATE_WAIT_US) {
				state = STATE_CALC;
				saveUS(DetectionTime);
				calculate();
			}
		return;
	}

	event void Timer1.fired() {		
		initState();
	}

	event void ReqSend.sendDone(message_t* ptr, error_t success) {
		sendBusy = FALSE;
		return;
	}	

	event void RadioControl.startDone(error_t err) {
		call Timer0.startPeriodic( REQUEST_PERIOD );

		// TODO open Detector after RF receival, stay open for x ms and after that turn off again
		// ! It was observed turRF arrives after US! US is detected and approx. after 10ms RF arrives.
		call Detector.StartDetector();
		
		initState();
	}
	event void RadioControl.stopDone(error_t error){}
}