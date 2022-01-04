OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_reset)
MAX_HAB_CSF_DATA_SIZE = 0x2000;
MEMORY
{
    ITCM_RAM (rwx): ORIGIN = 0x00000000, LENGTH = 512K
    BOOT_ROM (rx) : ORIGIN = 0x00200000, LENGTH = 128K
    DTCM_RAM (rwx): ORIGIN = 0x20000000, LENGTH = 512K
    ONCHIP_RAM2 (rwx): ORIGIN = 0x20200000, LENGTH = 512K
    HAB_RAM (rwx): ORIGIN = 0x20200000, LENGTH = 7K
    OCRAM (rwx): ORIGIN = 0x20208000, LENGTH = 480K
    ONCHIP_RAM1 (rwx): ORIGIN = 0x20280000, LENGTH = 512K
    FLEX_RAM (rwx): ORIGIN = 0x20280000, LENGTH = 512K
    ONCHIP_RAM3 (rwx): ORIGIN = 0x20300000, LENGTH = 512K
    M7SW_CODE (rwx): ORIGIN = 0x20300000, LENGTH = 32K
    M7SW_DATA (rwx): ORIGIN = 0x20308000, LENGTH = 32K
    M7SW_STACK (rwx): ORIGIN = 0x20316000, LENGTH = 8K
    CRASH_STACK (rwx): ORIGIN = 0x20318000, LENGTH = 8K
    M7SW_HEAP_STACK (rw) : ORIGIN = 0x2001C000, LENGTH = 128K
    EXT_FLASH (rwx): ORIGIN = 0x60000000, LENGTH = 1984K
    FBL_CODE (rwx): ORIGIN = 0x60000000, LENGTH = 64K
    APP_CODE (rwx): ORIGIN = 0x60010000, LENGTH = 1920K
}
_Min_Heap_Size = 0x800;
_Min_Stack_Size = 0x400;
SECTIONS
{
  . = 0;
  __image_start = ORIGIN(EXT_FLASH);
  .flash_cfg :
  {
    KEEP(*(.flash_cfg))
    FILL(0xFF)
    . = ALIGN(0x200);
  } > EXT_FLASH
  __fls_cfg_start = (SIZEOF(.flash_cfg) > 0) ? (ADDR(.flash_cfg)) : 0;
  __fls_cfg_end = (SIZEOF(.flash_cfg) > 0) ? (ADDR(.flash_cfg) + SIZEOF(.flash_cfg) - 1) : 0;
  .text.sw_info :
  {
    __sw_info_start = .;
    KEEP(*(.sw_info))
    KEEP(*(.sw_rel_info))
    __sw_info_end = .;
  } > EXT_FLASH
  .text.boot :
  {
    . = ALIGN(4);
    __boot_start = .;
    . = ALIGN(0x400);
    *(.armv7m_vect)
    *(.m7start)
    *(.armboot)
    *(.exit)
    *init*.o(.text)
    __boot_end = .;
    . = ALIGN(0x1000);
  } > EXT_FLASH
  PROVIDE(__boot_load = LOADADDR(.text.boot));
  .text.ivt :
  {
    __ivt_start = .;
    KEEP(*(.ivt))
    __ivt_end = .;
    __boot_data_start = .;
    KEEP(*(.boot_data))
    __boot_data_end = .;
  } > EXT_FLASH
  PROVIDE(__ivt_load = LOADADDR(.text.ivt));
  .text.dcd :
  {
    KEEP(*(.dcd))
  } > EXT_FLASH
  __dcd_start = (SIZEOF(.text.dcd) > 0) ? (ADDR(.text.dcd)) : 0;
  __dcd_end = (SIZEOF(.text.dcd) > 0) ? (ADDR(.text.dcd) + SIZEOF(.text.dcd) - 1) : 0;
  .text.progmem :
  {
    . = ALIGN(4);
    __text_start = .;
    __text_exec = .;
    *(.text*)
    *(.note.gnu.build-id)
    *(.gnu.linkonce.t.*)
    *(.glue_7t)
    *(.glue_7)
    *(.vfp11_veneer)
    *(.eh_frame)
    KEEP (*(.init))
    KEEP (*(.fini))
    *(.gcc_except_table)
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    PROVIDE_HIDDEN (__fini_array_end = .);
    . = ALIGN(4);
    PROVIDE(__ctors_start__ = .);
    KEEP(*(SORT(.ctors.*)))
    KEEP(*(.ctors))
    PROVIDE(__ctors_end__ = .);
    PROVIDE(__dtors_start__ = .);
    KEEP(*(SORT(.dtors.*)))
    KEEP(*(.dtors))
    PROVIDE(__dtors_end__ = .);
    . = ALIGN(4);
    *(.rodata)
    *(.rodata*)
    *(.gnu.linkonce.r.*)
    . = ALIGN(4);
    *(.ARM.extab*)
    *(.gnu.linkonce.armextab.*)
    __exidx_start = .;
    *(.ARM.exidx*)
    . = ALIGN(4);
    __text_end = .;
  } > OCRAM AT > EXT_FLASH
  PROVIDE(__text_load = LOADADDR(.text.progmem));
  .data : ALIGN(4)
  {
    . = ALIGN(4);
    __data_start = .;
    __data_exec = .;
    *(.data)
    *(.data*)
    *(.gnu.linkonce.d.*)
    SORT(CONSTRUCTORS)
    . = ALIGN(4);
    *(.fastrun .fastrun.*)
    *(.ramCode .ramCode.*)
    . = ALIGN(4);
    __data_end = .;
  } > OCRAM AT > EXT_FLASH = 0x5A
  PROVIDE(__data_load = LOADADDR(.data));
  .text.pad :
  {
    __pad_start = .;
    BYTE(0xA5)
    FILL(0x5A)
    . = ALIGN(0x1000);
    __pad_end = .;
  } > EXT_FLASH
  __image_size = SIZEOF(.text.boot) + SIZEOF(.text.ivt) + SIZEOF(.text.progmem) + SIZEOF(.data) + SIZEOF(.text.pad) + MAX_HAB_CSF_DATA_SIZE;
  .bss (NOLOAD) : ALIGN(0x100)
  {
    __bss_start = .;
    *(.bss)
    *(.bss*)
    *(.gnu.linkonce.b.*)
    *(COMMON)
    . = ALIGN(4);
    __bss_end = .;
  } > OCRAM
  .csf (NOLOAD) : ALIGN(0x400)
  {
    *(.csf)
  } > EXT_FLASH
  __csf_start = ADDR(.csf);
  __csf_end = ADDR(.csf) + MAX_HAB_CSF_DATA_SIZE;
  PROVIDE(__bss_exec = ADDR(.bss));
  .heap (NOLOAD) :
  {
    . = ALIGN(8);
    PROVIDE ( end = . );
    PROVIDE ( _end = . );
    *(.heap)
    . += _Min_Heap_Size;
    . = ALIGN(8);
    __heap_end__ = .;
  } > OCRAM
  .stack (NOLOAD) :
  {
    . = ALIGN(8);
    __stack_start = .;
    __stack_start__ = .;
    *(.stack)
    . = ALIGN(8);
    . += _Min_Stack_Size;
    __stack_end = .;
    . = ALIGN(8);
  } > OCRAM
  .crash.stack (NOLOAD) :
  {
    __crash_stack_start = .;
    *(.crash.stack)
    __crash_stack_end = .;
  } > CRASH_STACK
  /DISCARD/ :
  {
    libc.a ( * )
    libm.a ( * )
    libgcc.a ( * )
  }
  .ARM.attributes 0 : { *(.ARM.attributes) }
}
