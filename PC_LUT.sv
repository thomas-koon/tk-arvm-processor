module PC_LUT #(parameter D=12)(
  input       [ 4:0] addr,	   // target 4 values
  output logic[D-1:0] target); // next PC will become this target

  always_comb case(addr)   // contains parts of program we expect to use, can have different LUTs for different programs
    // ** program 1 **
    0: target = 0;   // start of program
    1: target = 224; // one more than the last line of machine code of program 1
    2: target = 4;	 
    // ** program 3 **	
    3: target = 29; // adding skip 1
    4: target = 53; // adding skip 2
    5: target = 66; // adding skip 3
    6: target = 80; // adding skip 4
    7: target = 93; // adding skip 5 or 2 errors
    8: target = 107; // end of program
    9: target = 120;   // beginning of loop
    10: target = 134; // start of concat loop
    11: target = 147; // end of loop
    12: target = 165; // total_count
    13: target = 170; // byte_count
    14: target = 188; // cross_byte_count
    15: target = 193; // iterate 
    16: target = 211; // reverse
    17: target = 216; // end of iterate
    18: target = 234; // end of iterate
    19: target = 239; // end of iterate
    20: target = 254; // end of iterate
    21: target = 270; // end of iterate
    22: target = 283; // end of iterate
    23: target = 297; // end of iterate
    24: target = 310; // end of iterate
    25: target = 324; // end of iterate
    26: target = 337; // end of iterate
    27: target = 351; // end of iterate
    28: target = 364;
	default: target = 'b0;  // hold PC
  endcase

endmodule

/*

	   pc = 4    0000_0000_0100	  4
	             1111_1111_1111	 -1

                 0000_0000_0011   3

				 (a+b)%(2**12)


   	  1111_1111_1011      -5
      0000_0001_0100     +20
	  1111_1111_1111      -1
	  0000_0000_0000     + 0


  */
