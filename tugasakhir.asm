

; Pembuat:
; Zafir Rasyidi Taufik
; Ariell Zaky Prabaswara Ariza
; Aljihad Ijlal Nadhif Suyudi

; Kolaborator (Random Algorithm):
; Sean Zeliq Urian
; Adrian Wijaya
; Falih Mufazan

.include "m8515def.inc"
.def temp2 = r0
.def arg1 = r1	; function arguments
.def arg2 = r2  ; function arguments
.def arg3 = r3	; function arguments
.def SEED = r4
.def DELAYREG1 = r7
.def DELAYREG2 = r8
.def DELAYREG3 = r9
.def row = r10	; register pointing row
.def col = r11	; register pointing column
.def lokasicursor = r6
.def temp = r16
.def counter = r17
.def pointer = r18;
.def leveltimenow = r19
.def levelcounter = r20
.def saveopen = r21

.equ layout_address = 0x60
.equ layout_flag = 0x80
.equ nama = 0xA0
.equ nama_highscore = 0xB0
.equ highscore = 0xAA

.org $00
	rjmp FULL_RESET

.org $01
	rjmp INIT

.org $04
	; 1 DETIK TELAH BERLALU
	rjmp ADD_LEVEL_TIME_NOW

FULL_RESET:
	ldi temp, low(nama)	
	mov arg1, temp
	ldi temp, high(nama)
	mov arg2, temp
	mov XL, arg1
	mov XH, arg2
	ldi temp, 0x5a
	st X+, temp
	ldi temp, 0x41
	st X+, temp
	ldi temp, 0x46
	st X+, temp
	ldi temp, 0x49
	st X+, temp
	ldi temp, 0x52
	st X+, temp

	ldi temp, low(highscore)	
	mov arg1, temp
	ldi temp, high(highscore)
	mov arg2, temp
	mov XL, arg1
	mov XH, arg2
	ldi temp, 128
	st X, temp
	rjmp INIT

INIT:
	ldi	temp, low(RAMEND)
	out	SPL, temp				; init Stack Pointer
	ldi	temp, high(RAMEND)
	out	SPH, temp				; init Stack Pointer

	INIT_EXT_INTERRUPT:
		ldi temp,0b00000010
		out MCUCR,temp
		ldi temp,0b01000000
		out GICR,temp

	INIT_LCD:
		cbi PORTA,1 ; CLR RS
		ldi temp,0x38 ; MOV DATA,0x38 --> 8bit, 2line, 5x7
		out PORTB,temp
		sbi PORTA,0 ; SETB EN
		cbi PORTA,0 ; CLR EN
		rcall DELAY
		cbi PORTA,1 ; CLR RS
		ldi temp,$0D ; MOV DATA,0x0D --> disp ON, cursor OFF, blink ON
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

	; SETUP LED HERE
	INIT_LED:
		ser temp
		out DDRE, temp

	; SETUP TIMER HERE
		; TIMER 1 UNTUK WAKTU PER LEVEL
	INIT_TIMER_1:
		ldi temp, 1<<CS11			; prescalar 256
		out TCCR1B, temp
		ldi temp, 1<<OCF1A			; interrupt if compare true in T/C1B
		out TIFR, temp	
		ldi temp, 1<<OCIE1A			; Enable timer/counter1B compare int
		out TIMSK, temp
		ldi temp, $F4				
		out OCR1AH, temp
		ldi temp, $24				; Compared value, to be around 1 second
		out OCR1AL, temp
		sei

		; TIMER 0 UNTUK RANDOM GENERATOR
	INIT_TIMER_0:	
		ldi temp, 1<<CS00			; No prescalar, turn it on
		out TCCR0,temp

	; SETUP KEYPAD HERE
	INIT_KEYPAD:
		ldi temp,0b11110000 ; data direction register column lines output
		out DDRC,temp    ; set direction register
		ldi temp,0b00001111 ; Pull-Up-Resistors to lower four port pins
		out PORTC,temp    ; to output port

	rcall MAIN

DELAY:
	; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; Delay 20 000 cycles
	; 5ms at 4.0 MHz

	    ldi  temp, 26
	    mov DELAYREG1, temp
	    ldi  temp, 249
	    mov DELAYREG2, temp	    
	L1: dec  DELAYREG2
	    brne L1
	    dec  DELAYREG1
	    brne L1
	    nop
	ret

