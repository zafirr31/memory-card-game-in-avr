

.include "m8515def.inc"

.def SEED=r3
.def temp=r16
.def lampu=r17
.def count=r18

.org $00
	rjmp RESET
.org $01
	rjmp GET_RANDOM_SEED
.org $02
	rjmp GENERATE_NEXT_RANDOM

RESET:
	ldi lampu, 0
	ldi	temp,low(RAMEND)
	out	SPL,temp
	ldi	temp,high(RAMEND)
	out	SPH,temp			; init Stack Pointer

	ldi temp,0b00001010
	out MCUCR,temp
	ldi temp,0b11000000		; External Interrupt setup
	out GICR,temp

	ldi temp, 1<<CS00
	out TCCR0,temp
	ser temp
	out DDRB,temp			; Set port B as output
	sei
	rjmp forever

forever:
	rjmp forever

GET_RANDOM_SEED:
	push temp
	in temp,SREG
	push temp

	get_seed:
		in temp, TCNT0		; Get current value of timer 0
		tst temp
		breq get_seed		; prevent seed=0
	mov lampu, temp			; new seed
	out PORTB,lampu			; write Port B

	mov SEED, temp

	pop temp
	out SREG,temp
	pop temp
	reti

GENERATE_NEXT_RANDOM:
	push temp
	in temp,SREG
	push temp

	mov temp, SEED
	lsl temp
	lsl temp
	eor SEED, temp
	mov temp, SEED
	lsr temp
	lsr temp
	lsr temp
	lsr temp
	lsr temp
	eor SEED, temp
	mov temp, SEED
	lsl temp
	lsl temp
	lsl temp
	eor SEED, temp

	mov lampu, SEED
	out PORTB,lampu	


	pop temp
	out SREG,temp
	pop temp
	reti

