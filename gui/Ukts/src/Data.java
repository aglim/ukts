/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

import java.util.*;

/* Hold all data received from motes */
class Data {
    /* The mote data is stored in a flat array indexed by a mote's identifier.
       A null value indicates no mote with that identifier. */
    private Node[] nodes = new Node[256];
    private Localization parent;

    Data(Localization parent) {
    this.parent = parent;
    }

    /* Data received from mote nodeId containing NREADINGS samples from
       messageId * NREADINGS onwards. Tell parent if this is a new node. */
    void update(int nodeId, int nodeX, int nodeY) {
    if (nodeId >= nodes.length) {
        int newLength = nodes.length * 2;
        if (nodeId >= newLength) {
            newLength = nodeId + 1;
        }

        Node newNodes[] = new Node[newLength];
        System.arraycopy(nodes, 0, newNodes, 0, nodes.length);
        nodes = newNodes;
    }
    Node node = nodes[nodeId];
    if (node == null) {
        nodes[nodeId] = node = new Node(nodeId);
        parent.newNode(node);
    }
    node.update(nodeX, nodeY);
    }

    /* Return value of sample x for mote nodeId, or -1 for missing data */
    int getX(int nodeId) {
    if (nodeId >= nodes.length || nodes[nodeId] == null)
        return -1;
    return nodes[nodeId].getX();
    }
    
    int getY(int nodeId) {
    if (nodeId >= nodes.length || nodes[nodeId] == null)
        return -1;
    return nodes[nodeId].getY();
    }
    
    ArrayList getX0(int nodeId) {
    if (nodeId >= nodes.length || nodes[nodeId] == null)
        return null;
    return nodes[nodeId].getX0();
    }
    
    ArrayList getY0(int nodeId) {
    if (nodeId >= nodes.length || nodes[nodeId] == null)
        return null;
    return nodes[nodeId].getY0();
    }
    
    int maxX() {
        int max = 0;

        for (int i = 0; i < nodes.length; i++) {
            if (nodes[i] != null) {
                int nmax = nodes[i].getX();

                if (nmax > max)
                    max = nmax;
            }
        }

        return max;
    }
    int maxY() {
        int max = 0;
        for (int i = 0; i < nodes.length; i++) {
            if (nodes[i] != null) {
                int nmax = nodes[i].getY();

                if (nmax > max)
                    max = nmax;
            }
        }

        return max;
    }

}