LONG_DELAY:
	; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; Delay 20 000 cycles
	; 5ms at 4.0 MHz

	    ldi  temp, 104
	    mov DELAYREG1, temp
	    ldi  temp, 229
	    mov DELAYREG2, temp	    
	L2: dec  DELAYREG2
	    brne L2
	    dec  DELAYREG1
	    brne L2
	    nop
	ret

LONG_LONG_DELAY:
	; Generated by delay loop calculator
	; at http://www.bretmulvey.com/avrdelay.html
	;
	; Delay 1 200 000 cycles
	; 300ms at 4.0 MHz

		ldi  temp, 7
    	mov  DELAYREG1, temp
    	ldi  temp, 23
	    mov  DELAYREG2, temp
	    ldi  temp, 107
	    mov  DELAYREG3, temp
	L3: dec  DELAYREG3
	    brne L3
	    dec  DELAYREG2
	    brne L3
	    dec  DELAYREG1
	    brne L3
	ret

PUT_STRING_PROG_MEM:
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

PUT_STRING_DATA_MEM:
	mov XL,arg1 ; Load low part of byte address into ZL
	mov XH,arg2 ; Load high part of byte address into ZH
	
	LOADBYTE_DATA_MEM:
		ld r0, X+

		tst r0 ; Check if we've reached the end of the message
		breq END_LCD_DATA_MEM ; If so, quit

		mov arg1, r0
		rcall WRITE_TEXT
		rjmp LOADBYTE_DATA_MEM

	END_LCD_DATA_MEM:
		ret

WRITE_TEXT:
	mov temp, arg1 ; Put the character onto Port B
	sbi PORTA,1 ; SETB RS
	out PORTB, temp
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	tst arg3	; If arg3 is not 0, delay
	brne DELAY
	ret

CLEAR_LCD:
	cbi PORTA,1 ; CLR RS
	ldi temp,$01 ; MOV DATA,0x01
	out PORTB,temp
	sbi PORTA,0 ; SETB EN
	cbi PORTA,0 ; CLR EN
	rcall DELAY
	ret

RESER_TIMER0:
	clr temp
	out TCNT0, temp
	ret

RESET_TIMER1:
	clr temp
	out TCNT1H, temp
	out TCNT1L, temp
	ret

ADD_LEVEL_TIME_NOW:

	push temp
	in temp,SREG
	push temp

	rcall RESET_TIMER1
	
	; add 1 to timer
	inc leveltimenow

	pop temp
	out SREG,temp
	pop temp

	reti

TURN_ON_YELLOW_LED:
	ldi temp, 0b00011000
	out PORTE, temp
	ret

TURN_ON_GREEN_LED:
	ldi temp, 0b00011111
	out PORTE, temp
	rcall LONG_DELAY
	rcall TURN_OFF_ALL_LED
	ret	

TURN_ON_RED_LED:
	ldi temp, 0b11111000
	out PORTE, temp
	rcall LONG_DELAY
	rcall TURN_OFF_ALL_LED
	ret

TURN_OFF_ALL_LED:
	clr temp
	out PORTE, temp
	ret

PRINT_CHAR_AT_CHAR_MAP:
	ldi temp, low(2*character_map)		; GET FIRST CHARACTER IN CHAR MAP
	add temp, pointer
	mov arg1, temp
	ldi temp, high(2*character_map)
	brcc SKIP		; IF OVERFLOW, ADD ONE TO HIGH
	inc temp
	SKIP:

	mov arg2, temp	; PRINT CURRENT CHAR AT KEYMAP
	mov ZL, arg1
	mov ZH, arg2
	lpm
	mov arg1, r0	; PRINT CURRENT CHAR AT KEYMAP
	rcall WRITE_TEXT
	rcall CHANGE_CURSOR_FINALLY
	
	ret

