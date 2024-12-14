class Packet;
    rand reg [3:0] A;
    rand reg [3:0] B;
    rand reg [2:0] opcode;

    string name;
    extern function new(string name = "Packet");
endclass

function Packet::new(string name = "Packet");
    this.name = name;
endfunction