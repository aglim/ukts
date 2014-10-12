import java.io.BufferedWriter;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.io.FileOutputStream;
import java.io.PrintStream;
import net.tinyos.message.*;
import net.tinyos.util.*;


public class PrintNeighborMsg implements MessageListener {
    public class RunWhenShuttingDown extends Thread {
            public void run()
            {
                    System.out.println("Control-C caught. Shutting down...");
                    if (writer!=null)
                        try {
                          writer.close();
                        } catch ( IOException e ) {
                           e.printStackTrace();
                        }
            }
    }

    MoteIF mote;    // For talking to the antitheft root node
    String name=""+System.currentTimeMillis();
    BufferedWriter writer;

    void connect()
    {
        try {
            mote = new MoteIF(PrintStreamMessenger.err);
            mote.registerListener(new NeighborMsg(), this);
            System.out.println("Connection ok!");
        }
        catch(Exception e) {
            e.printStackTrace();
            System.exit(2);
        }
    }

    public PrintNeighborMsg() {
                try {
          writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(name+".txt"), "utf-8"));
        } catch ( IOException e ) {
           e.printStackTrace();
        }
        connect();
        Runtime.getRuntime().addShutdownHook(new RunWhenShuttingDown());
    }

    public void writeReprot(NeighborMsg tspr)
    {

        /*
        typedef nx_struct neighbor_msg
        {
            nx_uint16_t id;
            nx_uint32_t unadjVal;
            nx_uint32_t adjVal;
            nx_uint32_t delta;
            nx_uint32_t timestamp;
        } neighbor_msg_t; 
        */
        String foo = (
            
                tspr.get_timestamp()+"\t"+
                tspr.get_id()+"\t"+
                tspr.get_state()+"\t"+
                ( ((float) tspr.get_unadjVal()) / 1000 )+"\t"+
                ( ((float) tspr.get_adjVal()) / 1000 )+"\t"+
                ( ((float) tspr.get_delta()) / 1000 )+"\t"
                                     
                );
        System.out.println(foo);
        try {
          writer.write(foo+"\n");
        } catch ( IOException e ) {
           e.printStackTrace();
        }
        
    }

    public void messageReceived(int dest_addr, Message msg)
    {
        if (msg instanceof NeighborMsg)
            writeReprot((NeighborMsg)msg);
    }

    /* Just start the app... */
    public static void main(String[] args)
    {   

        new PrintNeighborMsg();
    }
}