GET_NAME:

	ldi temp, 0x80
	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY

	clr arg3
	ldi temp, high(2*message_input_nama)
	mov arg2, temp
	ldi temp, low(2*message_input_nama)
	mov arg1, temp
	rcall PUT_STRING_PROG_MEM

	ldi temp, 0xC0
	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY

	ldi counter, 0
	; USE KEYPAD TO INPUT NAME
	GET_NAME_FINALLY:
	ldi pointer, 0

	ldi temp, 1		; WAIT FOR UP, DOWN, OR ENTER
	mov arg1, temp
	rcall WAIT_KEY

	inc counter
	cpi counter, 8
	brne GET_NAME_FINALLY

	ldi pointer, 0
	ldi temp, low(nama)	
	add temp, counter
	mov arg1, temp
	ldi temp, high(nama)
	mov arg2, temp		; ADD NULL BYTE

	mov XL, arg1
	mov XH, arg2
	st X, pointer

	; GET VALUE IN TCNT0
	; USE VALUE AS SEED FOR RANDOM
	in temp, TCNT0		; get value in timer for seed
	mov SEED, temp

	ret

GET_RANDOM_NUMBER:

	; USING SEED, GENERATE NEXT RANDOM NUMBER
	; KOLABORASI DENGAN KELOMPOK SEAN ZELIQ

	ldi temp, 73
	mul SEED, temp
	mov SEED, r0
	ldi temp, 31
	add SEED, temp
	in temp, TCNT0

	eor SEED, temp		; PUT VALUE IN temp
	mov temp, SEED

	ret

; not done
SETUP_LAYOUT:

	rcall CLEAR_LCD

	ldi temp, 1
	mov arg3, temp
	ldi temp, high(2*message_start)
	mov arg2, temp
	ldi temp, low(2*message_start)
	mov arg1, temp
	rcall PUT_STRING_PROG_MEM
	
	; set all to zero
	ldi counter, 0
	ldi temp, low(layout_address)	
	mov arg1, temp
	ldi temp, high(layout_address)
	mov arg2, temp
	mov XL, arg1
	mov XH, arg2
	clr temp

	SET_ZERO:
		st X+, temp
		inc counter
		cpi counter, 32
		brne SET_ZERO

	ldi counter, 0
											; USING RANDOM GENERATOR, SETUP LAYOUT
											; GET RANDOM VALUE, AND IMMEDIATE 31
	SETUP_LAYOUT_FINALLY:
		mov pointer, counter
		lsr pointer
		inc pointer

		rcall GET_RANDOM_NUMBER
		andi temp, 0x1F
		mov r0, temp

		; CEK THAT LOCATION, IF ALREADY HAS NUMBER, ADD 1, AND IMMEDIATE 31
		STILL_HAS:
			mov temp, r0
			inc temp
			andi temp, 0x1F
			mov r0, temp

			ldi temp, low(layout_address)	
			add temp, r0
			mov arg1, temp
			ldi temp, high(layout_address)
			mov arg2, temp

			mov XL, arg1
			mov XH, arg2
			ld temp, X
			cpi temp, 0x0
			brne STILL_HAS

		ldi temp, low(2*character_map)		; GET CHARACTER IN CHAR MAP
		add temp, pointer
		mov arg1, temp
		ldi temp, high(2*character_map)
		brcc SKIP3		; IF OVERFLOW, ADD ONE TO HIGH
		inc temp
		SKIP3:
		mov arg2, temp	
		mov ZL, arg1
		mov ZH, arg2
		mov temp, r0
		lpm

		st X, r0	
		
		; REPEAT 32 TIMES
		inc counter
		cpi counter, 32
		brne SETUP_LAYOUT_FINALLY

	ldi temp, 0x80
	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY

	clr arg3
	ldi temp, high(2*layout_coverall)
	mov arg2, temp
	ldi temp, low(2*layout_coverall)
	mov arg1, temp
	rcall PUT_STRING_PROG_MEM

	ldi temp, 0xC0
	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY

	ldi temp, high(2*layout_coverall)
	mov arg2, temp
	ldi temp, low(2*layout_coverall)
	mov arg1, temp
	rcall PUT_STRING_PROG_MEM

	ldi temp, 0x80
	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY	

	ret

DECREASE_LETTER:
	tst pointer
	brne NOTZERO
	ldi pointer, 0x20
	NOTZERO:
	dec pointer
	andi pointer, 0x1F

	rcall PRINT_CHAR_AT_CHAR_MAP

	rjmp WAIT_KEY

INCREASE_LETTER:
	inc pointer
	andi pointer, 0x1F

	rcall PRINT_CHAR_AT_CHAR_MAP

	rjmp WAIT_KEY

