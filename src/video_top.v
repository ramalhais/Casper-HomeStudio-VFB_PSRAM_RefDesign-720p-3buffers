// ==============0ooo===================================================0ooo===========
// =  Copyright (C) 2014-2019 Gowin Semiconductor Technology Co.,Ltd.
// =                     All rights reserved.
// ====================================================================================
// 
//  __      __      __
//  \ \    /  \    / /   [File name   ] video_top.v
//   \ \  / /\ \  / /    [Description ] Video demo
//    \ \/ /  \ \/ /     [Timestamp   ] Friday May 26 14:00:30 2019
//     \  /    \  /      [version     ] 1.0.0
//      \/      \/
//
// ==============0ooo===================================================0ooo===========
// Code Revision History :
// ----------------------------------------------------------------------------------
// Ver:    |  Author    | Mod. Date    | Changes Made:
// ----------------------------------------------------------------------------------
// V1.0    | Caojie     | 11/22/19     | Initial version 
// ----------------------------------------------------------------------------------
// ==============0ooo===================================================0ooo===========

//根据IP参数修改
//`define	WR_VIDEO_WIDTH_16
//`define	DEF_WR_VIDEO_WIDTH 16
`define	WR_VIDEO_WIDTH_24
`define	DEF_WR_VIDEO_WIDTH 24
//`define	WR_VIDEO_WIDTH_32
//`define	DEF_WR_VIDEO_WIDTH 32

//`define	RD_VIDEO_WIDTH_16
//`define	DEF_RD_VIDEO_WIDTH 16
`define	RD_VIDEO_WIDTH_24
`define	DEF_RD_VIDEO_WIDTH 24
//`define	RD_VIDEO_WIDTH_32
//`define	DEF_RD_VIDEO_WIDTH 32

//`define	USE_THREE_FRAME_BUFFER

`define	DEF_ADDR_WIDTH 21 
`define	DEF_SRAM_DATA_WIDTH 64

module video_top
(
    input             I_clk           ,   // board clock 27Mhz
    input             I_rst_n         ,   // board reset button
    input             I_run           ,   // active low button so 1 -> run, 0 -> pause
    output     [1:0]  O_led           ,   // board leds: PSRAM calibrated, blink
    
    // PSRAM interface
    output     [1:0]  O_psram_ck      ,   // PSRAM clock(+)
    output     [1:0]  O_psram_ck_n    ,   // PSRAM clock(-)
    inout      [1:0]  IO_psram_rwds   ,
    inout      [15:0] IO_psram_dq     ,
    output     [1:0]  O_psram_reset_n ,   // PSRAM reset
    output     [1:0]  O_psram_cs_n    ,   // PSRAM Chip Select
    
    // HDMI/DVI outputs
    output            O_tmds_clk_p    ,   // HDMI clock(+)
    output            O_tmds_clk_n    ,   // HDMI clock(-)
    output     [2:0]  O_tmds_data_p   ,   // HDMI data(+) {r,g,b}
    output     [2:0]  O_tmds_data_n       // HDMI data(-) {r,g,b}
);

//=========================================================
//SRAM parameters
parameter ADDR_WIDTH          = `DEF_ADDR_WIDTH        ;   // Całkowita pojemność = 2^21*32bit = 64Mbit ??
parameter DATA_WIDTH          = `DEF_SRAM_DATA_WIDTH   ;   // Związany z generowaniem PSRAM IP, ten psram 64Mbit, x32, szerokość bitów danych użytkownika jest stała 64bit
parameter WR_VIDEO_WIDTH      = `DEF_WR_VIDEO_WIDTH    ;  
parameter RD_VIDEO_WIDTH      = `DEF_RD_VIDEO_WIDTH    ;  



//===================================================
// CLOCKS
//===================================================

// ---------------------- PSRAM ---------------------

wire        memory_clk;       // PSRAM base clock    162 MHz
wire        mem_pll_lock  ;   // PSRAM clock stable

Gowin_rPLL gowin_rpll_inst
(
    .clkout(memory_clk    ),  // output memory clock 162 MHz
    .lock  (mem_pll_lock  ),  // output lock memore clock stable
    .clkin (I_clk         )   // input board clock 27 MHz
);


//---------------------- HDMI -------------------------

