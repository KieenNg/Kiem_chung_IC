`include "data_defs.v"
`include "Packet.sv"
`include "OutputPacket.sv"
class Scoreboard;
  string                          name;			// unique identifier
  Packet                          pkt_sent = new();	// Packet object from Driver
  OutputPacket                    pkt2cmp = new();		// Packet object from Receiver

  typedef mailbox #(Packet)       out_box_type;
  out_box_type                    driver_mbox;		// mailbox for Packet objects from Drivers

  typedef mailbox #(OutputPacket) rx_box_type;
  rx_box_type                   	receiver_mbox;		// mailbox for Packet objects from Receiver

  int                             num_tests;
  int                             num_tests_passed;
  int                             num_tests_failed;

	// Declare the signals to be compared over here.
  reg	[`REGISTER_WIDTH:0] 	      pre_aluout_chk = 0;
  reg	[`REGISTER_WIDTH:0] 	      aluout_chk = 0;
  reg                             carry_chk =0;
  reg				                      mem_en_chk = 0;
  reg	[`REGISTER_WIDTH-1:0]     	memout_chk = 0;

  reg	[`REGISTER_WIDTH-1:0]	      aluin1_chk =0;
  reg	[`REGISTER_WIDTH-1:0]       aluin2_chk=0; 
  reg	[2:0]		              	    opselect_chk=0;
  reg	[2:0]		                  	operation_chk=0;	
  reg	[4:0]               		    shift_number_chk=0;
  reg				                      enable_shift_chk=0;
  reg				                      enable_arith_chk=0;
  reg	[16:0] 		            	    aluout_half_chk;

  extern         function new(string name = "Scoreboard", out_box_type driver_mbox = null, rx_box_type receiver_mbox = null);
  extern virtual task start();
  extern virtual task check();
  extern virtual task check_arith();
  extern virtual task check_preproc();
  extern         task result();
endclass

function Scoreboard::new(string name, out_box_type driver_mbox, rx_box_type receiver_mbox);
  this.name           = name;
  if (driver_mbox == null) 
  driver_mbox         = new();
  if (receiver_mbox == null) 
  receiver_mbox       = new();
  this.driver_mbox    = driver_mbox;
  this.receiver_mbox  = receiver_mbox;
endfunction

task Scoreboard::start();
       $display ($time, "[SCOREBOARD] Scoreboard Started");

       $display ($time, "[SCOREBOARD] Receiver Mailbox contents = %d", receiver_mbox.num());
       fork
	       forever 
	       begin
          
		       if(receiver_mbox.try_get(pkt2cmp)) begin
			       $display ($time, "[SCOREBOARD] Grabbing Data From both Driver and Receiver");
			       //receiver_mbox.get(pkt2cmp);
			       driver_mbox.get(pkt_sent);
			       check();
             pre_aluout_chk = aluout_chk;
		       end
		       else 
		       begin
			       #1;
		       end
	       end
       join_none
       $display ($time, "[SCOREBOARD] Forking of Process Finished");
endtask

task Scoreboard::check();
	
  $display($time, "ns: [CHECKER] Checker Start\n\n");		
  // Grab packet sent from scoreboard 				
  $display($time, "ns:   [CHECKER] Pkt Contents: src1 = %h, src2 = %h, imm = %h, ", pkt_sent.src1, pkt_sent.src2, pkt_sent.imm);
  $display($time, "ns:   [CHECKER] Pkt Contents: opselect = %b, immp_regn = %b, operation = %b, ", pkt_sent.opselect_gen, pkt_sent.immp_regn_op_gen, pkt_sent.operation_gen);
  
  check_preproc();
  check_arith();

endtask

task Scoreboard::result();
  $display("Number tests : %0d, Pass: %0d, Fail: %0d",num_tests,num_tests_passed, num_tests_failed);
  $display("Accuracy: %0.2f%%",num_tests_passed*100/num_tests);
endtask