NEXT_CHAR:
	ldi temp, low(2*character_map)		; GET FIRST CHARACTER IN CHAR MAP
	add temp, pointer
	mov arg1, temp
	ldi temp, high(2*character_map)
	brcc SKIP2		; IF OVERFLOW, ADD ONE TO HIGH
	inc temp
	SKIP2:
	mov arg2, temp	

	mov ZL, arg1
	mov ZH, arg2
	lpm
	mov pointer, r0


	ldi temp, low(nama)		
	add temp, counter
	mov arg1, temp
	ldi temp, high(nama)
	mov arg2, temp		; ADDRESS OF NAMA

	mov XL, arg1
	mov XH, arg2
	ST X, pointer

	mov temp, lokasicursor
	inc temp
	andi temp, 0xCF			; Add 1, andi 0xCF to get important bits
	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY

	ret

CHANGE_CHARACTER:
	cpi temp, 0x5E				; down
	breq DECREASE_LETTER
	cpi temp, 0x5D				; up
	breq INCREASE_LETTER
	cpi temp, 0x6D				; enter
	breq NEXT_CHAR

	rjmp WAIT_KEY

OPEN_CARD_FINALLY_FINALLY:
	ldi temp, low(layout_address)		
	add temp, pointer
	mov arg1, temp
	ldi temp, high(layout_address)
	mov arg2, temp		; FLAG ARRAY

	mov XL, arg1
	mov XH, arg2
	ld temp, X
	mov arg1, temp
	rcall WRITE_TEXT
	rcall CHANGE_CURSOR_FINALLY
	ret

CLOSE_CARD:
	mov saveopen, arg1

	ldi temp, low(layout_flag)		; GET FIRST CHAR TO COMPARE
	add temp, saveopen
	mov arg1, temp
	ldi temp, high(layout_flag)
	mov arg2, temp		; FLAG ARRAY

	mov XL, arg1
	mov XH, arg2
	clr temp
	st X, temp

	mov arg1, saveopen

	;; GET CURSOR FROM NUMBER
	mov temp, saveopen
	andi saveopen, 0x0F
	andi temp, 0x10
	tst temp
	breq NO_SECOND_LINE
	ori saveopen, 0x40
	NO_SECOND_LINE:
	ori saveopen, 0x80
	mov temp, saveopen

	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY
	ldi temp, 63
	mov arg1, temp
	rcall WRITE_TEXT
	ret

OPEN_CARD:

	mov pointer, lokasicursor
	mov temp, lokasicursor
	andi pointer, 0x0F
	andi temp, 0x40
	tst temp
	breq SKIP4
	ori pointer, 0x10
	SKIP4:

	ldi temp, low(layout_flag)		
	add temp, pointer
	mov arg1, temp
	ldi temp, high(layout_flag)
	mov arg2, temp		; FLAG ARRAY

	mov XL, arg1
	mov XH, arg2
	ld temp, X
	
	tst temp
	breq OPEN_CARD_FINALLY
	rjmp DONE_OPEN_CARD


	OPEN_CARD_FINALLY:
		ldi temp, 1
		ST X, temp
		rcall OPEN_CARD_FINALLY_FINALLY
		inc counter
		cpi counter, 2
		breq TWO_OPEN_CARDS
		rcall TURN_ON_YELLOW_LED
		mov saveopen, pointer
		rjmp DONE_OPEN_CARD

		TWO_OPEN_CARDS:
		clr counter

		ldi temp, low(layout_address)		; GET FIRST CHAR TO COMPARE
		add temp, pointer
		mov arg1, temp
		ldi temp, high(layout_address)
		mov arg2, temp		; RAND ARRAY

		mov XL, arg1
		mov XH, arg2
		ld temp, X
		mov temp2, temp

		ldi temp, low(layout_address)		; GET SECOND CHAR TO COMPARE
		add temp, saveopen
		mov arg1, temp
		ldi temp, high(layout_address)
		mov arg2, temp		; RAND ARRAY

		mov XL, arg1
		mov XH, arg2
		ld temp, X

		cp temp, temp2
		breq OPEN_CARD_FOREVER

		CLOSE_BOTH_CARDS:
		rcall TURN_ON_RED_LED
		mov arg1, saveopen
		rcall CLOSE_CARD
		mov arg1, pointer
		rcall CLOSE_CARD
		rcall CHANGE_CURSOR_FINALLY
		rjmp DONE_OPEN_CARD

		OPEN_CARD_FOREVER:
		rcall TURN_ON_GREEN_LED
		inc levelcounter

	DONE_OPEN_CARD:
	rcall DELAY
	clr arg1
	ret

