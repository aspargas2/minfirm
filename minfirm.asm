.3ds
.create "min.firm",0
.headersize 0x0 + 0x3B00 ; ITCM, at offset where boot9 loads the firm header
                         ; Use the mirror at 0 so we can do PC-relative bl into the bootrom at 0xFFFFXXXX

payloadsector equ (0x0B400000 / 0x200)
nopslide_addr equ 0x1FFFA000
nopslide_size equ 0x4000
arm11stub_size equ (arm11stub_end - arm11stub)

area0maxsize equ (0x30 + 8) ; reserved + section 0 offset, address
area1maxsize equ (4 + 0x20 + 8) ; section 0 copy method + section 0 hash + section 1 offset, address
area2maxsize equ (4 + 0x20 + 8) ; section 1 copy method + section 1 hash + section 2 offset, address
area3maxsize equ (4 + 0x20 + 8) ; section 2 copy method + section 2 hash + section 3 offset, address
area4maxsize equ (4 + 0x20) ; section 3 copy method + section 3 hash

; Header:
.area 0x10
.ascii "FIRM" ; magic
.word 0 ; boot priority
.word nopslide_addr | 1 ; arm11 entry
.word Entry | 1 ; arm9 entry
.endarea

.orga 0x10
area0:
.area area0maxsize

.thumb
Entry:
    add sp, #0x1FC ; place stack in unused ITCM, saves space over
                   ; using arm-mode code to put it in fcram or whatever

    add r0, =arm11stub
    ldr r1, =(nopslide_addr + nopslide_size)
    mov r2, #arm11stub_size
    blx 0xFFFF03F0 ; memcpy

    ; sdmmc stuff adapted from https://github.com/yellows8/unprotboot9_sdmmc
    ldr r1, =0xfff000b8
    mov r7, #1
    str r7, [r1]

    bl 0xffff1ff8 ; funcptr_boot9init

    bl 0xffff56c8 ; funcptr_mmcinit

    lsl r0, r7, #9
    add r0, #1 ; =0x201
    bl 0xffff5774 ; ub9_initdev

    ldr r2, =(nopslide_addr + nopslide_size)
    add r2, #arm11stub_size
    mov r1, #1
    ldr r0, =payloadsector

    bl 0xffff55f8 ; ub9_readsectors

    ldr r6, =(nopslide_addr + nopslide_size)
    mov r4, #4
    add r6, #(0x40 + arm11stub_size)

firmload_loop:
    ldmia r6!, {r0, r2, r3}
    lsr r0, #9

endarea0:
.endarea

.orga 0x48
.word 0 ; section 0 size

.orga 0x4C
area1:
.area area1maxsize
    lsr r1, r3, #9
    beq firmload_skip
    ldr r3, =payloadsector
    add r0, r3
    bl 0xffff55f8 ; ub9_readsectors

firmload_skip:
    add r6, #0x24
    sub r4, #1
    bne firmload_loop

    ldr r0, =(nopslide_addr + nopslide_size)
    ldr r1, [r0, #(0xC + arm11stub_size)]

    strh r5, [r0] ; overwrite arm11 loop with movs r0, r0
    bx r1 ; jump to arm9 entrypoint

endarea1:
.endarea

.orga 0x78
.word 0 ; section 1 size

.orga 0x7C
area2:
.area area2maxsize

    ; more code can go here

endarea2:
.endarea

.orga 0xA8
.word 0 ; section 2 size

.orga 0xAC
area3:
.area area3maxsize

    ; more code can go here

.pool

endarea3:
.endarea

.orga 0xD8
.word 0 ; section 3 size

.orga 0xDC
area4:
.area area4maxsize

    ; more code can go here

.thumb
.align 4
arm11stub:
    b arm11stub ; This will get overwritten when arm9 is ready for arm11 to continue

    ldr r0, [pc, #0xC] ; FIRM header will get loaded right after the stub, so this loads arm11 entrypoint
                       ; I'd rather not hardcode the offset from PC like this but whatever
    bx r0

.align 4
arm11stub_end:

endarea4:
.endarea

.orga 0x100
.incbin "sig.bin"

.close

area0size equ (endarea0 - area0)
area1size equ (endarea1 - area1)
area2size equ (endarea2 - area2)
area3size equ (endarea3 - area3)
area4size equ (endarea4 - area4)

.notice "Area 0: 0x" + tohex(area0size, 2) + " / 0x" + tohex(area0maxsize, 2) + " bytes used, 0x" + tohex(area0maxsize - area0size, 2) + " bytes free"
.notice "Area 1: 0x" + tohex(area1size, 2) + " / 0x" + tohex(area1maxsize, 2) + " bytes used, 0x" + tohex(area1maxsize - area1size, 2) + " bytes free"
.notice "Area 2: 0x" + tohex(area2size, 2) + " / 0x" + tohex(area2maxsize, 2) + " bytes used, 0x" + tohex(area2maxsize - area2size, 2) + " bytes free"
.notice "Area 3: 0x" + tohex(area3size, 2) + " / 0x" + tohex(area3maxsize, 2) + " bytes used, 0x" + tohex(area3maxsize - area3size, 2) + " bytes free"
.notice "Area 4: 0x" + tohex(area4size, 2) + " / 0x" + tohex(area4maxsize, 2) + " bytes used, 0x" + tohex(area4maxsize - area4size, 2) + " bytes free"
.notice ""
.notice "Total: 0x" + tohex(area0size + area1size + area2size + area3size + area4size, 2) + " / 0x" + tohex(area0maxsize + area1maxsize + area2maxsize + area3maxsize + area4maxsize, 2) + " bytes used"