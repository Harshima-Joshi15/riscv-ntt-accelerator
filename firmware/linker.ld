ENTRY(_start)

MEMORY
{
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    RAM   (rwx) : ORIGIN = 0x00001000, LENGTH = 4K
}

SECTIONS
{
    .text :
    {
        KEEP(*(.text.init))
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
    } > FLASH

    .data :
    {
        . = ALIGN(4);
        *(.data*)
        . = ALIGN(4);
    } > RAM AT > FLASH

    .bss :
    {
        . = ALIGN(4);
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
    } > RAM

    /DISCARD/ :
    {
        *(.comment*)
        *(.eh_frame*)
        *(.riscv.attributes*)
    }
}