CHANGE_CURSOR_FINALLY:
	mov temp, lokasicursor
	cbi PORTA,1 			; CLR RS
	cbi PORTA,2 			; CLR RW
	out PORTB, temp
	sbi PORTA,0 			; SETB EN
	cbi PORTA,0 			; CLR EN
	rcall LONG_DELAY
	ret

MOVE_CURSOR_LEFT:
	mov temp, lokasicursor
	andi temp, 0x0F
	tst temp
	brne NOWRAP				; Wrap to right side
		ldi temp, 0x0F
		or lokasicursor, temp
		rjmp MOVE_CURSOR_LEFT_FINALLY
	NOWRAP:
		mov temp, lokasicursor	; Dont wrap
		dec temp
		andi temp, 0xCF
		mov lokasicursor, temp
	MOVE_CURSOR_LEFT_FINALLY:
	rcall CHANGE_CURSOR_FINALLY		; Change the position of the cursor
	rjmp WAIT_KEY

MOVE_CURSOR_UP_DOWN:
	ldi temp, 0b01000000
	eor lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY		; Change the position of the cursor
	rjmp WAIT_KEY

MOVE_CURSOR_RIGHT:
	mov temp, lokasicursor
	inc temp
	andi temp, 0xCF			; Add 1, andi 0xCF to get important bits
	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY		; Change the position of the cursor
	rjmp WAIT_KEY

CHANGE_CURSOR:
	cpi temp, 0x3E				; left
	breq MOVE_CURSOR_LEFT
	cpi temp, 0x5E				; down
	breq MOVE_CURSOR_UP_DOWN
	cpi temp, 0x6E				; right
	breq MOVE_CURSOR_RIGHT
	cpi temp, 0x5D				; up
	breq MOVE_CURSOR_UP_DOWN
	cpi temp, 0x6D				; enter
	rjmp OPEN_CARD

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
	ldi temp,0b01101111 ; leftmost column
	out PORTC,temp
	in temp,PINC 		
	ori temp,0b11110000 
	cpi temp,0b11111111 
	brne FOUND_KEY 		; key found


	FOUND_KEY:			; col (cat) row = button number
		mov temp, col
		or temp, row
	
	tst arg1
	breq CHANGE_CURSOR
	rjmp CHANGE_CHARACTER

WAIT_KEY:
	ldi temp,0b00001111 ; PB4..PB6=Null, pull-Up-resistors to input lines
	out PORTC,temp    ; of port pins PB0..PB3
	in temp,PINC     ; read key results
	mov row, temp		; value in temp is current row
	ori temp,0b11110000 ; mask all upper bits with a one
	cpi temp,0b11111111 ; all bits = One?
	brne GET_KEY         ; yes, no key is pressed
	rjmp WAIT_KEY

MOD10:
	mov temp, arg1

	cpi temp, 10
	brlt DONE_MODULO

	NOT_DONE_MODULO:
		subi temp, 10
		cpi temp, 10
		brge NOT_DONE_MODULO
	DONE_MODULO:
	ret

DIV10:
	mov temp, arg1
	clr arg1

	cpi temp, 10
	brlt DONE_DIVIDE

	NOT_DONE_DIVIDE:
		subi temp, 10
		inc arg1
		cpi temp, 10
		brge NOT_DONE_DIVIDE

	DONE_DIVIDE:
	mov temp, arg1
	ret

PRINT_SCORE_FINALLY:
	mov temp2, arg1
	mov temp, temp2
	ldi counter, 0xD0

	PRINT_NUMBER:
		mov temp2, temp
		dec counter
		mov lokasicursor, counter
		rcall CHANGE_CURSOR_FINALLY

		mov arg1, temp2
		rcall MOD10
		subi temp, -0x30
		mov arg1, temp
		rcall WRITE_TEXT

		mov arg1, temp2
		rcall DIV10

		tst temp
		brne PRINT_NUMBER

	ldi temp, 0x8F
	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY
	ret

