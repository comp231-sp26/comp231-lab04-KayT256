.text
.global _start

_start:
               // Initialization
               ldr     r8, =0xFF200020       // base address of hex3-hex0
               ldr     r9, =0xFF200050       // base address of keys
               mov     r5, #0                // counter
               b       display               // display initial state counter = 0

loop:          // Wait for key pressed
               ldr     r3, [r9]              // read key data register
               cmp     r3, #0                // check if no key is pressed
               beq     loop                  // keep polling

wait_release:  // Wait for key released
               ldr     r4, [r9]              // read key data reagister again
               cmp     r4, #0                // check if it is released (back to 0)
               bne     wait_release          // keep waiting
               
               // Process which key is pressed
               tst     r3, #1                // check if KEY0 is pressed (lowest bit is 1)
               bne     do_key0
               tst     r3, #2                // check if KEY1 is pressed (2nd lowest bit is 1)
               bne     do_key1
               tst     r3, #4                // check if KEY2 is pressed (3rd lowest bit is 1)
               bne     do_key2
               tst     r3, #8                // check if KEY3 is pressed (4th lowest bit is 1)
               bne     do_key3
               b       loop                  // fallback if sth goes wrong

do_key0:       mov     r5, #0                // set counter to 0
               b       display

do_key1:       add     r5, #1                // increment counter
               cmp     r5, #10               // check upper bound
               movge   r5, #0                // wrap back to 0
               b       display

do_key2:       sub     r5, #1                // decrement counter
               cmp     r5, #0                // check lower bound
               movlt   r5, #9                // wrap to 9
               b       display

do_key3:       b       blank

display:       mov     r0, r5
               bl      seg7_code
               str     r0, [r8]
               b       loop

blank:         mov     r0, #0
               str     r0, [r8]
               b       loop

bit_codes:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

seg7_code:  ldr     r1, =bit_codes  
            ldrb    r0, [r1, r0]    
            bx      lr 
          
.end
