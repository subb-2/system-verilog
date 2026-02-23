`timescale 1ns / 1ps

    class transaction;
        
        rand bit [31:0] a; // random 값으로 생성 
        rand bit [31:0] b;
        bit         mode;
    endclass //transaction 



module tb_adder_sv();

    logic [31:0] a,b,s;
    logic c, mode;

    adder dut(
        .a(a),
        .b(b),
        .mode(mode),
        .s(s),
        .c(c)
    );



endmodule
