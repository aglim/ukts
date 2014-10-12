
import java.util.ArrayList;

/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Class holding all data received from a mote.
 */
class Node {
    /* The mote's identifier */
    int id;
    
    int x;
    int y;
    
    ArrayList<Integer> x0 = new ArrayList<Integer>();
    ArrayList<Integer> y0 = new ArrayList<Integer>();

    Node(int _id) {
        id = _id;
        x0.add(0);
        y0.add(0);
    }

    /* Data received containing NREADINGS samples from messageId * NREADINGS 
       onwards */
    void update(int x, int y) {
        this.x0.add(this.x);        
        this.x = x;
        this.y0.add(this.y);         
        this.y = y;
    }
    int getId() {
        return id;
    }
   
    int getX() {
        return x;
    }
    int getY() {
        return y;
    }
    ArrayList getX0() {
        return x0;
    }
    ArrayList getY0() {
        return y0;
    }

}
