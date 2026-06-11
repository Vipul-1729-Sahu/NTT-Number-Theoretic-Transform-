`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.05.2026 16:05:58
// Design Name: 
// Module Name: Montgomery_multiplication
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


module Montgomery_multiplier (
    input clk,
    input reset,
    input start,

    input [11:0] a,
    input [11:0] b,

    output reg [11:0] result,
    output reg done
);

    parameter q = 3329;
    parameter QINV = 3327;

    // Pipeline registers
    reg valid_s1;
    reg valid_s2;
    reg valid_s3;
    reg valid_s4;
    
    
    // Pipeline data registers
    // Stage 1
    reg [31:0] product_s1;
   
    // Stage 2
    reg [31:0] product_s2;
    reg [15:0] u_s2;
    
    // Stage 3
    reg [31:0] temp_reduced_s3;
    
    // Stage 4
    reg [15:0] reduced_s4;
    
    
    // Combinational helper wires
    wire [31:0] temp_u_calc;
    wire [31:0] temp_reduced_calc;
    wire [15:0] reduced_calc;
    
    // u = (product * QINV) mod 2^16
    // Only lower 16 bits matter for module 2^16
    assign temp_u_calc = product_s1[15:0] * 16'd3327;
    
    // temp_reduced = product + u*q
    assign temp_reduced_calc = product_s2 + (u_s2 * 16'd3329);
    
    // divide by R = 2^16
    assign reduced_calc = temp_reduced_s3 >> 16;
    
    always @(posedge clk or negedge reset) begin
    
        if (reset == 0) begin
            
            valid_s1 <= 0;
            valid_s2 <= 0;
            valid_s3 <= 0;
            valid_s4 <= 0;
            
            product_s1 <= 0;
            product_s2 <= 0;
            u_s2       <= 0;
            
            temp_reduced_s3 <= 0;
            reduced_s4 <= 0;
            
            result <= 0;
            done <= 0;
            
        end
        else begin
            
            // Valid signal pipeline 
            valid_s1 <= start;
            valid_s2 <= valid_s1;
            valid_s3 <= valid_s2;
            valid_s4 <= valid_s3;
            
            // Stage 1: product = a*b
            if (start == 1) begin
                product_s1 <= a*b;
            end
            
            // Stage 2: 
            // u = lower 16 bits of product * QINV
            // Also pass product forward
            if (valid_s1 == 1)begin
                product_s2 <= product_s1;
                u_s2 <= temp_u_calc[15:0];
            end
            
            // Stage 3: temp_reduced = product + u*q
            if (valid_s2 == 1)begin
                temp_reduced_s3 <= temp_reduced_calc;
            end
            
            // Stage 4: shift and correction
            if (valid_s3)begin
                
                reduced_s4 <= reduced_calc;
                
                if(reduced_calc >= q)begin
                    result <= reduced_calc - q;
                end
                else begin
                    result <= reduced_calc[11:0];
                end
                
            end
            
            // done goes high when result is valid
            done <= valid_s3;
            
        end
    
    end
    
        
endmodule


// Montgomery reduction :
// For montgomery reduction R=2^16 and Qinv = 3327.
// let we have to find montgomery reduction of 'x'.
// Algorithm :
// u = (x*(Qinv)) mod R
// v = (x + u*Q)/R
// if (v>Q)
//      v = v - Q
// else 
//      v = v
