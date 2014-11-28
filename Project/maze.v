module maze(input [9:0]x, input[9:0]y, input clk, input reset, input moveup, input movedown, input moveright, output [9:0] red, output [9:0] green, output [9:0] blue, output reg win);



// x1, y1 designate the upperleft corner of the square

reg [9:0] squarex1_reg, squarey1_reg, squarex1_next, squarey1_next;

wire [9:0] squarey2, squarex2, squarex1, squarey1;

localparam SQUARE_SIZE = 15; 

localparam SQUARE_SPEED = 1;   //<------------------------------

wire square_on;

wire collision_on;




wire refr_tick;

assign refr_tick = (y == 481) && (x == 0);




reg [2:0] idx;

assign red = (idx[0]? 10'h3ff: 10'he1);

assign green = (idx[1]? 10'h3ff: 10'h2c2);

assign blue = (idx[2]? 10'h3ff: 10'h37a);




initial 

begin

	squarex1_reg <= 9'd55;

	squarey1_reg <= 9'd55;
	win <= 1'b0;

end




// moving the square, DON'T USE POSEDGE

//always @(negedge moveup or negedge moveright or negedge movedown)

assign squarex1 = squarex1_reg;

assign squarey1 = squarey1_reg;

assign squarex2 = squarex1 + SQUARE_SIZE; 

assign squarey2 = squarey1 + SQUARE_SIZE;

assign square_on = (squarex1 < x) && (squarex2 >= x) && (squarey1 < y) && (squarey2 >= y);

reg [40:0] count;

