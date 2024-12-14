`include "data_defs.v"
`include "Packet.sv"

`include "OutputPacket.sv"
class Scoreboard;
  string							name;			// unique identifier
  Packet							pkt_sent = new();	// Packet object from Driver
  OutputPacket						pkt_cmp = new();		// Packet object from Receiver

  typedef mailbox #(Packet)			out_box_type;
  out_box_type						driver_mbox;		// mailbox for Packet objects from Drivers

  typedef mailbox #(OutputPacket)	rx_box_type;
  rx_box_type						receiver_mbox;		// mailbox for Packet objects from Receiver

  int								num_tests;
  int								num_tests_passed;
  int								num_tests_failed;

	// Declare the signals to be compared over here.
  reg	[`REGISTER_WIDTH:0]			pre_aluout_chk = 0;
  reg	[`REGISTER_WIDTH:0]			aluout_chk = 0;
  reg								carry_chk =0;
  reg								mem_en_chk = 0;
  reg	[`REGISTER_WIDTH-1:0]     	memout_chk = 0;

  reg	[`REGISTER_WIDTH-1:0]		aluin1_chk =0;
  reg	[`REGISTER_WIDTH-1:0]       aluin2_chk=0; 
  reg	[2:0]						opselect_chk=0;
  reg	[2:0]						operation_chk=0;	
  reg	[4:0]						shift_number_chk=0;
  reg								enable_shift_chk=0;
  reg								enable_arith_chk=0;
  reg	[16:0]						aluout_half_chk;
//----------------------------------------------------Defien CG---------------------------------------------------------------------------------------------

  real 	coverage_value1, coverage_value2, coverage_value3,coverage_value4,coverage_value5,coverage_value6,coverage_value7; // COVERAGE 

// COVERAGE ADDITION 	
covergroup Arith_Cov_Ver1; 
	coverpoint 	pkt_sent.imm;
	coverpoint 	pkt_sent.src1;
	coverpoint 	pkt_sent.src2;
	coverpoint 	pkt_sent.opselect_gen;
	coverpoint 	pkt_sent.operation_gen;
endgroup

covergroup Arith_Cov_Ver2; 
	coverpoint pkt_sent.imm; 
	src1_cov: coverpoint pkt_sent.src1 ;
	src2_cov: coverpoint pkt_sent.src2 ;
	opselect_cov1: coverpoint pkt_sent.opselect_gen;
	opselect_cov2: coverpoint pkt_sent.opselect_gen {
				bins shift = {0};
				bins arith = {1};
				bins mem = {[4:5]};
	}
	opn_cov: coverpoint pkt_sent.operation_gen;
	// coverage with excessive points. NOT ALL OPSELECTS ARE VALID 
	cx_opsel_opn: cross opselect_cov1, opn_cov;
	// coverage with only the valid opselects 
	cx_opselcov_opn: cross opselect_cov2, opn_cov;
	cross src1_cov, src2_cov;
endgroup

