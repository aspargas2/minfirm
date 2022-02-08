# minfirm
The smallest possible bootable FIRM payload for the 3DS. This is a FIRM payload which is only 0x200 bytes large, meaning it consists of only a header and no FIRM sections.

## How to build / use
In general, don't. The only practical use for this is performing the [FIRM partitions known-plaintext](https://www.3dbrew.org/wiki/3DS_System_Flaws#Boot_ROM) exploit while only needing xorpads for one sector in the existing FIRM partitions. Other than that, this was just a fun challenge for me to see how much I could make the FIRM do while keeping the code as small as possible. If you do wish to build this, simply run `armips minfirm.asm` to produce `min.firm`.

## How it works
By setting all the section sizes to 0 in the FIRM section headers, the bootroms will simply not load any sections, ignore the rest of the section headers, and happily jump to the entrypoints for the respective processors. Since boot9 reliably loads the FIRM header of the FIRM it's about to boot to the same address in ITCM every boot and leaves it there after jumping to the entrypoints, I can set the ARM9 entrypoint to that address (or an offset from it, whatever) and the ARM9 will start executing the FIRM header as code. This gives a total of 0xE0 bytes (0x30 from the reserved region, plus 4 * 0x2C from the non-size fields of the section headers, see [here](https://www.3dbrew.org/wiki/FIRM)) to fill with almost totally arbitrary code for the ARM9 to execute.

To get control of the ARM11, I chose to set the ARM11 entrypoint to a NOP slide in AXIWRAM (reliably created every boot by a memset in boot11) and immediately copy a payload to the end of that slide on ARM9 which puts the ARM11 into a spinloop waiting for the ARM9 to tell it what to do next. This is technically a race condition, but from my testing the slide is several times longer than the size it would need to be for ARM9 to have a chance at losing the race. A more proper solution would probably be to make the ARM11 jump to some kind of loop in boot11 which can be broken from ARM9, but I couldn't find such an appropriate loop with some low-effort searching so I went for this.

It should be noted that this is only designed to be booted by Nintendo's bootroms, and would not work from any other loader I know of for many (hopefully obvious) reasons.