PRINT_PLAYER_SCORE:
	ldi temp, 0x80
	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY

	clr arg3
	ldi temp, high(2*message_player_score)
	mov arg2, temp
	ldi temp, low(2*message_player_score)
	mov arg1, temp
	rcall PUT_STRING_PROG_MEM

	ldi temp, 0xC0
	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY

	clr arg3
	ldi temp, high(nama)
	mov arg2, temp
	ldi temp, low(nama)
	mov arg1, temp
	rcall PUT_STRING_DATA_MEM

	mov arg1, leveltimenow
	rcall PRINT_SCORE_FINALLY

	ret

PRINT_HIGH_SCORE:
	ldi temp, 0x80
	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY

	clr arg3
	ldi temp, high(2*message_high_score)
	mov arg2, temp
	ldi temp, low(2*message_high_score)
	mov arg1, temp
	rcall PUT_STRING_PROG_MEM

	ldi temp, 0xC0
	mov lokasicursor, temp
	rcall CHANGE_CURSOR_FINALLY

	clr arg3
	ldi temp, high(nama_highscore)
	mov arg2, temp
	ldi temp, low(nama_highscore)
	mov arg1, temp
	rcall PUT_STRING_DATA_MEM

	ldi temp, low(highscore)	
	mov arg1, temp
	ldi temp, high(highscore)
	mov arg2, temp
	mov XL, arg1
	mov XH, arg2
	ld temp, X

	mov arg1, temp
	rcall PRINT_SCORE_FINALLY

	ret


COPY_NAME_TO_HIGHSCORE_NAME:
	ldi counter, 0
	ldi temp, low(nama)	
	mov arg1, temp
	ldi temp, high(nama)
	mov arg2, temp
	mov XL, arg1
	mov XH, arg2

	ldi temp, low(nama_highscore)	
	mov arg1, temp
	ldi temp, high(nama_highscore)
	mov arg2, temp
	mov YL, arg1
	mov YH, arg2

	MOVE_NAME:
		ld temp, X+
		st Y+, temp
		inc counter
		cpi counter, 8
		brne MOVE_NAME

	clr temp
	st Y, temp		; ADD NULL BYTE	
	ret

SET_HIGHSCORE:
	st X, leveltimenow
	rcall COPY_NAME_TO_HIGHSCORE_NAME
	ret

PLAY_GAME:
	
	ldi counter, 0
	ldi temp, low(layout_flag)	
	mov arg1, temp
	ldi temp, high(layout_flag)
	mov arg2, temp
	mov XL, arg1
	mov XH, arg2
	clr temp

	SET_ZERO2:
		st X+, temp
		inc counter
		cpi counter, 32
		brne SET_ZERO2

	clr levelcounter
	clr counter
	clr arg1
	clr leveltimenow		; PREPARE TIMER
	rcall RESET_TIMER1	

	NOT_DONE_YET_PLAYING:
		rcall WAIT_KEY
		cpi levelcounter, 16
		brne NOT_DONE_YET_PLAYING

	ldi temp, 0			; TURN OFF TIMER 1
	out TCCR1B, temp
	dec leveltimenow

	ldi temp, low(highscore)	
	mov arg1, temp
	ldi temp, high(highscore)
	mov arg2, temp
	mov XL, arg1
	mov XH, arg2
	ld temp, X

	cp leveltimenow, temp
	brsh NO_HIGHSCORE
	rcall SET_HIGHSCORE
	NO_HIGHSCORE:
	ret

MAIN:
	
	; INPUT NAME FUNC, GET_NAME
	rcall GET_NAME
	rcall CLEAR_LCD

	; DELAY, GET READY TO START GAME
	; PREPARE LAYOUT
	rcall SETUP_LAYOUT

	rcall PLAY_GAME

	forever:
		rcall CLEAR_LCD
		rcall PRINT_PLAYER_SCORE
		rcall LONG_LONG_DELAY
		rcall CLEAR_LCD
		rcall PRINT_HIGH_SCORE
		rcall LONG_LONG_DELAY
		rjmp forever

message_start:
.db "SIAP SIAP...", 0, 0

message_habis_waktu:
.db "WAKTU HABIS!", 0, 0

message_level_selesai:
.db "MANTAP!", 0

layout_coverall:
.db "????????????????", 0, 0

message_player_score:
.db "Your Time:", 0, 0

message_high_score:
.db "Fastest Time:", 0

message_input_nama:
.db "INPUT NAMA:", 0

character_map:
.db " ABCDEFGHIJKLMNOPQRSTUVWXYZ_?!+-", 0, 0