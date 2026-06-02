module FSM (
    input sysclk,
    input rst_n,
    input echo,       //传感器回传信号   抓取高电平持续时间测距离
    output trig,   //控制端口 -- > FPGA控制传感器  控制条件>10us
    output distance   //测得的距离
);
    
    parameter delay = 50*15+50_000*80   //15us trig(持续时间) +80ms(超声波工作一次最大的时间值)
    reg [31:0] count   //超声波工作阈值计数器
    
    //超声波工作计时模块
    always@(posedge sysclk)
        if(!rst_n)
            count <= 0;
        else if(count <= delay - 1)
            count <= 0;
        else
            count <= count + 1;

    assign trig = (0 <= count <= 15*50) ? 1 : 0;

endmodule