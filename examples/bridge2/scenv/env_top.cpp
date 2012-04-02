#include "systemc.h"
#include "systemperl.h"
#include "verilated_vcd_c.h"
#include "SpTraceVcd.h"
#include <unistd.h>
#include "Vbridge_ex2.h"

extern char *optarg;
extern int optind, opterr, optopt;

#define FILENAME_SZ 80

int sc_main(int argc, char *argv[])
{
  bool dumping = false;
  bool memfile = false;
  int index;
  char dumpfile_name[FILENAME_SZ];
  char mem_src_name[FILENAME_SZ];
  VerilatedVcdC *tfp;
	
  sc_clock clk("clk", 8, SC_NS, 0.5);

  sc_signal<bool>       reset;
  sc_signal<bool>	gmii_rx_dv[4];
  sc_signal<bool>	gmii_tx_en[4];
  sc_signal<uint32_t>	gmii_rxd[4];
  sc_signal<uint32_t>	gmii_txd[4];

  while ( (index = getopt(argc, argv, "d:i:k")) != -1) {
    printf ("DEBUG: getopt optind=%d index=%d char=%c\n", optind, index, (char) index);
    if  (index == 'd') {
      strncpy (dumpfile_name, optarg, FILENAME_SZ);
      dumping = true;
      printf ("VCD dump enabled to %s\n", dumpfile_name);
    } else if (index == 'i') {
      strncpy (mem_src_name, optarg, FILENAME_SZ);
      memfile = true;
    }
  }


  Vbridge_ex2 bridge_ex2("bridge_ex2");

  bridge_ex2.clk (clk);
  bridge_ex2.reset (reset);

  bridge_ex2.gmii_rx_clk_0 (clk);
  bridge_ex2.gmii_rx_clk_1 (clk);
  bridge_ex2.gmii_rx_clk_2 (clk);
  bridge_ex2.gmii_rx_clk_3 (clk);

  bridge_ex2.gmii_rx_dv_0 (gmii_rx_dv[0]);
  bridge_ex2.gmii_rx_dv_1 (gmii_rx_dv[1]);
  bridge_ex2.gmii_rx_dv_2 (gmii_rx_dv[2]);
  bridge_ex2.gmii_rx_dv_3 (gmii_rx_dv[3]);

  bridge_ex2.gmii_tx_en_0 (gmii_tx_en[0]);
  bridge_ex2.gmii_tx_en_1 (gmii_tx_en[1]);
  bridge_ex2.gmii_tx_en_2 (gmii_tx_en[2]);
  bridge_ex2.gmii_tx_en_3 (gmii_tx_en[3]);

  bridge_ex2.gmii_txd_0 (gmii_txd[0]);
  bridge_ex2.gmii_txd_1 (gmii_txd[1]);
  bridge_ex2.gmii_txd_2 (gmii_txd[2]);
  bridge_ex2.gmii_txd_3 (gmii_txd[3]);

  bridge_ex2.gmii_rxd_0 (gmii_rxd[0]);
  bridge_ex2.gmii_rxd_1 (gmii_rxd[1]);
  bridge_ex2.gmii_rxd_2 (gmii_rxd[2]);
  bridge_ex2.gmii_rxd_3 (gmii_rxd[3]);
    
  // Start Verilator traces
  if (dumping) {
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    bridge_ex2.trace (tfp, 99);
    tfp->open (dumpfile_name);
  }

  // set reset to 0 before sim start
  reset.write (0);

  sc_start();
  /*
    sc_close_vcd_trace_file (trace_file);
  */
  if (dumping)
    tfp->close();
    
  return 0;
}