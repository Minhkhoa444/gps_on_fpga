/*
    DO NOT TOUCH! THIS MODULE IS JUST A WRAPPER AROUND VENDOR IP!

    PARAMETER VALUE OF pll_model:
        - 0: use Xilinx MMCM
        - 1: use Xilinx PLL
        - 2: use Altera PLL
*/

module pll #(
    parameter pll_model = 0
) (
    input                                   clk_i,
    input                                   rst_i,

    output                                  clk0_o,
    output                                  clk1_o,
    output                                  clk2_o,
    output                                  clk3_o,
    output                                  clk4_o,
    output                                  clk5_o,
    output                                  locked_o
);

    generate
        //  Xilinx UG953
        if(pll_model == 0) begin
            MMCME2_BASE #(
               .BANDWIDTH("OPTIMIZED"),
               .CLKFBOUT_MULT_F(5.0),
               .CLKFBOUT_PHASE(0.0),
               .CLKIN1_PERIOD(0.0),
               .CLKOUT1_DIVIDE(1),
               .CLKOUT2_DIVIDE(1),
               .CLKOUT3_DIVIDE(1),
               .CLKOUT4_DIVIDE(1),
               .CLKOUT5_DIVIDE(1),
               .CLKOUT6_DIVIDE(1),
               .CLKOUT0_DIVIDE_F(1.0),
               .CLKOUT0_DUTY_CYCLE(0.5),
               .CLKOUT1_DUTY_CYCLE(0.5),
               .CLKOUT2_DUTY_CYCLE(0.5),
               .CLKOUT3_DUTY_CYCLE(0.5),
               .CLKOUT4_DUTY_CYCLE(0.5),
               .CLKOUT5_DUTY_CYCLE(0.5),
               .CLKOUT6_DUTY_CYCLE(0.5),
               .CLKOUT0_PHASE(0.0),
               .CLKOUT1_PHASE(0.0),
               .CLKOUT2_PHASE(0.0),
               .CLKOUT3_PHASE(0.0),
               .CLKOUT4_PHASE(0.0),
               .CLKOUT5_PHASE(0.0),
               .CLKOUT6_PHASE(0.0),
               .CLKOUT4_CASCADE("FALSE"),
               .DIVCLK_DIVIDE(1),
               .REF_JITTER1(0.0),
               .STARTUP_WAIT("FALSE")
            ) u_mmcme2_base (
               .CLKOUT0(clk0_o),
               .CLKOUT0B(),
               .CLKOUT1(clk1_o),
               .CLKOUT1B(),
               .CLKOUT2(clk2_o),
               .CLKOUT2B(),
               .CLKOUT3(clk3_o),
               .CLKOUT3B(),
               .CLKOUT4(clk4_o),
               .CLKOUT5(clk5_o),
               .CLKOUT6(),
               .CLKFBOUT(),
               .CLKFBOUTB(),
               .LOCKED(locked_o),
               .CLKIN1(clk_i),
               .PWRDWN(1'b0),
               .RST(rst_i),
               .CLKFBIN()
            );
        end
        //  Xilinx UG953
        else if(pll_model == 1) begin
            PLLE2_BASE #(
               .BANDWIDTH("OPTIMIZED"),
               .CLKFBOUT_MULT(5),
               .CLKFBOUT_PHASE(0.0),
               .CLKIN1_PERIOD(0.0),
               .CLKOUT0_DIVIDE(1),
               .CLKOUT1_DIVIDE(1),
               .CLKOUT2_DIVIDE(1),
               .CLKOUT3_DIVIDE(1),
               .CLKOUT4_DIVIDE(1),
               .CLKOUT5_DIVIDE(1),
               .CLKOUT0_DUTY_CYCLE(0.5),
               .CLKOUT1_DUTY_CYCLE(0.5),
               .CLKOUT2_DUTY_CYCLE(0.5),
               .CLKOUT3_DUTY_CYCLE(0.5),
               .CLKOUT4_DUTY_CYCLE(0.5),
               .CLKOUT5_DUTY_CYCLE(0.5),
               .CLKOUT0_PHASE(0.0),
               .CLKOUT1_PHASE(0.0),
               .CLKOUT2_PHASE(0.0),
               .CLKOUT3_PHASE(0.0),
               .CLKOUT4_PHASE(0.0),
               .CLKOUT5_PHASE(0.0),
               .DIVCLK_DIVIDE(1),
               .REF_JITTER1(0.0),
               .STARTUP_WAIT("FALSE")
            ) u_plle2_base (
               .CLKOUT0(clk0_o),
               .CLKOUT1(clk1_o),
               .CLKOUT2(clk2_o),
               .CLKOUT3(clk3_o),
               .CLKOUT4(clk4_o),
               .CLKOUT5(clk5_o),
               .CLKFBOUT(),
               .LOCKED(locked_o),
               .CLKIN1(clk_i),
               .PWRDWN(),
               .RST(rst_i),
               .CLKFBIN()
            );
        end
    endgenerate


endmodule
