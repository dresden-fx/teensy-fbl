#ifndef MAIN_C
#define MAIN_C
#endif /* MAIN_C */

#include "bsp.h"
#include "config.h"
#include "reg.h"
#include "trace_pub.h"
#include "arm_sys_timer.h"

#include "irqc.h"
#include "iomux.h"
#include "gpio.h"
#include "ccm.h"
#include "uart.h"
#include "cpu_irq.h"
#include "misc.h"

#include "hab_api.h"
#include "hab_info.h"
#include "ocotp_info.h"
#include "img_info.h"


/* Pad configuration value for the LED pads */
#define GPIO_O_PAD_CONF 0 \
  | BF_SET(PADCONF_eHYS_DIS, PADCONF_HYS_BF)    \
  | BF_SET(PADCONF_eODE_DIS, PADCONF_ODE_BF)       \
  | BF_SET(PADCONF_ePKE_ENA, PADCONF_PKE_BF)        \
  | BF_SET(PADCONF_ePUE_KEEP, PADCONF_PUE_BF)       \
  | BF_SET(PADCONF_ePUS_PU_100K, PADCONF_PUS_BF)    \
  | BF_SET(PADCONF_eSPEED_100MHZ, PADCONF_SPEED_BF) \
  | BF_SET(PADCONF_eDSE_R0_BY_7, PADCONF_DSE_BF)       \
  | BF_SET(PADCONF_eSRE_SLOW, PADCONF_SRE_BF)

#if (BSP_BOARD_TYPE == BSP_BRD_MIMXRT1060_EVK)

const T_IOMUX_DESC led_muxConf[] =
{
  {
    .padConf = PAD_CNF_DEF(PADCONF_GPIO_AD_B0_09_OFFS, GPIO_O_PAD_CONF),
    .muxConf = MUX_CNF_DEF(MUXCONF_GPIO_AD_B0_09_OFFS, 5, 0),
    .inpConf = INP_CNF_DEF(0, 0),
  },
  {0, 0, 0},
};


T_CCM_CLK_CFG led_clkCfg[] =
{
/*CLK_CNF_DEF(register-offs, bit-field, cfg) */
  CLK_CNF_DEF(CCM_CCGR1_OFFS, GPIO1_CLK_ENA_BF, CCM_CG_eCLK_ON_ALW), /* CG on */
  CLK_CNF_DEF(CCM_CCGR4_OFFS, IOMUXC_GPR_CLK_ENA_BF, CCM_CG_eCLK_ON_ALW), /* CG on */
  CLK_CNF_DEF(CCM_CCGR4_OFFS, IOMUXC_CLK_ENA_BF, CCM_CG_eCLK_ON_ALW), /* CG on */
  CLK_CNF_END(),
};

#elif (BSP_BOARD_TYPE == BSP_BRD_TEENSY40)

const T_IOMUX_DESC led_muxConf[] =
{
  {
    .padConf = PAD_CNF_DEF(PADCONF_GPIO2_IO03__GPIO_B0_03_ALT5_OFFS, GPIO_O_PAD_CONF),
    .muxConf = MUX_CNF_DEF(MUXCONF_GPIO2_IO03__GPIO_B0_03_ALT5_OFFS, 5, 0),
    .inpConf = INP_CNF_DEF(0, 0),
  },
  {0, 0, 0},
};

T_CCM_CLK_CFG led_clkCfg[] =
{
/*CLK_CNF_DEF(register-offs, bit-field, cfg) */
  CLK_CNF_DEF(CCM_CCGR0_OFFS, GPIO2_CLK_ENA_BF, CCM_CG_eCLK_ON_ALW), /* CG on */
  CLK_CNF_DEF(CCM_CCGR4_OFFS, IOMUXC_GPR_CLK_ENA_BF, CCM_CG_eCLK_ON_ALW), /* CG on */
  CLK_CNF_DEF(CCM_CCGR4_OFFS, IOMUXC_CLK_ENA_BF, CCM_CG_eCLK_ON_ALW), /* CG on */
  CLK_CNF_END(),
};

#endif /* BSP_BOARD_TYPE */


void checkHab(void)
{
  if(STATUS_eOK != hab_getStatus())
  {
    TRACE_INFO("ROM-Boot detected HAB failue in image.\n");
  }
  else
  {
    TRACE_INFO("ROM-Boot ok.\n");
  }
  hab_dumpStatus();
}


void cpu_init(void)
{
  cpu_enableIRQs();
  return;
}


int main(void)
{
  irqc_init();
  
  uart_initDev(STD_UART);
  uart_configCtl(STD_UART, &uart_ctlDevCfgTbl[0]);
  
  trace_init();

  cpu_init();
  
  TRACE_INFO("\n\n\n");
  TRACE_INFO("CPU initialized and running from %08X\n", (uint32)(void*)&main);

#if 1
  ldr_dumpLinkerInfo();
#endif

#if 1
  do
  {
    const T_SWINFO* swInfo;
    swInfo = swinfo_getOwnSwInfo();
    imginfo_dumpSwInfo(swInfo);
  }while(0);
#endif

#if 1
  ocotp_dumpUid();
  ocotp_dumpSrkHash();
  ocotp_dumpLockFuses();
  TRACE_INFO("\n");
#endif

#if 1
  boot_dumpBootInfo();
  TRACE_INFO("\n");
#endif
  
#if 1
  do
  {
    const void* ownIvt = hab_getOwnIvtAddr();
    TRACE_INFO("IVT detected at: %08X\n", (uint32_t)ownIvt);
    hab_dumpIvt(ownIvt);
    TRACE_INFO("\n");
  }while(0);
#endif

#if 0
  do
  {
    const void* ownCsf = hab_getOwnCsfAddr();
    TRACE_INFO("CSF detected at: %08X\n", (uint32_t)ownCsf);
    hab_dumpCsf(ownCsf);
    TRACE_INFO("\n");
  }while(0);
#endif

#if 1
  checkHab();
#endif

  arm_initSysTimer(0, (396000000 / 1000) - 1);
  int cnt = 0;
  while(1)
  {
    if(0 != arm_pollSysTimer())
    {
      if(cnt == 250)
      {
        REG32_WR_BASE_OFFS((7<<2), GPIO7_BASE, GPIO_DR_SET_OFFS);
      }
      else if(cnt == 500)
      {
        REG32_WR_BASE_OFFS((7<<2), GPIO7_BASE, GPIO_DR_CLR_OFFS);
        cnt = 0;
      }
      else
      {
      }
      cnt++;
    }
  }
  return 0;
}

int armv7m_main(void) __attribute__((alias("main")));
