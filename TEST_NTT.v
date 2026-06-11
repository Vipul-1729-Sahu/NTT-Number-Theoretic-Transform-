`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NIT Rourkela
// Engineer: Vipul Sahu
// 
// Create Date: 15.05.2026 18:08:42
// Design Name: 
// Module Name: TEST_NTT
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TEST_NTT();

    reg clk;
    reg reset;
    reg start;
    reg [11:0] a;
    reg [11:0] b;
    
    wire [11:0] result;
    wire done;
    
    integer errors;
    
    Montgomery_multiplier dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .a(a),
        .b(b),
        .result(result),
        .done(done)
    );

    // 10ns clock period
    always #5 clk = ~clk;
    
    // Task to apply one Montgomery multiplication test
    task test_mont;
    
        input [11:0] in_a;
        input [11:0] in_b;
        input [11:0] expected;
        
        begin
            @(negedge clk);
                a = in_a;
                b = in_b;
                start = 1'b1;
                
            @ (negedge clk);
                start = 1'b0;
                wait(done == 1);
            
            @(posedge clk);
                #1;
                
            if (result != expected) begin
                $display("FAIL : a=%0d , b=%od , expected = %0d , got = %0d", in_a , in_b , expected , result);
                errors = errors + 1;
            end
            else begin
                $display("PASS : a=%0d , b=%0d , result=%0d" , in_a , in_b , result);
            end
            
            @(negedge clk);
        end
    
    endtask
    
    
    initial begin

        clk = 0;
        reset = 0;
        start = 0;
        a = 0;
        b = 0;
        errors = 0;

        // Reset
        #20;
        reset = 1;
        #20;

        // -------------------------------------------------
        // Important:
        // This Montgomery multiplier computes:
        // result = a * b * R^(-1) mod q
        // where R = 2^16, q = 3329
        // -------------------------------------------------

        // Test 1: 0 * anything = 0
        test_mont(12'd0, 12'd100, 12'd0);

        // Test 2:
        // montgomery_reduce(1 * 1)
        // = 1 * R^-1 mod 3329
        // R^-1 mod 3329 = 169
        test_mont(12'd1, 12'd1, 12'd169);

        // Test 3:
        // zeta_mont = 2285
        // old_b = 1
        // montgomery_mul(2285, 1) should give normal zeta value
        // For Kyber table first Montgomery zeta 2285 corresponds to normal 17
        test_mont(12'd2285, 12'd1, 12'd17);

        // Test 4:
        // INV_NTT_FACTOR_MONT = 512
        // montgomery_mul(512, 1) = 3303
        // because 512 is Montgomery form of 3303
        test_mont(12'd512, 12'd1, 12'd3303);

        // Test 5:
        // random check using Python reference:
        // montgomery_reduce(1234 * 567) = 1573
        test_mont(12'd1234, 12'd567, 12'd1573);

        // Test 6:
        // random check using Python reference:
        // montgomery_reduce(3000 * 2000) = 1305
        test_mont(12'd3000, 12'd2000, 12'd1305);


        if (errors == 0) begin
            $display("ALL MONTGOMERY TESTS PASSED");
        end
        else begin
            $display("MONTGOMERY TEST FAILED: errors = %0d", errors);
        end

        $finish;
    end

endmodule
