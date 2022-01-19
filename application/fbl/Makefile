MOD_NAME = FBL
EXE_NAME = fbl
BIN_NAME = fbl
LIB_NAME =

# Source Directories
PRJDIR  = .
MKDIR   = $(PRJDIR)/../../mk
EXTDIR  = $(PRJDIR)/../../ext
DRVDIR  = $(PRJDIR)/../../driver
SERVDIR = $(PRJDIR)/../../service
CMNDIR  = $(PRJDIR)/../../common
TMPLDIR = $(PRJDIR)/../../doc_templ
UTILDIR = $(PRJDIR)/../../tools

INCDIR  = .
INCDIR += $(CMNDIR)                # bsp.h, reg.h, typedefs.h
INCDIR += $(CMNDIR)/generic        # svc_call.h
INCDIR += $(DRVDIR)/inc            # imxrt.h

ASMDIR  =
LIBDIR  =
LINKDIR = ./link


ifeq ($(PLATFORM), IMXRT)
  MCUDIR = imxrt

  SRCDIR         =
  SRCDIR        += .

  SRC_EXE       += main.c
  SRC_EXE       += cmdl.c
#  SRC_EXE       += noinit.c
#  SRC_EXE       += bmgr.c
#  SRC_EXE       += bcp.c
#  SRC_EXE       += fbl.c


  INCDIR        += $(DRVDIR)/../demo/startup
  SRCDIR        += $(DRVDIR)/../demo/startup
  SRC_EXE       += misc.c

  INCDIR        += $(PRJDIR)/specific # config.h, trace_cfg.h, trace_feature_cfg.h
  SRCDIR        += $(PRJDIR)/specific
  SRC_EXE       += flex_trc.c

  ASMDIR        += $(DRVDIR)/startup
  INCDIR        += $(DRVDIR)/startup
  SRCDIR        += $(DRVDIR)/startup
  SRC_EXE       += flexspi_config_tbl.c
  SRC_EXE       += armv7m_entry.S
  SRC_EXE       += startup.c

  # IVT and HAB helper
  INCDIR        += $(DRVDIR)/fwdesc/imx
  SRCDIR        += $(DRVDIR)/fwdesc/imx
  SRC_EXE       += ivt.c

  INCDIR        += $(DRVDIR)/hab            # hab.h, hab_api.h
  SRCDIR        += $(DRVDIR)/hab
  SRC_EXE       += hab_api.c
  SRC_EXE       += hab_info.c

  INCDIR        += $(SERVDIR)/swinfo
  SRCDIR        += $(SERVDIR)/swinfo
  SRC_EXE       += swinfo.c
  SRC_EXE       += sw_release.c
  SRC_EXE       += img_info.c

  # OCOTP
  INCDIR        += $(DRVDIR)/ocotp
  SRCDIR        += $(DRVDIR)/ocotp
  SRC_EXE       += ocotp.c
  SRC_EXE       += ocotp_info.c

  # DCP
