`timescale 1ns / 1ps

module top_module (
    input clk,
    input reset,
    input rx,
    output trigger,
    input echo,
    output tx,
    output [7:0] seg,
    output [3:0] an
);

    wire [15:0] distance;
    wire [7:0] w_rx_data;
    wire tick;
    wire w_rx_done;

    baud_tick_gen TICK_GEN (
        .clk(clk),
        .reset(reset),
        .baud_tick(tick)
    );

    uart_rx UART_RX (
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .rx(rx),
        .rx_done(w_rx_done),
        .rx_data(w_rx_data)
    );

    assign rx_trigger = w_rx_done && (w_rx_data == 8'h55 || w_rx_data == 8'h75); //u or U 탐지

    ultrasonic_sensor U_ultrasonic_sensor (
        .clk(clk),
        .reset(reset),
        .start_trigger(rx_trigger),
        .trigger(trigger),
        .echo(echo),
        .distance(distance),
        .echo_done(echo_done)
    );

    fnd_controller U_fnd_controller (
        .clk(clk),
        .reset(reset),
        .number(distance),
        .seg(seg),
        .an(an)
    );


    wire tx_fifo_empty;
    wire [7:0] fifo_wdata, o_data;
    wire fifo_wr;
    wire o_tx_done;

    uart_distance_sender U_MSG (
        .clk(clk),
        .reset(reset),
        .distance(distance),
        .fifo_empty(tx_fifo_empty),
        .distance_valid(echo_done),
        .wdata(fifo_wdata),
        .wr(fifo_wr)
    );

    fifo U_TX_FIFO_REG (
        .clk(clk),
        .reset(reset),
        .wdata(fifo_wdata),
        .wr(fifo_wr),
        .full(),
        .rd(~o_tx_done),
        .rdata(o_data),
        .empty(tx_fifo_empty)
    );

    uart_tx UART_TX (
        .clk(clk),
        .reset(reset),
        .tick(tick),
        .start_trigger(!tx_fifo_empty),
        .data_in(o_data),
        .o_tx(tx),
        .o_tx_done(o_tx_done)
    );

endmodule
