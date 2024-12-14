`include "Packet.sv"
`include "OutputPacket.sv"
`include "Driver.sv"
`include "Generator.sv"
`include "Receiver.sv"
`include "Scoreboard.sv"
`include "data_defs.v"
program Execute_test #(
  parameter TEST_NAME = "all_op",  //defaults
  parameter NUM_PACKETS= 10
  )(Execute_io.TB Execute, DUT_probe_if Prober);
	parameter   reg_wd    	=   `REGISTER_WIDTH;
	Generator  	generator;	// generator object
	Driver     	drvr;		// driver objects
	Scoreboard 	sb;			// scoreboard object
	Receiver 	rcvr;		// Receiver Object
	
	Packet 		pkt_sent = new("Packet");
	int 		count = 0;
	int 		number_packets;
    string 		test_name = TEST_NAME;
	
	initial begin
		number_packets 		 = NUM_PACKETS;
    	generator			 = new("Generator", number_packets);
		sb					 =new(); // NOTE THAT THERE ARE DEFAULT VALUES FOR THE NEW FUNCTION 
					      // FOR THE SCOREBOARD 
		drvr 				 =new("drvr[0]", generator.in_box, sb.driver_mbox, Execute);
		rcvr				 =new("rcvr[0]", sb.receiver_mbox, Execute, Prober);  
		reset();
    	$display("[%tns] Start test case for : %s",$time, test_name);
		generator.start(test_name);
		drvr.start(); 
		sb.start();
		rcvr.start();
		repeat(number_packets+1) @(Execute.cb);
		sb.result();
		$display($time, "WE ARE DONE .. GO HOME AND SLEEP!!! .. ACTUALLY NOT YET .. ");
	end

	task reset();
		$display ($time, "ns:  [RESET]  Design Reset Start");
		Execute.reset 				<= 1'b1; 
    	Execute.cb.enable_ex 		<= 1'b0; 
		repeat(5) @(Execute.cb);
		Execute.cb.enable_ex   	 	<= 1'b1;
		Execute.reset 				<= 1'b0;
		$display ($time, "ns:  [RESET]  Design Reset End");
	endtask

// This is the end of the TB
endprogram
