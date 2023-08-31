		.data
                .balign 8
halfpi:         .double 0r1.57079632679489661923
breakpoint:     .double 0r1.0e-10
one:            .double 0r1.0
ninety:         .double 0r90.0
zero:		.double	0r0.0

		.text
		.balign 4
str_title:	.string "Input\t\tsin(x)\t\tcos(x)\n"
str_filename:   .string "input.bin"
str_openfail:   .string "Cannot open input.bin file for writing!\n"
str_read:       .string "%.10f\t%.10f\t%.10f\n"

                // Syscall codes
                define(syscall_openat, 56)
                define(syscall_close, 57)
                define(syscall_read, 63)
                define(syscall_write, 64)

                // File Open Constants
                define(AT_FDCWD, -100)
                define(O_RDWR, 02)
                define(O_CREAT, 00100)
                define(O_RDONLY, 00)

                // Function macros
                define(fd_r, w25)
                define(bytes_read_r, w26)
                alloc = -(16 + 8) & -16
                dealloc = -alloc
                value_s = 16
                bytes_read_o = 20
                value_o = 24
/*
		.balign 4
                .global main
sin:            stp     x29, x30, [sp, 16]!
                mov     x29, sp

                fmov    d9, d0                          // d9 = x
                ldr     x10, =breakpoint
                ldr     d10, [x10]                      // d10 = 1.0e-13
                fmov    d19, d9                         // d19 = x
                fmov    d2, d19                         // d2 = temp sin(x)
                ldr     x11, =one
                ldr     d20, [x11]                      // d20 = 1.0            
                ldr     d21, [x11]                      // d22 = 1!             

sintest:        fmul    d19, d19, d9
                fmul    d19, d19, d9                    // d19 = x^n
                ldr     d25, [x11]
                fadd    d22, d21, d25                   // d22 = d21 + 1
                fadd    d23, d22, d25                   // d23 = d22 + 1
                fmul    d21, d21, d22
                fmul    d21, d21, d23                   // d21 = n!
                fdiv    d24, d19, d21                   // d24 = (x^n)/(n!)

                fneg    d20, d20                        // d20 = -1 (then 1, then continue)
                fmul    d24, d20, d24
                fmov    d3, d2                          // d3 = old sum
                fadd    d2, d2, d24                     // d2 = new sum

                fsub    d4, d2, d3
                fabs    d4, d4
                fcmp    d4, d10
                b.gt    sintest

                fmov    d0, d2
                ldp     x29, x30, [sp], 16
                ret
*/

                .balign 4
                .global main
main:           stp     x29, x30, [sp, alloc]!
                mov     x29, sp

                // Step 1. Open file
                mov     w0, AT_FDCWD
                ldr     x1, =str_filename
                mov     w2, O_RDONLY
                mov     w3, 0666
                mov     x8, syscall_openat
                svc     0
                mov     fd_r, w0

                // Check if there was error
                cmp     fd_r, 0
                b.ge    open_ok
                ldr     x0, =str_openfail
                bl      printf
                mov     w0, -1
                b       main_return
open_ok:
		ldr	x0, =str_title
		bl	printf
loop_read:
                mov     w0, fd_r
                add     x1, x29, value_s
                mov     w2, 8
                mov     x8, syscall_read
                svc     0
                mov     bytes_read_r, w0
                cmp     bytes_read_r, 0
                b.eq    loop_end
	
		// Test
		ldr	d0, [x29, value_s]	
		ldr	x12, =halfpi
		ldr	d26, [x12] 
		fmul	d0, d0, d26
		ldr	x12, =ninety
		ldr	d26, [x12]
		fdiv	d0, d0, d26
		bl	sin
		fmov	d22, d0
		// End test

		ldr     d0, [x29, value_s]
                ldr     x12, =halfpi
                ldr     d26, [x12]
                fmul    d0, d0, d26
                ldr     x12, =ninety
                ldr     d26, [x12]
                fdiv    d0, d0, d26
                bl      cos
                fmov    d23, d0

                ldr     x0, =str_read
                mov     w1, bytes_read_r
                ldr     d0, [x29, value_s]
		fmov	d1, d22
		fmov	d2, d23
                bl      printf

                b       loop_read

loop_end:       mov     w0, fd_r
                mov     x8, 57
                svc     0

main_return:    ldp     x29, x30, [sp], dealloc
                ret


                .balign 4
                .global main
sin:            stp     x29, x30, [sp, alloc]!
                mov     x29, sp

                fmov    d9, d0				// d9 = x
                ldr     x10, =breakpoint
                ldr     d10, [x10]			// d10 = 1.0e-13
                fmov    d19, d9                         // d19 = x
                fmov    d2, d19				// d2 = temp sin(x)
		ldr	x11, =one
		ldr	d20, [x11]		        // d20 = 1.0		
		ldr	d21, [x11]			// d22 = 1!
		ldr	d28, [x11]			// d28 = 1	

sintest:   	fmul    d19, d19, d9
		fmul	d19, d19, d9			// d19 = x^n
		ldr	d25, [x11]
		fadd	d28, d28, d25			// d22 = d28 + 1
		fmul	d21, d21, d28
		fadd	d28, d28, d25			// d23 = d28 + 2			
		fmul	d21, d21, d28			// d21 = n!
		fdiv	d24, d19, d21			// d24 = (x^n)/(n!)

		fneg	d20, d20			// d20 = -1 (then 1, then continue)
		fmul	d24, d20, d24			
		fmov	d3, d2				// d3 = old sum
		fadd	d2, d2, d24			// d2 = new sum

		fsub	d4, d2, d3
		fabs	d4, d4
		fcmp	d4, d10
		b.gt	sintest

		fmov	d0, d2
		ldp	x29, x30, [sp], dealloc
		ret


                .balign 4
                .global main
cos:            stp     x29, x30, [sp, alloc]!
                mov     x29, sp

                fmov    d9, d0                          // d9 = x
                ldr     x10, =breakpoint
                ldr     d10, [x10]                      // d10 = 1.0e-13
		ldr     x11, =one
                ldr    	d19, [x11]                      // d19 = 1
                fmov    d2, d19                         // d2 = temp sin(x)
                ldr     d20, [x11]                      // d20 = 1.0            
                ldr     d21, [x11]                      // d22 = 1!
		ldr	x12, =zero
                ldr     d28, [x12]                      // d28 = 0      

costest:        fmul    d19, d19, d9
                fmul    d19, d19, d9                    // d19 = x^n
                ldr     d25, [x11]
                fadd    d28, d28, d25                   // d22 = d28 + 1
                fmul    d21, d21, d28
                fadd    d28, d28, d25                   // d23 = d28 + 2                        
                fmul    d21, d21, d28                   // d21 = n!
                fdiv    d24, d19, d21                   // d24 = (x^n)/(n!)

                fneg    d20, d20                        // d20 = -1 (then 1, then continue)
                fmul    d24, d20, d24
                fmov    d3, d2                          // d3 = old sum
                fadd    d2, d2, d24                     // d2 = new sum

                fsub    d4, d2, d3
                fabs    d4, d4
                fcmp    d4, d10
                b.gt    sintest

                fmov    d0, d2
                ldp     x29, x30, [sp], dealloc
                ret