#  INCDIR        += $(DRVDIR)/dcp
#  SRCDIR        += $(DRVDIR)/dcp
#  SRC_EXE       += dcp.c

  # ROM API
  INCDIR        += $(DRVDIR)/rom_api        # rom_api.h
  SRCDIR        += $(DRVDIR)/rom_api
  SRC_EXE       += rom_api.c

  # IO-Mux Driver
  INCDIR        += $(DRVDIR)/iomux/imx
  SRCDIR        += $(DRVDIR)/iomux/imx
  SRC_EXE       += iomux.c

  # Clock Control Module Driver
  INCDIR        += $(DRVDIR)/ccm
  SRCDIR        += $(DRVDIR)/ccm
  SRC_EXE       += ccm.c

  # GPIO Driver
  INCDIR        += $(DRVDIR)/gpio
  INCDIR        += $(DRVDIR)/gpio/specific
  SRCDIR        += $(DRVDIR)/gpio
  SRC_EXE       += gpio.c

  # IRQ Controller Driver
  INCDIR        += $(DRVDIR)/irqc
  SRCDIR        += $(DRVDIR)/irqc
  SRC_EXE       += irqc.c
  SRC_EXE       += arm_nvic.c

  INCDIR        += $(DRVDIR)/inc/arm/armv7m # armv7m_regmap.h
  INCDIR        += $(DRVDIR)/timer/armv7m
  SRCDIR        += $(DRVDIR)/timer/armv7m
  SRC_EXE       += arm_sys_timer.c

  # Ring buffer
  INCDIR        += $(SERVDIR)/rbuf
  SRCDIR        += $(SERVDIR)/rbuf
  SRC_EXE       += rbuf.c

  # UART driver
  INCDIR        += $(DRVDIR)/uart
  SRCDIR        += $(DRVDIR)/uart
  SRC_EXE       += uart.c
  SRC_EXE       += uart_irq.c

  INCDIR        += $(DRVDIR)/uart/imxrt/specific
  SRCDIR        += $(DRVDIR)/uart/imxrt/specific
  SRC_EXE       += uart_ddm.c

  INCDIR        += $(SERVDIR)/trace
  SRCDIR        += $(SERVDIR)/trace
  SRC_EXE       += trace_core.c
  SRC_EXE       += trace_flex.c

  INCDIR        += $(CMNDIR)/generic
  SRCDIR        += $(CMNDIR)/generic
  SRC_EXE       += cpu_asm.S

  INCDIR        += $(CMNDIR)/generic/armv7m
  SRCDIR        += $(CMNDIR)/generic/armv7m
  SRC_EXE       += cpu_irq.c

  # C-lib
  INCDIR        += $(SERVDIR)/libc
  SRCDIR        += $(SERVDIR)/libc
  SRC_EXE       += libc.c

  # Commandline interface
  INCDIR        += $(SERVDIR)/cli
  SRCDIR        += $(SERVDIR)/cli
  SRC_EXE       += cli.c

  SRC_LNK       += fbl.ld.S

  LIBS          +=

  MCU ?= cortex-m4

  TARGET_OS = NONE
  ASM_EXT   = S
  OPTIMIZE  = 1

  CFLAGS   += -c -std=gnu99 -Wall -mthumb -mcpu=cortex-m4
  ASFLAGS  += -std=gnu99 -Wall -mthumb -mcpu=cortex-m4
  CPFLAGS  +=
  LFLAGS   += -Wl,-Map -Wl,$(MAPFILE) -nostdlib -T$(LINK_SCRIPT)

  INCLUDES += 
#  DEFINES  += -DBSP_BOARD_TYPE=BSP_BRD_MIMXRT1060_EVK
  DEFINES  += -DBSP_BOARD_TYPE=BSP_BRD_TEENSY40

endif # PLATFORM is IMXRT
PLATFORMS += IMXRT-map
PLATFORMS += IMXRT-exe
PLATFORMS += IMXRT-bin
PLATFORMS += IMXRT-hex


ifeq "$(PLATFORM)" "" # PLATFORM is not set

help:
	@ echo "Targets:"
	@ echo "all"
	@ echo
	@ echo "map"
	@ echo
	@ echo "Options:"
	@ echo "none"
	@ echo
	@ echo "Parameters:"
	@ echo "PLATFORM=IMXRT"

endif # PLATFORM

include $(MKDIR)/generic.mk
include $(MKDIR)/Makefile.version

SIGN_OPTS  = --image-type=FLS
SIGN_OPTS += --ivt-offs=0x1000                                 # Default IVT offset
SIGN_OPTS += --input-file=__out__/imxrt/fbl.bin                # Input binary image to be signed
SIGN_OPTS += --crc-offs=0x208                                  # Offset at which the CRC is patched
SIGN_OPTS += --srk-idx=0                                       # Super Root Key to use for signing

SIGN_OPTS += --srk-tbl=SRK_table.bin
SIGN_OPTS += --noca-cert=SRK1_sha256_2048_65537_v3_usr_crt.pem
#SIGN_OPTS += --verbose

#SIGN_OPTS += --srk-tbl=imxrt-srk-table.bin
#SIGN_OPTS += --csf-key=imxrt-csf1-cert.pem
#SIGN_OPTS += --img-key=imxrt-img1-cert.pem
#SIGN_OPTS += --imgk-slot=2

CRC_OPTS  = --crc-offs=0x208
CRC_OPTS += --input-file=__out__/imxrt/image_exp.bin
CRC_OPTS += --output-file=__out__/imxrt/image_exp.fbl

HEX_OPTS  += -I binary
HEX_OPTS  += -O ihex
HEX_OPTS  += --set-start 0x60000400
HEX_OPTS  += --change-address 0x60000000
HEX_OPTS  += __out__/imxrt/image_exp.fbl
HEX_OPTS  += __out__/imxrt/image_exp.hex

postlink: bin
	@perl -w $(UTILDIR)/hab-sign/genSignCfg.pl $(SIGN_OPTS)
	@perl -w $(UTILDIR)/patchCrc/patchCrc.pl $(CRC_OPTS)
	@objcopy $(HEX_OPTS)
