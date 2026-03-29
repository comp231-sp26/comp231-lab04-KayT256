.text
.global _start

_start:                             
             // Initialization
             ldr     r8, =0xFF200020       // base address of hex3-hex0
             ldr     r9, =0xFF20005C       // address of edge-capture register
             mov     r5, #0                // counter
             mov     r10, #1               // state flag (1 = running, 0 = paused)
                                           // the docs do not say anything about what happens
                                           // when a button is clicked. So I will assume that
                                           // it wants me to start/stop?
             // Clear edge-capture register initially
             mov     r0, #0
             str     r0, [r9]

loop:        ldr     r3, [r9]              // read edge-capture register
             cmp     r3, #0                // check if any bits are set (button pressed)
             beq     check_state           // not pressed
             eor     r10, #1               // if pressed, xor with 1 to toggle btween 0 and 1
             mov     r0, #0xF              // NOTE: Docs is wrong, it say write 0, but hardware requires Write-1-to-Clear (W1C)
                                           // write 0 does nothing
             str     r0, [r9]

check_state: cmp     r10, #0               // check if it is running or paused
             beq     loop                  // if paused, then skip display update and go back to wait
             bl      display               // else, it is running
             bl      do_delay              // wait ~0.25s
             add     r5, #1                // increment counter
             cmp     r5, #100
             movge   r5, #0                // wrap back if reach 100
             b       loop

do_delay:    ldr     r7, =200000000

sub_loop:    subs    r7, r7, #1
             bne     sub_loop
             bx      lr

display:     push    {lr}                  // push lr to stack cuz we are calling nested subroutines inside here
             mov     r0, r5
             bl      divide
             mov     r12, r1               // save tens digit as seg7_code use r1
             bl      seg7_code             // ones digit will be in r0; tens digit in r1
             mov     r4, r0                // save the tens digit
             mov     r0, r12               // retrieve the tens digit, get bit code
             bl      seg7_code
             orr     r4, r4, r0, lsl #8
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
