`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Nit Rourkela
// Engineer: Vipul Sahu
// 
// Create Date: 04.05.2026 10:25:50
// Design Name: 
// Module Name: Butterfly_NTT
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

`timescale 1ns / 1ps

module Butterfly_NTT(
    input clk,
    input reset,                  // asynchronous active low reset
    input NTT_start,
    input inverse_ntt,             // 0 = Forward NTT, 1 = Inverse NTT

    // Load interface
    input load_en,
    input [7:0] load_addr,
    input [11:0] load_data,
    
    //Read interface
    input read_en,
    input [7:0]read_addr,
    output reg [11:0] read_data,
    
    output reg busy,
    output reg done
);

    parameter q = 3329;
    parameter INV_NTT_FACTOR_MONT = 512;   // 3303 × 2^16 mod 3329 = 512  (in Montgomery form)

    reg [7:0] i;
    reg [7:0] len;
    reg [7:0] start;
    reg [7:0] scale_index;

    reg [11:0] old_a;
    reg [11:0] old_b;
    reg [11:0] t;
    reg [11:0] b_minus_a;

    reg [11:0] a_NTT_mem [255:0];

    reg [3:0] state;

    // FSM states
    parameter IDLE          = 4'd0;
    parameter initialize    = 4'd1;
    parameter READ_VALUES   = 4'd2;
    parameter START_MULT    = 4'd3;
    parameter WAIT_MULT     = 4'd4;
    parameter WRITE_VALUES  = 4'd5;
    parameter UPDATE_INDEX  = 4'd6;
    parameter SCALE_START   = 4'd7;
    parameter SCALE_WAIT    = 4'd8;
    parameter completed     = 4'd9;
    

    // Zeta ROM
    reg [7:0] zeta_index;
    wire [11:0] zeta;

    zeta_ROM get_zeta(
        .index(zeta_index),
        .zeta_value(zeta)
    );
    

    // Modular addition: (x + y) mod q
    function [11:0] mod_sum;
        input [11:0] x;
        input [11:0] y;

        reg [12:0] sum;

        begin
            sum = x + y;

            if (sum < q)
                mod_sum = sum[11:0];
            else
                mod_sum = sum - q;
        end
    endfunction
    

    // Modular subtraction: (x - y) mod q
    function [11:0] mod_diff;
        input [11:0] x;
        input [11:0] y;

        begin
            if (x >= y)
                mod_diff = x - y;
            else
                mod_diff = x + q - y;
        end
    endfunction


    // For Montgomery Multiplication
    reg mont_start;
    reg [11:0] mont_a;
    reg [11:0] mont_b;
    wire [11:0] mont_result;
    wire mont_done;   
    
    Montgomery_multiplier MONT1 (
        .clk(clk),
        .reset(reset),
        .start(mont_start),
        .a(mont_a),
        .b(mont_b),
        .result(mont_result),
        .done(mont_done)
    );


    always @(posedge clk or negedge reset) begin

        if (reset == 0) begin

            zeta_index  <= 0;
            done        <= 0;
            busy        <= 0;

            len         <= 0;
            start       <= 0;
            i           <= 0;
            scale_index <= 0;

            old_a       <= 0;
            old_b       <= 0;
            t           <= 0;
            b_minus_a   <= 0;

            mont_start  <= 0;
            mont_a      <= 0;
            mont_b      <= 0;

            read_data   <= 0;

            state       <= IDLE;

        end

        else begin
        
            // External load/read interface allowed only when NTT block is not busy    
            if (busy == 0) begin
                
                if (load_en == 1'b1) begin
                    a_NTT_mem[load_addr] <= load_data;
                end
                if (read_en == 1'b1) begin
                    read_data <= a_NTT_mem[read_addr];
                end
                
            end
            
            case (state)

                // Wait for start
                IDLE: begin
                
                    mont_start <= 0;
                    
                    if (NTT_start == 1) begin
                        done <= 0;
                        busy <= 1;
                        state <= initialize;
                    end

                end


                // Initialize forward or inverse NTT
                initialize: begin

                    start <= 0;
                    i     <= 0;

                    if (inverse_ntt == 0) begin
                        // Forward NTT
                        len        <= 128;
                        zeta_index <= 1;
                    end
                    else begin
                        // Inverse NTT
                        len        <= 2;
                        zeta_index <= 127;
                    end

                    state <= READ_VALUES;

                end


                // State 1: read butterfly values
                READ_VALUES: begin

                    old_a <= a_NTT_mem[i];
                    old_b <= a_NTT_mem[i + len];

                    state <= START_MULT;

                end


                // State 2: compute multiplication part
                START_MULT : begin
                    
                    mont_start <= 1;
                    
                    if (inverse_ntt == 0)begin
                        // Forward NTT:
                        // t = (Zeta * old_b) mod Q
                        mont_a <= zeta;
                        mont_b <= old_b;
                    end
                    else begin
                        // Inverse NTT:
                        // t = zeta * (old_b - old_a)
                        b_minus_a <= mod_diff(old_b,old_a);
                        mont_a <= zeta;
                        mont_b <= mod_diff(old_b,old_a);
                    end
                    
                    state <= WAIT_MULT;
                    
                end
                
                
                WAIT_MULT : begin
                    
                    mont_start <= 1'b0;
                    
                    if (mont_done == 1'b1) begin
                        t <= mont_result;
                        state <= WRITE_VALUES;              
                    end
                end
                


                // State 3: write butterfly result
                WRITE_VALUES: begin

                    if (inverse_ntt == 0) begin
                        // Forward butterfly:
                        // new_a = old_a + t
                        // new_b = old_a - t

                        a_NTT_mem[i]       <= mod_sum(old_a, t);
                        a_NTT_mem[i + len] <= mod_diff(old_a, t);
                    end
                    else begin
                        // Inverse butterfly:
                        // new_a = old_a + old_b
                        // new_b = zeta * (old_b - old_a)

                        a_NTT_mem[i]       <= mod_sum(old_a, old_b);
                        a_NTT_mem[i + len] <= t;
                    end

                    state <= UPDATE_INDEX;

                end


                // State 4: update i, start, len, and zeta_index
                UPDATE_INDEX: begin

                    // Move to next i in same group
                    if (i < start + len - 1) begin

                        i <= i + 1;
                        state <= READ_VALUES;

                    end

                    else begin

                        // Move to next start group
                        if ((start + (2 * len)) < 256) begin

                            start <= start + (2 * len);
                            i     <= start + (2 * len);

                            if (inverse_ntt == 0)
                                zeta_index <= zeta_index + 1;
                            else
                                zeta_index <= zeta_index - 1;

                            state <= READ_VALUES;
                        end

                        else begin

                            if (inverse_ntt == 0) begin

                                // Forward NTT next stage
                                if (len > 2) begin
                                    len        <= len/2;
                                    start      <= 0;
                                    i          <= 0;
                                    zeta_index <= zeta_index + 1;

                                    state <= READ_VALUES;

                                end
                                else begin

                                    state <= completed;

                                end

                            end

                            else begin

                                // Inverse NTT next stage
                                if (len < 128) begin

                                    len        <= len * 2;
                                    start      <= 0;
                                    i          <= 0;
                                    zeta_index <= zeta_index - 1;

                                    state <= READ_VALUES;

                                end
                                else begin

                                    scale_index <= 0;
                                    state <= SCALE_START;

                                end

                            end

                        end

                    end

                end


                // Final scaling for inverse NTT only
                // a[i] = a[i] * 3303 mod 3329
                // since Montgomery is used , factor = 512
                SCALE_START : begin
                    mont_start <= 1;
                    mont_a <= a_NTT_mem[scale_index];
                    mont_b <= INV_NTT_FACTOR_MONT;
                    
                    state <= SCALE_WAIT;
                end
                
                
                SCALE_WAIT : begin
                
                    mont_start <= 0;
                    
                    if (mont_done == 1) begin
                        
                        a_NTT_mem[scale_index] <= mont_result;
                        
                        if(scale_index == 255) begin
                            scale_index <= 0;
                            state <= completed;
                        end
                        else begin
                            scale_index <= scale_index + 1;
                            state <= SCALE_START;
                        end
                        
                    end
                
                end


                // Done state
                completed: begin
                    done <= 1;
                    busy <= 0;
                    mont_start <= 0;
                    state <= IDLE;
                end


                default: begin
                    state <= IDLE;
                end

            endcase

        end

    end

endmodule
