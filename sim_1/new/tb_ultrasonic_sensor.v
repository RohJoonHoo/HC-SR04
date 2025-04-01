`timescale 1ns / 1ps

module tb_ultrasonic_sensor;

    reg clk;
    reg reset;
    reg start_trigger;
    wire trigger;
    reg echo;
    wire [15:0] distance;
    wire echo_done;

    // DUT
    ultrasonic_sensor uut (
        .clk(clk),
        .reset(reset),
        .start_trigger(start_trigger),
        .trigger(trigger),
        .echo(echo),
        .distance(distance),
        .echo_done(echo_done)
    );

    // 100MHz clock => 10ns period
    always #5 clk = ~clk;

    initial begin
        // 초기화
        clk = 0;
        reset = 1;
        start_trigger = 0;
        echo = 0;

        #100;
        reset = 0;

        // ▶ 트리거 발생
        #50;
        start_trigger = 1;
        #10;
        start_trigger = 0;

        // ▶ echo를 일정 시간 HIGH로 설정 (예: 1ms = 1000us = 100000 tick @ 1us tick)
        // HC-SR04 거리 계산 공식: distance[cm] = echo_time[us] / 58
        // 예: 580us -> 10cm

        // trigger 끝난 뒤 충분히 기다림
        wait(trigger == 1);
        wait(trigger == 0);
        #1000;

        echo = 1;
        #58000;  // 580us 동안 HIGH → 10cm 거리 측정 기대
        echo = 0;

        // 결과 관찰용 대기
        #200000;

        $display("Measured Distance = %d cm", distance);
        $finish;
    end

endmodule
