.text
.global _start

_start:                             
             // Initialization
             ldr     r8, =0xFF200020       // base address of hex3-hex0
             ldr     r9, =0xFF20005C       // address of edge-capture register
             ldr     r10, =0xFFFEC600      // base address of A9 Private Timer
             mov     r5, #0                // DD counter (Hundredths, 0-99)
             mov     r7, #0                // SS counter (Seconds, 0-59)
             mov     r6, #0                // state flag (0 = paused initially, 1 = running)
             // Clear edge-capture register initially
             mov     r0, #0
             str     r0, [r9]
             // Configure timer
             ldr     r0, =2000000          // 200MHz * 0.01s = 2000000 ticks
             str     r0, [r10]             // write to load register
             mov     r0, #2                // control bits: A=1 (auto-reload), E=0 (disabled)
             str     r0, [r10, #8]         // write to control register

             bl      display               // display initial 00:00

loop:        ldr     r3, [r9]              // read edge-capture register
             cmp     r3, #0                // check if any bits are set (button pressed)
             beq     check_state           // not pressed
             eor     r6, #1                // if pressed, xor with 1 to toggle btween 0 and 1
             mov     r0, #0xF              // NOTE: Docs is wrong, it say write 0, but hardware requires Write-1-to-Clear (WIC)
                                           // write 0 does nothing
             str     r0, [r9]

check_state: cmp     r6, #0                // check if it is running or paused
             moveq   r0, #2                // E=0
             movne   r0, #3                // if running, E=1
             str     r0, [r10, #8]         // write to control register
             beq     loop                  // if paused, go back to wait
             ldr     r3, [r10, #0xC]       // else, read interrupt status register
             cmp     r3, #0                // check F bit
             beq     loop                  // if F=0, timer hasn't reached zero yet, keep polling
             mov     r0, #1                // else, the timer reaches 0
                                           // NOTE: Docs is wrong, it say write 0, but hardware requires Write-1-to-Clear (WIC)
                                           // write 0 does nothing
             str     r0, [r10, #0xC]       // write 1 to clear the F bit
             add     r5, #1                // increment DD
             cmp     r5, #100              // check if DD reaches 100
             blt     update_disp           // if less than 100, skip to display
             mov     r5, #0                // wrap DD to 0
             add     r7, #1                // increment SS
             cmp     r7, #60               // check if SS reaches 60
             blt     update_disp           // if less than 60, skip to display
             mov     r7, #0                // wrap SS to 0

update_disp: bl      display               // update the display
             b       loop

display:     push    {lr}                  // push lr to stack cuz we are calling nested subroutines inside here
             // DD
             mov     r0, r5
             bl      divide
             mov     r12, r1               // save tens digit as seg7_code use r1
             bl      seg7_code             // ones digit will be in r0; tens digit in r1
             mov     r4, r0                // save the tens digit
             mov     r0, r12               // retrieve the tens digit, get bit code
             bl      seg7_code
             orr     r4, r4, r0, lsl #8
             // SS
             mov     r0, r7
             bl      divide
             mov     r12, r1               // save tens digit as seg7_code use r1
             bl      seg7_code             // ones digit will be in r0; tens digit in r1
             orr     r4, r4, r0, lsl #16   // save the tens digit
             mov     r0, r12               // retrieve the tens digit, get bit code
             bl      seg7_code
             orr     r4, r4, r0, lsl #24

             str     r4, [r8]
             pop     {lr}                  // restore lr
             bx      lr

divide:     mov     r1, #0

cont:       cmp     r0, #10
            blt     div_end
            sub     r0, #10
            add     r1, #1
            b       cont

div_end:    bx      lr

bit_codes:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

seg7_code:  ldr     r1, =bit_codes  
            ldrb    r0, [r1, r0]    
            bx      lr              
          
.end
