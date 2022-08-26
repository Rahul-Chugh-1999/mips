# Generating machine code
To generate machine
1.  In genAsm.cpp, put your mips code in *Code Start* to *Code End* block, use: eAdd, eMul etc functions.
2.  Run command: g++ genAsm.cpp && ./a.out

# To simulate machine code
Run following commands
```bash
iverilog program.v
vvp a.out
```