wire serial_clk;              // HDMI Serial clock 126 MHz (640x480@60Hz)
wire pll_lock;                // HDMI clock stable
wire hdmi_rst_n;              // HDMI reset (active low) 

TMDS_PLL u_tmds_pll
(                               // 640x480    // 1280x720
    .clkin      (I_clk      ),  // input clk - board clock 27 MHz
    .clkout     (serial_clk ),  // 126 MHz    // 371,250 MHz
    .lock       (pll_lock   )   // output lock - clock stable
);
// Reset active when serial clock not ready or reset button pressed
assign hdmi_rst_n = I_rst_n & pll_lock;

//--------------- HDMI pixel/VGA pixel -----------------

wire pix_clk;                   // HDMI/VGA pixel clock 25,2 MHz (640x480@60Hz)

CLKDIV u_clkdiv
(
    .RESETN   (hdmi_rst_n ),    // keep reset until clocks ready
    .HCLKIN   (serial_clk ),    // serial clk  126,0 MHz   371,250 MHz
    .CLKOUT   (pix_clk    ),    // pixel clk    25,2 MHz    74,250 MHz
    .CALIB    (1'b1       )     // calibrate
);
defparam u_clkdiv.DIV_MODE="5";
defparam u_clkdiv.GSREN="false";

//------------------- VDG pixel ----------------------

//===========================================================================
// VDG base Clock
//===========================================================================

wire vdg_pix_clk = I_run ? I_clk : 1'b1;     // VDG Pixel Clock 

reg vdg_pix_clk_r;                // VDG Pixel Clock 

//wire vdg_pix_clk = I_run ? vdg_pix_clk_r : 1'b1;     // VDG Pixel Clock 

always@(posedge pix_clk) 
begin
  vdg_pix_clk_r <= ~vdg_pix_clk_r;
end






//===================================================
// LED blink 
//===================================================
reg  [31:0] run_cnt;
wire        running;

always @(posedge I_clk or negedge I_rst_n) //I_clk
begin
    if(!I_rst_n)
        run_cnt <= 32'd0;
    else if(run_cnt >= 32'd27_000_000)
        run_cnt <= 32'd0;
    else
        run_cnt <= run_cnt + 1'b1;
end

assign  running = (run_cnt < 32'd13_500_000) ? 1'b1 : 1'b0;
assign  O_led[0] = running;









//-------------------
//syn_code
wire                   syn_off0_re;  // ofifo read enable signal
wire                   syn_off0_vs;
wire                   syn_off0_hs;
                       
wire                   off0_syn_de  ;
wire [RD_VIDEO_WIDTH-1:0] off0_syn_data;

//-------------------------------------
//Hyperram
wire        dma_clk  ; 

//-------------------------------------------------
//memory interface
wire                    cmd           ;
wire                    cmd_en        ;
wire [ADDR_WIDTH-1:0]   addr          ;//[ADDR_WIDTH-1:0]
wire [DATA_WIDTH-1:0]   wr_data       ;//[DATA_WIDTH-1:0]
wire [DATA_WIDTH/8-1:0] data_mask     ;
wire                    rd_data_valid ;
wire [DATA_WIDTH-1:0]   rd_data       ;//[DATA_WIDTH-1:0]
wire                    init_calib     ;



assign  O_led[1] = ~init_calib;



//===========================================================================
// TEST PATTERN GENERATOR
//===========================================================================
wire        tp0_vs_in  ;
wire        tp0_hs_in  ;
wire        tp0_de_in ;
wire [ 7:0] tp0_data_r/*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_g/*synthesis syn_keep=1*/;
wire [ 7:0] tp0_data_b/*synthesis syn_keep=1*/;



//===========================================================================
// Test pattern autochanger
// changes pattern 
reg         vs_r;     // edge detection register
reg  [9:0]  cnt_vs;   // frame counter
reg         pattern_done;

always@(posedge vdg_pix_clk)
begin
    vs_r<=tp0_vs_in;
end

always@(posedge vdg_pix_clk or negedge hdmi_rst_n)
begin
    if(!hdmi_rst_n) begin
        cnt_vs<=0;
    end else if(vs_r && !tp0_vs_in) //vs24 falling edge
        cnt_vs<=cnt_vs+1'b1;

end 

always@(posedge vdg_pix_clk or negedge hdmi_rst_n)
begin
    if(!hdmi_rst_n) 
        pattern_done <= 1'b0;
    else if (cnt_vs[8] == 1'b1)
        pattern_done <= 1'b1;
end

//===========================================================================
//testpattern
testpattern testpattern_inst
(
    .I_pxl_clk   (vdg_pix_clk        ),// VDG pixel clock 25.2 / 2 MHz
    .I_rst_n     (hdmi_rst_n         ),//low active 
    
    // mode - display pattern selection
    .I_mode      ({1'b0,cnt_vs[9:8]} ), // 3bit pattern select
    .I_single_r  (8'd0               ), // RGB red for single color
    .I_single_g  (8'd255             ), // RGB green for single color
    .I_single_b  (8'd0               ), // RGB blue for single color


    // generated screen params                            // 720x480   // 640x480   // 800x600   // 1024x768  // 1280x720    
    .I_h_total   (12'd858            ), //hor total time  // 12'd858   // 12'd800   // 16'd1056  // 16'd1344  // 16'd1650  
    .I_h_sync    (12'd62             ), //hor sync time   // 12'd62    // 16'd96    // 16'd128   // 16'd136   // 16'd40    
    .I_h_bporch  (12'd56             ), //hor back porch  // 12'd56    // 16'd48    // 16'd88    // 16'd160   // 16'd220   
    .I_h_res     (12'd720            ), //hor resolution  // 12'd720   // 16'd640   // 16'd800   // 16'd1024  // 16'd1280  
    .I_v_total   (12'd525            ), //ver total time  // 12'd525   // 12'd525   // 16'd628   // 16'd806   // 16'd750    
    .I_v_sync    (12'd6              ), //ver sync time   // 12'd6     // 16'd2     // 16'd4     // 16'd6     // 16'd5     
    .I_v_bporch  (12'd30             ), //ver back porch  // 12'd30    // 16'd33    // 16'd23    // 16'd29    // 16'd20    
    .I_v_res     (12'd480            ), //ver resolution  // 12'd480   // 16'd480   // 16'd600   // 16'd768   // 16'd720    
    .I_hs_pol    (1'b1               ), //HS polarity , 0:negetive ploarity，1：positive polarity
    .I_vs_pol    (1'b1               ), //VS polarity , 0:negetive ploarity，1：positive polarity
    
    // output for generated screen
    .O_de        (tp0_de_in          ),   // display enable 
    .O_hs        (tp0_hs_in          ),   // HSync
    .O_vs        (tp0_vs_in          ),   // VSync
    .O_data_r    (tp0_data_r         ),   // RGB red 8bit data 
    .O_data_g    (tp0_data_g         ),   // RGB green 8bit data 
    .O_data_b    (tp0_data_b         )    // RGB blue 8bit data 
);





//==============================================
// PSRAM Write Channel 0 (from VDG)
//-------------------------
wire                   ch0_vfb_clk_in ;
wire                   ch0_vfb_vs_in  ;
wire                   ch0_vfb_de_in  ;
wire [WR_VIDEO_WIDTH-1:0] ch0_vfb_data_in;


    assign ch0_vfb_clk_in  = vdg_pix_clk;
    assign ch0_vfb_vs_in   = ~tp0_vs_in;  //negative VSync
    assign ch0_vfb_de_in   = tp0_de_in;   //positive display enable

`ifdef WR_VIDEO_WIDTH_16   
    assign ch0_vfb_data_in = {tp0_data_r[7:3],tp0_data_g[7:2],tp0_data_b[7:3]}; // RGB565
`endif

`ifdef WR_VIDEO_WIDTH_24   
    assign ch0_vfb_data_in = {tp0_data_r,tp0_data_g,tp0_data_b}; // RGB888
`endif

`ifdef WR_VIDEO_WIDTH_32   
    assign ch0_vfb_data_in = {8'd0,tp0_data_r,tp0_data_g,tp0_data_b}; // RGB888
`endif


//=====================================================
//PSRAM Controller
VFB_PSRAM_Top VFB_PSRAM_Top_inst
( 
    .I_rst_n            (init_calib       ),  // keep reset until PSRAM calibrated
    .I_dma_clk          (dma_clk          ),  // PSRAM_clock
`ifdef USE_THREE_FRAME_BUFFER 
    .I_wr_halt          (1'd0             ), //1:halt,  0:no halt
    .I_rd_halt          (1'd0             ), //1:halt,  0:no halt
`endif
    
    // VDG video data input  - write via Channel 0       
    .I_vin0_clk         (ch0_vfb_clk_in   ),  // VDG write clock
    .I_vin0_vs_n        (ch0_vfb_vs_in    ),  // VDG Vertical sync
    .I_vin0_de          (ch0_vfb_de_in    ),  // VDG Display enable
    .I_vin0_data        (ch0_vfb_data_in  ),  // VDG RGB data to write
    .O_vin0_fifo_full   (                 ),  // receiving fifo full
    
    // video data output          
    .I_vout0_clk        (pix_clk          ),  // HDMI read clock
    .I_vout0_vs_n       (~syn_off0_vs     ),  // HDMI Vertical sync 
    .I_vout0_de         (syn_off0_re      ),  // synchronizer Read enable
    .O_vout0_den        (off0_syn_de      ),
    .O_vout0_data       (off0_syn_data    ),
    .O_vout0_fifo_empty (                 ),
    
    // PSRAM write request
    .O_cmd              (cmd              ),  // read/write Command
    .O_cmd_en           (cmd_en           ),  // Command and address ready
    .O_addr             (addr             ),  // PSRAM address  [ADDR_WIDTH-1:0]
    .O_wr_data          (wr_data          ),  // Write data [DATA_WIDTH-1:0]
    .O_data_mask        (data_mask        ),  // Write data mask
    .I_rd_data_valid    (rd_data_valid    ),  // Read data valid
    .I_rd_data          (rd_data          ),  // Read data [DATA_WIDTH-1:0]
    .I_init_calib       (init_calib       )   // calibration complete
); 

//================================================
//PSRAM ip

PSRAM_Memory_Interface_HS_Top PSRAM_Memory_Interface_HS_Top_inst
(
    .clk            (vdg_pix_clk    ),  // board clock 27 MHz
    .memory_clk     (memory_clk     ),  // mem clock 162 MHz
    .pll_lock       (mem_pll_lock   ),  // clock stable
    .rst_n          (I_rst_n        ),  // reset button
    
    // PSRAM interface
    .O_psram_ck     (O_psram_ck     ),  // PSRAM clock(+)
    .O_psram_ck_n   (O_psram_ck_n   ),  // PSRAM clock(-)
    .IO_psram_rwds  (IO_psram_rwds  ),
    .IO_psram_dq    (IO_psram_dq    ),
    .O_psram_reset_n(O_psram_reset_n),
    .O_psram_cs_n   (O_psram_cs_n   ),

    .wr_data        (wr_data        ),  // 64bit data to write
    .rd_data        (rd_data        ),  // 64bit data to read
    .rd_data_valid  (rd_data_valid  ),  // read data ready
    .addr           (addr           ),
    .cmd            (cmd            ),
    .cmd_en         (cmd_en         ),
    .clk_out        (dma_clk        ),
    .data_mask      (data_mask      ),
    .init_calib     (init_calib     )
);

//================================================
// Synchronizer (DMA)
// Reads data from PSRAM and push to HDMI module
// 
//================================================
wire out_de;
syn_gen syn_gen_inst
(
    
    .I_pxl_clk   (pix_clk         ),// 27 MHz     // 25,2MHz    //40MHz      //65MHz      //74.25MHz    //148.5
    .I_rst_n     (hdmi_rst_n      ),// 720x480    // 640x480    //800x600    //1024x768   //1280x720    //1920x1080    
    .I_h_total   (16'd858         ),// 16'd858    // 16'd800    // 16'd1056  // 16'd1344  // 16'd1650   // 16'd2200  
    .I_h_sync    (16'd62          ),// 16'd62     // 16'd96     // 16'd128   // 16'd136   // 16'd40     // 16'd44   
    .I_h_bporch  (16'd56          ),// 16'd56     // 16'd48     // 16'd88    // 16'd160   // 16'd220    // 16'd148   
    .I_h_res     (16'd720         ),// 16'd720    // 16'd640    // 16'd800   // 16'd1024  // 16'd1280   // 16'd1920  
    .I_v_total   (16'd525         ),// 16'd525    // 16'd525    // 16'd628   // 16'd806   // 16'd750    // 16'd1125   
    .I_v_sync    (16'd6           ),// 16'd6      // 16'd2      // 16'd4     // 16'd6     // 16'd5      // 16'd5      
    .I_v_bporch  (16'd30          ),// 16'd30     // 16'd33     // 16'd23    // 16'd29    // 16'd20     // 16'd36      
    .I_v_res     (16'd480         ),// 16'd480    // 16'd480    // 16'd600   // 16'd768   // 16'd720    // 16'd1080   
    .I_rd_hres   (16'd720         ),
    .I_rd_vres   (16'd480         ),
    .I_hs_pol    (1'b1            ),//HS polarity , 0:负极性，1：正极性
    .I_vs_pol    (1'b1            ),//VS polarity , 0:负极性，1：正极性
    .O_rden      (syn_off0_re     ),
    .O_de        (out_de          ),   
    .O_hs        (syn_off0_hs     ),
    .O_vs        (syn_off0_vs     )
);


//===============================================================================
// VSync, HSync, Display Enable Pipeline
//===============================================================================
localparam N = 5; //delay N clocks
                          
reg  [N-1:0]  Pout_hs_dn   ;
reg  [N-1:0]  Pout_vs_dn   ;
reg  [N-1:0]  Pout_de_dn   ;

always@(posedge pix_clk or negedge hdmi_rst_n)
begin
    if(!hdmi_rst_n)
        begin                          
            Pout_hs_dn  <= {N{1'b1}};
            Pout_vs_dn  <= {N{1'b1}}; 
            Pout_de_dn  <= {N{1'b0}}; 
        end
    else 
        begin                          
            Pout_hs_dn  <= {Pout_hs_dn[N-2:0],syn_off0_hs};
            Pout_vs_dn  <= {Pout_vs_dn[N-2:0],syn_off0_vs}; 
            Pout_de_dn  <= {Pout_de_dn[N-2:0],out_de}; 
        end
end

//==============================================================================
//TMDS TX(HDMI) multiplex data
wire        rgb_vs     ;
wire        rgb_hs     ;
wire        rgb_de     ;
wire [23:0] rgb_data   ;  


`ifdef RD_VIDEO_WIDTH_16  
    assign rgb_data    = off0_syn_de ? {off0_syn_data[15:11],3'd0,off0_syn_data[10:5],2'd0,off0_syn_data[4:0],3'd0} : 24'hff0000;//{r,g,b}
`endif
`ifdef RD_VIDEO_WIDTH_24  
    assign rgb_data    = off0_syn_de ? off0_syn_data : 24'h0000ff;//{r,g,b}
`endif
`ifdef RD_VIDEO_WIDTH_32  
    assign rgb_data    = off0_syn_de ? off0_syn_data[23:0] : 24'h0000ff;//{r,g,b}
`endif

    assign rgb_vs      = Pout_vs_dn[4];//syn_off0_vs;
    assign rgb_hs      = Pout_hs_dn[4];//syn_off0_hs;
    assign rgb_de      = Pout_de_dn[4];//off0_syn_de;


//====================================================================

DVI_TX_Top DVI_TX_Top_inst
(
    .I_rst_n       (hdmi_rst_n    ),  // asynchronous reset, low active
    .I_serial_clk  (serial_clk    ),  // serial clock (5 x pixel clock)
    .I_rgb_clk     (pix_clk       ),  // pixel clock
    .I_rgb_vs      (rgb_vs        ),  
    .I_rgb_hs      (rgb_hs        ),    
    .I_rgb_de      (rgb_de        ), 
    .I_rgb_r       (rgb_data[23:16]    ),  
    .I_rgb_g       (rgb_data[15: 8]    ),  
    .I_rgb_b       (rgb_data[ 7: 0]    ),  
    .O_tmds_clk_p  (O_tmds_clk_p  ),
    .O_tmds_clk_n  (O_tmds_clk_n  ),
    .O_tmds_data_p (O_tmds_data_p ),  //{r,g,b}
    .O_tmds_data_n (O_tmds_data_n )
);



endmodule
