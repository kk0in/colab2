import Multiplexer::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import SpecialFIFOs::*;

/* Interface of the basic right shifter module */
interface BarrelShifterRightPipelined;
	method Action shift_request(Bit#(64) operand, Bit#(6) shamt, Bit#(1) val);
	method ActionValue#(Bit#(64)) shift_response();
endinterface

function Tuple3#(Bit#(64), Bit#(6), Bit#(1)) stage_f(Integer stage, Bit#(64) operand, Bit#(6) shamt, Bit#(1) val);
	Bit#(64) afterShift;
	for(Integer j=0; j<2**(5-stage); j=j+1)
	begin
		afterShift[63-j] = val;
	end
	for(Integer j=0; j<64-2**(5-stage); j=j+1)
	begin
		afterShift[j] = operand[j+2**(5-stage)];
	end

	operand = multiplexer64(shamt[5-stage], operand, afterShift);

	return tuple3(operand, shamt, val);
endfunction

module mkBarrelShifterRightPipelined(BarrelShifterRightPipelined);
	let inFifo <- mkFIFOF;
	let outFifo <- mkFIFOF;
	Reg#(Maybe#(Tuple3#(Bit#(64), Bit#(6), Bit#(1)))) sReg1 <- mkReg(tagged Invalid);
	Reg#(Maybe#(Tuple3#(Bit#(64), Bit#(6), Bit#(1)))) sReg2 <- mkReg(tagged Invalid);
	Reg#(Maybe#(Tuple3#(Bit#(64), Bit#(6), Bit#(1)))) sReg3 <- mkReg(tagged Invalid);
	Reg#(Maybe#(Tuple3#(Bit#(64), Bit#(6), Bit#(1)))) sReg4 <- mkReg(tagged Invalid);
	Reg#(Maybe#(Tuple3#(Bit#(64), Bit#(6), Bit#(1)))) sReg5 <- mkReg(tagged Invalid);

	rule shift;
		/* TODO: Implement a pipelined right shift logic. */	
              if (inFifo.notEmpty())
              begin
                      sReg1 <= tagged Valid stage_f(0, tpl_1(inFifo.first()), tpl_2(inFifo.first()), tpl_3(inFifo.first()));
                      inFifo.deq();
              end
              else
                      sReg1 <= tagged Invalid;
                      sReg2 <= isValid(sReg1)? tagged Valid stage_f(1, tpl_1(validValue(sReg1)), tpl_2(validValue(sReg1)), tpl_3(validValue(sReg1))):tagged Invalid;
		      sReg3 <= isValid(sReg2)? tagged Valid stage_f(2, tpl_1(validValue(sReg2)), tpl_2(validValue(sReg2)), tpl_3(validValue(sReg2))):tagged Invalid;
		      sReg4 <= isValid(sReg3)? tagged Valid stage_f(3, tpl_1(validValue(sReg3)), tpl_2(validValue(sReg3)), tpl_3(validValue(sReg3))):tagged Invalid;
		      sReg5 <= isValid(sReg4)? tagged Valid stage_f(4, tpl_1(validValue(sReg4)), tpl_2(validValue(sReg4)), tpl_3(validValue(sReg4))):tagged Invalid;
	      if (isValid(sReg5))
                      outFifo.enq(stage_f(5, tpl_1(validValue(sReg5)), tpl_2(validValue(sReg5)), tpl_3(validValue(sReg5))));
	endrule

	method Action shift_request(Bit#(64) operand, Bit#(6) shamt, Bit#(1) val);
		inFifo.enq(tuple3(operand, shamt, val));
	endmethod

	method ActionValue#(Bit#(64)) shift_response();
		outFifo.deq;
		return tpl_1(outFifo.first);
	endmethod
endmodule

/* Interface of the three shifter modules
 *
 * They have the same interface.
 * So, we just copy it using typedef declarations.
*/

interface BarrelShifterRightLogicalPipelined;
	method Action shift_request(Bit#(64) operand, Bit#(6) shamt);
	method ActionValue#(Bit#(64)) shift_response();
endinterface

typedef BarrelShifterRightLogicalPipelined BarrelShifterRightArithmeticPipelined;
typedef BarrelShifterRightLogicalPipelined BarrelShifterLeftPipelined;

module mkBarrelShifterLeftPipelined(BarrelShifterLeftPipelined);
	/* TODO: Implement left shifter using the pipelined right shifter. */
	let bsrp <- mkBarrelShifterRightPipelined;

	method Action shift_request(Bit#(64) operand, Bit#(6) shamt);
		bsrp.shift_request(reverseBits(operand), shamt, 0);
	endmethod

	method ActionValue#(Bit#(64)) shift_response();
		let temp <- bsrp.shift_response();
		let result = reverseBits(temp);
		return result;
	endmethod
endmodule

module mkBarrelShifterRightLogicalPipelined(BarrelShifterRightLogicalPipelined);
	/* TODO: Implement right logical shifter using the pipelined right shifter. */
	let bsrp <- mkBarrelShifterRightPipelined;

	method Action shift_request(Bit#(64) operand, Bit#(6) shamt);
		bsrp.shift_request(operand, shamt, 0);
	endmethod

	method ActionValue#(Bit#(64)) shift_response();
		let result <- bsrp.shift_response();
		return result;
	endmethod
endmodule

module mkBarrelShifterRightArithmeticPipelined(BarrelShifterRightArithmeticPipelined);
	/* TODO: Implement right arithmetic shifter using the pipelined right shifter. */
	let bsrp <- mkBarrelShifterRightPipelined;

	method Action shift_request(Bit#(64) operand, Bit#(6) shamt);
		bsrp.shift_request(operand, shamt, operand[63]);
	endmethod

	method ActionValue#(Bit#(64)) shift_response();
		let result <- bsrp.shift_response();
		return result;
	endmethod
endmodule
