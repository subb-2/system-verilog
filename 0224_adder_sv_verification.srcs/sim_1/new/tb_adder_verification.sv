`timescale 1ns / 1ps

interface adder_interface;
    logic [31:0] a;
    logic [31:0] b;
    logic        mode;
    logic [31:0] s;
    logic        c;
endinterface  //adder_interface

//stimulus(vector)
class transaction;
    //rand라는 keyword / randomize 할 때 불려서 사용됨 
    rand bit [31:0] a;
    rand bit [31:0] b;
    rand bit        mode;
    logic    [31:0] s;
    logic           c;

endclass  //transaction

//generator for randomize stimulus
class generator;
    //tr : transaction handler
    transaction tr;

    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox; //외부의 mbox와 연결하라는 의미 
        this.gen_next_ev = gen_next_ev;
    endfunction  //new()

    task run(int count);
        repeat (count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            @(gen_next_ev);  //event get 
        end
    endtask  //run
endclass  //generator

class driver;
    transaction tr;
    virtual adder_interface adder_if;

    mailbox #(transaction) gen2drv_mbox;
    event mon_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event mon_next_ev,
                 virtual adder_interface adder_if);
        this.adder_if = adder_if;
        this.mon_next_ev = mon_next_ev;
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction  //new()

    task run();
        forever begin  //forever 영원히 반복 
            gen2drv_mbox.get(tr);
            adder_if.a    = tr.a;
            adder_if.b    = tr.b;
            adder_if.mode = tr.mode;
            #10;
            //event generation 
            //->gen_next_ev;  //event push 
            -> mon_next_ev;
        end

    endtask  //run();
endclass  //driver

class monitor;

    transaction tr;
    virtual adder_interface adder_if;
    mailbox #(transaction) mon2scb_mbox;
    event mon_next_ev;

    function new(mailbox#(transaction) mon2scb_mbox,
                event mon_next_ev,
                 virtual adder_interface adder_if);

        this.mon2scb_mbox = mon2scb_mbox;
        this.mon_next_ev = mon_next_ev;
        this.adder_if = adder_if;

    endfunction  //new()

    task run();
        forever begin
            @(mon_next_ev);
            tr = new();
            tr.a = adder_if.a;
            tr.b = adder_if.b;
            tr.mode = adder_if.mode;
            tr.s = adder_if.s;
            tr.c = adder_if.c;
            mon2scb_mbox.put(tr);
        end
    endtask

endclass  //monitor

class scoreboard;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    function new(mailbox #(transaction) mon2scb_mbox,
            event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev = gen_next_ev;
        
    endfunction //new()

    task run ();
        forever begin
            mon2scb_mbox.get(tr);
            //compare , pass, fail
            $display("%t:a=%d, b=%d, mode = %d, s=%d, c=%d", $time, tr.a, tr.b, tr.mode, tr.s, tr.c);
            -> gen_next_ev;
        end
        
    endtask //run

endclass //scoreboard

class environment;

    generator               gen;
    driver                  drv;
    //virtual adder_interface adder_if;
    monitor                 mon;
    scoreboard scb;

    mailbox #(transaction)  gen2drv_mbox; //gen -> drv
    mailbox #(transaction)  mon2scb_mbox; //mon -> scb 

    event                   gen_next_ev; //scb to gen 
    event                   mon_next_ev; //drv to mon

    function new(virtual adder_interface adder_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox,
                  gen_next_ev);  // 이게 실행될 때 보낼 값 생성 
        drv = new(gen2drv_mbox, gen_next_ev, adder_if);
        mon = new(mon2scb_mbox, mon_next_ev, adder_if);
        scb = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()

    task run();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
        //순서 존재
        //begin end가 block 기본 
        //pork join 
        //현재 begin end가 생략되어있어서 기본적으로 begin end가 있어서 순서 대로 실행 
        //repeat(10) begin

        // end
        $stop;
    endtask  //run()
endclass  //environment

module tb_adder_verification ();

    adder_interface adder_if ();

    environment env;

    adder dut (
        .a(adder_if.a),
        .b(adder_if.b),
        .mode(adder_if.mode),
        .s(adder_if.s),
        .c(adder_if.c)
    );

    initial begin
        // constructor 
        env = new(adder_if);

        // exe
        env.run();
    end

endmodule
