COMPONENT=RobotAppC

BUILD_EXTRA_DEPS += RFMsg.class ReqMsg.class NeighborMsg.class PrintNeighborMsg.class
CLEAN_EXTRA = *.class RFMsg.java ReqMsg.java NeighborMsg.java PrintNeighborMsg.java

RFMsg.class: $(wildcard *.java) RFMsg.java
	javac *.java

RFMsg.java: ../Ukts.h
	mig java -target=null -java-classname=RFMsg ../Ukts.h rf_msg -o $@

ReqMsg.class: $(wildcard *.java) ReqMsg.java
	javac *.java

ReqMsg.java: ../Ukts.h
	mig java -target=null -java-classname=ReqMsg ../Ukts.h req_msg -o $@

NeighborMsg.class: $(wildcard *.java) NeighborMsg.java
	javac *.java

NeighborMsg.java: ../Ukts.h
	mig java -target=null -java-classname=NeighborMsg ../Ukts.h neighbor_msg -o $@

PFLAGS += -DTIMESYNC_RATE=10
PFLAGS += -I$(TOSPROJ)/lib/ultrasonic
PFLAGS += -I$(TOSDIR)/lib/ftsp

include $(MAKERULES)
