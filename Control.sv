// control decoder
module Control #(parameter opwidth = 3, mcodebits = 4)(
  input [mcodebits-1:0] instr,    // subset of machine code (any width you need)
  input       addsub, // last bit of the add/sub instruction
  output logic     wr_en,
  output logic      mov, // special signals for special instructions
              branch,
				  bank_switch, // if changing the bank value in R5
			     reg_imm, // exactly as it sounds
				  jump_en,
					load, 
			 mem_R2, // store
          alu_R0, // add/sub, xor/and
          alu_R3, // shift
			 alu_imm, // send immediate from code to ALU
			 load_regval,
			 store_regval,
			 rdx,
  output logic[3:0] register, // register for reg file to write to
  output logic[opwidth-1:0] ALUOp);	   // for up to 8 ALU operations

always_comb begin
// defaults
	  wr_en = 'b1;
     mov = 'b0;
     branch = 'b0;
	  bank_switch = 'b0;
	  reg_imm = 'b0;
	  jump_en = 'b0;
	  load = 'b0;
     mem_R2 = 'b0;
     alu_R0 = 'b0;
     alu_R3 = 'b0;
	  alu_imm = 'b0;
	  register = 'b0000;
	  ALUOp = 'b000;
	  load_regval = 'b0;
	  store_regval = 'b0;
	  rdx = 'b0;
	  
// sample values only -- use what you need
case(instr)    // override defaults with exceptions
	'b0000: begin // load immediate
		register = 'b0001;
		reg_imm = 'b1;
	end
	'b0001: begin // load mem to reg
		register = 'b0010;
		load = 'b1;
	end
	'b0010: begin // store
		register = 'b0010;
		wr_en = 'b0;
		mem_R2 = 'b1;
	end
	'b0011: begin // mov
		mov = 'b1;
	end
	'b0100: begin // add/sub
		register = 'b0000;
		alu_R0 = 'b1;
		if(addsub)
			ALUOp = 'b000; // add
		else
			ALUOp = 'b110; // subtract
	end
	'b0101: begin // shift
		register = 'b0011;
		alu_R3 = 'b1;
		ALUOp = 'b001; // any shift
	end
	'b0110: begin // XOR
		register = 'b0000;
		alu_R0 = 'b1;
		ALUOp = 'b011; // xor
	end
	'b0111: begin // AND/OR
		register = 'b0000;
		alu_R0 = 'b1;
		if(addsub)
			ALUOp = 'b100; // and
		else
			ALUOp = 'b101; // or
	end
	'b1000: begin // bank switch
		register = 'b0101;
		bank_switch = 'b1;
	end
	'b1001: begin // jump
		// TODO
		jump_en = 1; // goes to MUX before PC. If 1, PC gets adddress from lookup table 
		// give index to lookup table (from instruction)
	end
	'b1010: begin // beq   4 bits opcode, 5 bits address 
		register = 'b0100; 
		ALUOp = 'b110; // subtract
		branch = 'b1;
		wr_en = 'b0;
	end
	'b1011: begin // AND immediate
		register = 'b0010;
		alu_imm = 'b1; 
		ALUOp = 'b100; // and
	end
	'b1100: begin // excess
		register = 'b0110; 
		alu_R3 = 'b1;
		ALUOp = 'b010; // excess
	end
	'b1101: begin // load from mem to an address in a register
		register = 'b0010;
        load = 'b1;
        load_regval = 'b1;
	end
	'b1110: begin // store from reg to an address in a register
		register = 'b0010;
		wr_en = 'b0;
		mem_R2 = 'b1;
		store_regval = 'b1;
	end
	'b1111: begin  // reduction XOR
		register = 'b0101;
		rdx = 'b1;
		ALUOp = 'b111;
	end
// ...
endcase

end
	
endmodule