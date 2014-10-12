ukts
====
We are happy to present you project we worked through Fall 2013 to Summer 2014 semesters at DAS Lab at Ege University.

Ukts (tr. Uyarlanabilir Konum Tespit Sistemi) is a proof-of-concept adaptive localization system for WSNs. 

Ultrasound is used for ranging and we used Genetlab Sensenode motes equipped with US transmitter/receiver as a testbed.

Last state of the project:
* mobile and anchor nodes have different code, located in /robot and /anchor folders, respectively.
* both codebases uses https://github.com/aglim/sensenode-ultrasonic for driving US transmitter (in anchor) and receiver (in mobile node)
* mobile node can listen up to 3 neighbour anchors (?)
* AVT algorithm is used (and implemented) for robust localization. See our paper for details!
* 

Todo:
* merge code for mobile and anchor nodes

Installation
---
To try our system you need Genetlab Sensenode motes (or compatible ...) and tinyos toolchain installed to your system (check tinyos.net for further explanations). Firstly, specify positions of anchor nodes in /anchor/AnchorC.nc file. Build it using make install telosb. On success, use make install telosb,5 to install anchor node with id=5 and program all three anchor (id=5,6,7). After that build mobile node code in /robot and program mote. Place anchor nodes to their positions and mobile node somewhere in between with in mind that it should be in line-of-sight of all three anchor. Start up acnhor nodes and wait for some time (~5 min) for time synch to be reached. Now you can start mobile node and java tool located in /robot/PrintNeighborMsg.java (don't forget to program and connect BaseStation mote). Positon and other useful data will be printed in terminal periodically, as requests are sended by mobile node. You can observe how location, adjusted with AVT slowly converges. ...
