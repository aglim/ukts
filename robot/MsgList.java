import java.io.FileOutputStream;
import java.io.PrintStream;
import net.tinyos.message.*;
import net.tinyos.util.*;

public class MsgList implements MessageListener {
        public class RunWhenShuttingDown extends Thread {
                public void run()
                {
                        System.out.println("Control-C caught. Shutting down...");
                        if (outReport!=null)
                        outReport.close();
                }
        }

  MoteIF mote;    // For talking to the antitheft root node

        void connect()
        {
                try {
                        mote = new MoteIF(PrintStreamMessenger.err);
                        mote.registerListener(new ReqMsg(), this);
                        System.out.println("Connection ok!");
                }
                catch(Exception e) {
                        e.printStackTrace();
                        System.exit(2);
                }
        }
        PrintStream outReport = null;

        public MsgList() {
                connect();
                Runtime.getRuntime().addShutdownHook(new RunWhenShuttingDown());
        }

        public void writeReprot(ReqMsg tspr)
        {
                String foo = (

                        tspr.get_id()+"\t"+
                        //tspr.get_r0()+"\t"+
                        tspr.get_x()+"\t"+
                        //tspr.get_r1()+"\t"+
                        tspr.get_y()+"\t"+
                        //tspr.get_r2()+"\t"+
                        tspr.get_t()
                        );
                System.out.println(foo);
        }

      

        public void messageReceived(int dest_addr, Message msg)
        {
                if (msg instanceof ReqMsg)
                        writeReprot((ReqMsg)msg);
        }

        /* Just start the app... */
        public static void main(String[] args)
        {
                new MsgList();
        }
}