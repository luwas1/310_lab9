


.code16
.section .text
.globl _start

_start:
    # Configure the 8255 in Mode 0
    # Control word = 10000000b = 0x80
    # Port A and Port B are outputs

    movb $0x80, %al
    movw $0x643, %dx
    outb %al, %dx

    # Disable all digits initially
    movb $0xFF, %al
    movw $0x640, %dx
    outb %al, %dx

    # Clear all seven-segment outputs
    movb $0x00, %al
    movw $0x641, %dx
    outb %al, %dx

main_loop:
    # Display SHE at its current position
    call display_frame

    # Check the direction of movement
    cmpb $1, direction
    jne moving_left

moving_right:
    # Position 5 is the rightmost start
    cmpb $5, position
    je turn_left

    # Move one position to the right
    incb position
    jmp main_loop

turn_left:
    # Reverse direction at right end
    movb $0, direction
    decb position
    jmp main_loop

moving_left:
    # Position 0 is the leftmost start
    cmpb $0, position
    je turn_right

    # Move one position to the left
    decb position
    jmp main_loop

turn_right:
    # Reverse direction at left end
    movb $1, direction
    incb position
    jmp main_loop

display_frame:
    # Refresh the display 100 times
    # before shifting the word
    movw $100, %di

refresh_scan:
    # Start scanning from digit 7
    xorw %si, %si

next_digit:
    # Disable all digits to prevent ghosting
    movb $0xFF, %al
    movw $0x640, %dx
    outb %al, %dx

    # BX stores the digit index
    movw %si, %bx

    # Default to a blank digit
    movb $0x00, %al

    # Check if this digit displays S
    cmpb position, %bl
    je draw_s

    # Check if this digit displays H
    movb position, %ah
    incb %ah
    cmpb %ah, %bl
    je draw_h

    # Check if this digit displays E
    incb %ah
    cmpb %ah, %bl
    je draw_e

    # Otherwise leave the digit blank
    jmp output_segments

draw_s:
    # S uses segments a, c, d, f, g
    movb $0x6D, %al
    jmp output_segments

draw_h:
    # H uses segments b, c, e, f, g
    movb $0x76, %al
    jmp output_segments

draw_e:
    # E uses segments a, d, e, f, g
    movb $0x79, %al

output_segments:
    # Send the segment pattern to Port B
    movw $0x641, %dx
    outb %al, %dx

    # Select the appropriate digit
    # A zero bit activates the digit
    movb digit_masks(%bx), %al
    movw $0x640, %dx
    outb %al, %dx

    # Short delay for visibility
    movw $300, %cx

scan_dwell:
    nop
    loop scan_dwell

    # Move to the next digit
    incw %si
    cmpw $8, %si
    jb next_digit

    # Repeat the scanning process
    decw %di
    jnz refresh_scan

    ret

.section .data

# Starting position of S
# Valid values are 0 through 5
position:
    .byte 0

# Direction: 1 = right, 0 = left
direction:
    .byte 1

# Active-low digit selection masks
digit_masks:
    .byte 0xFE, 0xFD, 0xFB, 0xF7
    .byte 0xEF, 0xDF, 0xBF, 0x7F
