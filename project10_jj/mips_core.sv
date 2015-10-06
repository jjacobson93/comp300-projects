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

	logic mem_to_reg_w, pc_src_f, stall_f, stall_d, equal_d, alu_src_x, reg_dest_x, reg_write_w;
	logic jump_d, flush_x, fwd_a_d, fwd_b_d, fwd_data_x, fwd_data_m;
	logic [1:0] fwd_a_x, fwd_b_x;
	logic [2:0] alu_ctrl_x;
	logic [4:0] rs_d, rt_d, rs_x, rt_x, rd_x, write_reg_x, write_reg_m, write_reg_w;
	logic [31:0] instr_d;

	core_controller c(.op(instr_d[31:26]), .funct(instr_d[5:0]), .equal_d,
						.mem_to_reg_w, .dmem_write_m(dmem_write), .pc_src_f,
						.alu_src_x, .reg_dest_x, .reg_write_w, .jump_d,
						.alu_ctrl_x, .clk, .reset,
						.write_reg_x, .write_reg_m, .write_reg_w,
						.rs_d, .rt_d, .rs_x, .rt_x, .rd_x,
						.stall_f, .stall_d, .flush_x,
						.fwd_a_x, .fwd_b_x, .fwd_a_d, .fwd_b_d,
						.fwd_data_x, .fwd_data_m);
	core_datapath dp(.clk, .reset, .mem_to_reg_w, .pc_src_f, .instr_f,
						.alu_src_x, .reg_dest_x, .reg_write_w, .jump_d,
						.alu_ctrl_x, .equal_d, .pc, .instr_d,
						.alu_out_m(alu_out), .dmem_write_data_m(dmem_write_data), 
						.dmem_read_data_m(dmem_read_data),
						.stall_f, .stall_d, .flush_x,
				    .rs_d, .rt_d, .rs_x, .rt_x, .rd_x,
				    .write_reg_x, .write_reg_m, .write_reg_w,
				    .fwd_a_x, .fwd_b_x, .fwd_a_d, .fwd_b_d,
				    .fwd_data_x, .fwd_data_m);
endmodule

/*
 * Module that implements control component of processor.
 */
module core_controller(input  logic [5:0] op, funct,
		input  logic       equal_d,
		input  logic       clk, reset,
		output logic       mem_to_reg_w, dmem_write_m,
		output logic       pc_src_f, alu_src_x,
		output logic       reg_dest_x, reg_write_w,
		output logic       jump_d,
		output logic [2:0] alu_ctrl_x,
		input  logic [4:0] rs_d, rt_d, rs_x, rt_x, rd_x,
		input  logic [4:0] write_reg_x, write_reg_m, write_reg_w,
		output logic       stall_f, stall_d,
		output logic       flush_x, fwd_a_d, fwd_b_d,
		output logic       fwd_data_x, fwd_data_m,
		output logic [1:0] fwd_a_x, fwd_b_x);

	logic [1:0] alu_op;

	// ID buses
	logic reg_write_d, mem_to_reg_d, dmem_write_d, branch_d, alu_src_d, reg_dest_d;
	logic [2:0] alu_ctrl_d;

	// EX buses
	logic reg_write_x, mem_to_reg_x, dmem_write_x;

	// MEM buses
	logic reg_write_m, mem_to_reg_m;

	maindec md(.op,
				.mem_to_reg(mem_to_reg_d),
				.dmem_write_m(dmem_write_d),
				.branch(branch_d),
				.alu_src(alu_src_d), .reg_dest(reg_dest_d),
				.reg_write(reg_write_d),
				.jump(jump_d),
				.alu_op);
	aludec  ad(.funct,
				.alu_op, 
				.alu_ctrl(alu_ctrl_d));
				
	hazard_unit hu(.branch_d,
	               .rs_d, .rt_d,
	               .rs_x, .rt_x,
                 .write_reg_x, .write_reg_m, .write_reg_w,
                 .dmem_write_x, .dmem_write_m,
                 .mem_to_reg_x, .reg_write_x,
                 .mem_to_reg_m, .reg_write_m,
                 .mem_to_reg_w, .reg_write_w,
                 .stall_f, .stall_d,
                 .fwd_a_d, .fwd_b_d,
                 .fwd_data_x, .fwd_data_m,
                 .flush_x,
                 .fwd_a_x, .fwd_b_x);

	assign pc_src_f = branch_d & equal_d;


	/* inter-stage control registers */
	// ID-EX
	flopr #(1) reg_write_reg_d_x(.clk, .reset, .d(reg_write_d), .q(reg_write_x));
	flopr #(1) mem_to_reg_reg_d_x(.clk, .reset, .d(mem_to_reg_d), .q(mem_to_reg_x));
	flopr #(1) mem_write_reg_d_x(.clk, .reset, .d(dmem_write_d), .q(dmem_write_x));
	flopr #(3) alu_ctrl_reg_d_x(.clk, .reset, .d(alu_ctrl_d), .q(alu_ctrl_x));
	flopr #(1) alu_src_reg_d_x(.clk, .reset, .d(alu_src_d), .q(alu_src_x));
	flopr #(1) reg_dest_reg_d_x(.clk, .reset, .d(reg_dest_d), .q(reg_dest_x));

	// EX-MEM
	flopr #(1) reg_write_reg_x_m(.clk, .reset, .d(reg_write_x), .q(reg_write_m));
	flopr #(1) mem_to_reg_reg_x_m(.clk, .reset, .d(mem_to_reg_x), .q(mem_to_reg_m));
	flopr #(1) mem_write_reg_x_m(.clk, .reset, .d(dmem_write_x), .q(dmem_write_m));

	// MEM-WB
	flopr #(1) reg_write_reg_m_w(.clk, .reset, .d(reg_write_m), .q(reg_write_w));
	flopr #(1) mem_to_reg_reg_m_w(.clk, .reset, .d(mem_to_reg_m), .q(mem_to_reg_w));
