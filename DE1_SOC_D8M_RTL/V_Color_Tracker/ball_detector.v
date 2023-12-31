// This module looks at the video, selects red pixels, low-pass filters that, and
//   then finds the center of the red object.
// The output is the placement of a marker (+ like symbol) overlaying the camera video.

module ball_detector (
   input reset, 
   input [35:0] iVideo12bRgb,     // Post-de-bayer 12-bit RGB video data from the camera.
   input [19:0] iPixelAddress,    // Raw address of the current pixel. 20 bits, 10 bits for each axis.
   input iVgaHRequest,
   input iVgaVRequest,
   input iVgaClk,
   input iFreezeRam,              // Stop filling the ball_ram RAM with new image data. Freezes the display.
   input iVgaRequest,             // high when VGA is in the active area (not Hsync,Vsync...)
   input iVideoSelect,            // Selects camera video, or ball_ram video image.
   input iFilterOn,               // Turns on evaluation for red pixels
   output reg [23:0] oVideo8bRgb,  // 8-bit RGB output to VGA generator
   input [7:0] iCrLow, 
   input [7:0] iCrHigh, 
   input [7:0] iCbLow,
   input [7:0] iCbHigh, 
   output [15:0] oRedPixelHIndex,   // passes up the value of the number of the horizontal line of the center of the red object.
   output [15:0] oRedPixelVIndex,     // passes up the value of the number of the vertical line of the center of the red object.
   output [15:0] oHIndex,          // passes up the value of the number of the horizontal line of the current pixel.
   output [15:0] oVIndex          // passes up the value of the number of the vertical line of the current pixel.
);

assign oRedPixelHIndex = RedPixelHIndex;
assign oRedPixelVIndex = RedPixelVIndex;
assign oHIndex = hIndex;
assign oVIndex = vIndex;

wire [15:0] RedPixelHIndex;  // row of red middle.
wire [15:0] RedPixelVIndex;  // column of red middle.

wire isPixelRed;
wire [11:0] RED;
wire [11:0] GREEN;
wire [11:0] BLUE;

wire ram_seems_red;   // stored value of isPixelRed in the ball_ram.
wire [15:0] hIndex; // current horizontal pixel location.
wire [15:0] vIndex; // current vertical pixel location.

assign RED = iVideo12bRgb[35:24]; // 12-bit R
assign GREEN = iVideo12bRgb[23:12];
assign BLUE = iVideo12bRgb[11:0];

red_frame u1 ( 
   .iVgaClk( iVgaClk ),
   .reset( reset ),
   .iPixel12bRgb( {RED, GREEN, BLUE} ), 
   .iVgaHRequest( iVgaHRequest ),
   .iVgaVRequest( iVgaVRequest ),
   .iHIndex( hIndex ),
   .iVIndex( vIndex ),
   .oIsPixelRed( isPixelRed ),  // This is the output of red_frame. Low-pass filtered red detection.
   .oRedPixelHIndex( RedPixelHIndex ),
   .oRedPixelVIndex( RedPixelVIndex ),
   .iFilterOn( iFilterOn ),
   .iCrLow( iCrLow ),
   .iCrHigh( iCrHigh ),
   .iCbLow( iCbLow ),
   .iCbHigh( iCbHigh )
);

// Mux. Combinatorial logic to select the camera video, or, the red ball detector video frame.
wire [31:0] radius = 6; // radius of the marker
always @(*) begin
   if( iVideoSelect == 1'b1 ) begin      
      if( (hIndex == RedPixelVIndex) || (vIndex == RedPixelHIndex) ) begin
         oVideo8bRgb = { 8'd0, 8'd0, 8'd255 }; // crosshair on point
      end else if ( (hIndex == 320 || vIndex == 240) ) begin
         oVideo8bRgb = { 8'd255, 8'd0, 8'd0 }; // center of screen
      end else begin
         oVideo8bRgb = { RED[7:0], GREEN[7:0], BLUE[7:0] }; // camera video
      end
   end else begin
      // display a square with radius 3 around the center of the object
      if (hIndex <= RedPixelVIndex + radius && hIndex >= RedPixelVIndex - radius && vIndex <= RedPixelHIndex + radius && vIndex >= RedPixelHIndex - radius) begin // apparently changing this to be vIndex vs RedPixelVIndex causes shitty display
         oVideo8bRgb = { 8'd0, 8'd0, 8'd255 }; // dot on point
      end else if ( ram_seems_red == 1'b1 ) begin
         oVideo8bRgb = { 8'd0, 8'd127, 8'd0 }; // passed filter
      end else begin
         oVideo8bRgb = { 8'd0, 8'd0, 8'd0 }; // failed filter
      end
   end   
end

// Create a two-port RAM (ball_ram)). 1x640x480 bits.
// Input = Camera image, but red-detected and low-pass filtered by red_frame.v.
// Each pixel is 1 or 0, depending on red value.
// Output feeds the VGA waveform generator.
ball_ram this_ball_ram( 
	.clock( iVgaClk ),
	.data( isPixelRed ),
	.rdaddress( iPixelAddress ),
	.rden( iVgaHRequest || iVgaVRequest ),   // is high when VGA generator is in the active area
	.wraddress( iPixelAddress /*>= 1 ? VGA_ADDRESS-1 : VGA_ADDRESS*/ ),   // counters that track the output of the SDRAM
	.wren( iVgaRequest & ~iFreezeRam ),
	.q( ram_seems_red )
);
   
Mod_counter #(.N(10), .M(640)) h_count (
		.clk( iVgaClk ),
		.clk_en( iVgaHRequest  ),
		.reset( ~iVgaHRequest ),
		.max_tick( ),      // output when final count is reached
		.q( hIndex )    // horizontal (column) pixel counter, 0 to 639
);

Mod_counter #(.N(9), .M(480)) v_count (
		.clk( iVgaHRequest ),
		.clk_en( iVgaVRequest ),
		.reset( ~iVgaVRequest ),
		.max_tick( ),      // output when final count is reached
		.q( vIndex )    // vertical (row) pixel counter, 0 to 479
);

Mod_counter #(.N(19), .M(307200)) pixel_count (
		.clk( iVgaClk ),
		.clk_en( iVgaHRequest & iVgaVRequest ),
		.reset( ~iVgaVRequest ),
		.max_tick( ),      // output when final count is reached
		.q()    // counter output [N-1:0]
);

endmodule