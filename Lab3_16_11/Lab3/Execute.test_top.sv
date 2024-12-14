`include "data_defs.v"
module Execute_test_top;
	parameter simulation_cycle = `CLK_PERIOD;

	reg  SysClock;
	
	Execute_io top_io(SysClock);

	DUT_probe_if DUT_probe(
		.aluin1			(dut.aluin1),
		.aluin2			(dut.aluin2), 
		.opselect		(dut.opselect),
		.operation		(dut.operation),
		.shift_number	(dut.shift_number),
		.enable_shift	(dut.enable_shift), 
		.enable_arith	(dut.enable_arith)		
	);

  Top dut(
		.clock				(top_io.clock), 
		.enable_ex			(top_io.enable_ex),
		.reset				(top_io.reset), 
		.src1				(top_io.src1),   
		.src2				(top_io.src2),
	  	.imm				(top_io.imm),
		.control_in			(top_io.control_in),
		.mem_data_read_in	(top_io.mem_data_read_in), 
		.mem_data_write_out	(top_io.mem_data_write_out),
		.mem_write_en		(top_io.mem_write_en),
		.aluout				(top_io.aluout),
		.carry				(top_io.carry)
	);
  /* ------------- TEST NAME ------------------------
  1. all_top                            // Generate all operations

  2. arith_logic                        // Generate all arithmetic operations
    2.1 arith_logic_and_only_add        // Only add operation
    2.2 arith_logic_and_only_hadd       // Only hadd operation
    2.3 arith_logic_and_only_sub        // Only sub operation
    2.4 arith_logic_and_only_not        // Only not operation
    2.5 arith_logic_and_only_and        // Only and operation
    2.6 arith_logic_and_only_or         // Only or operation
    2.7 arith_logic_and_only_xor        // Only xor operation
    2.8 arith_logic_and_only_lhg        // Only lhg operation
    
  3. shift_reg                          // Generate all shift register operations
    3.1 shift_reg_and_only_shleftlog    // Only shift left logic
    3.2 shift_reg_and_only_shleftart    // Only shift left arithmetic
    3.3 shift_reg_and_only_shrghtlog    // Only shift right logigc
    3.4 shift_reg_and_only_shrghtart    // Only shift right arithmetic
    
  4. mem_read                           // Generate all memory read operations
    4.1 mem_read_and_only_loadbyte      // Only load byte operation
    4.1 mem_read_and_only_loadbyteu     // Only load byte unsigned operation
    4.1 mem_read_and_only_loadhalf      // Only load half operation
    4.1 mem_read_and_only_loadhalfu     // Only load half unsigned operation
    4.1 mem_read_and_only_loadword      // Only load word operation
      
  5. mem_write                          // Generate all memory write operation
	----------------------------------------------------*/

	Execute_test #(.TEST_NAME("arith_logic"),.NUM_PACKETS(10)) test(top_io, DUT_probe);   		
	
	initial
	begin
		SysClock = 0;
		forever 
		begin
			#(simulation_cycle/2)
			SysClock = ~SysClock;
		end
	end
endmodule
