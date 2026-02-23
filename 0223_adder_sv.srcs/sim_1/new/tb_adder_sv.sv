`timescale 1ns / 1ps

interface adder_interface; //kyeword 
    logic [31:0] a;
    logic [31:0] b;
    logic [31:0] s;
    logic        c;
    logic        mode;
endinterface  //adder_interface

class transaction;

    rand bit [31:0] a;  // random 값으로 생성 
    rand bit [31:0] b;
    bit             mode;
endclass  //transaction 

class generator;

    //변수 선언 : data type transction 
    transaction tr;
    virtual adder_interface adder_interf_gen;
    function new(virtual adder_interface adder_interf_ext);
        adder_interf_gen = adder_interf_ext;
        tr = new();
    endfunction

    task run();
        tr.randomize();
        tr.mode = 0;

        adder_interf_gen.a = tr.a;
        adder_interf_gen.b = tr.b;
        adder_interf_gen.mode = tr.mode;

        //drive
        #10;

    endtask

endclass  //generator


module tb_adder_sv ();

    //logic [31:0] a, b, s;
    //logic c, mode;

    adder_interface adder_interf();
    // class generator를 선언 
    generator gen; //사용자 정의 형 data type

    adder dut (
        .a(adder_interf.a),
        .b(adder_interf.b),
        .mode(adder_interf.mode),
        .s(adder_interf.s),
        .c(adder_interf.c)
    );

    initial begin
        //class generator를 생성 
        //generator class의 function new가 실행됨 
        gen = new(adder_interf); //new 생성자 
        gen.run(); // 생성된 new를 task run 실행 
        $stop;
    end

endmodule
