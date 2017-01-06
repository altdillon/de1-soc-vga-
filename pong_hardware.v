
module pong_hardware(
	input [9:0] SW,
	input [3:0] KEY,
	input CLOCK_50,
	output [9:0] LEDR,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output VGA_HS,
	output VGA_VS,
	output [7:0] VGA_R,
	output [7:0] VGA_G,
	output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_SYNC_N,
	output VGA_CLK
);
	wire clk;
	clockdivider div(CLOCK_50,clk);
	
	wire up,down,left,right; // wires for directions
	wire [9:0] posY,posX; // busses for position
	
	// edge detectors for inputs
	edgeDetector key_up(.clk(clk),.signalIn(KEY[0]),.sigout(up));
	edgeDetector key_down(.clk(clk),.signalIn(KEY[1]),.sigout(down));
	edgeDetector key_left(.clk(clk),.signalIn(KEY[2]),.sigout(left));
	edgeDetector key_right(.clk(clk),.signalIn(KEY[3]),.sigout(right));
	
	// counter for up,down,left,right
	counter vy(.clk(clk),.dec(up),.inc(down),.count(posY),.speed(SW[7:0]));
	counter vx(.clk(clk),.dec(left),.inc(right),.count(posX),.speed(SW[7:0]));
	
	// graphics
	assign VGA_CLK=clk;
	assign VGA_BLANK_N=1'b1;
	assign VGA_SYNC_N=1'b1;
	wire isdisplay;
	wire [9:0] drawX,drawY;
	vga_synch synchGen(.vga_HS(VGA_HS),.vga_VS(VGA_VS),.X(drawX),.Y(drawY),.clk(clk),.display(isdisplay));
	
	// registers for colors
	reg [7:0] red,blue,green;
	assign VGA_R=red;
	assign VGA_B=blue;
	assign VGA_G=green;
	
	//sizeX and sizeY for block
	reg [5:0] sizeX=20;
	reg [5:0] sizeY=20;
	
	always @(posedge clk) begin
		if(isdisplay) begin
			if(drawX > posX && drawX < posX + sizeX && drawY > posY && drawY < posY + sizeY) begin
				red <= 8'hff;
				blue <= 8'h00;
				green <= 8'h00;
			end else begin
				red <= 8'h00;
				blue <= 8'h00;
				green <= 8'h00;
			end
		end else begin
			red <= 8'h00;
			blue <= 8'h00;
			green <= 8'h00;
		end
	end
	
endmodule

module edgeDetector(
	input clk,
	input signalIn,
	output sigout
);
//	wire dff_out;
//	lab_DFF holdflag(.clock(clk),.data(signalIn),.Q(dff_out),.reset(1'b0),.preset(1'b0));
//	assign sigout=~dff_out&signalIn;
	
	reg flag;
	assign sigout=~signalIn&flag;
	
	always @(posedge clk) begin
		flag <= signalIn;
	end
	
endmodule

module counter(
	input clk,
	input dec,
	input inc,
	input [7:0] speed,
	output reg [9:0] count
);

	wire triger=dec|inc;

	always @(posedge clk) begin
		if(inc) begin
			count <= count + speed;
		end else if(dec) begin
			count <= count - speed;
		end
	end

endmodule

module clockdivider(
	input clk_in,
	output clk_out
);

	reg dat;
	assign clk_out=dat;
	
	always @(posedge clk_in) begin
		dat <= ~dat;
	end

endmodule


module vga_synch(
	output reg vga_HS,
	output reg vga_VS,
	output reg [9:0] X,
	output reg [9:0] Y,
	output reg display,
	output  [9:0] counterX,
	output  [9:0] counterY,
	input clk
);

	// parameter is the same word as const
   // horizontal values 
	parameter hz_color_scan=640;
	parameter hz_frount_porch=16;
	parameter hz_synch_pulse=96;
	parameter hz_back_porch=48;
	parameter hz_scan_width=800;
	
	// verticle lines 
	parameter ve_color_scan=480;
	parameter ve_frount_porch=10;
	parameter ve_synch_pulse=2;
	parameter ve_back_porch=33;
	parameter ve_scan_height=525;
	
	// registers for holding the vga cordents of the screen we're currently wring to
	reg [9:0] posVe,posHz;
	assign counterX=posHz;
	assign counterY=posVe;
	

	// generate the horizontal and verticle synch signals
	always @(posedge clk) begin
		if(posHz < hz_scan_width) begin
			posHz <= posHz + 1;
		end else begin // we've reached the end of a verticle scan line
			posHz <= 0;
			
			if(posVe < ve_scan_height) begin
				posVe <= posVe + 1;
			end else begin
				posVe <= 0;
			end
			
		end
		
		// generate the vs and hs signals
	
		// horizontal pulse 
		if(posHz > hz_frount_porch && posHz < (hz_frount_porch+hz_synch_pulse)) begin
			vga_HS <= 1'b0;
		end else begin
			vga_HS <= 1'b1;
		end
		
		// verticle pulse 
		if(posVe > ve_frount_porch && posVe < (ve_frount_porch+ve_synch_pulse)) begin
			vga_VS <= 1'b0;
		end else begin
			vga_VS <= 1'b1;
		end
		
		// set display to true when we're in the color scan region of the horizontal pulse 
		if((posHz > (hz_frount_porch + hz_synch_pulse + hz_back_porch))) begin //&& (posVe > (ve_frount_porch + ve_synch_pulse + ve_back_porch))) begin
				display <= 1'b1;
				X <= posHz - (hz_frount_porch + hz_synch_pulse + hz_back_porch -1);
				Y <= posVe - (ve_frount_porch + ve_synch_pulse + ve_back_porch -1);
			
		end else begin
				display <= 1'b0;
				X <= 0;
				Y <= 0;
		end
		
	end
	
endmodule
