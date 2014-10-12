module NeighborsM
{
    provides interface Neighbors;  
	uses interface AMSend as NeighborSend; 
}
implementation
{
    enum {          
        MAX_NEIGHBORS = 8,              // maximum number of neighbors
        TIMEOUT = 10,
    };

    enum {
        ENTRY_EMPTY = 0,
        ENTRY_FULL = 1,
    };

    typedef struct NeighborEntry{
		uint8_t state;					// is entry full or empty ?
		uint16_t id;					// ID of the neighbor
		uint32_t timestamp;				// receipt time of the last message

		float x;
		float y;
 
		float unadjustedDistance;	// AVT variables    

		float value;					// AVT variables    
		float delta;
		uint8_t lastFeedback;
    }NeighborEntry;

    NeighborEntry neighbors[MAX_NEIGHBORS]; // neighbor table in order to discover neighbors
    uint8_t numNeighbors;

    /**/
    uint8_t curNeighborI = 0;

	message_t sendBuf;
	bool sendBusy = FALSE;


    /* AVT SECTION ------------------------------------------------------------------*/ 
    /* feedback definitions */
    enum {
        FEEDBACK_GREATER = 0,
        FEEDBACK_LOWER = 1,
        FEEDBACK_GOOD = 2,
        FEEDBACK_NONE = 3,
    };
    /* ---------------------------------- */

    /* delta step parameters */
    #define INCREASE_FACTOR 2.0f
    #define DECREASE_FACTOR 3.0f
    /* ---------------------------------- */

    /* adaptive value tracking parameters */ 
    #define MIN_DELTA 0.1f
    #define MAX_DELTA 50.0f
    #define INITIAL_DELTA 1.0f        
    #define UPPER_BOUND 500.0f
    #define LOWER_BOUND 1.0f
    #define INITIAL_VALUE 0.0f
    /* ---------------------------------- */

    void increaseDelta(uint8_t i){
        neighbors[i].delta *= INCREASE_FACTOR;    
        
        if(neighbors[i].delta > MAX_DELTA){
            neighbors[i].delta = MAX_DELTA;
        }
    }
    
    void decreaseDelta(uint8_t i){
        neighbors[i].delta /= DECREASE_FACTOR;

        if(neighbors[i].delta < MIN_DELTA){
            neighbors[i].delta = MIN_DELTA;
        }     
    }
        
    void updateDelta(uint8_t i,uint8_t feedback){
    
        if (neighbors[i].lastFeedback == FEEDBACK_GOOD) {
            if (feedback == FEEDBACK_GOOD) {
                    decreaseDelta(i);
            } else {
                // do not change delta
            }
        }else if (neighbors[i].lastFeedback != feedback) {
            decreaseDelta(i);
        }else{
            increaseDelta(i);
        }
    }
    
    float min(float a,float b){
        if(a<b) 
            return a;
        
        return b;
    }
    
    float max(float a,float b){
        if(a>b) 
            return a;

        return b;
    }
    

    //void adjustValue(uint8_t i,uint8_t feedback)
    void adjustValue(uint8_t i,uint8_t feedback)
    {           
        // 1 - Updates the delta value
        updateDelta(i,feedback);

        // 2 - Adjust the current value
        if (feedback != FEEDBACK_GOOD) {
            neighbors[i].value = min(UPPER_BOUND,max(LOWER_BOUND,neighbors[i].value + neighbors[i].delta*(feedback == FEEDBACK_GREATER ? 1.0f : -1.0f)));
        }

        neighbors[i].lastFeedback = feedback;

    } 

    /* AVT SECTION ------------------------------------------------------------------*/ 


    void clearNeighbor(uint8_t i){
        neighbors[i].state = ENTRY_EMPTY;
        neighbors[i].value = INITIAL_VALUE;
        neighbors[i].delta = INITIAL_DELTA;
        neighbors[i].lastFeedback = FEEDBACK_GOOD;
        // debug . store count of adjustments
        //neighbors[i].id = 0;        
        neighbors[i].unadjustedDistance = 0;    
    }

    int8_t getNeighborSlot(uint16_t id) {
        int8_t i;

        for (i = 0; i < MAX_NEIGHBORS; i++) {
            if ((neighbors[i].state == ENTRY_FULL) && (neighbors[i].id == id)) {
                return i;
            }
        }

        return -1;
    }

    int8_t getFreeSlot() {
        int8_t i, freeItem = -1;

        for (i = 0; i < MAX_NEIGHBORS; ++i) {
            if (neighbors[i].state == ENTRY_EMPTY)  {
                freeItem = i;
            }
        }

        return freeItem;
    }

    command void Neighbors.neighborhoodUpdate(uint32_t localTime){
        int8_t i;
        uint32_t age;
        
        numNeighbors = 0;
                
        for (i = 0; i < MAX_NEIGHBORS; ++i) {            
            if (neighbors[i].state == ENTRY_FULL){
                age = localTime - neighbors[i].timestamp;
                if (age >= 10L ){
                        clearNeighbor(i);
                }
                else{
                        numNeighbors++;
                }
            }           
        }
    }

    command void Neighbors.neighborhoodReset(){
        uint8_t i;

        for(i = 0; i < MAX_NEIGHBORS; ++i){
            clearNeighbor(i);
        }

        numNeighbors = 0;
    }



    command error_t Neighbors.storeInfo(uint16_t id, float distance, float x, float y, uint32_t timestamp) {

        uint8_t found = 0;
        int8_t i = getNeighborSlot(id);

        if(i >= 0){
            found = 1;
        }
        else {
            i = getFreeSlot();
            // init all var to defaults, else delta would be equal to 0
            clearNeighbor(i);
        }

        if (i >= 0) {

			neighbors[i].state = ENTRY_FULL;
			neighbors[i].id = id;
			neighbors[i].timestamp = timestamp;

			neighbors[i].unadjustedDistance = distance;

			neighbors[i].x = x;
			neighbors[i].y = y;

			// AVT algorithm
			if((neighbors[i].value == INITIAL_VALUE) & (distance > 0)){
				if(distance < UPPER_BOUND) {
					neighbors[i].value = distance;    
				} else {
					neighbors[i].value = UPPER_BOUND;
				}
			} else {
                /* diff is int so all differences less than one will be omitted. Correct behaviour or not? */
				int32_t diff = (neighbors[i].value - distance);

				if(diff == 0){
					adjustValue(i,FEEDBACK_GOOD);
				} else if(diff > 0){
					adjustValue(i,FEEDBACK_LOWER);
				} else { 
                    /* diff < 0, new distance bigger than present distance */
					adjustValue(i,FEEDBACK_GREATER);
				}
			}
            return SUCCESS;
        }

        return FAIL;        
    }

    // function for getting neighbor's info with index of element in neighbor list
    command error_t Neighbors.getInfo(uint16_t i, uint16_t *id, float *unadjDistance, float *adjDistance, float *x, float *y, float *delta, uint32_t *timestamp) {
        // return SUCCESS if neighbors info is present and FAIL otherwise
        if (neighbors[i].state == ENTRY_FULL) {
        		*id = neighbors[i].id;

                *adjDistance = neighbors[i].value;
                *unadjDistance = neighbors[i].unadjustedDistance;
                *x = neighbors[i].x;
                *y = neighbors[i].y;
                *delta = neighbors[i].delta;
                *timestamp = neighbors[i].timestamp;
                
                return SUCCESS;
        }

        return FAIL;        
    }

	// function for getting neighbor's info with id
    command error_t Neighbors.getInfoId(uint16_t id, float *unadjDistance, float *adjDistance, float *x, float *y, float *delta, uint32_t *timestamp) {
      
        int8_t i = getNeighborSlot(id);
        uint16_t slack_id;

        if(i >= 0){
			if(call Neighbors.getInfo(i, &slack_id, unadjDistance, adjDistance, x, y, delta, timestamp) == SUCCESS) {
				return SUCCESS;	
			} else {
				return FAIL;
			}			
        } else {
            return FAIL;        
        }
    }

    command error_t Neighbors.getInfoTimestamp(uint16_t i, uint16_t *id, uint32_t *timestamp) {
		// return SUCCESS if neighbors info is present and FAIL otherwise
		if (neighbors[i].state == ENTRY_FULL) {
			*id = neighbors[i].id;
			*timestamp = neighbors[i].timestamp;

			return SUCCESS;
		}

		return FAIL;
	}

	void sendNeighborInfo(uint8_t i) {
		if (!sendBusy && sizeof(neighbor_msg_t) <= call NeighborSend.maxPayloadLength())
		{
			neighbor_msg_t* neighbor_msg = (neighbor_msg_t*)call NeighborSend.getPayload(&sendBuf, sizeof(neighbor_msg_t));

			/*
				 typedef struct NeighborEntry{
						uint8_t state;					// is entry full or empty ?
						uint16_t id;					// ID of the neighbor
						uint32_t timestamp;				// receipt time of the last message

						float x;
						float y;
				 
						float unadjustedDistance;	// AVT variables    

						float value;					// AVT variables    
						float delta;
						uint8_t lastFeedback;
				    }NeighborEntry;
          	*/ 

			neighbor_msg->id = neighbors[i].id;
			neighbor_msg->state = neighbors[i].state;
			neighbor_msg->unadjVal = (uint32_t) (neighbors[i].unadjustedDistance * 1000);
			neighbor_msg->adjVal = (uint32_t) (neighbors[i].value * 1000);
			neighbor_msg->delta = (uint32_t) (neighbors[i].delta * 1000);
			neighbor_msg->timestamp = neighbors[i].timestamp;

			if (call NeighborSend.send(AM_BROADCAST_ADDR, &sendBuf, sizeof(neighbor_msg_t)) == SUCCESS)
			    sendBusy = TRUE;
		}
		//if (!sendBusy)
			//report_problem();

	}

	event void NeighborSend.sendDone(message_t* ptr, error_t success) {
		sendBusy = FALSE;

		curNeighborI++;
		if(curNeighborI < MAX_NEIGHBORS) {
			sendNeighborInfo(curNeighborI);
		} else {
			curNeighborI = 0;
			signal Neighbors.sendNeighborInfoDone();
		}

		return;
	}

	command void Neighbors.startSendNeighborInfo() {
		sendNeighborInfo(0);
	}

    
}