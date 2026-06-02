module HC_SR04(
    input sysclk,
    input rst_n,
    input echo,       //传感器回传信号   抓取高电平持续时间测距离
    output trig,   //控制端口 -- > FPGA控制传感器  控制条件>10us
    output distance   //测得的距离
);
    
    parameter delay = 50 * 15 + 50_000 * 80;   //15us trig(持续时间) +80ms(超声波工作一次最大的时间值)
    reg [31:0] count;          //超声波工作阈值计数器
    reg [31:0] echo_cnt;       //超声波发送时间计数器
    reg [31:0] echo_cnt_reg;   //第二排-->确保数据流的准确性

    reg [2:0] current_state,next_state;

    //二进制状态编码-->独热码
    parameter IDLE = 3'b001,
                S1 = 3'b010,
                S2 = 3'b100;
    
    //超声波工作计时模块
    always@(posedge sysclk)
        if(!rst_n)
            count <= 0;
        else if(count <= delay - 1)
            count <= 0;
        else
            count <= count + 1;

    assign trig = (0 <= count <= 15 * 50) ? 1 : 0;
    
    //三段式第一式-->描述总状态的跳转情况
    always@(posedge sysclk)
        if(!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;

    //三段式状态机第二段-->描述各个状态之间跳转
    always@(*)
        if(!rst_n)
            next_state = IDLE;
        else
            case(current_state)
                IDLE:begin
                        if(echo == 1)
                            next_state = S1;
                        else
                            next_state = current_state;
                end
                  S1:begin
                        if(echo == 0)
                            next_state = S2;
                        else
                            next_state = current_state;
                  end
                  S2:next_state = IDLE;
                  default:next_state = IDLE;   //组合逻辑在FPGA中最好写出来，节省FPGA资源
            endcase

    //三段式状态机第三段-->描述各个状下的动作
    always@(posedge sysclk)
        if(!rst_n)
        begin
            echo_cnt <= 0;
            echo_cnt_reg <= 0;
        end
        else
            case(current_state)
                IDLE:
                begin
                    echo_cnt <= 0;
                    echo_cnt_reg <= echo_cnt_reg;
                end
                  S1:
                begin
                    echo_cnt <= echo_cnt + 1;
                    echo_cnt_reg <= echo_cnt_reg;
                end
                  S2:
                begin
                    echo_cnt <= 0;
                    echo_cnt_reg <= echo_cnt;
                end
                default:
                    begin
                    echo_cnt <= 0;
                    echo_cnt_reg <= 0;
                    end
            endcase
        
    assign distance = (echo_cnt_reg * 20) /1000 / 58;
    //

endmodule