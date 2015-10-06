/*
 * mips_core.sv
 * Authors: David and Sarah Harris
 * Updated By: Sat Garcia
 * Modules for a Single-cycle 32-bit MIPS processor.
 */

module mips_core(input  logic clk, reset,
					output logic [31:0] pc,
					input  logic [31:0] instr_f,
					output logic dmem_write,
					output logic [31:0] alu_out, dmem_write_data,
					input  logic [31:0] dmem_read_data);

	logic mem_to_reg_w, pc_src_f, zero, alu_src_x, reg_dest_x, reg_write_w, jump_d, equal_d;
	logic [2:0] alu_ctrl_x;
	logic [31:0] instr_d;

	core_controller c(.clk, .reset,
	           .op(instr_d[31:26]),
						.funct(instr_d[5:0]), 
						.zero,
						.equal_d,
						.mem_to_reg_w, 
						.dmem_write_m(dmem_write), 
						.pc_src_f,
						.alu_src_x, 
						.reg_dest_x, 
						.reg_write_w, 
						.jump_d,
						.alu_ctrl_x);
	core_datapath dp(.clk, .reset,
						.mem_to_reg_w, 
						.pc_src_f, 
						.instr_f,
						.alu_src_x, 
						.reg_dest_x, 
						.reg_write_w, 
						.jump_d,
						.alu_ctrl_x, 
						.zero, 
						.pc, 
						.instr_d,
						.alu_out_m(alu_out), 
						.dmem_write_data_m(dmem_write_data),
						.dmem_read_data_m(dmem_read_data),
						.equal_d);
endmodule

/*
 * Module that implements control component of processor.
 */
module core_controller(input  logic clk, reset,
            input  logic [5:0] op, funct,
						input  logic       zero, equal_d,
						output logic       mem_to_reg_w, dmem_write_m,
						output logic       pc_src_f, alu_src_x,
						output logic       reg_dest_x, reg_write_w,
						output logic       jump_d,
						output logic [2:0] alu_ctrl_x);

	logic [1:0] alu_op_d;
	logic       branch;

	// stage-specific logic signals here
	
	// ID
	logic [2:0] alu_ctrl_d;
	logic       reg_write_d, mem_to_reg_d, dmem_write_d,
	            alu_src_d, reg_dest_d;
	
	// EX
	logic reg_write_x, mem_to_reg_x, dmem_write_x;
	
	// MEM
	logic reg_write_m, mem_to_reg_m;

	// Note: controller is active in ID stage so you'll want to create decode
	// signals (e.g. mem_to_reg_d) and wire them up to the output of the
	// decoders.
	maindec md(.op, .mem_to_reg(mem_to_reg_d), .dmem_write(dmem_write_d), .branch,
				.alu_src(alu_src_d), .reg_dest(reg_dest_d), .reg_write(reg_write_d), .jump(jump_d),
				.alu_op(alu_op_d));
	aludec  ad(.funct, .alu_op(alu_op_d), .alu_ctrl(alu_ctrl_d));

	assign pc_src_f = branch & equal_d;

	// Inter-stage control registers
	
	// ID -> EX
	flopr #(1) reg_write_dx_reg(.clk, .reset, .d(reg_write_d), .q(reg_write_x));
	flopr #(1) mem_to_reg_dx_reg(.clk, .reset, .d(mem_to_reg_d), .q(mem_to_reg_x));
	flopr #(1) dmem_write_dx_reg(.clk, .reset, .d(dmem_write_d), .q(dmem_write_x));
	flopr #(3) alu_ctrl_dx_reg(.clk, .reset, .d(alu_ctrl_d), .q(alu_ctrl_x));
	flopr #(1) alu_src_dx_reg(.clk, .reset, .d(alu_src_d), .q(alu_src_x));
	flopr #(1) reg_dest_dx_reg(.clk, .reset, .d(reg_dest_d), .q(reg_dest_x));
	
	// EX -> MEM
	flopr #(1) reg_write_xm_reg(.clk, .reset, .d(reg_write_x), .q(reg_write_m));
	flopr #(1) mem_to_reg_xm_reg(.clk, .reset, .d(mem_to_reg_x), .q(mem_to_reg_m));
	flopr #(1) dmem_write_xm_reg(.clk, .reset, .d(dmem_write_x), .q(dmem_write_m));
	
	// MEM -> WB
	flopr #(1) reg_write_mw_reg(.clk, .reset, .d(reg_write_m), .q(reg_write_w));
	flopr #(1) mem_to_reg_mw_reg(.clk, .reset, .d(mem_to_reg_m), .q(mem_to_reg_w));
	
	
endmodule

/*
 * Module that computes all non-ALU control signals.
 *
 * You should NOT modify this module (i.e. leave its interface/implementation
 * as is).
 */
module maindec(input  logic [5:0] op,
               output logic       mem_to_reg, dmem_write,
               output logic       branch, alu_src,
               output logic       reg_dest, reg_write,
               output logic       jump,
               output logic [1:0] alu_op);

	logic [8:0] controls;

	assign {reg_write, reg_dest, alu_src,
			  branch, dmem_write,
			  mem_to_reg, jump, alu_op} = controls;

	always_comb
	begin
		case(op)
			6'b000000: controls = 9'b110000010; // Rtype
			6'b100011: controls = 9'b101001000; // LW
			6'b101011: controls = 9'b001010000; // SW
			6'b000100: controls = 9'b000100001; // BEQ
			6'b001000: controls = 9'b101000000; // ADDI
			6'b000010: controls = 9'b000000100; // J
			default:   controls = 9'bxxxxxxxxx; // ???
		endcase
	end
endmodule

