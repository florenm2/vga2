module vga2practice(CLK_50, VGA_R, VGA_B, VGA_G, VGA_HS, VGA_VS, VGA_SYNC_N, VGA_BLANK_N, VGA_CLK, rst, jump, reset);
	
    output [7:0] VGA_R, VGA_B, VGA_G;
    output VGA_HS, VGA_VS, VGA_BLANK_N, VGA_CLK, VGA_SYNC_N;
    input CLK_50, rst, jump, reset;
    wire CLK108;

    clock108(rst, CLK_50, CLK_108, locked);

    wire hblank, vblank, clkLine, blank;

    H_SYNC(CLK_108, VGA_HS, hblank, clkLine);
    V_SYNC(clkLine, VGA_VS, vblank);
	 // We had to add a reset seperate from the clock reset and jump inputs to color because
	 // because this is where all the animation is at
    color(reset, CLK_108, jump, VGA_R, VGA_B, VGA_G);

    assign VGA_CLK = CLK_108;
    assign VGA_BLANK_N = VGA_VS&VGA_HS;
    assign VGA_SYNC_N = 1'b0;

endmodule 

module color(rst, clk, jump, r, b, g);
   input clk, rst, jump;
   output [7:0] r, b, g;
	reg [7:0] r, b, g;
	reg [31:0] col = 32'd0;
	reg [31:0] row = 32'd0;
	
	// Changes to the lower row if it reaches the end of elements on that row
	always @(posedge clk) begin
		if (row < 1067 && col == 1688) begin
			row <= row + 1;
		end else	if (row < 1067) begin
			row <= row;
		end else
			row <= 0;
	end
	
	// Counts the elements on one row
	always @(posedge clk) begin
		if (col == 1688) begin
			col <= 0;
		end else begin
			col <= col + 1;
		end
	end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// Declaring everything
	reg [1:0] color;
	parameter black = 3'b00;
	parameter white = 3'b01;
	parameter blue = 3'b10;
	parameter red = 3'b11;
	
	reg state;
	parameter play = 1;
	parameter finish = 0;
	
	wire birdx = (col > 80 && col < 121);
	wire bary = ((row > 24 && row < 400) || row > 700);
	wire bary2 = ((row > 24 && row < 500) || row > 800);
	wire bary3 = ((row > 24 && row < 300) || row > 600);
	wire bary4 = ((row > 24 && row < 450) || row > 750);
	wire bary5 = ((row > 24 && row < 500) || row > 800);
	wire bary6 = ((row > 24 && row < 350) || row > 650);
	wire bary7 = ((row > 24 && row < 550) || row > 850);
	reg birdy, barx, barx2, barx3, barx4, barx5, barx6, barx7;
	
	integer i = 512;
	integer j = 553;
	
	integer d = 1231;
	integer e = 1281;
	integer barspeed = -5;
	integer refreshrate = 2900000;
	integer d2, e2, d3, e3, d4, e4, d5, e5, d6, e6, d7, e7, accl, tally;
	
	reg [31:0] boxtimer, bartimer, count4, score, count_between;
	reg [5:0]count_bars;
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// Where we tell colors to move in respect to time or events
	always @(posedge clk) begin
		case (state)  
			play: begin
				if(rst == 1)begin
					i <= 512;
					j <= 553;
					
					d <= 1231;
					e <= 1281;
					
					d2 <= 1231;
					e2 <= 1281;
					
					d3 <= 1231;
					e3 <= 1281;
					
					d4 <= 1231;
					e4 <= 1281;
					
					d5 <= 1231;
					e5 <= 1281;
					
					d6 <= 1231;
					e6 <= 1281;
					
					d7 <= 1231;
					e7 <= 1281;
					
					score <= 0;
					tally <= 0;
					boxtimer <= 0;
					accl <= 0;
					
					bartimer <= 0;
					count4 <= 0;
					count_between <= 100100000;
					count_bars <= 0;
				end
			
				birdy <= (row > i && row < j);
				barx <= (col > d && col < e);
				barx2 <= (col > d2 && col < e2);
				barx3 <= (col > d3 && col < e3);
				barx4 <= (col > d4 && col < e4);
				barx5 <= (col > d5 && col < e5);
				barx6 <= (col > d6 && col < e6);
				barx7 <= (col > d7 && col < e7);
				
				//Where colors are when the game is being played
				if(birdy && birdx) begin
					color <= blue;
				end
				else if(barx && bary) begin
					color <= black;
				end
				else if(barx2 && bary2 && count_bars >= 1) begin
					color <= black;
				end
				else if(barx3 && bary3 && count_bars >= 2) begin
					color <= black;
				end
				else if(barx4 && bary4 && count_bars >= 3) begin
					color <= black;
				end
				else if(barx5 && bary5 && count_bars >= 4) begin
					color <= black;
				end
				else if(barx6 && bary6 && count_bars >= 5) begin
					color <= black;
				end
				else if(barx7 && bary7 && count_bars >= 6) begin
					color <= black;
				end
				else if(row < 25 || row > 1000 || col < 40 || col > 1230) begin
							if((col > 10 && col < (11 + score)) && row > 3 && row < 20) begin 
								color <= red;
								if(score >= 200) begin
									score <= 0;
									tally <= tally + 1;
								end
							end
							else if(col > 224 && col < (225 + tally*7) && row > 3 && row < 20)
								if(col > 224 && col%7 == 0)
									color <= black;
								else
									color <= red;
							else
								color <= black;
				end
				else
					color <= white;
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				
				// Box Physics
				if(boxtimer >= refreshrate) begin
					if(jump)
						accl <= accl + 1;
					else
						accl <= -25;
					i <= i + accl/5;
					j <= j + accl/5;
					boxtimer <= 0;
				end
				else
					boxtimer <= boxtimer + 1;
				
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				
				// Bar movement for each bar and the increasing the score
				if (bartimer >= refreshrate)begin
					score <= score + 1;
					d <= d + barspeed;
					e <= e + barspeed;
					bartimer <= 0;
					if(e < 1) begin
						d <= 1231;
						e <= 1281;
					end
				end
				else begin 
					bartimer <= bartimer + 1;
					if (count4 >= count_between) begin
						count4 <= 0;
						if(count_bars < 6)
						count_bars <= count_bars + 1;
					end
					else
						count4 <= count4 + 1;
				end
				
				if (count_bars >= 1) begin
					if (bartimer >= refreshrate)begin
						d2 <= d2 + barspeed;
						e2 <= e2 + barspeed;
						bartimer <= 0;
						if(e2 < 1) begin
							d2 <= 1231;
							e2 <= 1281;
						end
		
					end
				end
				
				if (count_bars >= 2) begin
					if (bartimer >= refreshrate)begin
						d3 <= d3 + barspeed;
						e3 <= e3 + barspeed;
						bartimer <= 0;
						if(e3 < 1) begin
							d3 <= 1231;
							e3 <= 1281;
						end
		
					end
				end
				
				if (count_bars >= 3) begin
					if (bartimer >= refreshrate)begin
						d4 <= d4 + barspeed;
						e4 <= e4 + barspeed;
						bartimer <= 0;
						if(e4 < 1) begin
							d4 <= 1231;
							e4 <= 1281;
						end
					end
				end
				
				
				if (count_bars >= 4) begin
					if (bartimer >= refreshrate)begin
						d5 <= d5 + barspeed;
						e5 <= e5 + barspeed;
						bartimer <= 0;
						if(e5 < 1) begin
							d5 <= 1231;
							e5 <= 1281;
						end
		
					end
				end
				
				if (count_bars >= 5) begin
					if (bartimer >= refreshrate)begin
						d6 <= d6 + barspeed;
						e6 <= e6 + barspeed;
						bartimer <= 0;
						if(e6 < 1) begin
							d6 <= 1231;
							e6 <= 1281;
						end
		
					end
				end
				
				if (count_bars >= 6) begin
					if (bartimer >= refreshrate)begin
						d7 <= d7 + barspeed;
						e7 <= e7 + barspeed;
						bartimer <= 0;
						if(e7 < 1) begin
							d7 <= 1231;
							e7 <= 1281;
						end
		
					end
				end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
				
				// Game over when you go out of bounds or hit a bar
				if (i < 25 || j > 1000)begin
					state <= finish;
				end
				
				if (d > 40 && d < 121)begin
					if (i < 400 || j > 700) begin
						state <= finish;
					end
				end
				
				if (d2 > 40 && d2 < 121)begin
					if (i < 500 || j > 800) begin
						state <= finish;
					end
				end
				
				if (d3 > 40 && d3 < 121)begin
					if (i < 300 || j > 600) begin
						state <= finish;
					end
				end
					
				if (d4 > 40 && d4 < 121)begin
					if (i < 450 || j > 750) begin
						state <= finish;
					end
				end
					
				if (d5 > 40 && d5 < 121)begin
					if (i < 500 || j > 800) begin
						state <= finish;
					end
				end
					
				if (d6 > 40 && d6 < 121)begin
					if (i < 350 || j > 650) begin
						state <= finish;
					end
				end
					
				if (d7 > 40 && d7 < 121)begin
					if (i < 550 || j > 850) begin
						state <= finish;
					end
				end
			end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
			
			// Game over red screen of death
			finish: 	begin 
				if (rst == 1)begin
					state <= play;
				end
				else if(col > 300 && col < (301 + tally*10) && row > 450 && row < 550) begin
					if(col%10 == 0 || col%10-1 == 0)
						color <= red;
					else
						color <= black;
				end
				else
					color <= red;
			end
		endcase
	end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// This makes colors easy to call
	always @(*) begin
		case(color)
			black: begin
				r = 0;
				b = 0; 
				g = 0;
			end
			white: begin
				r = 255;
				b = 255;
				g = 255;
			end
			blue: begin
				r = 0;
				b = 255; 
				g = 0;
			end 
			red: begin
				r = 255;
				b = 0; 
				g = 0;
			end 
		endcase
	end
