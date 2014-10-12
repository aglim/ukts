#include "../Ukts.h"
configuration RobotAppC
{
}
implementation
{
	components MainC, RobotC as App, LedsC, PulserC, DetectorC;
	components new TimerMilliC() as Timer0, new TimerMilliC() as Timer1;


	App -> MainC.Boot;
	App.Timer0 -> Timer0;
	App.Timer1 -> Timer1;
	App.Leds -> LedsC;

	App.Detector -> DetectorC;

	components TimeSync32kC;

	MainC.SoftwareInit -> TimeSync32kC;
	TimeSync32kC.Boot -> MainC;
	App.GlobalTime -> TimeSync32kC;
	App.TimeSyncInfo -> TimeSync32kC;

	components ActiveMessageC;
	App.RadioControl -> ActiveMessageC;

	App.RFReceive -> ActiveMessageC.Receive[AM_RF_MSG];
	App.ReqSend -> ActiveMessageC.AMSend[AM_REQ_MSG];
	//App.NeighborSend -> ActiveMessageC.AMSend[AM_NEIGHBOR_MSG];

	App.Packet -> ActiveMessageC;
	App.PacketTimeStamp -> ActiveMessageC;

	components NeighborsC;
	App.Neighbors -> NeighborsC;

}