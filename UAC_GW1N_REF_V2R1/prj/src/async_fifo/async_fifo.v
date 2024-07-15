//
// File name          :async_fifo.v
// Module name        :async_fifo.v
// Created by         :GoWin Semi
// Author             :(Winson)
// Created On         :2020-09-07 09:25 GuangZhou
// Last Modified      :
// Update Count       :2020-09-07 09:25
// Description        :
//                     
//                     
//----------------------------------------------------------------------

module async_fifo #(
      parameter             DSIZE = 32,
      parameter             ASIZE = 6,
      parameter             AEMPT = 1,
      parameter             AFULL = 32
)(
      output reg [DSIZE-1:0]   Q,
      output reg               Full,
      output reg               Empty,
      output reg               AlmostEmpty,
      output reg               AlmostFull,
      output reg [ASIZE:0]   RdDataNum,
      output reg [ASIZE:0]   WrDataNum,
      input   [DSIZE-1:0]   Data,
      input                 WrEn,
      input                 WrClock,
      input                 WPReset,
      input                 RdEn,
      input                 RdClock,
      input                 RPReset
      );

      reg       [ASIZE:0]   wptr;
      reg       [ASIZE:0]   rptr; 
      reg       [ASIZE:0]   wq2_rptr;
      reg       [ASIZE:0]   rq2_wptr; 
      reg       [ASIZE:0]   wq1_rptr;
      reg       [ASIZE:0]   rq1_wptr;
      reg       [ASIZE:0]   rbin;
      reg       [ASIZE:0]   wbin;

      reg       [DSIZE-1:0] mem[0:(1<<ASIZE)-1];

      wire      [ASIZE-1:0] waddr;
      wire      [ASIZE-1:0] raddr;
      wire      [ASIZE:0]   rgraynext;
      wire      [ASIZE:0]   rbinnext;
      wire      [ASIZE:0]   wgraynext;
      wire      [ASIZE:0]   wbinnext;
      wire                  rempty_val;
      wire                  wfull_val;
      wire      [ASIZE:0]   wcount_r;
      wire      [ASIZE:0]   rcnt_sub;
      wire      [ASIZE:0]   rcount_w;
      wire      [ASIZE:0]   wcnt_sub;    

      always@(posedge RdClock, posedge RPReset)
      begin
          //if (RPReset) begin
          //    Q <= 0;
          //end
          //else if (RdEn) begin
          //    Q <= mem[raddr];
          //end
          if (RPReset) begin
              Q <= 0;
          end
          else begin
              Q <= mem[raddr];
          end    
      end

      always@(posedge WrClock)
      begin
        if(WrEn && !Full)
          mem[waddr] <= Data;
      end

      always @(posedge WrClock or posedge WPReset)
      begin
        if (WPReset)
          {wq2_rptr,wq1_rptr} <= 0;
        else
          {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};
      end

      always @(posedge RdClock or posedge RPReset)
      begin
        if (RPReset)
          {rq2_wptr,rq1_wptr} <= 0;
        else
          {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};
      end

      always @(posedge RdClock or posedge RPReset)
      begin
        if (RPReset)
          {rbin, rptr} <= 0;
        else
          {rbin, rptr} <= {rbinnext, rgraynext};
      end

      assign raddr      = rbin[ASIZE-1:0];
      assign rbinnext   = rbin + (RdEn & ~Empty);
      assign rgraynext  = (rbinnext>>1) ^ rbinnext;
      assign rempty_val = (rgraynext == rq2_wptr);

      assign wcount_r   = gry2bin(rq2_wptr);
      assign rcnt_sub   = {(wcount_r[ASIZE] ^ rbinnext[ASIZE]), wcount_r[ASIZE-1:0]} - {1'b0, rbinnext[ASIZE-1:0]};
      assign arempty_val= rcnt_sub <= AEMPT;

      always @(posedge RdClock or posedge RPReset)
      begin
        if (RPReset)
            RdDataNum <= 0;
        else
            RdDataNum <= rcnt_sub;
      end
      always @(posedge RdClock or posedge RPReset)
      begin
      if (RPReset)
        Empty <= 1'b1;
      else
        Empty <= rempty_val;
      end

      always @(posedge RdClock or posedge RPReset)
      begin
      if (RPReset)
        AlmostEmpty <= 1'b1;
      else
        AlmostEmpty <= arempty_val;
      end
 
      always @(posedge WrClock or posedge WPReset)
      begin
        if (WPReset)
          {wbin, wptr} <= 0;
        else
          {wbin, wptr} <= {wbinnext, wgraynext};
      end
   
      assign waddr      = wbin[ASIZE-1:0];
      assign wbinnext   = wbin + (WrEn & ~Full);
      assign wgraynext  = (wbinnext>>1) ^ wbinnext;
      assign wfull_val  = (wgraynext == {~wq2_rptr[ASIZE:ASIZE-1],
                                          wq2_rptr[ASIZE-2:0]});
  
      assign rcount_w   = gry2bin(wq2_rptr);
      assign wcnt_sub   = {(rcount_w[ASIZE] ^ wbinnext[ASIZE]), wbinnext[ASIZE-1:0]} - {1'b0, rcount_w[ASIZE-1:0]};
      assign awfull_val = wcnt_sub >= AFULL;

      always @(posedge WrClock or posedge WPReset)
      begin
        if (WPReset)
            WrDataNum <= 0;
        else
            WrDataNum <= wcnt_sub;
      end
      always @(posedge WrClock or posedge WPReset)
      begin
        if (WPReset)
          Full <= 1'b0;
        else
          Full <= wfull_val;
      end

      always @(posedge WrClock or posedge WPReset)
      begin
        if (WPReset)
          AlmostFull <= 1'b0;
        else
          AlmostFull <= awfull_val;
      end

      function [ASIZE:0]gry2bin;
        input [ASIZE:0] gry_code;
        integer         i;
        begin
          gry2bin[ASIZE]=gry_code[ASIZE];    
          for(i=ASIZE-1;i>=0;i=i-1)        
            gry2bin[i]=gry2bin[i+1]^gry_code[i];
        end
      endfunction

endmodule