task Scoreboard::check_arith();
       $display($time, "ns:  	[CHECK_ARITH] Golden Incoming Arithmetic enable = %b", enable_arith_chk);
       $display($time, "ns:  	[CHECK_ARITH] Golden Incoming ALUIN = %h  %h ", aluin1_chk, aluin2_chk);
       $display($time, "ns:  	[CHECK_ARITH] Golden Incoming CONTROL = %3b(opselect)  %3b(operation) ", opselect_chk, operation_chk);
       $display($time, "______Cp0____opselect_chk:      %b",opselect_chk      ); 
       $display($time, "______Cp0____operation_chk:     %b",operation_chk     ); 
       $display($time, "______Cp0____enable_arith_chk:  %b",enable_arith_chk  ); 
       $display($time, "______Cp0____enable_shift_chk:  %b",enable_shift_chk  );
       $display($time, "______Cp0____pkt_sent.enable:   %b",pkt_sent.enable   );
       //if (pkt_sent.enable)
       if (1)
    begin
        if(enable_arith_chk ==1) 
        begin
          if ((opselect_chk == `ARITH_LOGIC))	// arithmetic
          begin
            case(operation_chk)
            `ADD : 	begin	  aluout_chk = aluin1_chk + aluin2_chk; carry_chk= aluout_chk[31];  $display($time, "______Cp1____");end
            `HADD: 	begin  
               {aluout_half_chk} = aluin1_chk[15:0] + aluin2_chk[15:0]; 
               aluout_chk = {{16{aluout_half_chk[16]}},aluout_half_chk[15:0]};	
               carry_chk  = aluout_half_chk[16];
               $display($time, ""); $display($time, "______Cp2____"); end 
            `SUB: 	begin   aluout_chk = aluin1_chk - aluin2_chk; carry_chk= aluout_chk[31];    $display($time, "______Cp3____");end 
            `NOT: 	begin   aluout_chk = ~aluin2_chk;    	        carry_chk= aluout_chk[31];    $display($time, "______Cp4____");end 
            `AND:  	begin   aluout_chk = aluin1_chk & aluin2_chk; carry_chk= aluout_chk[31];    $display($time, "______Cp5____");end
            `OR: 	  begin   aluout_chk = aluin1_chk | aluin2_chk; carry_chk= aluout_chk[31];    $display($time, "______Cp6____");end
            `XOR: 	begin   aluout_chk = aluin1_chk ^ aluin2_chk; carry_chk= aluout_chk[31];    $display($time, "______Cp7____");end
            `LHG: 	begin   aluout_chk = {aluin2_chk[15:0],{16{1'b0}}};	                        $display($time, "______Cp7____");end
            endcase
          end
          if ((opselect_chk == `MEM_READ))
            begin
              case(operation_chk)
              `LOADBYTE :	
                begin 
                        aluout_chk = {0, aluin2_chk[7:0]};
                        $display($time, "______Cp8____");
                        if (aluin2_chk[7] == 1'b0) begin
                          aluout_chk ={aluout_chk[`REGISTER_WIDTH -1:8], aluin2_chk[7:0]};
                          $display($time, "______Cp9____");
                        end
                        else begin
                          aluout_chk ={~aluout_chk[`REGISTER_WIDTH -1:8], aluin2_chk[7:0]};
                          $display($time, "______Cp10____");
                        end
                end 
              `LOADBYTEU : 
                begin 	
                        aluout_chk = {0, aluin2_chk[7:0]};
                        $display($time, "______Cp11____");
                end 
              `LOADHALF : 
                begin 
                        aluout_chk = {0, aluin2_chk[15:0]};
                        $display($time, "______Cp12____");
                        if (aluin2_chk[15] == 1'b0) begin
                          aluout_chk ={aluout_chk[`REGISTER_WIDTH -1:16], aluin2_chk[15:0]};
                          $display($time, "______Cp13____");
                        end
                        else begin
                          aluout_chk ={~aluout_chk[`REGISTER_WIDTH -1:16], aluin2_chk[15:0]};
                          $display($time, "______Cp14____");
                        end
                end 
              `LOADHALFU : 
                begin 	
                        aluout_chk = {0, aluin2_chk[15:0]};
                        $display($time, "______Cp15____");
                end
              `LOADWORD :		
                begin 
                        aluout_chk = aluin2_chk; 
                        $display($time, "______Cp16____");
                end
              default :	
                begin 
                        aluout_chk = aluin2_chk; 
                        $display($time, "______Cp17____");
                end
              endcase 
          end
          
      end
	
	else if (enable_shift_chk == 1) begin
		if ((opselect_chk == `SHIFT_REG)) begin 
      $display($time, "ns SHIFT_REG: aluin1_chk:%h , shift_number_chk:%h ",aluin1_chk, shift_number_chk  );
        		case(operation_chk)
             
            			`SHLEFTLOG: begin // SHLEFTLOG
                			aluout_chk = {aluin1_chk << shift_number_chk}; 
                      $display($time, "______Cp18____");
            			end
            			`SHLEFTART: begin // SHLEFTART 
                			aluout_chk = {aluin1_chk[31:1] << shift_number_chk, aluin1_chk[0] }; 
                      $display($time, "______Cp19____");
            			end
            			`SHRGHTLOG: begin // SHRGHTLOG
                			aluout_chk = {aluin1_chk >> shift_number_chk};
                      $display($time, "______Cp20____");
                  end
                	`SHRGHTART: begin //SHRGHTART
                			aluout_chk = {{aluin1_chk[31]}, aluin1_chk[30:0] >> shift_number_chk};
                      $display($time, "______Cp21____");
                	end
            			default: begin aluout_chk = aluin1_chk; // Default NO CHANGE
                      $display($time, "______Cp22____");
                  end
        		endcase
           
		end
	end       
	else
      begin 	
        if (pkt_sent.enable == 0) aluout_chk=pre_aluout_chk;
        //else aluout_chk = 0;
        	
      $display($time, "______Cp23____");
      end

	ASSERT_aluout: assert (pkt2cmp.aluout == pre_aluout_chk[31:0]) begin
    $display($time, "ns:   [ASSERT_aluout] PASS ALUOUT: DUT = %h   & Golden Model = %h\n", pkt2cmp.aluout, pre_aluout_chk);
    num_tests ++;
    num_tests_passed ++;
  end	else begin
    $display($time, "ns:   [ASSERT_aluout] FAIL ALUOUT: DUT = %h   & Golden Model = %h\n", pkt2cmp.aluout, pre_aluout_chk);	
    num_tests ++;
    num_tests_failed ++;
  end
    end
