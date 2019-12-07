

.include "m8515def.inc"
.def arg1 = r1	; function arguments
.def arg2 = r2  ; function arguments
.def lokasicursor = r6
.def temp = r16 ; temporary register
.def row = r10	; register pointing row
.def col = r11	; register pointing column

.org $00
rjmp MAIN


DELAY:
	; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; Delay 20 000 cycles
	; 5ms at 4.0 MHz

	    ldi  r18, 26
	    ldi  r19, 249
	L1: dec  r19
	    brne L1
	    dec  r18
	    brne L1

PUT_STRING:
	mov ZL,arg1 ; Load low part of byte address into ZL
	mov ZH,arg2 ; Load high part of byte address into ZH
	
	LOADBYTE:
		lpm ; Load byte from program memory into r0

		tst r0 ; Check if we've reached the end of the message
		breq END_LCD ; If so, quit

		mov arg1, r0
		rcall WRITE_TEXT
		adiw ZL,1 ; Increase Z registers
		rjmp LOADBYTE

	END_LCD:
		ret

WRITE_TEXT:
	mov temp, arg1 ; Put the character onto Port B
	sbi PORTA,1 ; SETB RS
	out PORTB, temp
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	ret

CLEAR_LCD:
	cbi PORTA,1 ; CLR RS
	ldi temp,$01 ; MOV DATA,0x01
	out PORTB,temp
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY
	ret

CHANGE_CURSOR:
	mov temp, lokasicursor
	cbi PORTA,1 ; CLR RS
	cbi PORTA,2 ; CLR RW
	out PORTB, temp
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY
	ret

MOVE_CURSOR_LEFT:
	mov temp, lokasicursor
	andi temp, 0x0F
	tst temp
	brne NOWRAP
		ldi temp, 0x0F
		or lokasicursor, temp
		rjmp MOVE_CURSOR_LEFT_FINALLY
	NOWRAP:
		mov temp, lokasicursor
		dec temp
		andi temp, 0xCF
		mov lokasicursor, temp
	MOVE_CURSOR_LEFT_FINALLY:
	rcall CHANGE_CURSOR
	rjmp WAIT_KEY

MOVE_CURSOR_UP_DOWN:
	ldi temp, 0b01000000
	eor lokasicursor, temp
	rcall CHANGE_CURSOR
	rjmp WAIT_KEY

MOVE_CURSOR_RIGHT:
	mov temp, lokasicursor
	inc temp
	andi temp, 0xCF
	mov lokasicursor, temp
	rcall CHANGE_CURSOR
	rjmp WAIT_KEY

OPEN_CARD:
	rjmp OPEN_CARD

RUN_KEY:
	cpi temp, 0x3E	; left
	breq MOVE_CURSOR_LEFT
	cpi temp, 0x5E	; down
	breq MOVE_CURSOR_UP_DOWN
	cpi temp, 0x6E	; right
	breq MOVE_CURSOR_RIGHT
	cpi temp, 0x5D	; up
	breq MOVE_CURSOR_UP_DOWN
	cpi temp, 0x6D	; enter
	breq OPEN_CARD

	rjmp WAIT_KEY

GET_KEY:
	ldi temp,0b00110000
	mov col, temp
	ldi temp,0b00111111 ; rightmost column
	out PORTC,temp
	in temp,PINC 		
	ori temp,0b11110000 
	cpi temp,0b11111111 
	brne FOUND_KEY 		; key found

	ldi temp,0b01010000
	mov col, temp
	ldi temp,0b01011111 ; middle column
	out PORTC,temp
	in temp,PINC 		
	ori temp,0b11110000 
	cpi temp,0b11111111 
	brne FOUND_KEY 		; key found

	ldi temp,0b01100000
	mov col, temp

	FOUND_KEY:
		mov temp, col
		or temp, row
	
	rjmp RUN_KEY

WAIT_KEY:
	ldi temp,0b00001111 ; PB4..PB6=Null, pull-Up-resistors to input lines
	out PORTC,temp    ; of port pins PB0..PB3
	in temp,PINC     ; read key results
	mov row, temp		; value in temp is current row
	ori temp,0b11110000 ; mask all upper bits with a one
	cpi temp,0b11111111 ; all bits = One?
	brne GET_KEY         ; yes, no key is pressed
	rjmp WAIT_KEY

MAIN:

	INIT_STACK:
		ldi temp, low(RAMEND)
		ldi temp, high(RAMEND)
		out SPH, temp

	INIT_LCD:
		cbi PORTA,1 ; CLR RS
		ldi temp,0x38 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
		out PORTB,temp
		sbi PORTA,0 ; SETB EN
		cbi PORTA,0 ; CLR EN
		rcall DELAY
		cbi PORTA,1 ; CLR RS
		ldi temp,$0D ; MOV DATA,0x0D --> disp ON, cursor ON, blink ON
		out PORTB,temp
		sbi PORTA,0 ; SETB EN
		cbi PORTA,0 ; CLR EN
		rcall DELAY
		rcall CLEAR_LCD ; CLEAR LCD
		cbi PORTA,1 ; CLR RS
		ldi temp,$06 ; MOV DATA,0x06 --> increase cursor, display sroll OFF
		out PORTB,temp
		sbi PORTA,0 ; SETB EN
		cbi PORTA,0 ; CLR EN
		rcall DELAY
		ser temp
		out DDRA,temp ; Set port A as output
		out DDRB,temp ; Set port B as output
		ldi temp, 0b10000000
		mov lokasicursor, temp

	INIT_KEY:
		ldi temp,0b11110000 ; data direction register column lines output
		out DDRC,temp    ; set direction register
		ldi temp,0b00001111 ; Pull-Up-Resistors to lower four port pins
		out PORTC,temp    ; to output port

	rjmp WAIT_KEY

EXIT:
	rjmp EXIT

;====================================================================
; DATA
;====================================================================

message:
.db "POK EZPZ",0