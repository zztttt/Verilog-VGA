module vga_display (
	input up,
	input reset,
	input clk,
	input sw9,
	input sw8,
	input[3:1] key,
	output HS,
	output VS,
	output reg[7:0] VGA_R,
	output reg[7:0] VGA_G,
	output reg[7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_CLK
);
	//Hcnt, Vcnt for vga
	wire[31:0] Hcnt;
	wire[31:0] Vcnt;
	
	parameter TOP = 0, BOTTOM = 10'd480, LEFT = 0, RIGHT = 10'd640;
	
	parameter battles_num = 10, battles_gap = 10'd50, battle_radius = 10'd20, battles_y = 10'd50;
	reg[31:0] battles_x[battles_num];
	reg[31:0] battles_state;
	
	integer n;

	
	reg[31:0] step;
	reg[31:0] speed;
	
	reg finish;
	
	reg[31:0] ball_x, ball_y;
	parameter ball_radius = 10'd10;
	reg[1:0] direction = 2'b11;
	
	reg[31:0] rec_x, rec_y;
	parameter rec_height = 10'd30, rec_width = 10'd100;

	//activated when 1
	reg x_left_state = 0, x_right_state = 0, y_top_state = 0, y_bottom_state = 0;
	reg dir_state = 0;

	initial
	begin
		for(n = 0; n < battles_num; n = n + 1)
		begin
			battles_x[n] =  10'd100 + n*battles_gap;
		end
		battles_state <= ~(32'b0);
		
		step <= 10'd40;
		speed <= 10'd10;
		direction <= 2'b11;
		
		ball_x <= 10'd100;
		ball_y <= 10'd100;
		
		x_left_state <= 0;
		x_right_state <= 0;
		rec_x <= 10'd201;
		rec_y <= 10'd401;
		//finish
		finish <= 0;
	end
	
	reg clock_slow;
	reg [4:0] c = 2'b0000;
	always @ (posedge clk_200ms)
	begin
		clock_slow = ~clock_slow;
	end
	//rec move
	always@(posedge clk)begin
		if(clk)
		begin
				if(x_left_state && !key[3])
				begin
					//press key[3]
					if(rec_x <= step)begin
						rec_x = LEFT;
					end else
					begin
						rec_x = rec_x - step;
					end
					x_left_state = 0;
				end else if(!x_left_state && key[3])
				begin
					//activate the key[3]
					x_left_state = 1;
				end else if(x_right_state && !key[2])
				begin
					//press key[2]
					if(rec_x + rec_width + step >= RIGHT)begin
						rec_x = RIGHT - rec_width;
					end else
					begin
						rec_x = rec_x + step;
					end
					x_right_state = 0;
				end else if(!x_right_state && key[2])
				begin
					//activate key[2]
					x_right_state = 1;
				end

		end
	end
	
	//ball move
	integer b;
	always @ (posedge clk_200ms)begin
		//crack the Horizontal edge
		if(ball_x >= rec_x && ball_x+ball_radius <= rec_x+rec_width 
			&& ball_y+ball_radius > rec_y && ball_y < rec_y)begin
			//change y
			//ball_y = rec_y - ball_radius - speed;
			direction[0] = ~direction[0];
		end
		//crash the left Vertical edge
		if(ball_y >= rec_y && ball_y+ball_radius <= rec_y+rec_height && ball_x > rec_x && ball_x+ball_radius < rec_x)begin
			//change x
			ball_x = rec_x - ball_radius - speed;
			direction[1] = ~direction[1];
		end
		//crash battle
		for(b = 0; b < battles_num; b = b + 1)
		begin
			if(ball_x+ball_radius > battles_x[b] && ball_x < battles_x[b]+battle_radius
				&& ball_y+ball_radius > battles_y && ball_y < battles_y + battle_radius
				&& battles_state[b])
			begin
				battles_state[b] = 0;
				direction = ~direction;
			end
		end
		case(direction)
			//2'bxy
			2'b10:begin
				//ball_x = (ball_y+speed<RIGHT)?(ball_x + speed) % (RIGHT - ball_radius):ball_x;
				//ball_y = (ball_y>speed)?(ball_y - speed) % (BOTTOM - ball_radius):ball_y;
				if(ball_x + speed <= RIGHT)begin
					ball_x = ball_x + speed;
				end else  begin
					ball_x = RIGHT - speed;
					direction[1] = ~direction[1];
				end
				if(ball_y - speed > 1)begin
					ball_y = ball_y - speed;
				end else begin
					ball_y = TOP + speed;
					direction[0] = ~direction[0];
				end
			end
			2'b00:begin
				if(ball_x - speed > 0)begin
					ball_x = ball_x - speed;
				end else  begin
					ball_x = LEFT + speed;
					direction[1] = ~direction[1];
				end
				if(ball_y - speed > 1)begin
					ball_y = ball_y - speed;
				end else begin
					ball_y = TOP + speed;
					direction[0] = ~direction[0];
				end
			end
			2'b01:begin
				if(ball_x - speed > 0)begin
					ball_x = ball_x - speed;
				end else  begin
					ball_x = LEFT + speed;
					direction[1] = ~direction[1];
				end
				if(ball_y + speed <= BOTTOM)begin
					ball_y = ball_y + speed;
				end else begin
					ball_y = BOTTOM - speed;
					direction[0] = ~direction[0];
				end
			end
			2'b11:begin
				if(ball_x + speed < RIGHT)begin
					ball_x = ball_x + speed;
				end else  begin
					ball_x = RIGHT - speed;
					direction[1] = ~direction[1];
				end
				if(ball_y + speed < BOTTOM)begin
					ball_y = ball_y + speed;
				end else begin
					ball_y = BOTTOM - speed;
					direction[0] = ~direction[0];
				end
			end
			default:begin
				ball_x = (ball_x + speed) % RIGHT;
				ball_y = (ball_y + speed) % BOTTOM;
			end
		endcase
		//change direction
		if(dir_state && !key[1])
		begin
			direction = direction + 1;
			dir_state = 0;
		end else if(!dir_state && key[1])
		begin
			dir_state = 1;
		end
	end

	screen screen_ins(
	.clk(clk_25M),//50MHZ
	.reset(reset),
	.Hcnt(Hcnt),
	.Vcnt(Vcnt),
	.hs(HS),
	.vs(VS),
	.blank(VGA_BLANK_N),
	.vga_clk(VGA_CLK)
	);

	//assign color
	integer i;
	always@(posedge clk_25M)
	begin
		if (finish == 0)
		begin
			//ball
			if(Vcnt > ball_y && Vcnt < ball_y+ball_radius && Hcnt > ball_x && Hcnt < ball_x+ball_radius)
			begin //Vertical is col, Horizon is row
				VGA_R = 255;
				VGA_G = 20;
				VGA_B = 147;
			//rectangle
			end else if(Vcnt > rec_y && Vcnt < rec_y + rec_height && Hcnt > rec_x && Hcnt < rec_x + rec_width)
			begin
				VGA_R = 0;
				VGA_G = 0;
				VGA_B = 139;
			end
			else begin
				//background
				if (Hcnt <= 10'd636 && Vcnt <= 10'd476)
				begin
					VGA_R = 8'd135;
					VGA_G = 8'd206;
					VGA_B = 8'd250;
				end else
				begin
					VGA_R = 8'd221;
					VGA_G = 8'd169;
					VGA_B = 8'd105;
				end
				//battles
				for (i = 0; i < battles_num; i = i + 1)
				begin
					if(Hcnt > battles_x[i] && Hcnt < battles_x[i] + battle_radius
						&& Vcnt > battles_y && Vcnt < battles_y + battle_radius
						&& battles_state[i])
					begin
						VGA_R = 8'd80;
						VGA_G = 8'd255;
						VGA_B = 8'd80;
					end
				end
			end
		end
		//game over
		else
		begin
			VGA_R = 8'd255;
			VGA_G = 8'd128;
			VGA_B = 8'd128;
		end
	end
	
	reg clk_25M;
	//generate a half frequency clock of 25MHz
	always@(posedge(clk))
	begin
		clk_25M <= ~clk_25M;
	end
	
	//generate 200ms clock
	reg[31:0] counter_200ms;
	reg clk_200ms;
	parameter COUNT_200ms = 4999999;
	always@(posedge(clk))
	begin
		if (counter_200ms == COUNT_200ms)
		begin
			counter_200ms = 0;
			clk_200ms = ~clk_200ms;
		end
		else
		begin
			counter_200ms = counter_200ms + 1;
		end
	end
	
	//generate 500ms clock
	reg[31:0] counter_500ms;
	reg clk_500ms;
	parameter COUNT_500ms = 12999999;
	always@(posedge(clk))
	begin
		if (counter_500ms == COUNT_500ms)
		begin
			counter_500ms = 0;
			clk_500ms = ~clk_500ms;
		end
		else
		begin
			counter_500ms = counter_500ms + 1;
		end
	end
endmodule