endtask	

task Scoreboard::check_preproc();
  
       if (((pkt_sent.opselect_gen == `ARITH_LOGIC)||((pkt_sent.opselect_gen == `MEM_READ) && (pkt_sent.immp_regn_op_gen==1))) && pkt_sent.enable) begin
	       enable_arith_chk = 1'b1;
       end
       else begin
	       enable_arith_chk = 1'b0;
       end

       if ((pkt_sent.opselect_gen == `SHIFT_REG)&& pkt_sent.enable) begin
	       enable_shift_chk = 1'b1;
       end
       else begin
	       enable_shift_chk = 1'b0;
       end

       if (((pkt_sent.opselect_gen == `ARITH_LOGIC)||((pkt_sent.opselect_gen == `MEM_READ) && (pkt_sent.immp_regn_op_gen==1))) && pkt_sent.enable) begin 
	       if((pkt_sent.immp_regn_op_gen==1)) begin
		       if (pkt_sent.opselect_gen == `MEM_READ) // memory read operation that needs to go to dest 
			       aluin2_chk = pkt_sent.mem_data;
		       else // here we assume that the operation must be a arithmetic operation
			       aluin2_chk = pkt_sent.imm;
	       end
	       else begin
		       aluin2_chk = pkt_sent.src2;
	       end
       end

       if(pkt_sent.enable) begin
	       aluin1_chk = pkt_sent.src1;
	       operation_chk = pkt_sent.operation_gen;
	       opselect_chk = pkt_sent.opselect_gen;
       end

       if ((pkt_sent.opselect_gen == `SHIFT_REG)&& pkt_sent.enable) begin
  		//if (pkt_sent.imm[2] == 1'b0) 
      if (pkt_sent.immp_regn_op_gen == 1'b0)
       		shift_number_chk = pkt_sent.imm[10:6];
   		else 
       		shift_number_chk = pkt_sent.src2[4:0];
	end
	else 
   		shift_number_chk = 0;	
	memout_chk = pkt_sent.src2;
	

	if((pkt_sent.opselect_gen == `MEM_WRITE) && (pkt_sent.immp_regn_op_gen == 1)) mem_en_chk = 1;
	else mem_en_chk = 0;

	ASSERT_mem_data_write_out: assert(pkt2cmp.mem_data_write_out == memout_chk)  begin
    $display($time, "ns: [ASSERT_mem_data_write_out] MEM_WRITE PASS mem_DUT = %h    mem_GOL = %h\n", pkt2cmp.mem_data_write_out, memout_chk);
    num_tests ++;
    num_tests_passed++;
  end else begin 
    $display($time, "ns: [ASSERT_mem_data_write_out] MEM_WRITE FAIL mem_DUT = %h    mem_GOL = %h\n", pkt2cmp.mem_data_write_out, memout_chk);
    num_tests ++;
    num_tests_failed++;
  end



	ASSERT_mem_write_en: assert(pkt2cmp.mem_write_en == mem_en_chk) begin
    $display($time, "ns: [ASSERT_mem_write_en] MEM_EN PASS mem_DUT = %h    mem_GOL = %h\n", pkt2cmp.mem_write_en, mem_en_chk);
    num_tests ++;
    num_tests_passed ++;
  end	else begin
    $display($time, "ns: [ASSERT_mem_write_en] MEM_EN FAIL mem_DUT = %h    mem_GOL = %h\n", pkt2cmp.mem_write_en, mem_en_chk);
    num_tests ++;
    num_tests_failed ++;
  end

	ASSERT_aluin1: assert (pkt2cmp.aluin1 == aluin1_chk) begin
    $display($time, "ns:   [ASSERT_aluin1] PASS ALUIN1: DUT = %h   & Golden Model = %h\n", pkt2cmp.aluin1, aluin1_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin
	  $display($time, "ns:   [ASSERT_aluin1] FAIL ALUIN1: DUT = %h   & Golden Model = %h\n", pkt2cmp.aluin1, aluin1_chk);
    num_tests ++;
    num_tests_failed ++;
  end	
	ASSERT_aluin2: assert (pkt2cmp.aluin2 == aluin2_chk) begin
    $display($time, "ns:   [ASSERT_aluin2] PASS ALUIN2: DUT = %h   & Golden Model = %h\n", pkt2cmp.aluin2, aluin2_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin    
    $display($time, "ns:   [ASSERT_aluin2] PASS ALUIN2: DUT = %h   & Golden Model = %h\n", pkt2cmp.aluin2, aluin2_chk);	
    num_tests ++;
    num_tests_failed ++;
  end
  ASSERT_enable_arith: assert (pkt2cmp.enable_arith == enable_arith_chk) begin
    $display($time, "ns:   [ASSERT_enable_arith] PASS ENABLE_ARITH: DUT = %b   & Golden Model = %b\n", pkt2cmp.enable_arith, enable_arith_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin
    $display($time, "ns:   [ASSERT_enable_arith] FAIL ENABLE_ARITH: DUT = %b   & Golden Model = %b\n", pkt2cmp.enable_arith, enable_arith_chk);
    num_tests ++;
    num_tests_failed ++;
  end
  ASSERT_enable_shift: assert (pkt2cmp.enable_shift == enable_shift_chk) begin
    $display($time, "ns:   [ASSERT_enable_shift] PASS ENABLE_SHIFT: DUT = %h   & Golden Model = %h\n", pkt2cmp.enable_shift, enable_shift_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin
    $display($time, "ns:   [ASSERT_enable_shift] FAIL ENABLE_SHIFT: DUT = %h   & Golden Model = %h\n", pkt2cmp.enable_shift, enable_shift_chk);
    num_tests ++;
    num_tests_failed ++;
  end
  ASSERT_operation: assert (pkt2cmp.operation == operation_chk) begin
    $display($time, "ns:   [ASSERT_operation] PASS OPERATION: DUT = %h   & Golden Model = %h\n", pkt2cmp.operation, operation_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin
    $display($time, "ns:   [ASSERT_operation] FAIL OPERATION: DUT = %h   & Golden Model = %h\n", pkt2cmp.operation, operation_chk);
    num_tests ++;
    num_tests_failed ++;
  end	
	ASSERT_opselect: assert (pkt2cmp.opselect == opselect_chk) begin
    $display($time, "ns:   [ASSERT_opselect] PASS OPSELECT: DUT = %h   & Golden Model = %h\n", pkt2cmp.opselect, opselect_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin       
    $display($time, "ns:   [ASSERT_opselect] FAIL OPSELECT: DUT = %h   & Golden Model = %h\n", pkt2cmp.opselect, opselect_chk);
    num_tests ++;
    num_tests_failed ++;
  end
	ASSERT_shift_number: assert (pkt2cmp.shift_number == shift_number_chk) begin
    $display($time, "ns:   [ASSERT_shift_number] PASS SHIFT_NUMBER: DUT = %h   & Golden Model = %h\n", pkt2cmp.shift_number, shift_number_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin	       	
    $display($time, "ns:   [ASSERT_shift_number] FAIL SHIFT_NUMBER: DUT = %h   & Golden Model = %h\n", pkt2cmp.shift_number, shift_number_chk);
    num_tests ++;
    num_tests_failed ++;
  end


  ASSERT_carry: assert (pkt2cmp.carry == carry_chk) begin
    $display($time, "ns:   [ASSERT_carry_flag] PASS CARRY_FLAG: DUT = %h       & Golden Model = %h\n", pkt2cmp.carry, carry_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin	       	
    $display($time, "ns:   [ASSERT_carry_flag] FAIL CARRY_FLAG: DUT = %h       & Golden Model = %h\n", pkt2cmp.carry, carry_chk);
    num_tests ++;
    num_tests_failed ++;
  end



endtask