always @(posedge clk, posedge reset)
if (reset)
begin
squarex1_reg <= 9'd55;
squarey1_reg <= 9'd55;
end
else if (count==41'd50_000_000) //<------------------------------
begin
	if (((squarex1_next >= 46) & ((squarex1_next +SQUARE_SIZE) < 123 )) | ((squarex1_next >= 158) & ((squarex1_next +SQUARE_SIZE) < 236)) | 
	((squarex1_next >= 281) & ((squarex1_next +SQUARE_SIZE) < 358)) | ((squarex1_next >= 426) & ((squarex1_next +SQUARE_SIZE) < 503)))
	begin
	count <= 41'd0;
	 squarex1_reg <= squarex1_next - 15;
	 squarey1_reg <= squarey1_next;
	 end
	 else 
	 begin
	 count <= 41'd0;
	 squarex1_reg <= squarex1_next;
	 squarey1_reg <= squarey1_next + 15;
	 end
end
else
begin
count <= count+1;
squarex1_reg <= squarex1_next;
squarey1_reg <= squarey1_next;
end

always @(*)
begin
squarex1_next = squarex1_reg;
squarey1_next = squarey1_reg;
if (refr_tick)
	if (((squarey1_next <= 47) | ((squarey1_next +SQUARE_SIZE) > 328 )) & (squarex1_next >= 46) & ((squarex1_next +SQUARE_SIZE) < 123 )) 
	begin
	squarex1_next = 55;
	squarey1_next = 55;
	win <= 1'b0;
	end
	else if (((squarex1_next <= 46) | ((squarex1_next < 123) &((squarex1_next +SQUARE_SIZE) > 123 ))) & (squarey1_next >= 47) & ((squarey1_next +SQUARE_SIZE) < 250)) 
	begin
	squarex1_next = 55;
	squarey1_next = 55;
	win <= 1'b0;
	end
	else if (((squarey1_next <= 250) | ((squarey1_next +SQUARE_SIZE) > 328 )) & (squarex1_next >= 123) & ((squarex1_next +SQUARE_SIZE) < 158))
	begin
	squarex1_next = 55;
	squarey1_next = 55;
	win <= 1'b0;
	end
	else if (((squarey1_next <= 250) | ((squarey1_next +SQUARE_SIZE) > 429)) & (squarex1_next >= 158) & ((squarex1_next +SQUARE_SIZE) < 236))
	begin
	squarex1_next = 55;
	squarey1_next = 55;
	win <= 1'b0;
	end
	else if (((squarex1_next +SQUARE_SIZE) > 236) &(squarex1_next < 236) & (squarey1_next >= 250) & ((squarey1_next +SQUARE_SIZE) < 351))
	begin
	squarex1_next = 55;
	squarey1_next = 55;
	win <= 1'b0;
	end
	else if (((squarey1_next <= 351) | ((squarey1_next +SQUARE_SIZE) > 429)) & (squarex1_next >= 236) & ((squarex1_next +SQUARE_SIZE) < 281))
	begin
	squarex1_next = 55;
	squarey1_next = 55;
	win <= 1'b0;
	end
	else if (((squarex1_next +SQUARE_SIZE) > 358) & (squarex1_next < 358) & (squarey1_next >= 159) & ((squarey1_next +SQUARE_SIZE) < 429))
	begin
	squarex1_next = 55;
	squarey1_next = 55;
	win <= 1'b0;
	end
	else if (((squarey1_next <= 81) | ((squarey1_next +SQUARE_SIZE) > 429)) & (squarex1_next >= 281) & ((squarex1_next +SQUARE_SIZE) < 358))
	begin
	squarex1_next = 55;
	squarey1_next = 55;
	win <= 1'b0;
	end
	else if (((squarey1_next <= 81) | ((squarey1_next +SQUARE_SIZE) > 159)) & (squarex1_next >= 358) & ((squarex1_next +SQUARE_SIZE) < 426))
	begin
	squarex1_next = 55;
	squarey1_next = 55;
	win <= 1'b0;
	end
	else if (((squarex1_next +SQUARE_SIZE) > 503) & (squarey1_next >= 81) & ((squarey1_next +SQUARE_SIZE) < 222))
	begin
	squarex1_next = 55;
	squarey1_next = 55;
	win <= 1'b0;
	end
	else if (((squarey1_next <= 81) | ((squarey1_next +SQUARE_SIZE) > 299)) & (squarex1_next >= 426) & ((squarex1_next +SQUARE_SIZE) < 503))
	begin
	squarex1_next = 55;
	squarey1_next = 55;
	win <= 1'b0;
	end
	else if (((squarey1_next <= 222) | ((squarey1_next +SQUARE_SIZE) > 299)) & (squarex1_next >= 503) & ((squarex1_next +SQUARE_SIZE) < 609))
	begin
	squarex1_next = 55;
	squarey1_next = 55;
	win <= 1'b0;
	end
	else if (((squarex1_next +SQUARE_SIZE) > 609) & (squarey1_next >= 222) & ((squarey1_next +SQUARE_SIZE) < 299))
	begin
	win <= 1'b1;
	end
	else if (~moveup)
	begin
		squarey1_next = squarey1_reg - 1;
		win <= 1'b0;
		end
	else if (~movedown)
	begin
		squarey1_next = squarey1_reg + 1;
		win <= 1'b0;
	end
	else if (~moveright)
	begin
		squarex1_next = squarex1_reg + 1;
		win <= 1'b0;
	end
end

// rgb multiplexer

always@(*)
begin
	if (square_on)
		begin
		idx = 5;
		end
	else if ((x < 123) && (x >= 46) & (y >= 47) & (y < 328))
		begin
		idx = 3'd7;
		end
	else if ((x >= 123) && (x < 158) & (y >= 250) & (y < 328))
		begin
		idx = 3'd7;
		end
	else if ((x >= 158) && (x < 236) & (y >= 250) & (y < 429))
		begin
		idx = 3'd7;
		end
	else if ((x >= 236) & (x < 281) & (y < 429) & (y >= 351))
		begin
		idx = 3'd7;
		end
	else if ((x >= 281) & (x < 358) & (y < 429) & (y >= 81))
		begin
		idx = 3'd7;
		end
	else if ((x >= 358) & (x < 426) & (y >= 81) & (y < 159))
		begin
		idx = 3'd7;
		end
	else if ((x >= 426) & (x < 503) & (y >= 81) & (y < 299))
		begin
		idx = 3'd7;
		end
	else if ((x >= 503) & (x < 609) & (y < 299) & (y >= 222))
		begin
		idx = 3'd7;
		end
	else 
		begin
		idx = 0;
		end
end

endmodule
