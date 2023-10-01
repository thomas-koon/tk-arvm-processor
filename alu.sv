// combinational -- no clock
// sample -- change as desired
module alu(
  input[2:0] alu_cmd,    // ALU instructions
  input[7:0] inA, inB,	 // 8-bit wide data path
  input		 alu_imm,		 // load immediate into ALU
  input[4:0] last5bits,			 // immediate from instruction memory
  output logic[7:0] rslt,
  output logic pari,     // reduction XOR (output)
			   zero,      // NOR (output)
  output logic[7:0] excess
);

logic[7:0] immediate; // full 8 bit immediate
logic[15:0] excessBits;

always_comb begin 
  rslt = 'b0;            
  zero = !rslt;
  pari = ^rslt;
  if(alu_imm)
     immediate = {3'b000, last5bits};
  else
	  immediate = 8'b00000000;
  excessBits = 16'b0000000000000000;
  excess = 8'b00000000;
  case(alu_cmd)
    3'b000: // add 2 8-bit unsigned; automatically makes carry-out
      rslt = inA + inB;
		
	3'b001: begin // shift
    case(last5bits[1:0]) 
      2'b00: begin // left logical
        rslt = inA << last5bits[4:2];
      end
      2'b10: begin // right logical
        rslt = inA >> last5bits[4:2];
      end
      2'b01: begin // left barrel
        rslt = (inA << last5bits[4:2]) | (inA >> (8 - last5bits[4:2]));
      end
      2'b11: begin // right barrel
        rslt = (inA >> last5bits[4:2]) | (inA << (8 - last5bits[4:2]));
      end
    endcase
  end
    3'b010: begin// get excess
		  excessBits[15:0] = {inB,inA};
		  if (!last5bits[1]) begin
			  excessBits = ((excessBits << last5bits[4:2]) | (excessBits >> (16 - last5bits[4:2])));
			  rslt = excessBits[15:8];
		  	end
			  // barrel shift excessBits and put the top 8 bits into the output excess
			else begin // right logical
			  excessBits = ((excessBits >> last5bits[4:2]) | (excessBits << (16 - last5bits[4:2])));
			  rslt = excessBits[15:8];
			end
	end 
    3'b011: // bitwise XOR
	  rslt = inA ^ inB;
	3'b100: begin// bitwise AND (mask)
	  if(alu_imm)
		  rslt = inA & immediate;
	  else
		  rslt = inA & inB;
	end
	3'b101: // bitwise OR
	  rslt = inA | inB;
	3'b110: begin // subtract
		rslt = inA - inB;
    zero = !(inA - inB);
  end
	3'b111: begin // pass A
	  rslt = inA;
    pari = ^inA;
  end
  endcase
end
   
endmodule