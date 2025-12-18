//==============================================================================
// I2C Slave (спрощена навчальна модель)
// - Address+R/W, ACK якщо my_addr співпадає
// - R/W=0: прийом 1 байта -> data_received, імпульс data_valid
// - R/W=1: передача 1 байта data_to_send, очікування ACK/NACK від master
// - SDA open-drain, підтяжка зовнішня
// - SCL/SDA синхронізуються у clk-домен через 2 тригери
//==============================================================================

module i2c_slave (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [6:0] my_addr,
    input  wire       scl,
    inout  wire       sda,

    input  wire [7:0] data_to_send,

    output reg  [7:0] data_received,
    output reg        data_valid
);

    reg  sda_oe;
    wire sda_in = sda;
    assign sda = sda_oe ? 1'b0 : 1'bz;

    reg scl_m, scl_s, scl_d;
    reg sda_m, sda_s, sda_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_m <= 1'b1; scl_s <= 1'b1; scl_d <= 1'b1;
            sda_m <= 1'b1; sda_s <= 1'b1; sda_d <= 1'b1;
        end else begin
            scl_m <= scl;
            scl_s <= scl_m;
            scl_d <= scl_s;

            sda_m <= sda_in;
            sda_s <= sda_m;
            sda_d <= sda_s;
        end
    end

    wire scl_rise = ( scl_s && !scl_d);
    wire scl_fall = (!scl_s &&  scl_d);

    wire start_cond = (scl_s &&  sda_d && !sda_s);
    wire stop_cond  = (scl_s && !sda_d &&  sda_s);

    localparam [3:0]
        R_IDLE        = 4'd0,
        R_ADDR        = 4'd1,
        R_ADDR_ACK_0  = 4'd2,
        R_ADDR_ACK_1  = 4'd3,
        R_WDATA       = 4'd4,
        R_WACK_0      = 4'd5,
        R_WACK_1      = 4'd6,
        R_RDATA       = 4'd7,
        R_RACK_SAMPLE = 4'd8,
        R_WAITSTOP    = 4'd9;

    reg [3:0] state;
    reg [3:0] bit_cnt;

    reg [7:0] rx_shreg;
    reg [7:0] tx_shreg;

    reg       addr_match;
    reg       rw_dir;     // 0=write, 1=read

    wire [7:0] rx_next = {rx_shreg[6:0], sda_s};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= R_IDLE;
            bit_cnt       <= 4'd0;
            rx_shreg      <= 8'd0;
            tx_shreg      <= 8'd0;

            addr_match    <= 1'b0;
            rw_dir        <= 1'b0;

            sda_oe        <= 1'b0;
            data_received <= 8'd0;
            data_valid    <= 1'b0;
        end else begin
            data_valid <= 1'b0;

            if (stop_cond) begin
                state  <= R_IDLE;
                sda_oe <= 1'b0;
            end

            if (start_cond) begin
                state      <= R_ADDR;
                bit_cnt    <= 4'd7;
                rx_shreg   <= 8'd0;
                addr_match <= 1'b0;
                rw_dir     <= 1'b0;
                sda_oe     <= 1'b0;
            end

            case (state)
                R_IDLE: begin
                    sda_oe <= 1'b0;
                end

                R_ADDR: begin
                    sda_oe <= 1'b0;
                    if (scl_rise) begin
                        rx_shreg <= rx_next;

                        if (bit_cnt == 0) begin
                            addr_match <= (rx_next[7:1] == my_addr);
                            rw_dir     <=  rx_next[0];
                            state      <= R_ADDR_ACK_0;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                R_ADDR_ACK_0: begin
                    if (scl_fall) begin
                        sda_oe <= addr_match;
                        state  <= R_ADDR_ACK_1;
                    end
                end

                R_ADDR_ACK_1: begin
                    if (scl_fall) begin
                        sda_oe <= 1'b0;
                        if (addr_match) begin
                            if (rw_dir == 1'b0) begin
                                state    <= R_WDATA;
                                bit_cnt  <= 4'd7;
                                rx_shreg <= 8'd0;
                            end else begin
                                state    <= R_RDATA;
                                bit_cnt  <= 4'd7;
                                tx_shreg <= data_to_send;
                            end
                        end else begin
                            state <= R_IDLE;
                        end
                    end
                end

                R_WDATA: begin
                    sda_oe <= 1'b0;
                    if (scl_rise) begin
                        rx_shreg <= rx_next;

                        if (bit_cnt == 0) begin
                            data_received <= rx_next;
                            data_valid    <= 1'b1;
                            state         <= R_WACK_0;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                R_WACK_0: begin
                    if (scl_fall) begin
                        sda_oe <= 1'b1;
                        state  <= R_WACK_1;
                    end
                end

                R_WACK_1: begin
                    if (scl_fall) begin
                        sda_oe <= 1'b0;
                        state  <= R_WAITSTOP;
                    end
                end

                R_RDATA: begin
                    if (scl_fall) begin
                        sda_oe <= (tx_shreg[7] == 1'b0);
                    end
                    if (scl_rise) begin
                        tx_shreg <= {tx_shreg[6:0], 1'b0};

                        if (bit_cnt == 0) begin
                            sda_oe <= 1'b0;
                            state  <= R_RACK_SAMPLE;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                R_RACK_SAMPLE: begin
                    sda_oe <= 1'b0;
                    if (scl_rise) begin
                        state <= R_WAITSTOP;
                    end
                end

                R_WAITSTOP: begin
                    sda_oe <= 1'b0;
                end

                default: state <= R_IDLE;
            endcase
        end
    end

endmodule
