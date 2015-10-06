module project04_tb_jj();
	logic clk, reset, left, right;
	logic la, lb, lc, ra, rb, rc;
  
	project04_jj turnsignal(.clk, .reset, .left, .right,
									.la, .lb, .lc, .ra, .rb, .rc);

	// generate clock with 100 ns period
	initial
		forever begin
			clk = 0; #50; clk = 1; #50;
		end  
    
	// apply inputs
	initial begin 
		#10; // wait a bit so transitions don't occur on the clock edge

		// cycle 0: reset turn signal
		reset = 1;
		left = 0;
		right = 0;
		#100;

		// cycle 1: left turn
		reset = 0;
		left = 1;
		#400;
		
		// cycle 2: right turn
		left = 0;
		right = 1;
		#400;
		
		// cycle 3: left turn
		right = 0;
		left = 1;
		#100;
		
		// cycle 4: switch to right turn in the middle
		left = 0;
		right = 1;
		#100;
	end
    
endmodule