/*
 * Module that computs ALU control signals.
 *
 * You should NOT modify this module (i.e. leave its interface/implementation
 * as is).
 */
module aludec(input  logic [5:0] funct,
              input  logic [1:0] alu_op,
              output logic [2:0] alu_ctrl);

	always_comb
		case(alu_op)
			2'b00: alu_ctrl = 3'b010;  // add
			2'b01: alu_ctrl = 3'b110;  // sub
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
                input  logic        mem_to_reg_w, pc_src_f,
                input  logic        alu_src_x, reg_dest_x,
                input  logic        reg_write_w, jump_d,
                input  logic [2:0]  alu_ctrl_x,
                output logic        zero,
                output logic [31:0] pc,
                input  logic [31:0] instr_f,
                output logic [31:0] instr_d,
                output logic [31:0] alu_out_m, dmem_write_data_m,
                input  logic [31:0] dmem_read_data_m,
                output logic        equal_d);

	// IF signals
	logic [31:0] pc_next_f, pc_next_br_f, pc_plus_4_f;

	// ID signals
	logic [31:0] pc_plus_4_d, pc_branch_d, sign_imm_d, sign_imm_shifted_d,
	             dmem_write_data_d, srca_d;
	logic [4:0]  rt_d, rd_d;
	
	assign rt_d = instr_d[20:16];
	assign rd_d = instr_d[15:11];

	// EX signals
	logic [31:0] sign_imm_x, dmem_write_data_x, 
	             srca_x, srcb_x, alu_out_x;
	logic [4:0] rt_x, rd_x, write_reg_x;
	logic carry_x, overflow_x;

	// MEM signals
	logic [4:0] write_reg_m;
	
	// WB signals
	logic [31:0] alu_out_w, dmem_read_data_w, result_w;
	logic [4:0] write_reg_w;

	// IF Datapath components
	flopr #(32) pcreg(.clk, .reset, .d(pc_next_f), .q(pc));

	adder #(32) pcadd1(.a(pc), .b(32'b100), .y(pc_plus_4_f));

	mux2 #(32) pcbrmux(.d0(pc_plus_4_f), .d1(pc_branch_d), .sel(pc_src_f),
						  .y(pc_next_br_f));

	mux2 #(32) pcmux(.d0(pc_next_br_f), 
					  .d1({pc_plus_4_d[31:28], instr_d[25:0], 2'b00}), 
					  .sel(jump_d), .y(pc_next_f));


	// ID Datapath components 
	
	// Note: reg file also used WB
	regfile #(32,32) rf(.clk(~clk), .we3(reg_write_w & ~reset), 
						.ra1(instr_d[25:21]), .ra2(instr_d[20:16]),
						.rd1(srca_d), .rd2(dmem_write_data_d),
						.wa3(write_reg_w), .wd3(result_w)
					);

	signext se(.a(instr_d[15:0]), .y(sign_imm_d));
	
	shiftleft2 #(32) immsh(.a(sign_imm_d), .y(sign_imm_shifted_d));
	
	adder #(32) pcadd2(.a(pc_plus_4_d), .b(sign_imm_shifted_d), .y(pc_branch_d));
	
	equaler #(32) rdeq(.a(srca_d), .b(dmem_write_data_d), .y(equal_d));

	
	// EX Datapath components

	mux2 #(5) wrmux(.d0(rt_x), .d1(rd_x), .sel(reg_dest_x), 
					.y(write_reg_x));

	// selects if alu's 2nd input is immediate or register
	mux2 #(32) srcbmux(.d0(dmem_write_data_x), .d1(sign_imm_x),
						.sel(alu_src_x), .y(srcb_x));

	alu #(32) alu(.a(srca_x), .b(srcb_x), .f(alu_ctrl_x), .y(alu_out_x),
					.zero(zero), .carry(carry_x), .overflow(overflow_x));


	// WB Datapath components
	mux2 #(32) resmux(.d0(alu_out_w), .d1(dmem_read_data_w),
						 .sel(mem_to_reg_w), .y(result_w));


	// Inter-stage registers
	
	// IF -> ID
	flopr #(32) instr_fd_reg(.clk, .reset, .d(instr_f), .q(instr_d));
	flopr #(32) pc_fd_reg(.clk, .reset, .d(pc_plus_4_f), .q(pc_plus_4_d));
	
	// ID -> EX
	flopr #(32) srca_dx_reg(.clk, .reset, .d(srca_d), .q(srca_x));
	flopr #(32) dmem_wd_dx_reg(.clk, .reset, .d(dmem_write_data_d), .q(dmem_write_data_x));
	flopr #(5) rt_dx_reg(.clk, .reset, .d(rt_d), .q(rt_x));
	flopr #(5) rd_dx_reg(.clk, .reset, .d(rd_d), .q(rd_x));
	flopr #(32) sign_imm_dx_reg(.clk, .reset, .d(sign_imm_d), .q(sign_imm_x));
	
	// EX -> MEM
	flopr #(32) alu_out_xm_reg(.clk, .reset, .d(alu_out_x), .q(alu_out_m));
	flopr #(32) dmem_wd_xm_reg(.clk, .reset, .d(dmem_write_data_x), .q(dmem_write_data_m));
	flopr #(5) write_reg_xm_reg(.clk, .reset, .d(write_reg_x), .q(write_reg_m));

  // MEM -> WB
  flopr #(32) alu_out_mw_reg(.clk, .reset, .d(alu_out_m), .q(alu_out_w));
  flopr #(32) dmem_rd_mw_reg(.clk, .reset, .d(dmem_read_data_m), .q(dmem_read_data_w));
  flopr #(5) write_reg_mw_reg(.clk, .reset, .d(write_reg_m), .q(write_reg_w));

endmodule
