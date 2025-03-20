module pick_top_4 #(
    parameter D_WIDTH = 5
)(
    input   logic   clk,
    input   logic   rst_n,

    input   logic   i_vld,
    input   logic   signed  [D_WIDTH-1:0]   i_data,
    input   logic   acq_done,

    output  logic   o_vld,
    output  logic   signed  [D_WIDTH-1:0]   o_data  [0:3]
);

    logic   signed  [D_WIDTH-1:0]   top_4       [0:3];
    logic   [3:0]   update;
    logic   [3:0]   bigger;

    genvar i;
    generate
        for(i=0; i<4; i++) begin
            assign bigger[i] = (i_vld) ? (i_data > top_4[i]) : 'b0;
        end
    endgenerate

    assign  update[0] = bigger[0];
    assign  update[1] = bigger[0];
    assign  update[2] = |bigger[1:0];
    assign  update[3] = |bigger[2:0];

    always_ff @(posedge clk) begin
        if(~rst_n) begin
            top_4[0] <= 'b0;
            top_4[1] <= 'b0;
            top_4[2] <= 'b0;
            top_4[3] <= 'b0;
        end
        else begin
            if(update[0]) begin
                top_4[0] <= i_data;
            end

            if(update[1]) begin
                top_4[1] <= top_4[0];
            end

            if(update[2]) begin
                top_4[2] <= top_4[1];
            end

            if(update[3]) begin
                top_4[3] <= top_4[2];
            end
            else begin
                if(bigger[3]) begin
                    top_4[3] <= i_data;
                end
            end
        end
    end

    always_ff @(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            o_vld <= 'b0;
        end
        else begin
            o_vld <= acq_done;
        end
    end

    always_ff @(posedge clk) begin
        o_data <= top_4;
    end

endmodule