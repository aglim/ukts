interface Neighbors
{
    command void neighborhoodUpdate(uint32_t localTime);
    command void neighborhoodReset();
    command error_t storeInfo(uint16_t id, float distance, float x, float y, uint32_t timestamp);
    command error_t getInfo(uint16_t i, uint16_t *id, float *unadjDistance, float *adjDistance, float *x, float *y, float *delta, uint32_t *timestamp);
    command error_t getInfoId(uint16_t id, float *unadjDistance, float *adjDistance, float *x, float *y, float *delta, uint32_t *timestamp);
 	command error_t getInfoTimestamp(uint16_t i, uint16_t *id, uint32_t *timestamp);

 	command void startSendNeighborInfo();
	event void sendNeighborInfoDone();
}