covergroup Arith_Cov_Ver3; 
	coverpoint pkt_sent.imm;
	coverpoint 	pkt_sent.src1;
	coverpoint  pkt_sent.src2;
	src1_cov: coverpoint pkt_sent.src1 {
				option.auto_bin_max = 0;
				bins zero = {0};
				bins allfs = {32'hffffffff};
				bins special1 = {32'h55555555};
				bins special2 = {32'haaaaaaaa};
				bins positive = {[0:'1]} iff(pkt_sent.src1[31] == 1'b0);
				bins negative = {[0:'1]} iff(pkt_sent.src1[31] == 1'b1);
//					wildcard bins positive = {32'b0???????????????????????????????};
//					wildcard bins negative = {32'b1???????????????????????????????};
	}
	src2_cov: coverpoint pkt_sent.src2 {
				option.auto_bin_max = 0;
				bins zero = {0};
				bins allfs = {32'hffffffff};
				bins special1 = {32'h55555555};
				bins special2 = {32'haaaaaaaa};
				bins positive = {[0:'1]} iff(pkt_sent.src2[31] == 1'b0);
				bins negative = {[0:'1]} iff(pkt_sent.src2[31] == 1'b1);
//					wildcard bins positive = {32'b0???????????????????????????????};
//					wildcard bins negative = {32'b1???????????????????????????????};
	}
	imm_cov: coverpoint pkt_sent.imm {
          option.auto_bin_max = 0;
          bins zero = {0};
          bins allfs = {32'hffffffff};
          bins special1 = {32'h00005555};
          bins special2 = {32'h0000aaaa};
          bins positive = {[0:'1]} iff(pkt_sent.imm[31] == 1'b0);
          bins negative = {[0:'1]} iff(pkt_sent.imm[31] == 1'b1);     
    }
	opselect_cov: coverpoint pkt_sent.opselect_gen {
			option.auto_bin_max = 0;
			bins shift = {0};
			bins arith = {1};
			bins mem = {[4:5]};
	}
	immp_regn_op_gen_cov: coverpoint pkt_sent.immp_regn_op_gen{
          option.auto_bin_max = 0;
          bins zero = {0};
          bins one = {1};
    }
	opn_cov: coverpoint pkt_sent.operation_gen{
          option.auto_bin_max = 0;
          bins mem_op = {[0:7]};
          bins shift_op = {[0:3]};
          bins arith_op = {[0:7]};
    }
	cx_opselcov_opn: cross opselect_cov, opn_cov;
	// multi-dimensional cross coverage 
	//cross src1_cov, src2_cov, opn_cov; 
	// coverage to ensure that an add with some corner cases has taken place
	addition_cov: cross src1_cov, src2_cov,imm_cov, opselect_cov, opn_cov,immp_regn_op_gen_cov {
      option.cross_auto_bin_max = 0;
      bins addfs_zero =  binsof(src1_cov.allfs) && binsof(src2_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {0};
      bins addfs_one =  binsof(src1_cov.allfs) && binsof(imm_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {0};   

      bins addpos_zero =   binsof(src1_cov.positive) && binsof(src2_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(imm_cov.allfs) && 
              binsof(opn_cov.arith_op) intersect {0};
      bins addpos_one =   binsof(src1_cov.positive) && binsof(imm_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {0};

      bins addneg_zero =   binsof(src1_cov.negative) && binsof(src2_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {0};
      bins addneg_one =   binsof(src1_cov.negative) && binsof(imm_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {0};
    }
    half_additon_cov: cross src1_cov, src2_cov,imm_cov, opselect_cov, opn_cov,immp_regn_op_gen_cov {
      option.cross_auto_bin_max = 0;
      bins haddfs_zero =  binsof(src1_cov.allfs) && binsof(src2_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {1};
      bins haddfs_one =  binsof(src1_cov.allfs) && binsof(imm_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {1};   
      bins haddspec =  binsof(src1_cov.special1) && binsof(src2_cov.special2) && 
              binsof(opselect_cov.arith) && 
              binsof(opn_cov.arith_op) intersect {1};
      bins haddpos_zero =   binsof(src1_cov.positive) && binsof(src2_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(imm_cov.allfs) && 
              binsof(opn_cov.arith_op) intersect {1};
      bins haddpos_one =   binsof(src1_cov.positive) && binsof(imm_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {1};
      bins haddneg_zero =   binsof(src1_cov.negative) && binsof(src2_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {1};
      bins haddneg_one =   binsof(src1_cov.negative) && binsof(imm_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {1}; 
      }
      sub_cov_ver3: cross src1_cov, src2_cov,imm_cov, opselect_cov, opn_cov,immp_regn_op_gen_cov {
      option.cross_auto_bin_max = 0;
      bins subfs_zero =  binsof(src1_cov.allfs) && binsof(src2_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {2};
      bins subfs_one =  binsof(src1_cov.allfs) && binsof(imm_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {2};   
      bins subspec =  binsof(src1_cov.special1) && binsof(src2_cov.special2) && 
              binsof(opselect_cov.arith) && 
              binsof(opn_cov.arith_op) intersect {2};
      bins subpos_zero =   binsof(src1_cov.positive) && binsof(src2_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(imm_cov.allfs) && 
              binsof(opn_cov.arith_op) intersect {2};
      bins subpos_one =   binsof(src1_cov.positive) && binsof(imm_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {2};
      bins subneg_zero =   binsof(src1_cov.negative) && binsof(src2_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {2};
      bins subneg_one =   binsof(src1_cov.negative) && binsof(imm_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {2};
      }
      and_cov_ver3: cross src1_cov, src2_cov,imm_cov, opselect_cov, opn_cov,immp_regn_op_gen_cov {
      option.cross_auto_bin_max = 0;
      bins andfs_zero =  binsof(src1_cov.allfs) && binsof(src2_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {4};
      bins andfs_one =  binsof(src1_cov.allfs) && binsof(imm_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {4};   
      bins andspec =  binsof(src1_cov.special1) && binsof(src2_cov.special2) && 
              binsof(opselect_cov.arith) && 
              binsof(opn_cov.arith_op) intersect {4};
      bins andpos_zero =   binsof(src1_cov.positive) && binsof(src2_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(imm_cov.allfs) && 
              binsof(opn_cov.arith_op) intersect {4};
      bins andpos_one =   binsof(src1_cov.positive) && binsof(imm_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {4};
      bins andneg_zero =   binsof(src1_cov.negative) && binsof(src2_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {4};
      bins andneg_one =   binsof(src1_cov.negative) && binsof(imm_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {4};
      }
      or_cov_ver3: cross src1_cov, src2_cov,imm_cov, opselect_cov, opn_cov,immp_regn_op_gen_cov {
      option.cross_auto_bin_max = 0;
      bins orfs_zero =  binsof(src1_cov.allfs) && binsof(src2_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {5};
      bins orfs_one =  binsof(src1_cov.allfs) && binsof(imm_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {5};   
      bins orspec =  binsof(src1_cov.special1) && binsof(src2_cov.special2) && 
              binsof(opselect_cov.arith) && 
              binsof(opn_cov.arith_op) intersect {5};
      bins orpos_zero =   binsof(src1_cov.positive) && binsof(src2_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(imm_cov.allfs) && 
              binsof(opn_cov.arith_op) intersect {5};
      bins orpos_one =   binsof(src1_cov.positive) && binsof(imm_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {5};
      bins orneg_zero =   binsof(src1_cov.negative) && binsof(src2_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {5};
      bins orneg_one =   binsof(src1_cov.negative) && binsof(imm_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {5};
      }
      xor_cov_ver3: cross src1_cov, src2_cov,imm_cov, opselect_cov, opn_cov,immp_regn_op_gen_cov {
      option.cross_auto_bin_max = 0;
      bins xorfs_zero =  binsof(src1_cov.allfs) && binsof(src2_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {6};
      bins xorfs_one =  binsof(src1_cov.allfs) && binsof(imm_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {6};   
      bins xorspec =  binsof(src1_cov.special1) && binsof(src2_cov.special2) && 
              binsof(opselect_cov.arith) && 
              binsof(opn_cov.arith_op) intersect {6};
      bins xorpos_zero =   binsof(src1_cov.positive) && binsof(src2_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(imm_cov.allfs) && 
              binsof(opn_cov.arith_op) intersect {6};
      bins xorpos_one =   binsof(src1_cov.positive) && binsof(imm_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {6};
      bins xorneg_zero =   binsof(src1_cov.negative) && binsof(src2_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {6};
      bins xorneg_one =   binsof(src1_cov.negative) && binsof(imm_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {6};
      }
      not_cov_ver3: cross src2_cov,imm_cov, opselect_cov, opn_cov,immp_regn_op_gen_cov {
      option.cross_auto_bin_max = 0;
      bins notfs_zero =  binsof(src2_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {3};
      bins notfs_one =  binsof(imm_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {3};   
      bins notspec =  binsof(src2_cov.special2) && 
              binsof(opselect_cov.arith) && 
              binsof(opn_cov.arith_op) intersect {3};
      bins notpos_zero = binsof(src2_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(imm_cov.allfs) && 
              binsof(opn_cov.arith_op) intersect {3};
      bins notpos_one = binsof(imm_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(imm_cov.allfs) && 
              binsof(opn_cov.arith_op) intersect {3};
      bins notneg_zero = binsof(src2_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {3};
      bins notneg_one = binsof(imm_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(imm_cov.allfs) && 
              binsof(opn_cov.arith_op) intersect {3};  
      }
      lhg_cov_ver3: cross src1_cov, src2_cov,imm_cov, opselect_cov, opn_cov,immp_regn_op_gen_cov {
      option.cross_auto_bin_max = 0;
      bins lhgfs_zero =  binsof(src1_cov.allfs) && binsof(src2_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {7};
      bins lhgfs_one =  binsof(src1_cov.allfs) && binsof(imm_cov.allfs) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {7};   
      bins lhgspec =  binsof(src1_cov.special1) && binsof(src2_cov.special2) && 
              binsof(opselect_cov.arith) && 
              binsof(opn_cov.arith_op) intersect {7};
      bins lhgpos_zero =   binsof(src1_cov.positive) && binsof(src2_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(imm_cov.allfs) && 
              binsof(opn_cov.arith_op) intersect {7};
      bins lhgpos_one =   binsof(src1_cov.positive) && binsof(imm_cov.positive) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {7};
      bins lhgneg_zero =   binsof(src1_cov.negative) && binsof(src2_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.zero) &&
              binsof(opn_cov.arith_op) intersect {7};
      bins lhgneg_one =   binsof(src1_cov.negative) && binsof(imm_cov.negative) && 
              binsof(opselect_cov.arith) && binsof(immp_regn_op_gen_cov.one) &&
              binsof(opn_cov.arith_op) intersect {7};
      }   
endgroup
covergroup shift_cov_design; 
    // coverpoint pkt_sent.imm;
    // coverpoint  pkt_sent.src1;
    // coverpoint  pkt_sent.src2;
    src1_cov: coverpoint pkt_sent.src1 {
          bins zero = {0};
          bins allfs = {32'hffffffff};
          bins special1 = {32'h00005555};
          bins special2 = {32'h0000aaaa};
          bins positive = {[0:'1]} iff(pkt_sent.src1[31] == 1'b0);
          bins negative = {[0:'1]} iff(pkt_sent.src1[31] == 1'b1);
//          wildcard bins positive = {32'b0???????????????????????????????};
//          wildcard bins negative = {32'b1???????????????????????????????};
    }
    src2_cov: coverpoint pkt_sent.src2 {
          bins zero = {0};
          bins allfs = {32'hffffffff};
          bins special1 = {32'h00005555};
          bins special2 = {32'h0000aaaa};
          bins positive = {[0:'1]} iff(pkt_sent.src2[31] == 1'b0);
          bins negative = {[0:'1]} iff(pkt_sent.src2[31] == 1'b1);
//          wildcard bins positive = {32'b0???????????????????????????????};
//          wildcard bins negative = {32'b1???????????????????????????????};
    }
    imm_cov: coverpoint pkt_sent.imm {
          bins zero = {0};
          bins allfs = {32'hffffffff};
          bins special1 = {32'h00005555};
          bins special2 = {32'h0000aaaa};
          bins positive = {[0:'1]} iff(pkt_sent.imm[31] == 1'b0);
          bins negative = {[0:'1]} iff(pkt_sent.imm[31] == 1'b1);     
    }
    opselect_cov: coverpoint pkt_sent.opselect_gen {
          option.auto_bin_max = 0;
          bins shift = {0};
          bins arith = {1};
          bins mem = {[4:5]};
    }
    shift_opn_cov: coverpoint pkt_sent.operation_gen{
          option.auto_bin_max = 0;
          bins shleftlog = {0};
          bins sheleftart = {1};
          bins shrightlog = {2};
          bins shrightart = {3};
    }
    cx_opselcov_opn: cross opselect_cov, shift_opn_cov;
    // multi-dimensional cross coverage 
    //cross src1_cov, src2_cov, opn_cov; 
    // coverage to ensure that an add with some corner cases has taken place
    shleftlog_cov: cross src1_cov, opselect_cov, shift_opn_cov {
      option.cross_auto_bin_max = 0;
      // negative bin
      bins shleftlog_neg= binsof(src1_cov.negative) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov.shleftlog);

      // positive bin
      bins shleftlog_pos= binsof(src1_cov.positive) &&binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov.shleftlog);

      bins shleftlog_allfs= binsof(src1_cov.allfs) &&binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov.shleftlog);

      bins shleftlog_zero= binsof(src1_cov.zero) &&binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov.shleftlog);
      
      bins shleftlog_sp1= binsof(src1_cov.special1) &&binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov.shleftlog);
      
      bins shleftlog_sp2= binsof(src1_cov.special2) &&binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov.shleftlog);

    }
    shleftarith_cov: cross src1_cov, opselect_cov, shift_opn_cov{

      option.cross_auto_bin_max = 0;
      // negative bin
      bins  shleftarith_neg= binsof(src1_cov.negative) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {1};

      // positive bin
      bins  shleftarith_pos= binsof(src1_cov.positive) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {1};

      bins  shleftarith_allfs= binsof(src1_cov.allfs) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {1};

      bins  shleftarith_zero= binsof(src1_cov.zero) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {1};
      
      bins  shleftarith_sp1= binsof(src1_cov.special1) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {1};

      bins  shleftarith_sp2= binsof(src1_cov.special2) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {1};
      
    }

    // right shift logical coverage
    shrightlog_cov: cross src1_cov, opselect_cov, shift_opn_cov{
      
      option.cross_auto_bin_max = 0;

      // negative bin
      bins  shrghtlog_neg= binsof(src1_cov.negative) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {2};

      // positive bin
      bins  shrghtlog_pos= binsof(src1_cov.positive) && binsof(opselect_cov.shift) &&
             binsof(shift_opn_cov) intersect {2};
      
      bins  shrghtlog_allfs= binsof(src1_cov.allfs) && binsof(opselect_cov.shift) &&
             binsof(shift_opn_cov) intersect {2};
      
      bins  shrghtlog_zero= binsof(src1_cov.zero) && binsof(opselect_cov.shift) &&
             binsof(shift_opn_cov) intersect {2};
      
      bins  shrghtlog_sp1= binsof(src1_cov.special1) && binsof(opselect_cov.shift) &&
             binsof(shift_opn_cov) intersect {2};

      bins  shrghtlog_sp2= binsof(src1_cov.special2) && binsof(opselect_cov.shift) &&
             binsof(shift_opn_cov) intersect {2};

    }


    // right shift arithmetic coverage
    shrightarith_cov: cross src1_cov, opselect_cov, shift_opn_cov{
      option.cross_auto_bin_max = 0;
      // negative bin
      bins shrghtarith_neg= binsof(src1_cov.negative) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {3};

      // positive bin
      bins shrghtarith_pos= binsof(src1_cov.positive) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {3};

      bins shrghtarith_allfs= binsof(src1_cov.allfs) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {3};

      bins shrghtarith_zero= binsof(src1_cov.zero) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {3};

      bins shrghtarith_sp1= binsof(src1_cov.special1) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {3};

      bins shrghtarith_sp2= binsof(src1_cov.special2) && binsof(opselect_cov.shift) &&
              binsof(shift_opn_cov) intersect {3};

    }

  endgroup

covergroup Mem_Rd_Cov_design;

    //// ip side enable 
    dev_en_cov:coverpoint  pkt_sent.enable;

    //// check coverage for all possible airthmetic operations 
    opsel_cov: coverpoint pkt_sent.opselect_gen {
                 bins mem_read ={5};
        }

    oprtn_cov: coverpoint pkt_sent.operation_gen;


    
    
    src2_cov: coverpoint pkt_cmp.aluin2 {
          bins zero = {0};
          bins allfs = {32'hffffffff};
          bins special1 = {32'h00005555};
          bins special2 = {32'h0000aaaa};
          bins positive = {[0:'1]} iff(pkt_sent.src2[31] == 1'b0);
          bins negative = {[0:'1]} iff(pkt_sent.src2[31] == 1'b1);
    }

    src2_7cov: coverpoint pkt_cmp.aluin2 {
          bins zero = {[0:'1]} iff ((pkt_sent.src2[7:0] == 8'h00));
          bins allfs = {[0:'1]} iff ((pkt_sent.src2[7:0] == 8'hff));
          bins special1 = {[0:'1]} iff ((pkt_sent.src2[7:0] == 8'h55));
                bins special2 = {[0:'1]} iff ((pkt_sent.src2[7:0] == 8'haa));
          bins positive = {[0:'1]} iff(pkt_sent.src2[7] == 1'b0);
          bins negative = {[0:'1]} iff(pkt_sent.src2[7] == 1'b1);
    }   

    src2_15cov: coverpoint pkt_cmp.aluin2 {
          bins zero = {[0:'1]} iff ((pkt_sent.src2[15:0] == 16'h0000));
          bins allfs = {[0:'1]} iff ((pkt_sent.src2[15:0] == 16'hffff));
          bins special1 = {[0:'1]} iff ((pkt_sent.src2[15:0] == 16'h5555));
                bins special2 = {[0:'1]} iff ((pkt_sent.src2[15:0] == 16'haaaa));
          bins positive = {[0:'1]} iff(pkt_sent.src2[15] == 1'b0);
          bins negative = {[0:'1]} iff(pkt_sent.src2[15] == 1'b1);

    }

  
    //ip coverage for load byte operation   

    load_byte_cov: cross src2_7cov,opsel_cov,oprtn_cov{
          option.cross_auto_bin_max = 0;
          bins ld_byte= binsof(src2_7cov) &&
                  binsof(opsel_cov) &&
                        binsof(oprtn_cov);
                }

    load_byteu_cov: cross src2_7cov,opsel_cov,oprtn_cov{
          option.cross_auto_bin_max = 0;
          bins ld_byteu= binsof(src2_7cov) &&
                  binsof(opsel_cov) &&
                        binsof(oprtn_cov) intersect {4};
                }
    load_half_cov: cross src2_15cov,opsel_cov,oprtn_cov{
          option.cross_auto_bin_max = 0;
          bins ld_half= binsof(src2_15cov) &&
                  binsof(opsel_cov) &&
                        binsof(oprtn_cov) intersect {1};
                }
    // load_halfu_cov: cross aluin2_15cov,opsel_cov,oprtn_cov,carry_cov{
    //           option.cross_auto_bin_max = 0;
    //            bins ld_halfu= binsof(aluin2_15cov) &&
    //               binsof(opsel_cov) &&
    //                     binsof(oprtn_cov) intersect {5} &&
    //               binsof(carry_cov) intersect {0};
    //             }
    load_word_cov: cross src2_cov,opsel_cov,oprtn_cov{
              option.cross_auto_bin_max = 0;
               bins ld_word=  binsof(src2_cov) &&
                  binsof(opsel_cov) &&
                        binsof(oprtn_cov) intersect {3};
                }
endgroup
covergroup Mem_Write_design;

    dev_en_cov:coverpoint  pkt_sent.enable;

    //// check coverage for all possible airthmetic operations 
    opsel_cov: coverpoint pkt_sent.opselect_gen{
                 bins mem_write ={4};
        }

    oprtn_cov: coverpoint pkt_sent.operation_gen {bins check = {[0:7]};}

    wr_data: coverpoint pkt_sent.src2{
            bins zero = {0};
            bins allfs = {32'hffffffff};
            bins special1 = {32'h00005555};
            bins special2 = {32'h0000aaaa};
            bins positive = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b0);
            bins negative = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b1);
          } 

    immp_regn_op_gen_cov: coverpoint pkt_sent.immp_regn_op_gen{
          option.auto_bin_max = 0;
          bins zero = {0};
          bins one = {1};
    }

    opcode: cross  opsel_cov,oprtn_cov;


    write_op: cross opsel_cov,oprtn_cov,wr_data,immp_regn_op_gen_cov{

      bins write = binsof(opsel_cov) &&
             binsof(oprtn_cov.check) &&
                 binsof(wr_data) &&
             binsof(immp_regn_op_gen_cov.one);

      bins not_write = binsof(opsel_cov) &&
             binsof(oprtn_cov.check) &&
                 binsof(wr_data) &&
             binsof(immp_regn_op_gen_cov.zero);
    }

    
  endgroup
//----------------------------------------------------------------------------------------------------------------------

// Top most coverage to check exercising of all operands at the Ip of the Module
covergroup All_Ip_Operands_Cov;

//	coverpoint 	pkt_sent.opselect_gen;
//	coverpoint 	pkt_sent.operation_gen;
	
	imm_gen_cov: coverpoint pkt_sent.immp_regn_op_gen;			// to check imm or src mode coverage for general instructions

	enable_cov : coverpoint pkt_sent.enable;

	imm_shift_cov: coverpoint      pkt_sent.imm {			// to check imm or src mode coverage for general instructions	
			wildcard bins imm = {32'b?????????????????????????????0??};
			wildcard bins src = {32'b?????????????????????????????1??};
	}
	
	opselect_cov: coverpoint pkt_sent.opselect_gen {
				bins shift			= {0};
				bins arith			= {1};
				bins mem_read 		= {5};
				bins mem_write		= {4};
	}
	
	opn_cov: coverpoint pkt_sent.operation_gen {
		bins shift_valid			= {0, 1, 2, 3}; 
		bins arith_valid			= {0, 1, 2, 3, 4, 5, 6, 7};
        bins mem_read_valid			= {0, 1, 3, 4, 5}; 
        bins mem_write_valid		= {0, 1, 2, 3, 4, 5, 6, 7};
	}

	cx_opselcov_opn: cross opselect_cov, opn_cov{ 
		bins shift		= binsof(opselect_cov.shift) && binsof(opn_cov.shift_valid);
		bins arith		= binsof(opselect_cov.arith) && binsof(opn_cov.arith_valid);
		bins mem_read	= binsof(opselect_cov.mem_read) && binsof(opn_cov.mem_read_valid);
		bins mem_write	= binsof(opselect_cov.mem_write) && binsof(opn_cov.mem_write_valid);
	}		


	cx_opword_cov: cross opselect_cov,opn_cov,imm_gen_cov{	// to check cross coverage with all operations/opselects along with 
								////immediate mode			
				bins shift		=	binsof(opselect_cov.shift) && binsof(opn_cov.shift_valid) && binsof(imm_gen_cov);
				bins arith		=	binsof(opselect_cov.arith) && binsof(opn_cov) && binsof(imm_gen_cov);
				bins mem_read	=	binsof(opselect_cov.mem_read) && binsof(opn_cov.mem_read_valid) && binsof(imm_gen_cov) intersect {1} ;
				bins mem_write	=	binsof(opselect_cov.mem_write) && binsof(opn_cov)&& binsof(imm_gen_cov);
	}

	cx_imm_shift_cov:cross opselect_cov,imm_shift_cov,opn_cov{
				bins imm_shift	=	binsof(imm_shift_cov) && binsof(opselect_cov.shift) && binsof(opn_cov.shift_valid) ;//intersect {0,1,2,3};
	}

endgroup


//Coverage to check exercising of all operands and enables at the Intermediate stage between the Pre Pro and ALU block
covergroup All_Inter_Operands_Cov;
	// Cover aluout với các giá trị đặc biệt
	aluout_cov: coverpoint pkt_cmp.aluout {
		bins zero = {0};
		bins allfs = {32'hffffffff};
		bins special1 = {32'h0000};
		bins special2 = {32'h55555555};
		bins value_range0 = {[32'h0: 32'hf]};
		bins value_range1 = {[32'hf: 32'hff]};
		bins value_range2 = {[32'hff: 32'hfff]};
		bins value_range3 = {[32'hfff: 32'hffff]};
		bins value_range4 = {[32'hffff: 32'hfffff]};
		bins value_range5 = {[32'hfffff: 32'hffffff]};
		bins value_range6 = {[32'hffffff: 32'hfffffff]};
		bins value_range7 = {[32'hfffffff: 32'hffffffff]};
		bins positive = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b0);
		bins negative = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b1);
	}

	// Cover mem_write_en (cờ enable ghi bộ nhớ)
	mem_write_en_cov: coverpoint pkt_cmp.mem_write_en {
		bins enabled     = {1};
		bins disabled    = {0};
	}

	// Cover mem_data_write_out với các giá trị đặc biệt
	mem_data_write_out_cov: coverpoint pkt_cmp.mem_data_write_out {
		bins zero = {0};
		bins allfs = {32'hffffffff};
		bins special1 = {32'h0000};
		bins special2 = {32'h55555555};
		bins value_range0 = {[32'h0: 32'hf]};
		bins value_range1 = {[32'hf: 32'hff]};
		bins value_range2 = {[32'hff: 32'hfff]};
		bins value_range3 = {[32'hfff: 32'hffff]};
		bins value_range4 = {[32'hffff: 32'hfffff]};
		bins value_range5 = {[32'hfffff: 32'hffffff]};
		bins value_range6 = {[32'hffffff: 32'hfffffff]};
		bins value_range7 = {[32'hfffffff: 32'hffffffff]};
		bins positive = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b0);
		bins negative = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b1);
	}


	// Cover carry flag
    carry_cov: coverpoint pkt_cmp.carry {
        bins carry_set   = {1};
        bins carry_clear = {0};
    }
	
    aluin1_cov: coverpoint pkt_cmp.aluin1 {
        bins zero = {0};
		bins allfs = {32'hffffffff};
		bins special1 = {32'h0000};
		bins special2 = {32'h55555555};
		bins value_range0 = {[32'h0: 32'hf]};
		bins value_range1 = {[32'hf: 32'hff]};
		bins value_range2 = {[32'hff: 32'hfff]};
		bins value_range3 = {[32'hfff: 32'hffff]};
		bins value_range4 = {[32'hffff: 32'hfffff]};
		bins value_range5 = {[32'hfffff: 32'hffffff]};
		bins value_range6 = {[32'hffffff: 32'hfffffff]};
		bins value_range7 = {[32'hfffffff: 32'hffffffff]};
		bins positive = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b0);
		bins negative = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b1);
    }

	aluin2_cov: coverpoint pkt_cmp.aluin2 {
        bins zero = {0};
		bins allfs = {32'hffffffff};
		bins special1 = {32'h0000};
		bins special2 = {32'h55555555};
		bins value_range0 = {[32'h0: 32'hf]};
		bins value_range1 = {[32'hf: 32'hff]};
		bins value_range2 = {[32'hff: 32'hfff]};
		bins value_range3 = {[32'hfff: 32'hffff]};
		bins value_range4 = {[32'hffff: 32'hfffff]};
		bins value_range5 = {[32'hfffff: 32'hffffff]};
		bins value_range6 = {[32'hffffff: 32'hfffffff]};
		bins value_range7 = {[32'hfffffff: 32'hffffffff]};
		bins positive = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b0);
		bins negative = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b1);
    }

    shift_number_cov: coverpoint pkt_cmp.shift_number {
        bins low_value	= {[0:15]};
        bins high_value	= {[16:31]};
        
    }
	opsel_cov:coverpoint pkt_cmp.opselect {
		bins shift = {0};
		bins arith = {1};
		bins mem_read = {5};
		bins mem_write = {4};
	}
	
	oprtn_cov: coverpoint pkt_cmp.operation
	{

		bins shift = {0,1,2,3};
		bins arith = {0,1,2,3,4,5,6,7};
		bins mem_read = {0,1,3,4,5};
		bins mem_write = {0,1,2,3,4,5,6,7};

	}


	// Cover enable_shift
    en_shift_cov: coverpoint pkt_cmp.enable_shift {
        bins enabled  = {1};
        bins disabled = {0};
    }

    // Cover enable_arith
    en_arith_cov: coverpoint pkt_cmp.enable_arith {
        bins enabled  = {1};
        bins disabled = {0};
    }
	

    
	

	cx_opword_cov: cross opsel_cov,oprtn_cov{	// to check cross coverage with all operations/opselects				
				bins shift = binsof(opsel_cov.shift) && binsof(oprtn_cov.shift) ;
				bins arith =  binsof(opsel_cov.arith) && binsof(oprtn_cov) ;
				bins mem_read =  binsof(opsel_cov.mem_read) && binsof(oprtn_cov.mem_read) ;
				bins mem_write =  binsof(opsel_cov.mem_write) && binsof(oprtn_cov);

	}


	
endgroup	


// Coverage to exercise the Arithmetic block 
covergroup Arith_Cov; 

	// ip side enable	
	dev_en_cov:coverpoint  pkt_sent.enable;
	// Intermediate ips for enable
	en_arith_cov:coverpoint pkt_cmp.enable_arith
	{
		bins enable  = {1};
        bins disabled = {0};
	}


	// alu1
	aluin1_cov: coverpoint pkt_cmp.aluin1 {
				bins zero			= {0};
				bins allfs			= {32'hffffffff};
				bins special1		= {32'h0000};
				bins special2		= {2'h55555555};
				bins value_range0	= {[32'h0: 32'hf]};
				bins value_range1	= {[32'hf: 32'hff]};
				bins value_range2	= {[32'hff: 32'hfff]};
				bins value_range3	= {[32'hfff: 32'hffff]};
				bins value_range4	= {[32'hffff: 32'hfffff]};
				bins value_range5	= {[32'hfffff: 32'hffffff]};
				bins value_range6	= {[32'hffffff: 32'hfffffff]};
				bins value_range7	= {[32'hfffffff: 32'hffffffff]};
				bins positive		= {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b0);
				bins negative		= {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b1);
//					wildcard bins positive = {32'b0???????????????????????????????};
//					wildcard bins negative = {32'b1???????????????????????????????};
	}
	//alu2
	aluin2_cov: coverpoint pkt_cmp.aluin2 {
				bins zero			= {0};
				bins allfs			= {32'hffffffff};
				bins special1		= {32'h0000};
				bins special2		= {2'h55555555};
				bins value_range0	= {[32'h0: 32'hf]};
				bins value_range1	= {[32'hf: 32'hff]};
				bins value_range2	= {[32'hff: 32'hfff]};
				bins value_range3	= {[32'hfff: 32'hffff]};
				bins value_range4	= {[32'hffff: 32'hfffff]};
				bins value_range5	= {[32'hfffff: 32'hffffff]};
				bins value_range6	= {[32'hffffff: 32'hfffffff]};
				bins value_range7	= {[32'hfffffff: 32'hffffffff]};
				bins positive		= {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b0);
				bins negative		= {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b1);
//					wildcard bins positive = {32'b0???????????????????????????????};
//					wildcard bins negative = {32'b1???????????????????????????????};
	}

//		half aluin1
	h_aluin1_cov: coverpoint pkt_cmp.aluin1 {
				bins zero		= {[0:'1]} iff ((pkt_cmp.aluin1[15:0] == 16'h0000));
				bins allfs		= {[0:'1]} iff ((pkt_cmp.aluin1[15:0] == 16'hffff));
				bins special1	= {[0:'1]} iff ((pkt_cmp.aluin1[15:0] == 16'h5555)); // xoa tam
				bins special2	= {[0:'1]} iff ((pkt_cmp.aluin1[15:0] == 16'haaaa)); // xoa tam
				bins positive	= {[0:'1]} iff(pkt_cmp.aluin1[15] == 1'b0);
				bins negative	= {[0:'1]} iff(pkt_cmp.aluin1[15] == 1'b1);
//					wildcard bins positive = {32'b0???????????????????????????????};
//					wildcard bins negative = {32'b1???????????????????????????????};
	}

	
	//half aluin2
	h_aluin2_cov: coverpoint pkt_cmp.aluin2 {
				bins zero = {[0:'1]} iff ((pkt_cmp.aluin2[15:0] == 16'h0000));
				bins allfs = {[0:'1]} iff ((pkt_cmp.aluin2[15:0] == 16'hffff));
				bins special1 = {[0:'1]} iff ((pkt_cmp.aluin2[15:0] == 16'h5555)); // xoa tam
				bins special2 = {[0:'1]} iff ((pkt_cmp.aluin2[15:0] == 16'haaaa)); // xoa tam
				bins positive = {[0:'1]} iff(pkt_cmp.aluin2[15] == 1'b0);
				bins negative = {[0:'1]} iff(pkt_cmp.aluin2[15] == 1'b1);
//					wildcard bins positive = {32'b0???????????????????????????????};
//					wildcard bins negative = {32'b1???????????????????????????????};
	}


	// coverage for carry
	carry_cov: coverpoint pkt_cmp.carry
	{
		bins low ={0};
		bins high ={1};
	}

	// check coverage for all possible airthmetic operations 
	opsel_cov: coverpoint pkt_cmp.opselect{
				bins arith ={1};
	}

	oprtn_cov: coverpoint pkt_cmp.operation
	{
		bins value0 ={0};
		bins value1 ={1};
		bins value2 ={2};
		bins value3 ={3};
		bins value4 ={4};
		bins value5 ={5};
		bins value6 ={6};
		bins value7 ={7};
	}

	cx_opword_cov: cross opsel_cov,oprtn_cov;


	// ADD	
	// check coverage for addition  operations
	add_cov: cross aluin1_cov, aluin2_cov, opsel_cov, oprtn_cov,carry_cov,en_arith_cov
			{
		bins add_ffs = 	binsof(aluin1_cov.allfs) && binsof(aluin2_cov.allfs) && binsof(opsel_cov) && binsof(oprtn_cov.value0) && binsof(en_arith_cov.enable);							
		bins add_spec =	binsof(aluin1_cov.special1) && binsof(aluin2_cov.special2) && binsof(opsel_cov) && binsof(oprtn_cov.value0) &&binsof(en_arith_cov.enable);			
		bins add_pos =	binsof(aluin1_cov.positive) && binsof(aluin2_cov.positive) && binsof(opsel_cov) && binsof(oprtn_cov.value0) &&binsof(carry_cov) &&binsof(en_arith_cov.enable);						
		bins add_neg =	binsof(aluin1_cov.negative) && binsof(aluin2_cov.negative) && binsof(opsel_cov) && binsof(oprtn_cov.value0) &&binsof(carry_cov) &&binsof(en_arith_cov.enable);
		bins add_any =	binsof(opsel_cov) && binsof(oprtn_cov.value0) &&binsof(carry_cov) &&binsof(en_arith_cov.enable);

	}

	
	// SUB coverage

	sub_cov: cross aluin1_cov, aluin2_cov, opsel_cov, oprtn_cov,carry_cov,en_arith_cov
	{
		bins subffs = 	binsof(aluin1_cov.allfs) && binsof(aluin2_cov.allfs) && binsof(opsel_cov) && binsof(oprtn_cov.value2) && binsof(en_arith_cov.enable);						
		bins subspec =	binsof(aluin1_cov.special1) && binsof(aluin2_cov.special2) && binsof(opsel_cov) && binsof(oprtn_cov.value2) && binsof(en_arith_cov.enable);				
		bins subpos =  	binsof(aluin1_cov.positive) && binsof(aluin2_cov.positive) && binsof(opsel_cov) && binsof(oprtn_cov.value2) &&binsof(carry_cov) && binsof(en_arith_cov.enable);							
		bins subneg =  	binsof(aluin1_cov.negative) && binsof(aluin2_cov.negative) && binsof(opsel_cov) && binsof(oprtn_cov.value2) &&binsof(carry_cov) && binsof(en_arith_cov.enable);
		bins subany =	binsof(opsel_cov) && binsof(oprtn_cov.value2) &&binsof(carry_cov) && binsof(en_arith_cov.enable);

	}




	//HADD

	hadd_cov: cross h_aluin1_cov, h_aluin2_cov, opsel_cov, oprtn_cov,carry_cov,en_arith_cov
	{
		bins hadd_subffs = 	binsof(h_aluin1_cov.allfs) && binsof(h_aluin2_cov.allfs) && binsof(opsel_cov) && binsof(oprtn_cov.value1)&& binsof(en_arith_cov.enable);							
		bins hadd_subspec =	binsof(h_aluin1_cov.special1) && binsof(h_aluin2_cov.special2) && binsof(opsel_cov) && binsof(oprtn_cov.value1)&& binsof(en_arith_cov.enable);		
		bins hadd_subpos =	binsof(h_aluin1_cov.positive) && binsof(h_aluin2_cov.positive) && binsof(opsel_cov) && binsof(oprtn_cov.value1)&&binsof(carry_cov) && binsof(en_arith_cov.enable);						
		bins hadd_subneg =	binsof(h_aluin1_cov.negative) && binsof(h_aluin2_cov.negative) && binsof(opsel_cov) && binsof(oprtn_cov.value1)&&binsof(carry_cov) && binsof(en_arith_cov.enable);
		bins hadd_subany =	binsof(opsel_cov) && binsof(oprtn_cov.value1)&&binsof(carry_cov) && binsof(en_arith_cov.enable);

	}


	// Logic operations - 

	logic_cov: cross aluin1_cov,aluin2_cov,opsel_cov,oprtn_cov,carry_cov
	{
		
		bins aNd = 	binsof(aluin1_cov) && binsof(aluin2_cov) && binsof(opsel_cov) && binsof(oprtn_cov.value4)&&  binsof(carry_cov.low);
		bins nOt = 	binsof(aluin1_cov) && binsof(aluin2_cov) && binsof(opsel_cov) && binsof(oprtn_cov.value3)&&  binsof(carry_cov.low);
		bins oR = 	binsof(aluin1_cov) && binsof(aluin2_cov) && binsof(opsel_cov) && binsof(oprtn_cov.value5)&&  binsof(carry_cov.low);
		bins xOr = 	binsof(aluin1_cov) && binsof(aluin2_cov) && binsof(opsel_cov) && binsof(oprtn_cov.value6)&&  binsof(carry_cov.low);
		bins lHg = 	binsof(aluin1_cov) && binsof(aluin2_cov) && binsof(opsel_cov) && binsof(oprtn_cov.value7)&&  binsof(carry_cov.low);
	}		
				
endgroup


/*
*Coverage to exercise the Shift block 
*/
	covergroup Shift_Cov; 

	//// ip side enable	
	dev_en_cov:coverpoint  pkt_sent.enable;

	//// Intermediate ips for enable
	en_shift_cov:coverpoint pkt_cmp.enable_shift
	{
		bins enabled  = {1};
        bins disabled = {0};
	}

	//// coverage for carry
	carry_cov: coverpoint pkt_cmp.carry
	{
		bins low = {0};
		bins high = {1};
	}

	//// check coverage for all possible airthmetic operations 
	opsel_cov: coverpoint pkt_cmp.opselect
	{
		bins shift ={0};
	}

	oprtn_cov: coverpoint pkt_cmp.operation
	{
		bins value0 ={0};
		bins value1 ={1};
		bins value2 ={2};
		bins value3 ={3};
		bins value4 ={4};
		bins value5 ={5};
		bins value6 ={6};
		bins value7 ={7};
	}

	//// alu1
	
	
	aluin1_cov: coverpoint pkt_cmp.aluin1
	{
				bins zero = {0};
				bins allfs = {32'hffffffff};
				bins special1 = {32'h55555555};
				bins special2 = {32'haaaaaaaa};
				bins positive = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b0);
				bins negative = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b1);
//					wildcard bins positive = {32'b0???????????????????????????????};
//					wildcard bins negative = {32'b1???????????????????????????????};
	}

	////leftlog shift coverage

	shleftlog_cov: cross aluin1_cov,oprtn_cov,opsel_cov,carry_cov{
		
		// normal bin
		bins shleftlog_nrml= binsof(aluin1_cov) &&binsof(opsel_cov) && binsof(oprtn_cov.value0) && binsof(carry_cov.low) ;
		
		// negative bin
		bins shleftlog_neg= binsof(aluin1_cov.negative) &&binsof(opsel_cov) && binsof(oprtn_cov.value0) && binsof(carry_cov.low) ;

		// positive bin
		bins shleftlog_pos= binsof(aluin1_cov.positive) &&binsof(opsel_cov) && binsof(oprtn_cov.value0) && binsof(carry_cov.low) ;
	}


		// left shift arithmetic coverage
	shleftarith_cov: cross aluin1_cov,oprtn_cov,opsel_cov,carry_cov{
		
		// normal bin
		bins 	shleftarith_nrml= binsof(aluin1_cov) &&binsof(opsel_cov) && binsof(oprtn_cov.value1)  &&binsof(carry_cov) ;
		
		// negative bin
		bins 	shleftarith_neg= binsof(aluin1_cov.negative) &&binsof(opsel_cov) &&  binsof(oprtn_cov.value1) &&binsof(carry_cov) ;

		// positive bin
		bins 	shleftarith_pos= binsof(aluin1_cov.positive) &&binsof(opsel_cov) &&  binsof(oprtn_cov.value1) &&binsof(carry_cov) ;
	}

	// right shift logical coverage
	shrghtlog_cov: cross aluin1_cov,oprtn_cov,opsel_cov,carry_cov{
		
		// normal bin
		bins 	shrghtlog_nrml= binsof(aluin1_cov) &&binsof(opsel_cov) && binsof(oprtn_cov.value2) &&  binsof(carry_cov.low);
		
		// negative bin
		bins 	shrghtlog_neg= binsof(aluin1_cov.negative) &&binsof(opsel_cov) &&binsof(oprtn_cov.value2) && binsof(carry_cov.low);

		// positive bin
		bins	shrghtlog_pos= binsof(aluin1_cov.positive) &&binsof(opsel_cov) &&binsof(oprtn_cov.value2) && binsof(carry_cov.low);
	}


	// right shift arithmetic coverage
	shrghtarith_cov: cross aluin1_cov,oprtn_cov,opsel_cov,carry_cov{
		
		// normal bin
		bins 	shrghtarith_nrml= binsof(aluin1_cov) &&binsof(opsel_cov) &&binsof(oprtn_cov.value3) && binsof(carry_cov.low);			
		// negative bin
		bins shrghtarith_neg= binsof(aluin1_cov.negative) &&binsof(opsel_cov) &&binsof(oprtn_cov.value3) && binsof(carry_cov.low);

		// positive bin
		bins shrghtarith_pos= binsof(aluin1_cov.positive) &&binsof(opsel_cov) &&binsof(oprtn_cov.value3) && binsof(carry_cov.low);
	}


endgroup


	/*
	*Covergroup for coveragr collection with regard to Mem Read Operation
		*/

covergroup Mem_Rd_Cov;

		//// ip side enable	
		dev_en_cov:coverpoint  pkt_sent.enable;

	//// check coverage for all possible airthmetic operations 
	opsel_cov: coverpoint pkt_cmp.opselect{
						bins mem_read ={5};
			}

	oprtn_cov: coverpoint pkt_cmp.operation
	{
		bins value0 ={0};
		bins value1 ={1};
		bins value2 ={2};
		bins value3 ={3};
		bins value4 ={4};
		bins value5 ={5};
		bins value6 ={6};
		bins value7 ={7};
	}

	carry_cov:coverpoint pkt_cmp.carry
	{
		bins low = {0};
		bins high = {0};
	}

	//// alu1
	
	
	aluin2_cov: coverpoint pkt_cmp.aluin2 {
				bins zero = {0};
				bins allfs = {32'hffffffff};
				bins special1 = {32'h55555555};
				bins special2 = {32'haaaaaaaa};
				bins value_range0 = {[32'h0: 32'hf]};
				bins value_range1 = {[32'hf: 32'hff]};
				bins value_range2 = {[32'hff: 32'hfff]};
				bins value_range3 = {[32'hfff: 32'hffff]};
				bins value_range4 = {[32'hffff: 32'hfffff]};
				bins value_range5 = {[32'hfffff: 32'hffffff]};
				bins value_range6 = {[32'hffffff: 32'hfffffff]};
				bins value_range7 = {[32'hfffffff: 32'hffffffff]};
				bins positive = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b0);
				bins negative = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b1);
	}

	aluin2_7cov: coverpoint pkt_cmp.aluin2 {
				bins zero = {[0:'1]} iff ((pkt_cmp.aluin2[7:0] == 8'h00));
				bins allfs = {[0:'1]} iff ((pkt_cmp.aluin2[7:0] == 8'hff));
				bins special1 = {[0:'1]} iff ((pkt_cmp.aluin2[7:0] == 8'h55));
					bins special2 = {[0:'1]} iff ((pkt_cmp.aluin2[7:0] == 8'haa));
				bins positive = {[0:'1]} iff(pkt_cmp.aluin2[7] == 1'b0);
				bins negative = {[0:'1]} iff(pkt_cmp.aluin2[7] == 1'b1);
	}		

	aluin2_15cov: coverpoint pkt_cmp.aluin2 {
				bins zero = {[0:'1]} iff ((pkt_cmp.aluin2[15:0] == 16'h0000));
				bins allfs = {[0:'1]} iff ((pkt_cmp.aluin2[15:0] == 16'hffff));
				bins special1 = {[0:'1]} iff ((pkt_cmp.aluin2[15:0] == 16'h5555));
					bins special2 = {[0:'1]} iff ((pkt_cmp.aluin2[15:0] == 16'haaaa));
				bins positive = {[0:'1]} iff(pkt_cmp.aluin2[15] == 1'b0);
				bins negative = {[0:'1]} iff(pkt_cmp.aluin2[15] == 1'b1);

	}


	//ip coverage for load byte operation 	

	load_byte_cov: cross aluin2_7cov,opsel_cov,oprtn_cov,carry_cov{
				bins ld_byte= binsof(aluin2_7cov) &&
							binsof(opsel_cov) &&
								binsof(oprtn_cov.value0) &&
							 binsof(carry_cov.low);
						}

	load_byteu_cov: cross aluin2_7cov,opsel_cov,oprtn_cov,carry_cov{
				bins ld_byteu= binsof(aluin2_7cov) &&
							binsof(opsel_cov) &&
								binsof(oprtn_cov.value4) &&
							 binsof(carry_cov.low);
						}
	load_half_cov: cross aluin2_15cov,opsel_cov,oprtn_cov,carry_cov{
				bins ld_half= binsof(aluin2_15cov) &&
							binsof(opsel_cov) &&
								binsof(oprtn_cov.value1) &&
							 binsof(carry_cov.low);
						}
	load_halfu_cov: cross aluin2_15cov,opsel_cov,oprtn_cov,carry_cov{
					bins ld_halfu= binsof(aluin2_15cov) &&
							binsof(opsel_cov) &&
								binsof(oprtn_cov.value5) &&
							 binsof(carry_cov.low);
						}
	load_word_cov: cross aluin2_cov,opsel_cov,oprtn_cov,carry_cov{
					bins ld_word=  binsof(aluin2_cov) &&
							binsof(opsel_cov) &&
								binsof(oprtn_cov.value3) &&
							 binsof(carry_cov.low);
						}
endgroup



covergroup Mem_Write;

	dev_en_cov:coverpoint  pkt_sent.enable;

	//// check coverage for all possible airthmetic operations 
	opsel_cov: coverpoint pkt_cmp.opselect{
						bins mem_write ={4};
			}

	oprtn_cov: coverpoint pkt_cmp.operation;
	

	wr_enable:coverpoint pkt_cmp.mem_write_en;

	wr_data: coverpoint pkt_cmp.mem_data_write_out{
					bins zero = {0};
					bins allfs = {32'hffffffff};
					bins special1 = {32'h55555555};
					bins special2 = {32'haaaaaaaa};
					bins value_range0 = {[32'h0: 32'hf]};
					bins value_range1 = {[32'hf: 32'hff]};
					bins value_range2 = {[32'hff: 32'hfff]};
					bins value_range3 = {[32'hfff: 32'hffff]};
					bins value_range4 = {[32'hffff: 32'hfffff]};
					bins value_range5 = {[32'hfffff: 32'hffffff]};
					bins value_range6 = {[32'hffffff: 32'hfffffff]};
					bins value_range7 = {[32'hfffffff: 32'hffffffff]};
					bins positive = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b0);
					bins negative = {[0:'1]} iff(pkt_cmp.aluin1[31] == 1'b1);
				}	



	opcode:	cross  opsel_cov,oprtn_cov;


	write_op: cross opsel_cov,oprtn_cov,wr_data,wr_enable{

		bins write = binsof(opsel_cov) &&
					binsof(oprtn_cov) &&
					binsof(wr_data) &&
					binsof(wr_enable);
	}
endgroup
covergroup Pre_processor_2_ALU;
    pre_src1_cov: coverpoint pkt_sent.src1 {
          option.auto_bin_max = 0;
          bins zero = {0};
          bins allfs = {32'hffffffff};
          bins special1 = {32'h00005555};
          bins special2 = {32'h0000aaaa};
          bins positive = {[0:'1]} iff(pkt_sent.src1[31] == 1'b0);
          bins negative = {[0:'1]} iff(pkt_sent.src1[31] == 1'b1);
//          wildcard bins positive = {32'b0???????????????????????????????};
//          wildcard bins negative = {32'b1???????????????????????????????};
    }
    pre_src2_cov: coverpoint pkt_sent.src2 {
          option.auto_bin_max = 0;
          bins zero = {0};
          bins allfs = {32'hffffffff};
          bins special1 = {32'h00005555};
          bins special2 = {32'h0000aaaa};
          bins positive = {[0:'1]} iff(pkt_sent.src2[31] == 1'b0);
          bins negative = {[0:'1]} iff(pkt_sent.src2[31] == 1'b1);
//          wildcard bins positive = {32'b0???????????????????????????????};
//          wildcard bins negative = {32'b1???????????????????????????????};
    }
    pre_imm_cov: coverpoint pkt_sent.imm {
          option.auto_bin_max = 0;
          bins zero = {0};
          bins allfs = {32'hffffffff};
          bins special1 = {32'h00005555};
          bins special2 = {32'h0000aaaa};
          bins positive = {[0:'1]} iff(pkt_sent.imm[31] == 1'b0);
          bins negative = {[0:'1]} iff(pkt_sent.imm[31] == 1'b1);     
    }
    pre_opselect_cov: coverpoint pkt_sent.opselect_gen {
          option.auto_bin_max = 0;
          bins shift = {0};
          bins arith = {1};
          bins mem = {[4:5]};
    }
    pre_immp_regn_op_gen_cov: coverpoint pkt_sent.immp_regn_op_gen{
          option.auto_bin_max = 0;
          bins zero = {0};
          bins one = {1};
    }
    pre_mem_data_cov: coverpoint pkt_sent.mem_data{
          option.auto_bin_max = 0;
          bins zero = {0};
          bins allfs = {32'hffffffff};
          bins special1 = {32'h00005555};
          bins special2 = {32'h0000aaaa};
          bins positive = {[0:'1]} iff(pkt_sent.mem_data[31] == 1'b0);
          bins negative = {[0:'1]} iff(pkt_sent.mem_data[31] == 1'b1);
//          wildcard bins positive = {32'b0???????????????????????????????};
//          wildcard bins negative = {32'b1???????????????????????????????};
    }
    pre_opn_cov: coverpoint pkt_sent.operation_gen;
    pre_enable_cov : coverpoint pkt_sent.enable{
          option.auto_bin_max = 0;
          bins zero = {0};
          bins one = {1};
    }
    preprocessing_cov: cross pre_src1_cov, pre_src2_cov, pre_imm_cov, pre_immp_regn_op_gen_cov, pre_opn_cov, pre_opselect_cov, pre_enable_cov, pre_mem_data_cov
    {
      option.cross_auto_bin_max=0;
      // No change at all
      bins pre_NC = binsof(pre_src1_cov) && binsof(pre_src2_cov) && binsof(pre_imm_cov) &&
                    binsof(pre_opn_cov) && binsof(pre_opselect_cov) && binsof(pre_mem_data_cov) &&
                    binsof(pre_immp_regn_op_gen_cov) && binsof(pre_enable_cov.zero);

      bins pre_arith_aluin2_is_src2= binsof(pre_src1_cov) && binsof(pre_src2_cov) && binsof(pre_imm_cov) &&
                                     binsof(pre_opn_cov) && binsof(pre_opselect_cov.arith) && binsof(pre_mem_data_cov) &&
                                     binsof(pre_enable_cov.one) && binsof(pre_immp_regn_op_gen_cov) intersect {0};

      bins pre_arith_aluin2_is_imm=  binsof(pre_src1_cov) && binsof(pre_src2_cov) && binsof(pre_imm_cov) &&
                                     binsof(pre_opn_cov) && binsof(pre_opselect_cov.arith) && binsof(pre_mem_data_cov) &&
                                     binsof(pre_enable_cov.one) && binsof(pre_immp_regn_op_gen_cov) intersect {1};

      bins pre_mread_aluin2_NC =     binsof(pre_src1_cov) && binsof(pre_src2_cov) && binsof(pre_imm_cov) &&
                                     binsof(pre_opn_cov) && binsof(pre_opselect_cov.mem) && binsof(pre_mem_data_cov) &&
                                     binsof(pre_enable_cov.one) && binsof(pre_immp_regn_op_gen_cov) intersect {0};

      bins pre_mread_aluin2_is_mdata = binsof(pre_src1_cov) && binsof(pre_src2_cov) && binsof(pre_imm_cov) &&
                                     binsof(pre_opn_cov) && binsof(pre_opselect_cov.mem) && binsof(pre_mem_data_cov) &&
                                     binsof(pre_enable_cov.one) && binsof(pre_immp_regn_op_gen_cov) intersect {1};
                                    
      bins pre_shift =               binsof(pre_src1_cov) && binsof(pre_src2_cov) && binsof(pre_imm_cov) &&
                                     binsof(pre_opn_cov) && binsof(pre_opselect_cov.shift) && binsof(pre_mem_data_cov) &&
                                     binsof(pre_enable_cov.one) && binsof(pre_immp_regn_op_gen_cov);  
    }

endgroup



//----------------------------------------------------------------------------------------------------------------------------------------------------------
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
// COVERAGE ADDITION 
       /* Arith_Cov_Ver1 = new();*/
	//Arith_Cov_Ver2 = new();
	/*Arith_Cov_Ver3 = new();*/
	All_Ip_Operands_Cov =new();
	All_Inter_Operands_Cov =new();
	Arith_Cov=new();
	Shift_Cov=new();
	Mem_Rd_Cov=new();
	Mem_Write=new();
endfunction

task Scoreboard::start();
       $display ($time, "[SCOREBOARD] Scoreboard Started");

       $display ($time, "[SCOREBOARD] Receiver Mailbox contents = %d", receiver_mbox.num());
       fork
	       forever 
	       begin
          
		       if(receiver_mbox.try_get(pkt_cmp)) begin
			       $display ($time, "[SCOREBOARD] Grabbing Data From both Driver and Receiver");
			       //receiver_mbox.get(pkt_cmp);
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

  /* // COVERAGE ADDITION */
	//Arith_Cov_Ver1.sample();		
	//Arith_Cov_Ver2.sample();		
	/*Arith_Cov_Ver3.sample();*/
	All_Ip_Operands_Cov.sample();
	All_Inter_Operands_Cov.sample();
	Arith_Cov.sample();
	Shift_Cov.sample();
	Mem_Rd_Cov.sample();
	Mem_Write.sample();	

       /* coverage_value1 = 	Arith_Cov_Ver1.get_coverage();*/
	//coverage_value2 = 	Arith_Cov_Ver2.get_coverage();
	/*coverage_value3 =   	Arith_Cov_Ver3.get_coverage();*/
	coverage_value1 = 		All_Ip_Operands_Cov.get_coverage();
	coverage_value2=        All_Inter_Operands_Cov.get_coverage();
	coverage_value3=        Arith_Cov.get_coverage();
	coverage_value4=        Shift_Cov.get_coverage();
	coverage_value5=        Mem_Rd_Cov.get_coverage();
	coverage_value6=        Mem_Write.get_coverage();

	$display ($time, "			[SCOREBOARD -> COVERAGE] Coverage Result for cover 1 At present = %d", coverage_value1);
	$display ($time, "			[SCOREBOARD -> COVERAGE] Coverage Result for cover 2 At present = %d", coverage_value2);
	$display ($time, "			[SCOREBOARD -> COVERAGE] Coverage Result for cover 3 At present = %d", coverage_value3);
	$display ($time, "			[SCOREBOARD -> COVERAGE] Coverage Result for cover 4 At present = %d", coverage_value4);
	$display ($time, "			[SCOREBOARD -> COVERAGE] Coverage Result for cover 5 At present = %d", coverage_value5);
    $display ($time, "			[SCOREBOARD -> COVERAGE] Coverage Result for cover 6 At present = %d", coverage_value6);
	//$display ($time, "			[SCOREBOARD -> COVERAGE] Coverage Result for cover 7 At present = %d", coverage_value7);
	/*$display ($time, "			[SCOREBOARD -> COVERAGE] Coverage Result for cover 8 At present = %d", coverage_value8);*/


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

	ASSERT_aluout: assert (pkt_cmp.aluout == pre_aluout_chk[31:0]) begin
    $display($time, "ns:   [ASSERT_aluout] PASS ALUOUT: DUT = %h   & Golden Model = %h\n", pkt_cmp.aluout, pre_aluout_chk);
    num_tests ++;
    num_tests_passed ++;
  end	else begin
    $display($time, "ns:   [ASSERT_aluout] FAIL ALUOUT: DUT = %h   & Golden Model = %h\n", pkt_cmp.aluout, pre_aluout_chk);	
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

	ASSERT_mem_data_write_out: assert(pkt_cmp.mem_data_write_out == memout_chk)  begin
    $display($time, "ns: [ASSERT_mem_data_write_out] MEM_WRITE PASS mem_DUT = %h    mem_GOL = %h\n", pkt_cmp.mem_data_write_out, memout_chk);
    num_tests ++;
    num_tests_passed++;
  end else begin 
    $display($time, "ns: [ASSERT_mem_data_write_out] MEM_WRITE FAIL mem_DUT = %h    mem_GOL = %h\n", pkt_cmp.mem_data_write_out, memout_chk);
    num_tests ++;
    num_tests_failed++;
  end



	ASSERT_mem_write_en: assert(pkt_cmp.mem_write_en == mem_en_chk) begin
    $display($time, "ns: [ASSERT_mem_write_en] MEM_EN PASS mem_DUT = %h    mem_GOL = %h\n", pkt_cmp.mem_write_en, mem_en_chk);
    num_tests ++;
    num_tests_passed ++;
  end	else begin
    $display($time, "ns: [ASSERT_mem_write_en] MEM_EN FAIL mem_DUT = %h    mem_GOL = %h\n", pkt_cmp.mem_write_en, mem_en_chk);
    num_tests ++;
    num_tests_failed ++;
  end

	ASSERT_aluin1: assert (pkt_cmp.aluin1 == aluin1_chk) begin
    $display($time, "ns:   [ASSERT_aluin1] PASS ALUIN1: DUT = %h   & Golden Model = %h\n", pkt_cmp.aluin1, aluin1_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin
	  $display($time, "ns:   [ASSERT_aluin1] FAIL ALUIN1: DUT = %h   & Golden Model = %h\n", pkt_cmp.aluin1, aluin1_chk);
    num_tests ++;
    num_tests_failed ++;
  end	
	ASSERT_aluin2: assert (pkt_cmp.aluin2 == aluin2_chk) begin
    $display($time, "ns:   [ASSERT_aluin2] PASS ALUIN2: DUT = %h   & Golden Model = %h\n", pkt_cmp.aluin2, aluin2_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin    
    $display($time, "ns:   [ASSERT_aluin2] PASS ALUIN2: DUT = %h   & Golden Model = %h\n", pkt_cmp.aluin2, aluin2_chk);	
    num_tests ++;
    num_tests_failed ++;
  end
  ASSERT_enable_arith: assert (pkt_cmp.enable_arith == enable_arith_chk) begin
    $display($time, "ns:   [ASSERT_enable_arith] PASS ENABLE_ARITH: DUT = %b   & Golden Model = %b\n", pkt_cmp.enable_arith, enable_arith_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin
    $display($time, "ns:   [ASSERT_enable_arith] FAIL ENABLE_ARITH: DUT = %b   & Golden Model = %b\n", pkt_cmp.enable_arith, enable_arith_chk);
    num_tests ++;
    num_tests_failed ++;
  end
  ASSERT_enable_shift: assert (pkt_cmp.enable_shift == enable_shift_chk) begin
    $display($time, "ns:   [ASSERT_enable_shift] PASS ENABLE_SHIFT: DUT = %h   & Golden Model = %h\n", pkt_cmp.enable_shift, enable_shift_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin
    $display($time, "ns:   [ASSERT_enable_shift] FAIL ENABLE_SHIFT: DUT = %h   & Golden Model = %h\n", pkt_cmp.enable_shift, enable_shift_chk);
    num_tests ++;
    num_tests_failed ++;
  end
  ASSERT_operation: assert (pkt_cmp.operation == operation_chk) begin
    $display($time, "ns:   [ASSERT_operation] PASS OPERATION: DUT = %h   & Golden Model = %h\n", pkt_cmp.operation, operation_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin
    $display($time, "ns:   [ASSERT_operation] FAIL OPERATION: DUT = %h   & Golden Model = %h\n", pkt_cmp.operation, operation_chk);
    num_tests ++;
    num_tests_failed ++;
  end	
	ASSERT_opselect: assert (pkt_cmp.opselect == opselect_chk) begin
    $display($time, "ns:   [ASSERT_opselect] PASS OPSELECT: DUT = %h   & Golden Model = %h\n", pkt_cmp.opselect, opselect_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin       
    $display($time, "ns:   [ASSERT_opselect] FAIL OPSELECT: DUT = %h   & Golden Model = %h\n", pkt_cmp.opselect, opselect_chk);
    num_tests ++;
    num_tests_failed ++;
  end
	ASSERT_shift_number: assert (pkt_cmp.shift_number == shift_number_chk) begin
    $display($time, "ns:   [ASSERT_shift_number] PASS SHIFT_NUMBER: DUT = %h   & Golden Model = %h\n", pkt_cmp.shift_number, shift_number_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin	       	
    $display($time, "ns:   [ASSERT_shift_number] FAIL SHIFT_NUMBER: DUT = %h   & Golden Model = %h\n", pkt_cmp.shift_number, shift_number_chk);
    num_tests ++;
    num_tests_failed ++;
  end


  ASSERT_carry: assert (pkt_cmp.carry == carry_chk) begin
    $display($time, "ns:   [ASSERT_carry_flag] PASS CARRY_FLAG: DUT = %h       & Golden Model = %h\n", pkt_cmp.carry, carry_chk);
    num_tests ++;
    num_tests_passed ++;
  end else begin	       	
    $display($time, "ns:   [ASSERT_carry_flag] FAIL CARRY_FLAG: DUT = %h       & Golden Model = %h\n", pkt_cmp.carry, carry_chk);
    num_tests ++;
    num_tests_failed ++;
  end



endtask