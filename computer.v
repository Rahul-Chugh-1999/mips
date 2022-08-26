/*
    Set of instructions:
    ALU:    op[5] r1[3] r2[3] w[3] x[2]
    ALUI:   op[5] r[3] w[3] data[5]
    lw:     op[5] addr[3] w[3] offset[5]
    sw:     op[5] addr[3] r[3] offset[5]
    jump:   op[5] offset[11]
    beq:    op[5] r1[3] r2[3] offset[5]
    jr:     op[5] r[3] x[8]
    end:    op[5] x[11]
    print   op[5] r[3] x[8]
*/

`define opExit  5'b00000
`define opPrint 5'b00001
`define opAdd   5'b00010
`define opSub   5'b00011
`define opMul   5'b00100
`define opDiv   5'b00101
`define opEq    5'b00110
`define opNe    5'b00111
`define opAddi  5'b01000
`define opSubi  5'b01001
`define opLw    5'b01010
`define opSw    5'b01011
`define opBeq   5'b01100
`define opBne   5'b01101
`define opJmp   5'b01110
`define opJr    5'b01111

// alu codes for different alu operations
`define aluAdd 4'b0001
`define aluSub 4'b0010
`define aluMul 4'b0011
`define aluDiv 4'b0100
`define aluEq  4'b0101
`define aluNe  4'b0110

// c= a alu b
module ALU(
    input[03:0] alu, 
    input[15:0] a, 
    input[15:0] b, 
    output zero,
    output reg[15:0] c
);
    assign zero= c[0];
    always @(*) begin
        case (alu)
            `aluAdd: c <= a+b;
            `aluSub: c <= a-b;
            `aluMul: c <= a*b;
            `aluDiv: c <= a/b;
            `aluEq : c <= a==b;
            `aluNe : c <= a!=b; 
            default: c <= a;
        endcase
    end
endmodule

// pc points to instruction, instruction is fetched instruction
// program contains initial instruction memory (loaded as it is at reset)
module InstructionMemory(
    input clk, 
    input rst, 
    input[15:0] pc, 
    input[2**16-1:0][7:0] program, 
    output[15:0] instruction
);
    reg[2**16-1:0][7:0] memory;

    // we have to access two consecutive bytes
    wire[15:0] pc1, pc2;
    assign pc1= pc;
    assign pc2= pc+1;
    assign instruction={memory[pc2], memory[pc1]};

    always @(posedge clk) begin
        if(rst) memory<= program;
    end
endmodule

module DataMemory(
    input clk,
    input rst,
    input[15:0] address,
    input toWrite,
    input[15:0] writeData,
    output[15:0] readData
);
    reg[2**16-1:0][7:0] memory;

    // we have to access two consecutive bytes
    wire[15:0] byte1, byte2;
    assign byte1= address;
    assign byte2= address+1;
    assign readData={memory[byte2], memory[byte1]};
    
    always @(posedge clk) begin
        if(rst) memory<=0;
        else if(toWrite) begin
            memory[byte1]<= writeData[7:0];
            memory[byte2]<= writeData[15:8];
        end
    end 
endmodule


// r1-> readRegister1, w-> write register
// if(toWrite) r1<= write
module Registers(
    input clk,
    input rst,
    input[2:0] writeReg,
    input[2:0] readReg1,  
    input[2:0] readReg2,
    input toWrite,
    input[15:0] writeData,
    output[15:0] readData1,
    output[15:0] readData2
);
    reg[7:0][15:0] registers;
    assign readData1= registers[readReg1];
    assign readData2= registers[readReg2];
    always @(posedge clk) begin
        if(rst) registers<= 0;
        else if(toWrite)
            registers[writeReg]<= writeData;
    end 
endmodule


// Simple sign extend from 5 to 16 bits
module SignExtend(
    input[4:0] a,
    output[15:0] b
);
    assign b= {{12{a[4]}}, a[3:0]};
endmodule


/*
    Set of instructions:
    ALU:    op[5] r1[3] r2[3] w[3] x[2]
    ALUI:   op[5] r[3] w[3] data[5]
    lw:     op[5] addr[3] w[3] offset[5]
    sw:     op[5] addr[3] r[3] offset[5]
    jump:   op[5] offset[11]
    beq:    op[5] r1[3] r2[3] offset[5]
    jr:     op[5] r[3] x[8]
    end:    op[5] x[11]
    print   op[5] r[3] x[8]
*/

