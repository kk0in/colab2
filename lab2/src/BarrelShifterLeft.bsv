import BarrelShifterRight::*;

interface BarrelShifterLeft;
	method ActionValue#(Bit#(64)) leftShift(Bit#(64) val, Bit#(6) shiftAmt);
endinterface

module mkBarrelShifterLeft(BarrelShifterLeft);
	let bsr <- mkBarrelShifterRightLogical;
	method ActionValue#(Bit#(64)) leftShift(Bit#(64) val, Bit#(6) shiftAmt);
		/* TODO: Implement a left shifter using the given logical right shifter */
		let temp <- bsr.rightShift(reverseBits(val), shiftAmt);
		let result = reverseBits(temp);
		return result;
	endmethod
endmodule
