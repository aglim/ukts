configuration NeighborsC
{
    provides interface Neighbors;       
}
implementation
{
    components NeighborsM; 
    
    Neighbors = NeighborsM;

	components ActiveMessageC;
    NeighborsM.NeighborSend -> ActiveMessageC.AMSend[AM_NEIGHBOR_MSG];
}