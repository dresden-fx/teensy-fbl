MOD_NAME = 
EXE_NAME = boot
BIN_NAME = boot
LIB_NAME =

# Source Directories
PRJDIR  = ../..
MKDIR   = $(PRJDIR)/../../mk
DRVDIR  = $(PRJDIR)/../../driver
SERVDIR = $(PRJDIR)/../../service
CMNDIR  = $(PRJDIR)/../../common
UTILDIR = $(PRJDIR)/../../tools


INCDIR  = .
INCDIR += ..
INCDIR += $(PRJDIR)
INCDIR += $(CMNDIR)                # bsp.h, reg.h, typedefs.h
INCDIR += $(CMNDIR)/generic        # svc_call.h
INCDIR += $(DRVDIR)/inc            # imxrt.h
INCDIR += $(DRVDIR)/inc/arm/armv7m # armv7m_regmap.h

ASMDIR  = ..
LINKDIR = ./link



ifeq ($(PLATFORM), IMXRT)
  MCUDIR = imxrt

  SRCDIR         =
  SRCDIR        += .
  SRCDIR        += ..

  SRC_EXE       += main.c
  SRC_EXE       += misc.c

  INCDIR        += ../specific      # config.h, trace_cfg.h, trace_feature_cfg.h
  SRCDIR        += ../specific
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

  INCDIR        += $(SERVDIR)/swinfo
  SRCDIR        += $(SERVDIR)/swinfo
  SRC_EXE       += swinfo.c
  SRC_EXE       += sw_release.c
  SRC_EXE       += img_info.c

  INCDIR        += $(DRVDIR)/hab
  SRCDIR        += $(DRVDIR)/hab
  SRC_EXE       += hab_api.c
  SRC_EXE       += hab_info.c

  # OCOTP
  INCDIR        += $(DRVDIR)/ocotp
  SRCDIR        += $(DRVDIR)/ocotp
  SRC_EXE       += ocotp_info.c
  SRC_EXE       += ocotp.c

  INCDIR        += $(DRVDIR)/timer/armv7m
  SRCDIR        += $(DRVDIR)/timer/armv7m
  SRC_EXE       += arm_sys_timer.c

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

  # Ring buffer
  INCDIR        += $(SERVDIR)/rbuf
  SRCDIR        += $(SERVDIR)/rbuf
  SRC_EXE       += rbuf.c

  # C-lib
  INCDIR        += $(SERVDIR)/libc
  SRCDIR        += $(SERVDIR)/libc
  SRC_EXE       += libc.c

  INCDIR        += $(CMNDIR)/generic
  SRCDIR        += $(CMNDIR)/generic
  SRC_EXE       += cpu_asm.S

  INCDIR        += $(CMNDIR)/generic/armv7m
  SRCDIR        += $(CMNDIR)/generic/armv7m
  SRC_EXE       += cpu_irq.c

  SRC_LNK       += flash-boot.ld.S

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
#  DEFINES  += -DBSP_BOARD_TYPE=BSP_BRD_TEENSY40
  DEFINES  += -DBSP_BOARD_TYPE=BSP_BRD_MIMXRT1060_EVK

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
SIGN_OPTS += --input-file=__out__/imxrt/boot.bin               # Input binary image to be signed
SIGN_OPTS += --crc-offs=0x208                                  # Offset at which the CRC is patched
SIGN_OPTS += --srk-idx=0                                       # Super Root Key to use for signing

SIGN_OPTS += --srk-tbl=SRK_table.bin
SIGN_OPTS += --noca-cert=SRK1_sha256_2048_65537_v3_usr_crt.pem
#SIGN_OPTS += --verbose

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
#	@objcopy $(HEX_OPTS)
