#include<bits/stdc++.h>
using namespace std;

string opExit=  "00000";
string opPrint= "00001";
string opAdd=   "00010";
string opSub=   "00011";
string opMul=   "00100";
string opDiv=   "00101";
string opEq =   "00110";
string opNe =   "00111";
string opAddi = "01000";
string opSubi = "01001";

vector<string> binary;

string str(int n, char c)
{
    string s;
    while(n--) s.push_back(c);
    return s;
}

string toBin(int n, int m=3)
{
    if(n<0) n+= (1<<m);
    string s= str(m, '0');
    for(int i=0; i<m; i++)
        s[m-i-1]+= (n&(1<<i))>0;
    return s;
}

// emits alu instructions
void emitALU(int a, int b, int c, string op)
{
    binary.push_back(op+toBin(b)+toBin(c)+toBin(a)+"00");
}

// emits immediate type instructions
void emitALUi(int a, int b, int v, string op)
{
    binary.push_back(op+toBin(b)+toBin(a)+toBin(v, 5));
}

void eFinish()
{
    binary.push_back(opExit+str(11, '0'));
}

void ePrint(int a)
{
    binary.push_back(opPrint+toBin(a)+str(8, '0'));
}

void eAdd(int a, int b, int c){ emitALU(a, b, c, opAdd); }
void eSub(int a, int b, int c){ emitALU(a, b, c, opSub); }
void eMul(int a, int b, int c){ emitALU(a, b, c, opMul); }
void eDiv(int a, int b, int c){ emitALU(a, b, c, opDiv); }
void eEq (int a, int b, int c){ emitALU(a, b, c, opEq ); }
void eNe (int a, int b, int c){ emitALU(a, b, c, opNe ); }

void eAddi(int a, int b, int v){ emitALUi(a, b, v, opAddi); }
void eSubi(int a, int b, int v){ emitALUi(a, b, v, opSubi); }

int main()
{    
    /********* Code Start *********/

    eAddi   (1, 0, 1);
    ePrint(1);  
    eFinish();

    /********* Code End *********/
    
    ofstream bin("program.v");
    bin<<
    "`include \"computer.v\"\n"
    "module Test();\n\n"
    "    reg clk, rst;\n\n"
    "    always #5 clk=~clk;\n\n"
    "    wire[2**16-1:0][7:0] program;\n\n";

    for(int i=0; i<binary.size(); i++)
        bin<<"\tassign program["+to_string(2*i+1)+":"+to_string(2*i)+"]= 16'b"+binary[i]<<";"<<endl;
    
    bin<<"\tassign program[65535:"+to_string(2*binary.size())+"]= 0;\n\n"
    "    wire finish, toDisplay;\n"
    "    wire[15:0] display;\n"
    "    Computer computer(clk, rst, program, finish, toDisplay, display);\n\n"
    "    initial begin\n"
    "        clk=0; rst=1;\n"
    "        #10; rst=0;\n"
    "    end\n\n"
    "    always @(negedge clk) begin\n"
    "        if(~rst & toDisplay)\n"
    "            $display(\"%d\", $signed(display));\n"
    "        if(~rst & finish)\n"
    "            $finish;\n\n"
    "    end\n"
    "endmodule\n";
}
