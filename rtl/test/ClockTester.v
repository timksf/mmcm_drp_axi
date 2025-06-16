module ClockTester(
    input clk_fst,
    input clk_slw,
    input reset_n,
    output [15:0] ht_out,
    output [15:0] lt_out
);

    wire [15:0] ht;
    wire [15:0] lt;
    wire clk_slow_del;

    always @ (posedge clk_fst) begin
        if(!reset_n) begin
            //synchronous reset
            ht <= 0;
            lt <= 0;
            clk_slow_del <= 0;
            ht_out <= 0;
            lt_out <= 0;
        end else begin
            case({clk_slow_del, clk_slw})
                2'b00: lt <= lt + 1;
                2'b11: ht <= ht + 1;
                2'b01: begin
                    if(ht_out != ht) 
                        ht_out <= ht;
                    ht <= 0;
                end
                2'b10: begin
                    if(lt_out != lt) 
                        lt_out <= lt;
                    lt <= 0;
                end
            endcase
            clk_slow_del <= clk_slw;
        end
    end


endmodule