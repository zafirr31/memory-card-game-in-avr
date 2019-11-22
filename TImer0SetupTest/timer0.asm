

.include "m8515def.inc"

.def temp=r16
.def lampu=r17
.def count=r18

.org $00
	rjmp RESET
.org $01
	rjmp INT_EXT0

RESET:
	ldi lampu, 0
	ldi	temp,low(RAMEND)
	out	SPL,temp
	ldi	temp,high(RAMEND)
	out	SPH,temp			; init Stack Pointer

	ldi temp,0b00000010
	out MCUCR,temp
	ldi temp,0b01000000		; External Interrupt setup
	out GICR,temp

	ldi temp, 1<<CS00
	out TCCR0,temp
	ser temp
	out DDRB,temp			; Set port B as output
	sei
	rjmp forever

forever:
	rjmp forever

INT_EXT0:
	push temp
	in temp,SREG
	push temp

	in lampu, TCNT0			; Get current value of timer 0
	out PORTB,lampu			; write Port B

	pop temp
	out SREG,temp
	pop temp
	reti
