
_start:
        li t0,0xFFC
        li t1,0xAAAAAAAA
        li t2,0x55555555
Repeat: sw t1,0(t0)
        nop
        sw t2,0(t0)
        j Repeat