endmodule

module H_SYNC(clk, hout, bout, newLine);

    input clk;
    output hout, bout, newLine;

    reg [31:0] count = 32'd0;
    reg hsync, blank, new;

    always @(posedge clk) begin
        if (count <  1688)
            count <= count + 1;
        else 
            count <= 0;
    end 

    always @(*) begin
        if (count == 0)
            new = 1;
        else
            new = 0;
    end 

    always @(*) begin
        if (count > 1279) 
            blank = 1;
        else 
            blank = 0;
    end

    always @(*) begin
        if (count < 1328)
            hsync = 1;
        else if (count > 1327 && count < 1440)
            hsync = 0;
        else    
            hsync = 1;
        end

    assign hout = hsync;
    assign bout = blank;
    assign newLine = new;

endmodule

module V_SYNC(clk, vout, bout);

    input clk;
    output vout, bout;

    reg [31:0] count = 32'd0;
    reg vsync, blank;

    always @(posedge clk) begin
        if (count <  1066)
            count <= count + 1;
        else 
            count <= 0;
    end 

    always @(*) begin
        if (count < 1024) 
            blank = 1;
        else 
            blank = 0;
    end

    always @(*) begin
        if (count < 1025)
            vsync = 1;
        else if (count > 1024 && count < 1028)
            vsync = 0;
        else    
            vsync = 1;
        end

    assign vout = vsync;
    assign bout = blank;

