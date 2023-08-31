		// Initalize constants to use in program (.data section)
		.data
                .balign 8
halfpi:         .double 0r1.57079632679489661923
breakpoint:     .double 0r1.0e-10
one:            .double 0r1.0
ninety:         .double 0r90.0
zero:		.double	0r0.0

		// Format string to print in program (.text section)
		.text
		.balign 4
str_title:	.string "Input\t\tsin(x)\t\tcos(x)\n"
str_filename:   .string "input.bin"
str_openfail:   .string "Cannot open file for reading!\n"
str_read:       .string "%.10f\t%.10f\t%.10f\n"
error_s:	.string "usage: a6.o input.bin\n"

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
		define(argc_r, w20)
		define(argv_r, x21)
                define(fd_r, w25)
                define(bytes_read_r, w26)

                alloc = -(16 + 8) & -16			// Calculate allocation size for function (same 8 bytes as returning and using double)
                dealloc = -alloc			// Calculate deallocation size for function
                value_s = 16				// Position where I store value_s
                bytes_read_o = 20			// Position where I store bytes_read_o
                value_o = 24				// Position where I store value_o

                .balign 4				// Set alignment for main function
                .global main				// Make main function visible across all file
main:           stp     x29, x30, [sp, alloc]!		// 2 lines of code to start main function
                mov     x29, sp

		mov	argc_r, w0			// Move number of arguments to argc_r
		mov	argv_r, x1			// Move list of command line arguments to argv_r

		cmp	w0, 2				// if number of arguments != 2
		b.ne	error				// Print error message and end program
	
                // Step 1. Open file
                mov     w0, AT_FDCWD			// mov AT_FDCWD = -100 into w0
		mov	w26, 1				// Move 1 to w26 (index of command line argument)
                ldr     x1, [argv_r, w26, SXTW 3]	// Load string of input to x1
                mov     w2, O_RDONLY			// w2 = 0 (O_RDONLY)
                mov     w3, 0666			// w3 = permissions
                mov     x8, syscall_openat		// Set x8 as 56 (openat) system call
                svc     0				// openat(-100, input, 0, 0666)
                mov     fd_r, w0

                // Check if there was error
                cmp     fd_r, 0	
                b.ge    open_ok
                ldr     x0, =str_openfail
                bl      printf
                mov     w0, -1
                b       main_return
open_ok:
		ldr	x0, =str_title			// Print the top row if file opening is ok
		bl	printf					
loop_read:
                mov     w0, fd_r			// w0 = fd
                add     x1, x29, value_s		// w1 = address of value on stack
                mov     w2, 8				// w2 = size to read (8 bytes)
                mov     x8, syscall_read		// Set x8 as 63 (read system call)
                svc     0				// read (fd, &value, 8)
                mov     bytes_read_r, w0			
                cmp     bytes_read_r, 0			// Check if next element is empty
                b.eq    loop_end			// Branch to end of loop
	
		// Convert degree to radian and calculate sin(x)
		ldr	d0, [x29, value_s]		// Load value of d0 (in degree to register)
		
		ldr	x13, =ninety			// Load 90.0 to x13
		ldr	d26, [x13]			// Load 90.0 to d26
		fcmp	d0, d26				// Compare x with 90.0
		b.gt	branch_back			// If x > 90.0, skip the calculation

		ldr     x13, =zero			// Load 0.0 to x13
                ldr     d26, [x13]			// Load 0.0 to d26
                fcmp     d0, d26			// Compare x with 0.0
                b.lt    branch_back			// If x < 0.0, skip the calculation
	
		ldr	x12, =halfpi			// Load pi/2 to x12
		ldr	d26, [x12] 			// Load pi/2 to d26
		fmul	d0, d0, d26			// d0 = d0 * (pi/2)
		ldr	x12, =ninety			// Load 90.0 to x12
		ldr	d26, [x12]			// Load 90.0 to x26
		fdiv	d0, d0, d26			// d0 = d0 * (pi/180) (convert degrees to radians)
		bl	sin				// Call sin function
		fmov	d22, d0				// Save returned value in d22

		// Convert degree to radian and calculate cos(x)
		ldr     d0, [x29, value_s]		// Load value of d0 (in degree to register)

		ldr     x13, =ninety			// Load 90.0 to x13
                ldr     d26, [x13]			// Load 90.0 to d26
                fcmp     d0, d26			// Compare x with 90.0
                b.gt    branch_back			// If x > 90.0, skip the calculation

                ldr     x13, =zero			// Load 0.0 to x13
                ldr     d26, [x13]			// Load 0.0 to d26
                fcmp     d0, d26			// Compare x with 0.0
                b.lt    branch_back			// If x < 0.0, skip the calculation
 
                ldr     x12, =halfpi			// Load pi/2 to x12
                ldr     d26, [x12]			// Load pi/2 to d26
                fmul    d0, d0, d26			// d0 = d0 * (pi/2)
                ldr     x12, =ninety			// Load 90.0 to x12
                ldr     d26, [x12]			// Load 90.0 to d26
                fdiv    d0, d0, d26			// d0 = d0 * (pi/180) (convert degrees to radians)
                bl      cos				// Call cos function
                fmov    d23, d0				// Save returned value in d23

                ldr     x0, =str_read			// Load the printing output to x0
                mov     w1, bytes_read_r			
                ldr     d0, [x29, value_s]		// Load first argument (degree in radian) to d0
		fmov	d1, d22				// Load second argument sin(x) to d1
		fmov	d2, d23				// Load third argument cos(x) to d2
                bl      printf				// Print the output

