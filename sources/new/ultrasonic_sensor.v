`timescale 1ns / 1ps

module ultrasonic_sensor (
    input             clk,            // 100MHz clock
    input             reset,
    input             start_trigger,  // trigger를 내보내기 위한 trigger
    output reg        trigger,        // HC-SR04 trigger
    input             echo,           // HC-SR04 echo
    output reg [15:0] distance,       // 거리 결과 (cm)
    output reg        echo_done
);

    parameter CLKS_PER_US = 100;  // 100MHz 기준

    parameter
        IDLE = 3'd0,
        TRIG_HIGH = 3'd1,
        WAIT_ECHO_HIGH = 3'd2,
        MEASURE = 3'd3,
        DONE = 3'd4;

    reg [2:0] state, next_state;

    reg [21:0] counter;
    reg [21:0] echo_duration;

    wire tick;

    tick_gen tick_1us (
        .clk  (clk),
        .reset(reset),
        .tick (tick)
    );

    // FSM 상태 전이
    always @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE;
        else state <= next_state;
    end


    always @(*) begin
        case (state)
            IDLE: begin
                if (start_trigger) next_state = TRIG_HIGH;
                else next_state = IDLE;
            end

            TRIG_HIGH: begin
                if (counter >= CLKS_PER_US * 10) next_state = WAIT_ECHO_HIGH;
                else next_state = TRIG_HIGH;
            end

            WAIT_ECHO_HIGH: begin
                if (echo) next_state = MEASURE;
                else next_state = WAIT_ECHO_HIGH;
            end

            MEASURE: begin
                if (!echo) next_state = DONE;
                else next_state = MEASURE;
            end

            DONE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end



    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            echo_duration <= 0;
            trigger <= 0;
            distance <= 0;
            echo_done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    trigger <= 0;
                    counter <= 0;
                    echo_duration <= 0;
                    echo_done <= 0;
                end

                TRIG_HIGH: begin
                    trigger <= 1;
                    counter <= counter + 1;
                end

                WAIT_ECHO_HIGH: begin
                    trigger <= 0;
                end

                MEASURE: begin
                    if (tick) echo_duration <= echo_duration + 1;
                end

                DONE: begin
                    distance  <= echo_duration / 58;
                    echo_done <= 1;
                end

                default: begin
                    trigger <= 0;
                    counter <= 0;
                    echo_duration <= 0;
                    echo_done <= 0;
                end
            endcase
        end
    end

endmodule


module tick_gen #(
    parameter DIV = 100
) (
    input clk,
    input reset,
    output reg tick
);

    reg [$clog2(DIV)-1:0] count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            tick  <= 0;
        end else if (count == DIV - 1) begin
            count <= 0;
            tick  <= 1;
        end else begin
            count <= count + 1;
            tick  <= 0;
        end
    end
endmodule
