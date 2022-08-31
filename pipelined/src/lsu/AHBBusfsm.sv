///////////////////////////////////////////
// busfsm.sv
//
// Written: Ross Thompson ross1728@gmail.com December 29, 2021
// Modified: 
//
// Purpose: Load/Store Unit's interface to BUS for cacheless system
// 
// A component of the Wally configurable RISC-V project.
// 
// Copyright (C) 2021 Harvey Mudd College & Oklahoma State University
//
// MIT LICENSE
// Permission is hereby granted, free of charge, to any person obtaining a copy of this 
// software and associated documentation files (the "Software"), to deal in the Software 
// without restriction, including without limitation the rights to use, copy, modify, merge, 
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons 
// to whom the Software is furnished to do so, subject to the following conditions:
//
//   The above copyright notice and this permission notice shall be included in all copies or 
//   substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
//   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
//   PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
//   BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
//   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE 
//   OR OTHER DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////

`include "wally-config.vh"

// HCLK and clk must be the same clock!
module AHBBusfsm 
  (input logic        HCLK,
   input logic        HRESETn,

   // IEU interface
   input logic [1:0]  RW,
   input logic        CPUBusy,
   output logic       BusCommitted,
   output logic       BusStall,
   output logic       CaptureEn,
   input logic        HREADY,
   output logic [1:0] HTRANS,
   output logic       HWRITE
);
  
  typedef enum logic [2:0] {STATE_READY,
				            STATE_CAPTURE,
				            STATE_DELAY,
				            STATE_CPU_BUSY} busstatetype;

  typedef enum logic [1:0] {AHB_IDLE = 2'b00, AHB_BUSY = 2'b01, AHB_NONSEQ = 2'b10, AHB_SEQ = 2'b11} ahbtranstype;

  (* mark_debug = "true" *) busstatetype BusCurrState, BusNextState;

  always_ff @(posedge HCLK)
    if (~HRESETn)    BusCurrState <= #1 STATE_READY;
    else BusCurrState <= #1 BusNextState;  
  
  always_comb begin
	case(BusCurrState)
	  STATE_READY: if(HREADY & |RW)  BusNextState = STATE_CAPTURE;
                   else        BusNextState = STATE_READY;
      STATE_CAPTURE: if(HREADY)  BusNextState = STATE_DELAY;
		           else        BusNextState = STATE_CAPTURE;
      STATE_DELAY: if(CPUBusy) BusNextState = STATE_CPU_BUSY;
		           else        BusNextState = STATE_READY;
      STATE_CPU_BUSY: if(CPUBusy) BusNextState = STATE_CPU_BUSY;
                   else        BusNextState = STATE_READY;
	  default:                 BusNextState = STATE_READY;
	endcase
  end

  assign BusStall = (BusCurrState == STATE_READY & |RW) |
					(BusCurrState == STATE_CAPTURE);
  
  assign BusCommitted = BusCurrState != STATE_READY;

  assign HTRANS = (BusCurrState == STATE_READY & HREADY & |RW) |
                  (BusCurrState == STATE_CAPTURE & ~HREADY) ? AHB_NONSEQ : AHB_IDLE;
  assign HWRITE = (BusCurrState == STATE_READY) & RW[0]; // *** might not be necessary, maybe just RW[0]
  assign CaptureEn = BusCurrState == STATE_CAPTURE;
  
endmodule