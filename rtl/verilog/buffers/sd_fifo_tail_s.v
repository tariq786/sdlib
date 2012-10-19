//----------------------------------------------------------------------
// Srdy/Drdy FIFO Head "S"
//
// Building block for FIFOs.  The "S" (small/sync) FIFO is design for smaller
// FIFOs based around memories or flops, with sizes that are a power of 2.
//
// The "S" FIFO can be used as a two-clock asynchronous FIFO.
//
// Parameters:
//   depth : depth/size of FIFO, in words
//   asz   : address size, automatically computed from depth
//   async : 1 for clock-synchronization FIFO, 0 for normal
//
// Naming convention: c = consumer, p = producer, i = internal interface
//----------------------------------------------------------------------
// Author: Guy Hutchison
//
// This block is uncopyrighted and released into the public domain.
//----------------------------------------------------------------------

// Clocking statement for synchronous blocks.  Default is for
// posedge clocking and positive async reset
`ifndef SDLIB_CLOCKING 
 `define SDLIB_CLOCKING posedge clk or posedge reset
`endif

// delay unit for nonblocking assigns, default is to #1
`ifndef SDLIB_DELAY 
 `define SDLIB_DELAY #1 
`endif

module sd_fifo_tail_s
  #(parameter depth=16,
    parameter async=0,
    parameter asz=$clog2(depth)
    )
    (
     input              clk,
     input              clken,
     input              reset,

     input [asz:0]      wrptr_head,
     output reg [asz:0] rdptr_tail,

     output reg         rd_en,
     output [asz-1:0]   rd_addr,

     output reg         p_srdy,
     input              p_drdy,
     
     output reg [asz:0] p_usage
     );

  reg [asz:0]           rdptr;
  reg [asz:0]           nxt_rdptr;
  reg [asz:0]           rdptr_p1;
  reg                   empty;
  reg                   nxt_p_srdy;
  wire [asz:0]          wrptr;

  assign rd_addr = nxt_rdptr[asz-1:0];

  always @*
    begin
      rdptr_p1 = rdptr + 1;
      
      empty = (wrptr == rdptr);

      if (p_drdy & p_srdy)
        nxt_rdptr = rdptr_p1;
      else
        nxt_rdptr = rdptr;
          
      nxt_p_srdy = (wrptr != nxt_rdptr);
      rd_en = clken & nxt_p_srdy & ~(p_srdy & ~p_drdy);
      
      if (wrptr[asz] == rdptr[asz])
        p_usage = wrptr - rdptr;
      else
        p_usage = (wrptr[asz-1:0] + depth) - rdptr[asz-1:0];
    end
      
  always @(`SDLIB_CLOCKING)
    begin
      if (reset)
        begin
          p_srdy  <= `SDLIB_DELAY 0;
        end
      else if (clken)
        begin
          p_srdy <= `SDLIB_DELAY nxt_p_srdy;
        end // else: !if(reset)
    end // always @ (posedge clk)

  generate if (async == 0)
    begin : sync_rptr                     
      always @(`SDLIB_CLOCKING)
        begin
          if (reset)
            rdptr <= `SDLIB_DELAY 0;
          else if (clken)
            rdptr <= `SDLIB_DELAY nxt_rdptr;
        end // always @ (posedge clk)

      always @*
        rdptr_tail = rdptr;
    end // block: sync_wptr
  else
    begin : async_rptr
      always @(`SDLIB_CLOCKING)
        begin
          if (reset)
            rdptr_tail <= `SDLIB_DELAY 0;
          else if (clken)
            rdptr_tail <= `SDLIB_DELAY bin2grey (nxt_rdptr);
        end

      always @*
        rdptr = grey2bin(rdptr_tail);
    end
  endgenerate

  function [asz:0] bin2grey;
    input [asz:0] bin_in;
    integer       b;
    begin
      bin2grey[asz] = bin_in[asz];
      for (b=0; b<asz; b=b+1)
        bin2grey[b] = bin_in[b] ^ bin_in[b+1];
    end
  endfunction // for

  function [asz:0] grey2bin;
    input [asz:0] grey_in;
    integer       b;
    begin
      grey2bin[asz] = grey_in[asz];
      for (b=asz-1; b>=0; b=b-1)
        grey2bin[b] = grey_in[b] ^ grey2bin[b+1];
    end
  endfunction

  //assign rdptr_tail = (async) ? bin2grey(rdptr) : rdptr;
  assign wrptr = (async)? grey2bin(wrptr_head) : wrptr_head;
  
endmodule // sd_fifo_head_s
