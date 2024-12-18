`include "data_defs.v"
`ifndef PACKET_SV
`define PACKET_SV
class Packet;

	rand	reg	[`REGISTER_WIDTH-1:0] 	src1;		 
	rand	reg	[`REGISTER_WIDTH-1:0] 	src2;		 
	rand	reg	[`REGISTER_WIDTH-1:0] 	imm;		
	rand	reg	[`REGISTER_WIDTH-1:0] 	mem_data;		
	rand	reg							immp_regn_op_gen;
	randc	reg 	[2:0]				operation_gen;
	randc	reg 	[2:0]				opselect_gen;
	
	reg									enable;
	string 								name;

  constraint data {
		src1					 inside	{[0:65534]};// From  0 to FFFF
		src2					 inside	{[0:65534]};// From  0 to FFFF
		imm						 inside	{[0:65534]};// From  0 to FFFF
		mem_data				 inside	{[0:65534]};// Fromm 0 to FFFF
  }
	
	constraint all_op {
		opselect_gen inside {[0:1], [4:5]};	//these are the only valid inputs 
		//opselect_gen inside {[1:1]};	//arith only 
		
		if ((opselect_gen == `ARITH_LOGIC)){
			operation_gen inside {[0:7]};
		}
		else if ((opselect_gen == `SHIFT_REG)) {
			//immp_regn_op_gen inside {0};
			operation_gen inside {[0:3]};
		}
		else if ((opselect_gen == `MEM_READ)) {
			immp_regn_op_gen inside {1};
			operation_gen inside {[0:4]};
		}
		else if ((opselect_gen == `MEM_WRITE)) {
			immp_regn_op_gen inside {1};
			operation_gen inside {[0:7]}; // just make sure it does not matter
		}
	}

	constraint arith_logic {		
		opselect_gen inside {`ARITH_LOGIC};	// opselect gen only Arithmetic Logic
		soft operation_gen inside {[0:7]}; // 8 arithmetic logic operations
	}

	constraint shift_reg {
		opselect_gen inside {`SHIFT_REG};	// opselect gen only Shift register
		immp_regn_op_gen inside {0};
		soft operation_gen inside {[0:3]}; 		// 4 shifting operations
	}

	constraint mem_read {
		opselect_gen inside {`MEM_READ};	// opselect gen only Read Memory
		immp_regn_op_gen inside {1};
		soft operation_gen inside {[0:4]};	    // 5 data transfer operations
	}

	constraint mem_write {
			opselect_gen inside {`MEM_WRITE};	// opselect gen only Write Memory
			immp_regn_op_gen inside {1};
		}
		
	extern function new(string name = "Packet");
endclass

function Packet::new(string name = "Packet");
	this.name = name;
endfunction
`endif
