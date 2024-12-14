module alu(
    input       [3:0]   A,
    input       [3:0]   B,
    input       [2:0]   opcode,
    output reg  [3:0]   result,
    output reg          carry_out,
    output reg          zero
);
localparam ADD = 3'b000,   // ADDITION
           SUB = 3'b001,   // SUBTRACTION
           AND = 3'b010,   // AND
           OR = 3'b011,    // OR
           XOR = 3'b100,   // XOR
           NAND = 3'b101,  // NAND
           NOR = 3'b110,   // NOR
           SLT = 3'b111;   // SET LESS THAN (A < B)

always @(*) begin
    // Default values
    carry_out = 0;
    zero = 0;

    case (opcode)
        ADD: begin
            {carry_out, result} = A + B;  // Addition with carry
        end

        SUB: begin
            {carry_out, result} = A - B;  // Subtraction with borrow (carry_out as borrow)
        end

        AND: begin
            result = A & B;   // AND operation
        end

        OR: begin
            result = A | B;    // OR operation
        end

        XOR: begin
            result = A ^ B;    // XOR operation
        end

        NAND: begin
            result = ~(A & B); // NAND operation
        end

        NOR: begin
            result = ~(A | B); // NOR operation
        end

        SLT: begin
            // Set Less Than: result = 1 if A < B, else 0
            result = (A < B) ? 4'b0001 : 4'b0000;
        end

        default: begin
            result = 4'b0000;  // Default result
        end
    endcase

    // Zero flag
    zero = (result == 4'b0000) ? 1 : 0;
end


endmodule