endmodule

// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module clock108 (areset, inclk0, c0, locked);

    input     areset;
    input     inclk0;
    output    c0;
    output    locked;

`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif

tri0      areset;

`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

    wire [0:0] sub_wire2 = 1'h0;
    wire [4:0] sub_wire3;
    wire  sub_wire5;
    wire  sub_wire0 = inclk0;
    wire [1:0] sub_wire1 = {sub_wire2, sub_wire0};
    wire [0:0] sub_wire4 = sub_wire3[0:0];
    wire  c0 = sub_wire4;
    wire  locked = sub_wire5;

altpll  altpll_component (
            .areset (areset),
            .inclk (sub_wire1),
            .clk (sub_wire3),
            .locked (sub_wire5),
            .activeclock (),
            .clkbad (),
            .clkena ({6{1'b1}}),
            .clkloss (),
            .clkswitch (1'b0),
            .configupdate (1'b0),
            .enable0 (),
            .enable1 (),
            .extclk (),
            .extclkena ({4{1'b1}}),
            .fbin (1'b1),
            .fbmimicbidir (),
            .fbout (),
            .fref (),
            .icdrclk (),
            .pfdena (1'b1),
            .phasecounterselect ({4{1'b1}}),
            .phasedone (),
            .phasestep (1'b1),
            .phaseupdown (1'b1),
            .pllena (1'b1),
            .scanaclr (1'b0),
            .scanclk (1'b0),
            .scanclkena (1'b1),
            .scandata (1'b0),
            .scandataout (),
            .scandone (),
            .scanread (1'b0),
            .scanwrite (1'b0),
            .sclkout0 (),
            .sclkout1 (),
            .vcooverrange (),
            .vcounderrange ());
defparam
    altpll_component.bandwidth_type = "AUTO",
    altpll_component.clk0_divide_by = 25,
    altpll_component.clk0_duty_cycle = 50,
    altpll_component.clk0_multiply_by = 54,
    altpll_component.clk0_phase_shift = "0",
    altpll_component.compensate_clock = "CLK0",
    altpll_component.inclk0_input_frequency = 20000,
    altpll_component.intended_device_family = "Cyclone IV E",
    altpll_component.lpm_hint = "CBX_MODULE_PREFIX=clock108",
    altpll_component.lpm_type = "altpll",
    altpll_component.operation_mode = "NORMAL",
    altpll_component.pll_type = "AUTO",
    altpll_component.port_activeclock = "PORT_UNUSED",
    altpll_component.port_areset = "PORT_USED",
    altpll_component.port_clkbad0 = "PORT_UNUSED",
    altpll_component.port_clkbad1 = "PORT_UNUSED",
    altpll_component.port_clkloss = "PORT_UNUSED",
    altpll_component.port_clkswitch = "PORT_UNUSED",
    altpll_component.port_configupdate = "PORT_UNUSED",
    altpll_component.port_fbin = "PORT_UNUSED",
    altpll_component.port_inclk0 = "PORT_USED",
    altpll_component.port_inclk1 = "PORT_UNUSED",
    altpll_component.port_locked = "PORT_USED",
    altpll_component.port_pfdena = "PORT_UNUSED",
    altpll_component.port_phasecounterselect = "PORT_UNUSED",
    altpll_component.port_phasedone = "PORT_UNUSED",
    altpll_component.port_phasestep = "PORT_UNUSED",
    altpll_component.port_phaseupdown = "PORT_UNUSED",
    altpll_component.port_pllena = "PORT_UNUSED",
    altpll_component.port_scanaclr = "PORT_UNUSED",
    altpll_component.port_scanclk = "PORT_UNUSED",
    altpll_component.port_scanclkena = "PORT_UNUSED",
    altpll_component.port_scandata = "PORT_UNUSED",
    altpll_component.port_scandataout = "PORT_UNUSED",
    altpll_component.port_scandone = "PORT_UNUSED",
    altpll_component.port_scanread = "PORT_UNUSED",
    altpll_component.port_scanwrite = "PORT_UNUSED",
    altpll_component.port_clk0 = "PORT_USED",
    altpll_component.port_clk1 = "PORT_UNUSED",
    altpll_component.port_clk2 = "PORT_UNUSED",
    altpll_component.port_clk3 = "PORT_UNUSED",
    altpll_component.port_clk4 = "PORT_UNUSED",
    altpll_component.port_clk5 = "PORT_UNUSED",
    altpll_component.port_clkena0 = "PORT_UNUSED",
    altpll_component.port_clkena1 = "PORT_UNUSED",
    altpll_component.port_clkena2 = "PORT_UNUSED",
    altpll_component.port_clkena3 = "PORT_UNUSED",
    altpll_component.port_clkena4 = "PORT_UNUSED",
    altpll_component.port_clkena5 = "PORT_UNUSED",
    altpll_component.port_extclk0 = "PORT_UNUSED",
    altpll_component.port_extclk1 = "PORT_UNUSED",
    altpll_component.port_extclk2 = "PORT_UNUSED",
    altpll_component.port_extclk3 = "PORT_UNUSED",
    altpll_component.self_reset_on_loss_lock = "OFF",
    altpll_component.width_clock = 5;


endmodule
