.section .text.init
.globl _start

_start:
    li sp, 0x2000
    call main

halt:
    j halt