branch_back:
                b       loop_read			// Loop to print the next value

		// Close the file
loop_end:       mov     w0, fd_r				
                mov     x8, 57
                svc     0
		b	main_return			// Branch to return to avoid unexpected error message

error:		ldr	x0, =error_s			// Print error message 
		bl	printf

main_return:    ldp     x29, x30, [sp], dealloc		// 2 lines of code to end main function
                ret


                .balign 4				// Set alignment for sin function	
                .global main
sin:            stp     x29, x30, [sp, alloc]!		// 2 lines of code to start sin function
                mov     x29, sp

                fmov    d9, d0				// d9 = x
                ldr     x10, =breakpoint
                ldr     d10, [x10]			// d10 = 1.0e-13
                fmov    d19, d9                         // d19 = x
                fmov    d2, d19				// d2 = current cos(x)
		ldr	x11, =one			// Load 1.0 to x11
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

		fneg	d20, d20			// d20 = -1 (then continue to toggle between 1 and -1)
		fmul	d24, d20, d24			
		fmov	d3, d2				// d3 = old sum
		fadd	d2, d2, d24			// d2 = new sum

		fsub	d4, d2, d3			// d4 = new sum - old sum
		fabs	d4, d4				// d4 = |d4|
		fcmp	d4, d10				// Compare d4 with 1.0e-10
		b.gt	sintest				// If d4 > 1.0e-10, continue the loop

		fmov	d0, d2				// Save value to d0 to return
		ldp	x29, x30, [sp], dealloc		// 2 lines of code to end the function
		ret


                .balign 4				// Set alignment for cos function
                .global main				
cos:            stp     x29, x30, [sp, alloc]!		// 2 lines of code to start cos function
                mov     x29, sp

                fmov    d9, d0                          // d9 = x
                ldr     x10, =breakpoint
                ldr     d10, [x10]                      // d10 = 1.0e-13
		ldr     x11, =one			// Load 1.0 to x11
                ldr    	d19, [x11]                      // d19 = 1
                fmov    d2, d19                         // d2 = current cos(x)
                ldr     d20, [x11]                      // d20 = 1.0            
                ldr     d21, [x11]                      // d22 = 1!
		ldr	x12, =zero			// Load 0.0 to x12
                ldr     d28, [x12]                      // d28 = 0      

costest:        fmul    d19, d19, d9
                fmul    d19, d19, d9                    // d19 = x^n
                ldr     d25, [x11]
                fadd    d28, d28, d25                   // d22 = d28 + 1
                fmul    d21, d21, d28
                fadd    d28, d28, d25                   // d23 = d28 + 2                      
                fmul    d21, d21, d28                   // d21 = n!
                fdiv    d24, d19, d21                   // d24 = (x^n)/(n!)

                fneg    d20, d20                        // d20 = -1 (then continue to toggle between 1 and -1)
                fmul    d24, d20, d24
                fmov    d3, d2                          // d3 = old sum
                fadd    d2, d2, d24                     // d2 = new sum

                fsub    d4, d2, d3			// d4 = new sum - old sum
                fabs    d4, d4				// d4 = |d4|
                fcmp    d4, d10				// Compare d4 with 1.0e-10
                b.gt    costest				// If d4 > 1.0e-10, continue the loop			

                fmov    d0, d2				// Save value to d0 to return
                ldp     x29, x30, [sp], dealloc		// 2 lines of code to end the function
                ret