endmodule

/*
 * Module that computes all non-ALU control signals.
 */
module maindec(input  logic [5:0] op,
               output logic       mem_to_reg, dmem_write_m,
               output logic       branch, alu_src,
               output logic       reg_dest, reg_write,
               output logic       jump,
               output logic [1:0] alu_op);

	logic [8:0] controls;

	assign {reg_write, reg_dest, alu_src,
			  branch, dmem_write_m,
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
                //output logic        zero,
                output logic [31:0] pc,
                output  logic [31:0] instr_d,
                input  logic [31:0] instr_f,
                output logic [31:0] alu_out_m, dmem_write_data_m,
                input  logic [31:0] dmem_read_data_m,
				        output logic 		equal_d,
				        input  logic stall_f, stall_d,
				        output logic [4:0] rs_d, rt_d, rs_x, rt_x, rd_x,
				        output logic [4:0] write_reg_x, write_reg_m, write_reg_w,
				        input  logic flush_x, fwd_a_d, fwd_b_d, fwd_data_x, fwd_data_m,
				        input  logic [1:0] fwd_a_x, fwd_b_x);

	// fetch wires
	logic [31:0] pc_next_f, pc_next_br_f;
	logic [31:0] pc_plus_4_f;

	// decode wires
	logic [31:0] sign_imm_d;
	logic [31:0] sign_imm_shifted_d;
	logic [31:0] pc_plus_4_d;
	logic [31:0] srca_d1, srca_d2, srcb_d1, srcb_d2;
	logic [31:0] dmem_write_data_d;
	logic [31:0] pc_branch_d;

	// exec wires
	logic [31:0] sign_imm_x, srca_x1, srcb_x1, srca_x2, srcb_x2;
	logic [31:0] alu_out_x, dmem_write_data_x;
	logic zero_x, carry_x, overflow_x;

	// wb wires
	logic [31:0] result_w, alu_out_w, dmem_read_data_w;

	/* Datapath components */

	// logic for determining next PC
	// IF
	adder #(32) pcadd1(.a(pc), .b(32'b100), .y(pc_plus_4_f));

	// IF
	mux2 #(32) pcbrmux(.d0(pc_plus_4_f), .d1(pc_branch_d), .sel(pc_src_f),
						  .y(pc_next_br_f));

	// IF
	mux2 #(32) pcmux(.d0(pc_next_br_f), 
					  .d1({pc_plus_4_d[31:28], instr_d[25:0], 2'b00}), 
					  .sel(jump_d), .y(pc_next_f));

	// IF
	flopenr #(32) pcreg(.clk, .reset, .en(~stall_f), .d(pc_next_f), .q(pc));

	// ID
	regfile #(32,32) rf(.clk(~clk), .we3(reg_write_w & ~reset), .ra1(instr_d[25:21]),
						.ra2(instr_d[20:16]), .wa3(write_reg_w), 
						.wd3(result_w), .rd1(srca_d1), .rd2(srcb_d1));
						
	// ID
	mux2 #(32) srca_d_mux(.d0(srca_d1), .d1(alu_out_m),
	                      .sel(fwd_a_d), .y(srca_d2));
	
	// ID
	mux2 #(32) srcb_d_mux(.d0(srcb_d1), .d1(alu_out_m),
	                      .sel(fwd_b_d), .y(srcb_d2));

	// ID
	eq #(32) equals(.a(srca_d2), .b(srcb_d2), .equal(equal_d));

	// ID
	signext se(.a(instr_d[15:0]), .y(sign_imm_d));


	// ID
	shiftleft2 #(32) immsh(.a(sign_imm_d), .y(sign_imm_shifted_d));

	// ID
	adder #(32) pcadd2(.a(pc_plus_4_d), .b(sign_imm_shifted_d), .y(pc_branch_d));


  // EX
  mux3 #(32) srcamux(.d0(srca_x1), .d1(result_w), .d2(alu_out_m),
                    .sel(fwd_a_x), .y(srca_x2));
            
  // EX
  logic [31:0] dmem_write_data_x_sub;
  mux3 #(32) srcbmux1(.d0(srcb_x1), .d1(result_w), .d2(alu_out_m),
                     .sel(fwd_b_x), .y(dmem_write_data_x_sub));

	// EX
	mux2 #(5) wrmux(.d0(rt_x), .d1(rd_x),
						.sel(reg_dest_x), .y(write_reg_x));

	// EX
	mux2 #(32) srcbmux2(.d0(dmem_write_data_x), .d1(sign_imm_x),
						.sel(alu_src_x), .y(srcb_x2));

	// EX
	alu #(32) alu(.a(srca_x2), .b(srcb_x2), .f(alu_ctrl_x), .y(alu_out_x),
					.zero(zero_x), .carry(carry_x), .overflow(overflow_x));
					
	// EX
	mux2 #(32) dmemmux_x(.d0(dmem_write_data_x_sub),  .d1(result_w),
	                   .sel(fwd_data_x), .y(dmem_write_data_x));
					
	// MEM
	logic [31:0] dmem_write_data_m_sub;
	mux2 #(32) dmemmux_m(.d0(dmem_write_data_m_sub),  .d1(result_w),
	                   .sel(fwd_data_m), .y(dmem_write_data_m));

	// WB
	mux2 #(32) resmux(.d0(alu_out_w), .d1(dmem_read_data_w),
						 .sel(mem_to_reg_w), .y(result_w));



	/* inter-stage registers */
	
	logic if_id_r, id_ex_r;
	assign if_id_r = reset | jump_d | pc_src_f;
	assign id_ex_r = reset | flush_x;
	
	logic [4:0] rd_d;
	assign rs_d = instr_d[25:21];
	assign rt_d = instr_d[20:16];
	assign rd_d = instr_d[15:11];

	// IF-ID registers
	flopenr #(32) instr_reg_f_d(.clk, .reset(if_id_r), .en(~stall_d), .d(instr_f), .q(instr_d));
	flopenr #(32) pc_plus_4_reg_f_d(.clk, .reset(if_id_r), .en(~stall_d), .d(pc_plus_4_f), .q(pc_plus_4_d));

	// ID-EX registers
	flopr #(32) srca_reg_d_x(.clk, .reset(id_ex_r), .d(srca_d2), .q(srca_x1));
	flopr #(32) srcb_reg_d_x(.clk, .reset(id_ex_r), .d(srcb_d2), .q(srcb_x1));
	//flopr #(32) dmem_write_data_reg_d_x(.clk, .reset(id_ex_r), .d(dmem_write_data_d), .q(dmem_write_data_x));
	flopr #(5) rs_reg_d_x(.clk, .reset(id_ex_r), .d(rs_d), .q(rs_x));
	flopr #(5) rt_reg_d_x(.clk, .reset(id_ex_r), .d(rt_d), .q(rt_x));
	flopr #(5) rd_reg_d_x(.clk, .reset(id_ex_r), .d(rd_d), .q(rd_x));
	flopr #(32) sign_imm_reg_d_x(.clk, .reset(id_ex_r), .d(sign_imm_d), .q(sign_imm_x));

	// EX-MEM registers
	flopr #(32) alu_out_reg_x_m(.clk, .reset, .d(alu_out_x), .q(alu_out_m));
	flopr #(32) dmem_write_data_reg_x_m(.clk, .reset, .d(dmem_write_data_x), .q(dmem_write_data_m_sub));
	flopr #(5) write_reg_reg_x_m(.clk, .reset, .d(write_reg_x), .q(write_reg_m));

	// MEM-WB registers
	flopr #(32) alu_out_reg_m_w(.clk, .reset, .d(alu_out_m), .q(alu_out_w));
	flopr #(32) dmem_read_reg_data_m_w(.clk, .reset, .d(dmem_read_data_m), .q(dmem_read_data_w));
	flopr #(5) write_reg_reg_m_w(.clk, .reset, .d(write_reg_m), .q(write_reg_w));
