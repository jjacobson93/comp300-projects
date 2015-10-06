/*
 * mips_core.sv
 * Authors: David and Sarah Harris
 * Updated By: Sat Garcia
 * Modules for a Single-cycle 32-bit MIPS processor.
 */

module mips_core(input  logic clk, reset,
					output logic [31:0] pc,
					input  logic [31:0] instr,
					output logic dmem_write,
					output logic [31:0] alu_out, dmem_write_data,
					input  logic [31:0] dmem_read_data);

	logic mem_to_reg, branch, pc_src, zero, alu_src, reg_dest, reg_write, ori, brneg, jump;
	logic [2:0] alu_ctrl;

	core_controller c(.op(instr[31:26]), .funct(instr[5:0]), .zero,
						.mem_to_reg, .dmem_write, .pc_src,
						.alu_src, .reg_dest, .reg_write, .ori, .brneg, .jump,
						.alu_ctrl);
	core_datapath dp(.clk, .reset, .mem_to_reg, .pc_src,
						.alu_src, .reg_dest, .reg_write, .ori, .jump,
						.alu_ctrl, .zero, .pc, .instr,
						.alu_out, .dmem_write_data, .dmem_read_data);
endmodule

/*
 * Module that implements control component of processor.
 */
module core_controller(input  logic [5:0] op, funct,
		input  logic       zero,
		output logic       mem_to_reg, dmem_write,
		output logic       pc_src, alu_src,
		output logic       reg_dest, reg_write,
		output logic       ori, brneg,
		output logic       jump,
		output logic [2:0] alu_ctrl);

	logic [1:0] alu_op;
	logic       branch;

	maindec md(.op, .mem_to_reg, .dmem_write, .branch,
				.alu_src, .reg_dest, .reg_write, .ori, .brneg, .jump,
				.alu_op);
	aludec  ad(.funct, .alu_op, .alu_ctrl);

	assign pc_src = branch & (zero | (brneg & ~zero)) ;
endmodule

/*
 * Module that computes all non-ALU control signals.
 */
module maindec(input  logic [5:0] op,
               output logic       mem_to_reg, dmem_write,
               output logic       branch, alu_src,
               output logic       reg_dest, reg_write,
               output logic       ori, brneg,
               output logic       jump,
               output logic [1:0] alu_op);

	logic [10:0] controls;

	assign {reg_write, reg_dest, alu_src,
			  branch, dmem_write,
			  mem_to_reg, jump, ori, brneg, alu_op} = controls;

	always_comb
	begin
		case(op)
			6'b000000: controls = 11'b11000000010; // Rtype
			6'b100011: controls = 11'b10100100000; // LW
			6'b101011: controls = 11'b00101000000; // SW
			6'b000100: controls = 11'b00010000001; // BEQ
			6'b000101: controls = 11'b00010000101; // BNE
			6'b001000: controls = 11'b10100000000; // ADDI
			6'b000010: controls = 11'b00000010000; // J
			6'b001101: controls = 11'b10100001011; // ORI
			default:   controls = 11'bxxxxxxxxxxx; // ???
		endcase
	end
endmodule

/*
 * Module that computs ALU control signals.
 */
module aludec(input  logic [5:0] funct,
              input  logic [1:0] alu_op,
              output logic [2:0] alu_ctrl);

	always_comb
		case(alu_op)
			2'b00: alu_ctrl = 3'b010;  // add
			2'b01: alu_ctrl = 3'b110;  // sub
			2'b11: alu_ctrl = 3'b001;  // or
			default: // R-type
				case(funct)
					6'b100000: alu_ctrl = 3'b010; // ADD
					6'b100010: alu_ctrl = 3'b110; // SUB
					6'b100100: alu_ctrl = 3'b000; // AND
					6'b100101: alu_ctrl = 3'b001; // OR
					6'b101010: alu_ctrl = 3'b111; // SLT
					default:   alu_ctrl = 3'bxxx; // ???
				endcase
		endcase
endmodule


/*
 * Module that implements datapath component of MIPS core.
 */
module core_datapath(input  logic   clk, reset,
                input  logic        mem_to_reg, pc_src,
                input  logic        alu_src, reg_dest,
                input  logic        reg_write, ori, jump,
                input  logic [2:0]  alu_ctrl,
                output logic        zero,
                output logic [31:0] pc,
                input  logic [31:0] instr,
                output logic [31:0] alu_out, dmem_write_data,
                input  logic [31:0] dmem_read_data);

	logic [4:0]  write_reg;
	logic [31:0] pc_next, pc_next_br, pc_plus_4, pc_branch;
	logic [31:0] sign_imm, sign_imm_shifted, zero_imm;
	logic [31:0] srca, srcb, srcimm;
	logic [31:0] result;
	logic carry, overflow;

	// logic for determining next PC
	flopr #(32) pcreg(.clk, .reset, .d(pc_next), .q(pc));

	adder #(32) pcadd1(.a(pc), .b(32'b100), .y(pc_plus_4));

	shiftleft2 #(32) immsh(.a(sign_imm), .y(sign_imm_shifted));

	adder #(32) pcadd2(.a(pc_plus_4), .b(sign_imm_shifted), .y(pc_branch));

	mux2 #(32) pcbrmux(.d0(pc_plus_4), .d1(pc_branch), .sel(pc_src),
						  .y(pc_next_br));
	mux2 #(32) pcmux(.d0(pc_next_br), 
					  .d1({pc_plus_4[31:28], instr[25:0], 2'b00}), 
					  .sel(jump), .y(pc_next));

	// logic associated with register file
	regfile #(32,32) rf(.clk, .we3(reg_write & ~reset), .ra1(instr[25:21]),
						.ra2(instr[20:16]), .wa3(write_reg), 
						.wd3(result), .rd1(srca), .rd2(dmem_write_data));

	mux2 #(5) wrmux(.d0(instr[20:16]), .d1(instr[15:11]),
						.sel(reg_dest), .y(write_reg));
	mux2 #(32) resmux(.d0(alu_out), .d1(dmem_read_data),
						 .sel(mem_to_reg), .y(result));
	signext se(instr[15:0], sign_imm);
	
	zeroext ze(instr[15:0], zero_imm);

	// logic associated with the ALU
  mux2 #(32) immmux(.d0(sign_imm), .d1(zero_imm),
            .sel(ori), .y(srcimm));
  
	mux2 #(32) srcbmux(.d0(dmem_write_data), .d1(srcimm),
						.sel(alu_src), .y(srcb));

	alu #(32) alu(.a(srca), .b(srcb), .f(alu_ctrl), .y(alu_out),
					.zero(zero), .carry, .overflow);
endmodule
