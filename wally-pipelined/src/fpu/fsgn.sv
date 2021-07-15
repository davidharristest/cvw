//performs the fsgnj/fsgnjn/fsgnjx RISCV instructions

module fsgn (  
	input logic        XSgnE, YSgnE,
    input logic [10:0] XExpE,
    input logic [51:0] XFracE,
	input logic XExpMaxE,
	input logic FmtE,
	input  logic [1:0]   SgnOpCodeE,
	output logic [63:0]  SgnResE,
	output logic   SgnNVE);

	logic AonesExp;
	logic ResSgn;

	//op code designation:
	//
	//00 - fsgnj - directly copy over sign value of FSrcYE
	//01 - fsgnjn - negate sign value of FSrcYE
	//10 - fsgnjx - XOR sign values of FSrcXE & FSrcYE
	//
	
	assign ResSgn = SgnOpCodeE[1] ? (XSgnE ^ YSgnE) : (YSgnE ^ SgnOpCodeE[0]);
	assign SgnResE = FmtE ? {ResSgn, XExpE, XFracE} : {{32{1'b1}}, ResSgn, XExpE[7:0], XFracE[51:29]};

	//If the exponent is all ones, then the value is either Inf or NaN,
	//both of which will produce a QNaN/SNaN value of some sort. This will 
	//set the invalid flag high.

	//the only flag that can occur during this operation is invalid
	//due to changing sign on already existing NaN
	assign SgnNVE = XExpMaxE & SgnResE[63];

endmodule
