`include "data_defs.v"
`include "Packet.sv"
class Generator;
	string  name;		
	Packet  pkt2send;	

  typedef mailbox #(Packet) in_box_type;
	in_box_type in_box;
	
	int		packet_number;
	int 	number_packets;
	extern function new(string name = "Generator", int number_packets);
	extern virtual task gen(string test_name);
	extern virtual task start(string test_name);

  // function int contains(string a, string b);
  //   // checks if string A contains string B
  //   int len_a;
  //   int len_b;
  //   len_a = a.len();
  //   len_b = b.len();
  //   $display("a (%s) len %d -- b (%s) len %d", a, len_a, b, len_b);
  //   for( int i=0; i<len_a; i++) begin
  //     if(a.substr(i,i+len_b-1) == b)
  //          return 1;
  //   end
  //   return 0;
  // endfunction
endclass

function Generator::new(string name = "Generator", int number_packets);
	this.name = name;
	this.pkt2send = new();
	this.in_box = new;
	this.packet_number = 0;
	this.number_packets = number_packets;
endfunction

task Generator::gen(string test_name);
	pkt2send.name = $psprintf("Packet[%0d]", packet_number++);

  // setup constrain mode for packet
  pkt2send.data.constraint_mode(1);
  pkt2send.all_op.constraint_mode(0);
  pkt2send.arith_logic.constraint_mode(0);
  pkt2send.shift_reg.constraint_mode(0);
  pkt2send.mem_read.constraint_mode(0);
  pkt2send.mem_write.constraint_mode(0);

  if(contains(test_name,"all_op")) begin
    pkt2send.all_op.constraint_mode(1);
    if (!pkt2send.randomize()) 
    begin
      $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed with all_op test!", $time);
      $finish;	
    end
  end else if(contains(test_name,"arith_logic")) begin
    pkt2send.arith_logic.constraint_mode(1);
    if(contains(test_name,"only_add")) begin
      if (!pkt2send.randomize() with {operation_gen == `ADD;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With arith_logic and only_add test!", $time);
        $finish;	
      end
    end else if(contains(test_name,"only_hadd")) begin
      if (!pkt2send.randomize() with {operation_gen == `HADD;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With arith_logic and only_hadd test!", $time);
        $finish;	
      end
    end else if(contains(test_name,"only_sub"))  begin
      if (!pkt2send.randomize() with {operation_gen == `SUB;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With arith_logic and only_sub test!", $time);
        $finish;	
      end
    end else if(contains(test_name,"only_not"))  begin
      if (!pkt2send.randomize() with {operation_gen == `NOT;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With arith_logic and only_not test!", $time);
        $finish;	
      end
    end else if(contains(test_name,"only_and"))  begin
      if (!pkt2send.randomize() with {operation_gen == `AND;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With arith_logic and only_and test!", $time);
        $finish;	
      end
    end else if(contains(test_name,"only_or"))   begin
      if (!pkt2send.randomize() with {operation_gen == `OR;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With arith_logic and only_or test!", $time);
        $finish;	
      end
    end else if(contains(test_name,"only_xor"))  begin
      if (!pkt2send.randomize() with {operation_gen == `XOR;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With arith_logic and only_xor test!", $time);
        $finish;	
      end
    end else if(contains(test_name,"only_lhg"))  begin
      if (!pkt2send.randomize() with {operation_gen == `LHG;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With arith_logic and only_lhg test!", $time);
        $finish;	
      end
    end else begin
      if (!pkt2send.randomize()) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With arith_logic test!", $time);
        $finish;	
      end
    end
  end else if(contains(test_name, "shift_reg")) begin
    pkt2send.shift_reg.constraint_mode(1);
    if(contains(test_name,"only_shleftlog")) begin
      if (!pkt2send.randomize() with {operation_gen == `SHLEFTLOG;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With shift_reg and only_shleftlog test!", $time);
        $finish;	
      end
    end else 
    if(contains(test_name,"only_shleftart")) begin
      if (!pkt2send.randomize() with {operation_gen == `SHLEFTART;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With shift_reg and only_shleftart test!", $time);
        $finish;	
      end
    end else 
    if(contains(test_name,"only_shrghtlog")) begin
      if (!pkt2send.randomize() with {operation_gen == `SHRGHTLOG;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With shift_reg and only_shrghtlog test!", $time);
        $finish;	
      end
    end else 
    if(contains(test_name,"only_shrghtart")) begin
      if (!pkt2send.randomize() with {operation_gen == `SHRGHTART;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With shift_reg and only_shrghtart test!", $time);
        $finish;	
      end
    end else begin
      if (!pkt2send.randomize()) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With shift_reg test!", $time);
        $finish;	
      end
    end
  end else if(contains(test_name, "mem_read")) begin
    pkt2send.mem_read.constraint_mode(1);
    if(contains(test_name,"only_loadbyte")) begin
      if (!pkt2send.randomize() with {operation_gen == `LOADBYTE;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With mem_read and only_loadbyte test!", $time);
        $finish;
      end
    end else if(contains(test_name,"only_loadbyteu")) begin
      if (!pkt2send.randomize() with {operation_gen == `LOADBYTEU;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With mem_read and only_loadbyteu test!", $time);
        $finish;
      end
    end else if(contains(test_name,"only_loadhalf")) begin
      if (!pkt2send.randomize() with {operation_gen == `LOADHALF;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With mem_read and only_loadhalf test!", $time);
        $finish;
      end
    end else if(contains(test_name,"only_loadhalfu")) begin
      if (!pkt2send.randomize() with {operation_gen == `LOADHALFU;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With mem_read and only_loadhalfu test!", $time);
        $finish;
      end
    end else if(contains(test_name,"only_loadword")) begin
      if (!pkt2send.randomize() with {operation_gen == `LOADWORD;}) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With mem_read and only_loadword test!", $time);
        $finish;
      end
    end else begin
      if (!pkt2send.randomize()) begin
        $display(" \n%m\n[ERROR]%0d gen(): Randomization Failed With mem_read test!", $time);
        $finish;	
      end
    end
  end else if(contains(test_name, "mem_write")) begin
    pkt2send.mem_write.constraint_mode(1);
  end
	pkt2send.enable = $urandom_range(0,1);
	$display ($time, " [GENERATOR] Packet Generation done .. Now to put it in Driver mailbox");	
endtask

task Generator::start(string test_name);
	  $display ($time, "ns:  [GENERATOR] Generator Started");
	  fork
		  for (int i=0; i<number_packets || number_packets <= 0; i++)
		  begin
			  gen(test_name);
			  begin
			      Packet pkt = new pkt2send; 
			      in_box.put(pkt); // FUNNY .. 
			  end
		  end
		  $display($time, "ns:  [GENERATOR] Generation Finished Creating %d Packets  ", number_packets);
      join_none
endtask
