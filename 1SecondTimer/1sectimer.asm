

.include "m8515def.inc"
.def temp = r16
.def lampu = r17

.org $00
	rjmp init

.org $04
	rjmp ISR_TCOM1A 

init:
	ldi lampu, 0b01
	ldi	temp,low(RAMEND)
	out	SPL,temp	            ;init Stack Pointer		
	ldi	temp,high(RAMEND)
	out	SPH,temp
	

	ldi temp, 1<<CS11			; prescalar 256
	out TCCR1B, temp
	ldi temp, 1<<OCF1A			; inturrupt if compare true in T/C1B
	out TIFR, temp	
	ldi temp, 1<<OCIE1A			; Enable timer/counter1B compare int
	out TIMSK, temp
	ldi temp, $F4				
	out OCR1AH, temp
	ldi temp, $24				; Compared value, source https://www.avrfreaks.net/forum/1-sec-timer-using-internal-8mhz-osc-atmega-8
	out OCR1AL, temp
	ser temp
	out DDRB, temp				; Set port B as output
	sei
	rjmp forever

main:
	ldi temp, 0b11
	eor lampu, temp
	ret

forever:
	rjmp forever

ISR_TCOM1A:
	push temp
	in temp,SREG
	push temp

	clr temp
	out TCNT1H, temp
	out TCNT1L, temp
	rcall main
	out PORTB,lampu	; write Port B

	pop temp
	out SREG,temp
	pop temp
	reti
