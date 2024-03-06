//*******************************************************************
//ENCABEZADO
//*******************************************************************
// UNIVERSIDAD DEL VALLE DE GUATEMALA
// PROGRAMACIÓN DE MICROCONTROLADORES
// PRE-LABORATORIO 3
// AUTOR: LEFAJ, NATHALIE FAJARDO
//CREADO: 3/2/2024 10:18:35 PM
//*******************************************************************
//LIBRERÍA
.INCLUDE "M328PDEF.inc"
.cseg
//*******************************************************************
//INTERRUPCIONES
//*******************************************************************
.org 0x00
	JMP MAIN			//Vector reset
;.org 0x08				//Vector interrupçion puerto c (entrada de los botones)
;	JMP ISR_PCINT1
.org 0x0020 //interrupción timer0
	JMP ISR_TIMER
//*******************************************************************
//CONTADORES
//*******************************************************************
;.DEF count_state=R18
;.DEF count_al_mode=R19
.DEF count_unidades=R21
.DEF count_decenas=R22
.DEF count_umin=R23
.DEF count_dmin=R25
.DEF counter=R18
.DEF segundos=R19
//*******************************************************************
//STACK
//*******************************************************************
LDI R16, LOW(RAMEND)
OUT SPL,R16
LDI R17,HIGH (RAMEND)
OUT SPH, R17
//*******************************************************************
//CONFIGURACION
//*******************************************************************
MAIN:
	LDI R16, LOW(RAMEND)
	OUT SPL,R16
	LDI R17,HIGH(RAMEND)
	OUT SPH,R17

	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	LPM R16,Z

SETUP:
	
	LDI R16, 0b0000_0000//cambiar esto después de la prueba
	OUT DDRC, R16 //Set PINES C segpun esquema de entradas y salidas

	LDI r16,0b0001_1111 //habilitamos pullup para todos los botones del puerto C
	OUT PORTC,r16

	LDI R16, 0b0111_1111//Configura el puerto D (7seg) como salida
	OUT DDRD,R16

	LDI R16, 0b0001_1111
	OUT DDRB, R16 //Configura el puerto B como salida segun esquema

	LDI R16, 0b0001_1111 //coloca la máscara a pines del puerto c con botón
	STS PCMSK1, R16	

	LDI R16,0b0010//pines de evaluación de interrupción (PORTC)
	STS PCICR,R16


	//TIMER0
	
	LDI R16, 0b0000_0101//preescaler de 1024
	STS TCCR0B,R16

	LDI R16,178
	STS TCNT0,R16

	LDI R16,0b0000_0001
	STS TIMSK0,R16
	//PINES RX0 y RX1
	LDI R16,0
	STS UCSR0B,R16

	CALL delayT0

	SEI //habilitamos interrupcoines

	;CLR count_state
	;CLR count_al_mode
	CLR count_unidades
	CLR count_decenas
	CLR count_umin
	CLR count_dmin
	CLR counter
	CLR segundos


LOOP:
	//enciende el display que tiene que mostrar y deja que los valores se muestren a tiempo completo
	//bloque unidades de minuto
	SBI PORTB,PB0
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL,count_unidades
	CLR R24
	LPM R24,Z //Load from program memory R16
	OUT PORTD,R24
	CALL delaybounce
	CBI PORTB,PB0
	CALL delaybounce
	CALL delaybounce

	//bloque para decenas de minuto
	SBI PORTB,PB1
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL,count_decenas
	CLR R24
	LPM R24,Z //Load from program memory R16
	OUT PORTD,R24
	CALL delaybounce
	CBI PORTB,PB1
	CALL delaybounce
	CALL delaybounce

	//bloque para unidades de hora
	SBI PORTB,PB2
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL,count_umin
	CLR R24
	LPM R24,Z //Load from program memory R16
	OUT PORTD,R24
	CALL delaybounce
	CBI PORTB,PB2
	CALL delaybounce
	CALL delaybounce

	//bloque para decenas de hora
	SBI PORTB,PB3
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL,count_dmin
	CLR R24
	LPM R24,Z //Load from program memory R16
	OUT PORTD,R24
	CALL delaybounce
	CBI PORTB,PB3
	CALL delaybounce
	CALL delaybounce

	RJMP LOOP

//*******************************************************************
//SUBRUTINAS DE INTERRUPCIÓN
//*******************************************************************

delayT0:
	LDI R16, (1 << CS02) | (1 << CS00)
	OUT TCCR0B, R16

	LDI R16,1
	OUT TCNT0, R16

	RET
ISR_TIMER:
	PUSH R16
	IN R16,SREG
	PUSH R16

	//SBI PORTB,PB5

	LDI R16,178
	OUT TCNT0,R16

	INC counter
	CPI counter, 178
	BRNE SALTO
	CLR counter

	INC segundos
	CPI segundos,60
	BREQ empieza
	RJMP SALTO

empieza:
	INC count_unidades
	CPI count_unidades, 0b0000_1010
	BREQ overflow
	RJMP SALTO

SALTO:
	POP R16
	OUT SREG,R16
	POP R16
	RETI

overflow:
	LDI count_unidades,0b0000
	INC count_decenas
	CPI count_decenas, 0b0000_0110
	BREQ overflow_decenas
	RJMP SALTO

overflow_decenas:
	LDI count_decenas,0b0000_0000
	INC count_umin
	CPI count_umin,0b0000_0101
	BREQ verificar_hora
	CPI count_umin,0b0000_1010
	BREQ overflow_umin
	RJMP SALTO

overflow_umin:
	LDI count_umin,0b0000_0000
	INC count_dmin
	RJMP SALTO

verificar_hora:
	CPI count_dmin,2
	BREQ ultima_hora
	RJMP SALTO

ultima_hora:
	LDI count_umin,0b0000_0000
	LDI count_dmin,0b0000_0000
	RJMP SALTO

delaybounce:
	LDI r16,250//250 para notar el valor de muestreo en los display
	delay:
		DEC r16
		BRNE delay
	RET
/*ISR_PCINT1:
	PUSH R16
	IN R16,SREG
	PUSH R16

	IN R16, PINC
	SBRS r16, 0 //PC0 igual a 1?
	RJMP ISR_POP
	RJMP CAMBIO_MODO

CAMBIO_MODO:
	INC count_state
	CPI count_state,3
	BREQ OVERFLOW
	CPI count_state,0
	BREQ ISR_POP

OVERFLOW:
	CLR count_state
	RJMP ISR_POP
ISR_POP:
	POP R16
	OUT SREG,R16
	POP R16
	RETI*/

//*******************************************************************
//TABLA DE VALORES
//*******************************************************************
TABLA7SEG: .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71;


