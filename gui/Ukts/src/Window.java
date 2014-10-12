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
import javax.swing.table.*;
import javax.swing.event.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

/* The main GUI object. Build the GUI and coordinate all user activities */
class Window {
    Localization parent;
    Graph graph;
    
    Font smallFont = new Font("Dialog", Font.PLAIN, 8);
    Font boldFont = new Font("Dialog", Font.BOLD, 12);
    Font normalFont = new Font("Dialog", Font.PLAIN, 12);
    MoteTableModel moteListModel; // GUI view of mote list
    JLabel xLabel; // Label displaying X axis range
    JTextField sampleText, yText; // inputs for sample period and Y axis range
    JFrame frame;

    Window(Localization parent) {
	this.parent = parent;
    }

    /* A model for the mote table, and general utility operations on the mote
       list */
    class MoteTableModel extends AbstractTableModel {
	private ArrayList<Integer> motes = new ArrayList<Integer>();
        
        private ArrayList<Integer> xs = new ArrayList<Integer>();
        private ArrayList<Integer> ys = new ArrayList<Integer>();
        
	private ArrayList<Color> colors = new ArrayList<Color>();

	/* Initial mote colors cycle through this list. Add more colors if
	   you want. */
	private Color[] cycle = {
	    Color.RED, Color.WHITE, Color.GREEN, Color.MAGENTA,
	    Color.YELLOW, Color.GRAY, Color.YELLOW
	};
	int cycleIndex;
	
	/* TableModel methods for achieving our table appearance */
	public String getColumnName(int col) {
	    if (col == 0) {
		return "Mote";
            } else if (col == 1) {
		return "X";
	    } else if (col == 2) {
		return "Y";
	    } else {
		return "Color";
	    }
	}

	public int getColumnCount() { return 4; }

	public synchronized int getRowCount() { return motes.size(); }
	
	public synchronized Object getValueAt(int row, int col) {
	    if (col == 0) {
		return motes.get(row);
            } else if (col == 1) {
		return xs.get(row);
	    } else if (col == 2) {
		return ys.get(row);
	    } else {
		return colors.get(row);
	    }
	}

        public Class getColumnClass(int col) {
            return getValueAt(0, col).getClass();
        }

	public boolean isCellEditable(int row, int col) {
	    return col == 1;
	}

	public synchronized void setValueAt(Object value, int row, int col) {
	    colors.set(row, (Color)value);
            fireTableCellUpdated(row, col);
	    graph.repaint();
        }

	/* Return mote id of i'th mote */
	int get(int i) { return (motes.get(i)).intValue(); }
	
        
	/* Return color of i'th mote */
        /* Return color of mote with id = nodeId */
	Color getColor(int nodeId)  {
            int i = getIndexByNodeId(nodeId);
            if(i!=-1) {
                return colors.get(i);
            }             
            return Color.WHITE;
        }
	
	/* Return number of motes */
	int size() { return motes.size(); }
	
	/* Add a new mote */
	synchronized void newNode(Node node) {
	    /* Shock, horror. No binary search. */
	    int i, len = motes.size();
	    
	    for (i = 0; ; i++) {
		if (i == len || node.id < get(i)) {
		    motes.add(i, new Integer(node.getId()));
                    xs.add(i, new Integer(node.getX()));                    
                    ys.add(i, new Integer(node.getY()));
                    System.out.println(ys.toString());
		    // Cycle through a set of initial colors
		    colors.add(i, cycle[cycleIndex++ % cycle.length]);
		    break;
		}
	    }
	    fireTableRowsInserted(i, i);
	}
        /* Add a new mote */
	synchronized void updateNode(int nodeId, int x, int y) {
            int i = getIndexByNodeId(nodeId);

            if(i != -1) {
                xs.set(i, new Integer(x));
                ys.set(i, new Integer(y));
            }

	    fireTableRowsUpdated(i, i);
	}
	
