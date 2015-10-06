/*
 * logic_devices.sv
 * Author: David Harris
 * Updated By: Sat Garcia
 * Digital logic devices used in a 32-bit MIPS processor.
 */

/*
 * Register file module with 2 read ports and 1 write port.
 * Note that reading is asynchronous while writing is synchronous.
 * Register 0 (i.e. $zero in MIPS) is hardwired to 0 (even if you try to write
 * to it).
 */
module regfile#(parameter NUM_REG=32, WIDTH=32)
			   (input  logic        clk, 
                input  logic        we3, 
                input  logic [$clog2(NUM_REG)-1:0]  ra1, ra2, wa3, 
                input  logic [WIDTH-1:0] wd3, 
                output logic [WIDTH-1:0] rd1, rd2);

	logic [WIDTH-1:0] rf [0:NUM_REG-1];

	always_ff @(posedge clk)
	begin
		if (we3) rf[wa3] <= wd3;	
	end

	assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
	assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule

/*
 * Simple adder module.
 */
module adder#(parameter WIDTH=32)
			 (input  logic [WIDTH-1:0] a, b,
              output logic [WIDTH-1:0] y);

	assign y = a + b;
endmodule

/*
 * Module whose output is the result of shifting the input left by 2.
 */
module shiftleft2#(parameter WIDTH=32)
		   (input  logic [WIDTH-1:0] a,
           	output logic [WIDTH-1:0] y);

	assign y = {a[WIDTH-3:0], 2'b00};
endmodule

/*
 * Module that sign-extends a value.
 */
module signext(input  logic [15:0] a,
               output logic [31:0] y);
              
	assign y = {{16{a[15]}}, a};
endmodule

/*
 * Module that zero-extends a value.
 */
module zeroext(input  logic [15:0] a,
               output logic [31:0] y);
  assign y = {{16'b0}, a};
endmodule

/*
 * Module for a resetable D flip-flop.
 */
module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset,
               input  logic [WIDTH-1:0] d, 
               output logic [WIDTH-1:0] q);

	always_ff @(posedge clk, posedge reset)
	begin
		if (reset) q <= 0;
		else       q <= d;
	end
endmodule

/*
 * Module for a resetable D flip-flop with an additional enable input.
 */
module flopenr #(parameter WIDTH = 8)
                (input  logic             clk, reset,
                 input  logic             en,
                 input  logic [WIDTH-1:0] d, 
                 output logic [WIDTH-1:0] q);
 
	always_ff @(posedge clk, posedge reset)
	begin
		if      (reset) q <= 0;
		else if (en)    q <= d;
	end
endmodule

/*
 * Module for a 2 input multiplexer.
 */
module mux2 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, 
              input  logic             sel, 
              output logic [WIDTH-1:0] y);

	assign y = sel ? d1 : d0; 
endmodule
