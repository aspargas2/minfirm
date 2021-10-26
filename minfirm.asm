.3ds
.create "min.firm",0
.headersize 0x01FF8000 + 0x3B00 ; ITCM, at offset where boot9 loads firm header

.area 0x10 ; firm header
.ascii "FIRM" ; magic
.word 0       ; boot priority
.ascii "LMAO" ; arm11 entry, we don't care if arm11 dies so just needs some nonzero 
              ;     for boot9 to be happy
.word Entry   ; arm9 entry
.endarea

.orga 0x10
.area 0x30 + 8 ; reserved + section 0 offset, address
Entry:
    mov sp, #0x27000000
    
    ldr r1, =0xffff01b0
    blx r1 ; funcptr_cleardtcm

    ldr r1, =0xfff000b8
    mov r2, #1
    str r2, [r1]

    ldr r1, =0xffff1ff9
    blx r1 ; funcptr_boot9init()

    ldr r1, =0xffff56c9
    blx r1 ; funcptr_mmcinit();

    ldr r0, =0x201
    ldr r1, =0xffff5775 ; ub9_initdev
    blx r1

    ldr r2, =0x08006000

.endarea

.orga 0x48
.word 0 ; section 0 size

.orga 0x4C
.area 4 + 0x20 + 8 ; section 0 copy method + section 0 hash + section 1 offset, address

    mov r1, #0xFF
    ldr r0, =0x5C000

    ldr r3, =0xffff55f9
    blx r3 ; ub9_readsectors
    blx r3 ; lol (readsectors returns with the address in r3)

.endarea

.orga 0x78
.word 0 ; section 1 size

.orga 0x7C
.area 4 + 0x20 + 8 ; section 1 copy method + section 1 hash + section 2 offset, address
    
    ; more code can go here
    
.endarea

.orga 0xA8
.word 0 ; section 2 size

.orga 0xAC
.area 4 + 0x20 + 8 ; section 2 copy method + section 2 hash + section 3 offset, address

    ; more code can go here
    
.endarea

.orga 0xD8
.word 0 ; section 3 size

.orga 0xDC
.area 4 + 0x20 ; section 3 copy method + section 3 hash
    ; can fit more code here if your pool is small enough, or if you don't use one at all
.pool
.endarea

.orga 0x100
.incbin "sig.bin"

.close