class Generator;
    string name;
    Packet pkt2send;

    typedef mailbox #(Packet) in_box_type;
    in_box_type in_box;

    int packet_number;
    int number_packets;

    extern function new(string name = "Generator", int number_packets);
    extern virtual task gen(string test_name);
    extern virtual task start(string test_name);
endclass

function Generator::new(string name = "Generator", int number_packets);
    this.name = name;
    this.pkt2send = new();
    this.in_box = new();
    this.packet_number = 0;
    this.number_packets = number_packets;
endfunction

task Generator::gen(string test_name);
    pkt2send.name = $psprintf("Packet[%d]", packet_number++);
    
endtask