`define opExit  5'b00000
`define opPrint 5'b00001
`define opAdd   5'b00010
`define opSub   5'b00011
`define opMul   5'b00100
`define opDiv   5'b00101
`define opEq    5'b00110
`define opNe    5'b00111
`define opAddi  5'b01000
`define opSubi  5'b01001
`define opLw    5'b01010
`define opSw    5'b01011
`define opBeq   5'b01100
`define opBne   5'b01101
`define opJmp   5'b01110
`define opJr    5'b01111

module Control(
    input[4:0] instruction,
    output finish,
    output toDisplay,
    output regDst,
    output regWrite,
    output aluSrc,
    output memWrite,
    output memToReg,
    output toJump,
    output toBranch,
    output toReturn,
    output reg[3:0] alu
);
    assign finish= instruction== `opExit;
    
    assign toDisplay= instruction== `opPrint;
    
    assign regDst=    (instruction== `opAdd) 
                    | (instruction== `opSub) 
                    | (instruction== `opMul)
                    | (instruction== `opDiv)
                    | (instruction== `opEq )
                    | (instruction== `opNe )
                    ;
    
    assign regWrite=  (instruction== `opAdd)
                    | (instruction== `opSub)
                    | (instruction== `opMul)
                    | (instruction== `opDiv)
                    | (instruction== `opEq )
                    | (instruction== `opNe )
                    | (instruction== `opAddi)
                    | (instruction== `opSubi)
                    | (instruction== `opLw)
                    ;

    assign aluSrc=    (instruction== `opAddi)
                    | (instruction== `opSubi)
                    | (instruction== `opLw  )
                    | (instruction== `opSw  )
                    | toBranch
                    ;

    assign memWrite= instruction== `opSw;

    assign memToReg= instruction== `opLw;

    assign toJump= instruction== `opJmp;

    assign toBranch=  (instruction== `opBeq)
                    | (instruction== `opBne)
                    ;    

    assign toReturn= instruction== `opJr;

    always @(*) begin
        case(instruction)
            `opAdd : alu<= `aluAdd;
            `opSub : alu<= `aluSub;
            `opMul : alu<= `aluMul;
            `opDiv : alu<= `aluDiv;
            `opEq  : alu<= `aluEq ;
            `opNe  : alu<= `aluNe ;
            `opAddi: alu<= `aluAdd;
            `opSubi: alu<= `aluSub;
            `opLw  : alu<= `aluAdd;
            `opSw  : alu<= `aluAdd;
            `opBeq : alu<= `aluEq ;
            `opBne : alu<= `aluNe ;
            default: alu<= `aluAdd;
        endcase
    end

endmodule 



module Computer(
    input clk,
    input rst,
    input[2**16-1:0][7:0] program,
    output finish,
    output toDisplay,
    output[15:0] display
);

    reg[15:0] pc;
    
    wire[15:0] instruction;
    InstructionMemory instructionMemory(clk, rst, pc, program, instruction);
    
    wire regDst, regWrite, aluSrc, memWrite, memToReg;
    wire toJump, toBranch, toReturn; wire[3:0] alu;
    Control control(
            instruction[15:11], 
            finish, toDisplay, 
            regDst, regWrite, 
            aluSrc, memWrite, 
            memToReg, toJump, 
            toBranch, toReturn, 
            alu
        );


    wire[15:0] regWriteData, reg1, reg2;
    Registers registers(
            clk,  rst, 
            regDst? instruction[4:2]: instruction[7:5], 
            instruction[10:8], 
            instruction[7:5], 
            regWrite, 
            regWriteData, 
            reg1, reg2
        );

    assign display= reg1;

    wire[15:0] iValue;
    SignExtend signExtend(instruction[4:0], iValue);

    wire[15:0] aluRes; wire zero;
    ALU aLU(alu, reg1, aluSrc? iValue: reg2, zero, aluRes);

    wire[15:0] readData;
    DataMemory dataMemory(clk, rst, aluRes, memWrite, reg2, readData);

    assign regWriteData= memToReg?  readData: aluRes;

    always @(posedge clk) begin
        if(rst) pc<=0;
        else if(toJump)
            pc<= {pc[15:12], instruction[10:0], 1'b0};
        else if(toBranch & zero)
            pc<= pc+ {iValue[14:0], 1'b0};
        else if(toReturn)
            pc<= pc+ {reg1[14:0], 1'b0};
        else pc<= pc+2;
    end

endmodule