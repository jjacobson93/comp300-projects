/*
 * memory.sv
 * Author: David Harris
 * Updated By: Sat Garcia
 *
 * External memories used by MIPS single-cycle processor.
 */

/*
 * Module for an asynchronous read, synchronous write memory module.
 */
module dmem(input  logic        clk, write_en,
            input  logic [31:0] addr, write_data,
            output logic [31:0] read_data);

	logic [31:0] RAM[63:0];

	assign read_data = RAM[addr[31:2]]; // word aligned

	always @(posedge clk)
	begin
		if (write_en)
			RAM[addr[31:2]] <= write_data;
	end
endmodule


/*
 * Module for an asynchronous read, synchronous write memory module.
 * The contents of memory is initialized from imem.dat
 *
 * @note This is not synthesizable. Only use this for simulation.
 */
module imem(input  logic [5:0]  addr,
            output logic [31:0] read_data);

	logic [31:0] RAM [0:63];

	initial
	begin
		$readmemh("imem.dat", RAM); // load memory contents from file
	end

	assign read_data = RAM[addr]; // word aligned
endmodule