	/* Remove all motes */
	void clear() {
	    motes = new ArrayList<Integer>();
	    colors = new ArrayList<Color>();
	    fireTableDataChanged();
	}
        
        int getIndexByNodeId(int nodeId) {
            int len = motes.size();
            for (int i = 0; i<len; i++) {
                if(motes.get(i) == nodeId) {
                    return i;
                }
            }
            return -1;
        }
    } /* End of MoteTableModel */

    /* A simple full-color cell */
    static class MoteColor extends JLabel implements TableCellRenderer {
	public MoteColor() { setOpaque(true); }
	public Component getTableCellRendererComponent
	    (JTable table, Object color,
	     boolean isSelected, boolean hasFocus, 
	     int row, int column) {
	    setBackground((Color)color);
	    return this;
	}
    }

    /* Convenience methods for making buttons, labels and textfields.
       Simplifies code and ensures a consistent style. */

    JButton makeButton(String label, ActionListener action) {
	JButton button = new JButton();
        button.setText(label);
        button.setFont(boldFont);
	button.addActionListener(action);
	return button;
    }

    JLabel makeLabel(String txt, int alignment) {
	JLabel label = new JLabel(txt, alignment);
	label.setFont(boldFont);
	return label;
    }
    
    JLabel makeSmallLabel(String txt, int alignment) {
	JLabel label = new JLabel(txt, alignment);
	label.setFont(smallFont);
	return label;
    }
    
    JTextField makeTextField(int columns, ActionListener action) {
	JTextField tf = new JTextField(columns);
	tf.setFont(normalFont);
	tf.setMaximumSize(tf.getPreferredSize());
	tf.addActionListener(action);
	return tf;
    }

    /* Build the GUI */
    void setup() {
	JPanel main = new JPanel(new BorderLayout());

	main.setMinimumSize(new Dimension(500, 250));
	main.setPreferredSize(new Dimension(800, 400));
	
	// Three panels: mote list, graph, controls
	moteListModel = new  MoteTableModel();
	JTable moteList = new JTable(moteListModel);
	moteList.setDefaultRenderer(Color.class, new MoteColor());
	moteList.setDefaultEditor(Color.class, 
				  new ColorCellEditor("Pick Mote Color"));
	moteList.setPreferredScrollableViewportSize(new Dimension(300, 400));
	JScrollPane motePanel = new JScrollPane();
	motePanel.getViewport().add(moteList, null);
	main.add(motePanel, BorderLayout.WEST);
	
	graph = new Graph(this);
	main.add(graph, BorderLayout.CENTER);
	
	// The frame part
	frame = new JFrame("Localization");
	frame.setSize(main.getPreferredSize());
	frame.getContentPane().add(main);
	frame.setVisible(true);
	frame.addWindowListener(new WindowAdapter() {
		public void windowClosing(WindowEvent e) { System.exit(0); }
	    });
    }

    /* User operation: clear data */
    void clearData() {
	synchronized (parent) {
	    moteListModel.clear();
	    parent.clear();
	    graph.newData();
	}
    }

    /* User operation: set Y-axis range. */
    void setYAxis() {
	
    }

    /* User operation: set sample period. */
    void setSamplePeriod() {
	String periodS = sampleText.getText().trim();
	try {
	    int newPeriod = Integer.parseInt(periodS);
	    if (parent.setInterval(5, newPeriod, newPeriod+50)) {
		return;
	    }
	}
	catch (NumberFormatException e) { }
	error("Invalid sample period " + periodS);
    }

    /* Notification: sample period changed. */
    void updateSamplePeriod() {
	sampleText.setText("" + parent.interval);
    }

    /* Notification: new node. */
    void newNode(Node node) {
	moteListModel.newNode(node);
    }

    /* Notification: new data. */
    void newData(int nodeId, int x, int y) {
        moteListModel.updateNode(nodeId, x, y);
	graph.newData();
    }

    void error(String msg) {
	JOptionPane.showMessageDialog(frame, msg, "Error",
				      JOptionPane.ERROR_MESSAGE);
    }
}
