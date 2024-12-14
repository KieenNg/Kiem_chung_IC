`timescale 1ns/1ns
`include "interface.sv"


module alu_tb ();
    alu_if vif();
    alu dut(
        .A          (vif.a_if),
        .B          (vif.b_if),
        .opcode     (vif.opcode_if),
        .result     (vif.result_if),
        .carry_out  (vif.carry_out_if),
        .zero       (vif.zero_if)
    );
    
endmodule