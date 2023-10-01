// cache memory/register file
// default address pointer width = 4, for 16 registers
module reg_file #(parameter pw=4)(
  input[7:0] dat_in,   
  input      clk,
  input      reset,
  input      wr_en,           // write enable
  input      mov,
  input      branch,
  input      bank_switch,
  input      reg_imm,
  input      mem_R2, // store
          alu_R0, // add/sub, xor/and
          alu_R3, // shift
          alu_imm,
          load_regval,
          store_regval,
          rdx,
          pari,
  input[pw-1:0] register,       // specified register
  input[4:0] last5bits,       // loading immediates for AND immediate
  output[2:0] bank_num,
  output logic[7:0] datA_out, // read data
                    datB_out);

  logic[7:0] core[2**pw];    // 2-dim array  8 wide  16 deep

  assign bank_num = core[5][2:0];

  initial begin 
    for (int i = 0; i < 16; i++) begin 
        core[i] <= 8'b00000000;
      end
  end

  // reads are combinational
  // sending to ALU and memory

  always_comb begin
	  if(branch && !alu_R0 && !alu_R3 && !mem_R2) begin // branch
			datA_out = core[0];
			datB_out = core[4];
	  end
     else if((alu_imm || mem_R2 || store_regval) && !alu_R0 && !alu_R3 && !branch) begin // store
        datA_out = core[2];
        datB_out = core[last5bits[4:1]];
     end 
	  else if(alu_R0 && !mem_R2 && !alu_R3 && !branch) begin // add/sub, xor/and/or
        datA_out = core[0];
        datB_out = core[last5bits[4:1]];
     end 
	  else if(alu_R3 && !mem_R2 && !alu_R0 && !branch) begin // shift
        datA_out = core[3];
        datB_out = core[6];
     end
     else if (load_regval || rdx) begin 
        datA_out = core[last5bits[4:1]];
        datB_out = 8'b00000000;
     end else begin
		  datA_out = 8'b11111111;
		  datB_out = 8'b00000000;
	  end
  end
  
// writes are sequential (clocked)
  always_ff @(posedge clk) 
/*
    if(reset) begin 
      for (int i = 0; i < 16; i++) begin 
        core[i] <= 8'b00000000;
      end
    end */

    if(wr_en)   begin            // anything but stores or no ops
		if(reg_imm)
			core[register] = last5bits;
		else if(bank_switch)
			core[5][2:0] = last5bits[2:0]; // change the last 3 bits of R5 to bank
    else if(rdx)
      core[5][7] = pari;
		else if(mov) 
			core[last5bits[4:1]] <= core[core[1]];
		else 
			core[register] <= dat_in;
     end // if(wr_en)
// ...
endmodule