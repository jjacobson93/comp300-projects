module alu32_tb();
	logic clk;
	logic [31:0] a, b, y;
	logic [2:0] f;
	logic zero, carry_out, overflow;
	
	logic [111:0] test_vectors [32:0]; // 33 test vectors, each with 112 bits
	logic [111:0] test;
	
	integer test_num;
  
	alu #(32) alu32(.a, .b, .f, .y, .zero, .carry_out, .overflow);
	
	initial
		forever begin
			clk = 0; #50; clk = 1; #50;
		end
    
	// apply inputs
	initial
	begin 
		$readmemh("alu32.tv", test_vectors);
		//@(negedge clk);
		
		f = 0;
		a = 0;
		b = 0;
		
		for (test_num = 0; test_num < 25; test_num = test_num + 1)
		begin
			//@(negedge clk);
			test = test_vectors[test_num];
			f = test[111:108];
			a = test[107:76];
			b = test[75:44];
			
			#25;

			
			if (y !== test[43:12])
			begin
				$display("%d: y should be %h, not %h", test_num, test[43:12], y);
			end
			
			if (zero !== test[8])
			begin
				$display("%d: zero should be %h, not %h", test_num, test[8], zero);
			end
			
			#50;
		end
	end
    
endmodule
