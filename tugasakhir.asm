

; Pembuat:
; Zafir Rasyidi Taufik
; Ariell Zaky Prabaswara Ariza
; Aljihad Ijlal Nadhif Suyudi

.include "m8515def.inc"
.def SEED = r3
.def LEVELTIME = r5
.def LOKASICURSOR = r6
.def temp = r16
.def LEVELCOUNTER = r19
.def LEVELTIMENOW = r20

.org $00
	rjmp init

.org $04
	; 1 DETIK TELAH BERLALU
	rjmp addleveltimenow

init:
	ldi	temp, low(RAMEND)
	out	SPL, temp				; init Stack Pointer
	ldi	temp, high(RAMEND)
	out	SPH, temp				; init Stack Pointer

	; SETUP LCD HERE

	; SETUP LED HERE

	; SETUP TIMER HERE
		; TIMER 1 UNTUK WAKTU PER LEVEL
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
	ser temp
	out DDRB, temp				; Set port B as output
	sei

		; TIMER 0 UNTUK RANDOM GENERATOR
	ldi temp, 1<<CS00			; No prescalar, turn it on
	out TCCR0,temp

	; SETUP KEYPAD HERE


	rcall main

	; RESET

resettimer0:
	clr temp
	out TCNT0, temp
	ret

resettimer1:
	clr temp
	out TCNT1H, temp
	out TCNT1L, temp
	ret

addleveltimenow:

	push temp
	in temp,SREG
	push temp

	rcall resettimer1
	
	; add 1 to timer
	inc LEVELTIMENOW

	pop temp
	out SREG,temp
	pop temp

	reti

getname:

	; USE KEYPAD TO INPUT NAME

	; GET VALUE IN TCNT0
	; USE VALUE AS SEED FOR RANDOM
	get_seed:
		in temp, TCNT0		; get value in timer for seed
		tst temp
		breq get_seed		; prevent seed=0
	mov SEED, temp

	ret

getrandomnumber:

	; USING SEED, GENERATE NEXT RANDOM NUMBER
	; USE XORSHIFT ALGORITHM, https://en.wikipedia.org/wiki/Xorshift

	mov temp, SEED		; shift left by 2
	lsl temp
	lsl temp
	eor SEED, temp
	mov temp, SEED
	lsr temp			; shift right by 5
	lsr temp
	lsr temp
	lsr temp
	lsr temp
	eor SEED, temp
	mov temp, SEED
	lsl temp			; shift left by 3
	lsl temp
	lsl temp
	eor SEED, temp

	mov temp, SEED		; PUT VALUE IN temp


setuplayout:
	
	; EMPTY ENTIRE LAYOUT
	; USING RANDOM GENERATOR, SETUP LAYOUT
	; GET RANDOM VALUE, AND IMMEDIATE 31
	; CEK THAT LOCATION, IF ALREADY HAS NUMBER, ADD 1, AND IMMEDIATE 31
	; REPEAT 32 TIMES

movecursor:
	
	cekbisa:

		; LOKASICURSOR DALAM BATAS 0 - 31 (inklusif) ? BISA : TIDAK BISA

	; KIRI, BISA ? LOKASICURSOR -1
	; KANAN, BISA ? LOKASICURSOR +1
	; ATAS, BISA ? LOKASICURSOR -16
	; BAWAH, BISA ? LOKASICURSOR +16

opencard:

	; DAPAT DIBUKA ? BUKA, COUNTER KARTU YANG TERBUKA +1 : RETURN DARI FUNGSI
	; YANG DIBUKA SUDAH 2 ? CEK KALO SAMA, COUNTER +1, BUKA SELAMANYA : TUTUP KEDUANYA

closecard:

	; GANTI SPRITE JADI BLACK BOX
	; COUNTER KARTU YANG TERBUKA -1

main:
	
	; INPUT NAME FUNC, getname
	rcall getname

	; SAVE NAME IN FLASH MEMORY
	; NAME HAS MAX OF 8 BYTES

	; DELAY, GET READY TO START GAME
	; PREPARE LAYOUT
	; PREPARE TIMER

	; LAYOUT DISIMPAN DI SRAM
	; COUNTER UNTUK KETAHUI JIKA PASANGAN TELAH DITEMUKAN
	; COUNTER == 16 ? UDAH SELESAI
	; LEVELTIMENOW == LEVELTIME ? KALAH
	; TAMBAHKAN 1 KE GLOBAL LEVEL COUNTER
	; START NEXT LEVEL, LEVELTIME -1

	; JIKA HABIS WAKTU, GAME BERAKHIR
	; SCORE > HIGHSCORE ? HIGHSCORE = SCORE
	; TAMPILKAN NAMA DAN HIGHSCORE

	; ADA BUTTON UNTUK MAIN ULANG
	; DITEKAN ? DELAY, RJMP INIT


message_start:
.db "SIAP SIAP...", 0

message_habis_waktu:
.db "WAKTU HABIS!", 0

message_level_selesai:
.db "MANTAP!", 0

nama:
.db 0, 0, 0, 0, 0, 0, 0, 0, 0

highscore:
.db 0