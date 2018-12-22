module vga_display(clk, resetn, r, g, b, hs, vs);
	input  clk, resetn;
	output reg[2:0] r, g, b;
	output hs, vs;
	
	//the area which could be display
	parameter UP_BOUND = 31;  
   parameter DOWN_BOUND = 510;  
   parameter LEFT_BOUND = 144;  
   parameter RIGHT_BOUND = 783;  
	
	//rectangle in the center of the screen
	parameter up_pos = 211;  
	parameter down_pos = 330;  
	parameter left_pos = 384;  
	parameter right_pos = 543;  
	
	wire pclk;
	reg [1:0] count;  
	reg [9:0] hcount, vcount;  
	
	 // generate the clock 25MHZ
    assign pclk = count[1];  
    always @ (posedge clk or posedge resetn)  
    begin  
        if (resetn)  
            count <= 0;  
        else  
            count <= count+1;  
    end  
	  // 列计数与行同步  
    assign hs = (hcount < 96) ? 0 : 1;  
    always @ (posedge pclk or posedge resetn)  
    begin  
        if (resetn)  
            hcount <= 0;  
        else if (hcount == 799)  
            hcount <= 0;  
        else  
            hcount <= hcount+1;  
    end 
	  // 行计数与场同步  
    assign vs = (vcount < 2) ? 0 : 1;  
    always @ (posedge pclk or posedge resetn)  
    begin  
        if (resetn)  
            vcount <= 0;  
        else if (hcount == 799) begin  
            if (vcount == 520)  
                vcount <= 0;  
            else  
                vcount <= vcount+1;  
        end  
        else  
            vcount <= vcount;  
    end  
	  // 设置显示信号值  
    always @ (posedge pclk or posedge resetn)  
    begin  
        if (resetn) begin  
            r <= 0;  
            g <= 0;  
            b <= 0;  
        end  
        else if (vcount>=UP_BOUND && vcount<=DOWN_BOUND  
                && hcount>=LEFT_BOUND && hcount<=RIGHT_BOUND) begin  
            if (vcount>=up_pos && vcount<=down_pos  
                    && hcount>=left_pos && hcount<=right_pos) begin  
                r <= 3'b000;  
                g <= 3'b111;  
                b <= 2'b00;  
            end  
            else begin  
                r <= 3'b000;  
                g <= 3'b000;  
                b <= 2'b00;  
            end  
        end  
        else begin  
            r <= 3'b000;  
            g <= 3'b000;  
            b <= 2'b00;  
        end  
    end  
endmodule