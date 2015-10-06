module project04_jj(input logic clk,
						  input logic reset,
						  input logic left, right,
						  output logic la, lb, lc, ra, rb, rc);
			
	typedef enum logic [6:0] {OFF,
									  SL1, SL2, SL3,
									  SR1, SR2, SR3} statetype;
	statetype state;
	
	always_ff@(posedge clk)
		case (state)
			OFF:
				if (left & ~reset) begin
					state <= SL1;
					la <= 1;
				end
				else if (right & ~reset) begin
					state <= SR1;
					ra <= 1;
				end
			// Left turn
		   SL1:
				if (left & ~reset) begin
					state <= SL2;
					lb <= 1;
				end
				else begin
					state <= OFF;
					la <= 0;
				end
			SL2:
				if (left & ~reset) begin
					state <= SL3;
					lc <= 1;
				end
				else begin
					state <= OFF;
					la <= 0; lb <= 0;
				end
			// Right turn
		   SR1: 
				if (right & ~reset) begin
					state <= SR2;
					rb <= 1;
				end
				else begin
					state <= OFF;
					ra <= 0;
				end
			SR2:
				if (right & ~reset) begin
					state <= SR3;
					rc <= 1;
				end
				else begin
					state <= OFF;
					ra <= 0; rb <= 1;
				end
		   default: // handles SL3, SR3
				begin
					state <= OFF;
					la <= 0; lb <= 0; lc <= 0;
					ra <= 0; rb <= 0; rc <= 0;
				end
		endcase
				
		   
endmodule