#include "../Ukts.h"
configuration AnchorAppC
{
}
implementation
{
	components MainC, AnchorC as App, LedsC, PulserC, DetectorC;
	components new TimerMilliC() as Timer0;


	App -> MainC.Boot;
	App.Timer0 -> Timer0;

	App.Leds -> LedsC;

	App.Pulser -> PulserC;

	components TimeSync32kC;

	MainC.SoftwareInit -> TimeSync32kC;
	TimeSync32kC.Boot -> MainC;
	App.GlobalTime -> TimeSync32kC;
	App.TimeSyncInfo -> TimeSync32kC;

	components ActiveMessageC;
	App.RadioControl -> ActiveMessageC;

	App.ReqReceive -> ActiveMessageC.Receive[AM_REQ_MSG];
	App.RFSend -> ActiveMessageC.AMSend[AM_RF_MSG];	

	App.Packet -> ActiveMessageC;
	App.PacketTimeStamp -> ActiveMessageC;

	components RandomC;
	App.Random -> RandomC;
}