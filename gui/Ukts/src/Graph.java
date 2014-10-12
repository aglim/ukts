/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.font.*;
import java.awt.geom.*;
import java.util.*;

/* Panel for drawing mote-data graphs */
class Graph extends JPanel
{
    final static int BORDER_LEFT = 20;
    final static int BORDER_RIGHT = 20;
    final static int BORDER_TOP = 20;
    final static int BORDER_BOTTOM = 20;

    final static int TICK_SPACING = 40;
    final static int MAX_TICKS = 16;
    final static int TICK_WIDTH = 10;

    final static int MIN_WIDTH = 50;

    int gx0, gx1, gy0, gy1; // graph bounds
    int scale = 2; // gx1 - gx0 == MIN_WIDTH << scale
    Window parent;

    /* Graph to screen coordinate conversion support */
    int height, width;
    double xscale, yscale;

    void updateConversion() {
    height = getHeight() - BORDER_TOP - BORDER_BOTTOM;
    width = getWidth() - BORDER_LEFT - BORDER_RIGHT;
    if (height < 1) {
        height = 1;
    }
    if (width < 1) {
        width = 1;
    }
      
    xscale = (double)width / (gx1 - gx0 + 1);
    yscale = (double)height / (gy1 - gy0 + 1);
    

    }

    Graphics makeClip(Graphics g) {
    return g.create(BORDER_LEFT, BORDER_TOP, width, height);
    }

     Graph(Window parent) {
    this.parent = parent;
    gy0 = 0; gy1 = 1;
    gx0 = 0; gx1 = 1;
    }

    protected void paintComponent(Graphics g) {
    Graphics2D g2d = (Graphics2D)g;

    /* Repaint. Synchronize on Oscilloscope to avoid data changing.
       Simply clear panel, draw Y axis and all the mote graphs. */
    synchronized (parent.parent) {
        updateConversion();
        g2d.setColor(Color.BLACK);
        g2d.fillRect(0, 0, getWidth(), getHeight());

        Graphics clipped = makeClip(g2d);
        int count = parent.moteListModel.size();
        for (int i = 0; i < count; i++) {
        clipped.setColor(parent.moteListModel.getColor(i));
        drawNode(clipped, parent.moteListModel.get(i));
        }
    }
    } 

    /* Draw graph for mote nodeId */
    protected void drawNode(Graphics g, int nodeId) {
    
    int x = parent.parent.data.getX(nodeId);
    int y = parent.parent.data.getY(nodeId);
    
    ArrayList<Integer> x0 = parent.parent.data.getX0(nodeId);
    ArrayList<Integer> y0 = parent.parent.data.getY0(nodeId);
    
    String capture;
    
    capture = "N";
    capture += ((Integer) nodeId).toString();
    capture += " ";
    capture += "(";
    capture += ((Integer) x).toString();
    capture += ",";
    capture += ((Integer) y).toString();
    capture += ")";
   

    g.setColor(parent.moteListModel.getColor(nodeId));
    
    int captionX = scale(x)+10;
    int captionY = scale(y)+10;
    /*
    if(captionX > height) {
        captionX = scaledX-100;
    }
    if(captionY > width) {
        captionY = scaledY-100;
    }
    */
    int i=0;
    //System.out.println("x0:"+(int)(scale(x0)+2.5)+"y0:"+(int)(scale(y0)+2.5)+"x:"+(int)(scale(x)+2.5)+"y:"+(int)(scale(y)+2.5));
    if(x0 != null) {
        if(y0 != null) {
            for(i=0; i<x0.size()-1; i++) {
                g.drawLine((int)(scale(x0.get(i))+2.5),(int)(scale(y0.get(i))+2.5),(int)(scale(x0.get(i+1))+2.5),(int)(scale(y0.get(i+1))+2.5));
            }
        }
    }
    g.drawLine((int)(scale(x0.get(i))+2.5),
            (int)(scale(y0.get(i))+2.5),
            (int)(scale(x)+2.5),
            (int)(scale(y)+2.5)
    );
    g.drawString(capture, captionX, captionY);
    g.drawOval(scale(x), scale(y), 5, 5);

    }
    
    int scale(int point) {
        return point*6;
    }
    /* New data received. Redraw graph, scrolling if necessary */
    void newData() {
        int maxX = parent.parent.data.maxX();
        int maxY = parent.parent.data.maxY();

        gx0 = 0;
        gx1 = maxX;

        gy0 = 0;
        gy1 = maxY;
        updateConversion();

        //System.out.println("xsc"+xscale);
        //System.out.println("ysc"+yscale);

        repaint();
    }
}