endmodule

module hazard_unit(input  logic branch_d,
                   input  logic [4:0] rs_d, rt_d, 
                   input  logic [4:0] rs_x, rt_x,
                   input  logic [4:0] write_reg_x, write_reg_m, write_reg_w,
                   input  logic dmem_write_x, dmem_write_m,
                   input  logic mem_to_reg_x, reg_write_x,
                   input  logic mem_to_reg_m, reg_write_m,
                   input  logic mem_to_reg_w, reg_write_w,
                  
                   output logic stall_f, stall_d,
                   output logic fwd_a_d, fwd_b_d,
                   output logic fwd_data_x, fwd_data_m,
                   output logic flush_x,
                   output logic [1:0] fwd_a_x, fwd_b_x);
                   
  logic lwstall, branchstall;
  
  assign lwstall = ((rs_d == rt_x) | (rt_d == rt_x)) & mem_to_reg_x;
  assign branchstall = 
        (branch_d & reg_write_x & ((write_reg_x == rs_d) | (write_reg_x == rt_d))) |
        (branch_d & mem_to_reg_m & ((write_reg_m == rs_d) | (write_reg_m == rt_d)));        
  
  assign stall_f = lwstall | branchstall;
  assign stall_d = lwstall | branchstall;
  assign flush_x = lwstall | branchstall;
  
  assign fwd_a_d = (rs_d != 0) & (rs_d == write_reg_m) & reg_write_m;
  assign fwd_b_d = (rt_d != 0) & (rt_d == write_reg_m) & reg_write_m;
  
  assign fwd_a_x = ((rs_x != 0) & (rs_x == write_reg_m) & reg_write_m) ? 2'b10 :
                   (((rs_x != 0) & (rs_x == write_reg_w) & reg_write_w) ? 2'b01 : 2'b00);

  assign fwd_b_x = ((rt_x != 0) & (rt_x == write_reg_m) & reg_write_m) ? 2'b10 :
                   (((rt_x != 0) & (rt_x == write_reg_w) & reg_write_w) ? 2'b01 : 2'b00);
                   
  assign fwd_data_x = 0; // dmem_write_x & mem_to_reg_w; // & (write_reg_x == write_reg_w);
  assign fwd_data_m = 0; //dmem_write_m & mem_to_reg_w;// & (write_reg_m == write_reg_w);
endmodule
