// sample top level design
module top_level(
  input        clk, reset, 
  output logic done);
  parameter D = 12,             // program counter width
    A = 3;             		  // ALU command bit width
	 
  wire[D-1:0] target, 			  // jump 
              prog_ctr;
  wire        RegWrite;
  
  wire   wr_en,
  mov,
  branch,
  bank_switch,
  reg_imm,
  jump_en,
  load,
  mem_R2,
  alu_R0,
  alu_R3,
  alu_imm,
  load_regval,
  store_regval,
  rdx;
  wire[2:0] ALUOp;
  
  logic[7:0]   regfile_in;
  wire[7:0]   datA,datB,		  // from RegFile
              muxB;
  logic[D-1:0]   muxPC;           // next address for PC 
  wire[7:0]     rslt, immed;
	
 // logic sc_in,   				  // shift/carry out from/to ALU
 //  		pariQ,              	  // registered parity flag from ALU
//		zeroQ;                    // registered zero flag from ALU 
  wire  pari,
        zero,
        ALUSrc;		              // immediate switch
  wire[A-1:0] alu_cmd;
  wire[8:0]   mach_code;          // machine code
  wire[3:0]   register;
  
  wire[3:0] opcode;
  wire[1:0] last2bits;
  wire[4:0] last5bits;
  wire[2:0] bank_num;
  logic[7:0] mem_addr;
  
  wire[7:0] mem_out;

always_comb begin
	if((jump_en && !branch) || (!jump_en && branch && zero))
		muxPC = target;
	else if((!jump_en && !branch) || (branch && !zero))
		muxPC = prog_ctr + 12'b000000000001;
	else
		muxPC = 12'b000000000000;
end

always_comb begin 
  if (load_regval)
    mem_addr = datA;
  else if (store_regval)
    mem_addr = datB;
  else
    mem_addr = {3'b000, last5bits};
end

// fetch subassembly
  PC #(.D(D)) 					  // D sets program counter width
     pc1 (.reset            ,
         .clk              ,
			.next(muxPC),
		 .prog_ctr(prog_ctr)  );

// lookup table to facilitate jumps/branches
  PC_LUT #(.D(D))
    pl1 (.addr  (last5bits),
         .target          );   

// contains machine code
  instr_ROM ir1(.prog_ctr,
               .mach_code);

  assign last2bits = mach_code[1:0];
  assign last5bits = mach_code[4:0];
  assign opcode = mach_code[8:5];
  
// control decoder
  Control ctl1(.instr(opcode),
  .addsub  (last2bits[0]), 
  .wr_en,
  .mov,
  .branch,
  .bank_switch,
  .reg_imm,
  .jump_en,
  .load(load),
  .mem_R2,
  .alu_R0,
  .alu_R3,
  .alu_imm,
  .load_regval,
  .store_regval,
  .rdx,
  .register,
  .ALUOp(ALUOp)
   );
  
// dat_in is either from memory or ALU
always_comb begin
	if(load)
		regfile_in = mem_out;
	else if(alu_R0 || alu_R3 || alu_imm)
		regfile_in = rslt;
	else
		regfile_in = 8'b00000000;
end

  reg_file rf1(
              .dat_in(regfile_in),	   // loads, most ops
              .clk,
              .wr_en,
				  .mov,
				  .branch,
				  .bank_switch,
				  .reg_imm,
				  .mem_R2,
				  .alu_R0,
				  .alu_R3,
          .alu_imm,
          .load_regval,
          .store_regval,
          .rdx,
          .pari,
              .register,
				  .last5bits(last5bits),
				  .bank_num(bank_num),
              .datA_out(datA),
              .datB_out(datB)); 

  alu alu1(.alu_cmd(ALUOp),
         .inA    (datA),
		 .inB    (datB),
		 .alu_imm,
		 .last5bits(last5bits),
		 .rslt       , // go to regfile
		 .pari,
		  .zero);  

  dat_mem dm1(.dat_in(datA)  ,  // from reg_file
             .clk           ,
			 .wr_en  (mem_R2), // stores
			 .addr   (mem_addr),
			 .bank_num(bank_num),
             .dat_out(mem_out));

				 
// registered flags from ALU
/*
  always_ff @(posedge clk) begin
    //pariQ <= pari;
	  //zeroQ <= zero;
    if (reset)
      muxPC <= '0;
  end
*/

  assign done = prog_ctr == 392;
 
endmodule