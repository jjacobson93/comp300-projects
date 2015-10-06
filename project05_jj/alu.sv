module alu
			#(parameter WIDTH=16)
			 (input logic [WIDTH-1:0] a, b,
			  input logic [2:0] f,
			  output logic [WIDTH-1:0] y,
			  output logic zero, carry_out, overflow);
	
	always_comb
	begin
		case (f)
			3'b000: // a AND b
				begin
					y = a & b;
				end
			3'b001: // a OR b
				begin
					y = a | b;
				end
			3'b010: // a + b
				begin
					y = a + b;
				end
			//3'b011: // unused
			3'b100: // a XOR b
				begin
					y = a ^ b;
				end
			3'b101: // a NOR b
				begin
					y = ~(a | b);
				end
			3'b110: // a - b
				begin
					y = a - b;
				end
			3'b111: // SLT, i.e. (a < b) ? 1 : 0
				begin
					y = (a - b);
					y = y[WIDTH-1];
				end
			default:
				begin
					y = 0;
				end
				
		endcase
	
		carry_out = 0;
		overflow = 0;
		zero = (y == 0);
	end

endmodule