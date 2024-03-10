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
.org 0x08				//Vector interrupçion puerto c (entrada de los botones)
	JMP ISR_PCINT1
.org 0x0020 //interrupción timer0
	JMP ISR_TIMER
//*******************************************************************
//CONTADORES
//*******************************************************************
;.DEF al_flag=R14; no se puede utilizar
;fecha evaluarla en el registro 15
;registro 16 y 17 para usarlos como variables fáciles
.DEF mode=R18
.DEF counter=R19
.DEF segundos=R20
.DEF count_unidades=R21
.DEF count_decenas=R22
;.DEF count_umin=R23
;registro 24 único para mostrar valores
;.DEF count_dmin=R25

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
	
	LDI R16, 0b0001_1111//cambiar esto después de la prueba
	OUT DDRC, R16 //Set PINES C segpun esquema de entradas y salidas

	LDI r16,0b0001_1111 //habilitamos pullup para todos los botones del puerto C
	OUT PORTC,r16

	LDI R16, 0b0111_1111//Configura el puerto D (7seg) como salida
	OUT DDRD,R16

	LDI R16, 0b0001_1111
	OUT DDRB, R16 //Configura el puerto B como salida segun esquema

	LDI R16, 0b0001_1111 //coloca la máscara a pines del puerto c con botón
	STS PCMSK1, R16	

	LDI R16,0b0000_0010//pines de evaluación de interrupción (PORTC)
	STS PCICR,R16


	//TIMER0
	
	LDI R16, 0b0000_0101//preescaler de 1024
	OUT TCCR0B,R16

	LDI R16,1
	OUT TCNT0,R16

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
	CLR counter
	CLR segundos


LOOP:
	//enciende el display que tiene que mostrar y deja que los valores se muestren a tiempo completo
	//bloque unidades de minuto
	SBI PORTB,PB0
	LDI R16,0b0000_1111
	AND R16,count_unidades
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL,R16
	CLR R24
	LPM R24,Z //Load from program memory R16
	OUT PORTD,R24
	CALL delaybounce
	CBI PORTB,PB0
	CALL delaybounce
	CALL delaybounce

	//bloque para decenas de minuto
	SBI PORTB,PB1
	LDI R16,0b0000_1111
	AND R16,count_decenas
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL,R16
	CLR R24
	LPM R24,Z //Load from program memory R16
	OUT PORTD,R24
	CALL delaybounce
	CBI PORTB,PB1
	CALL delaybounce
	CALL delaybounce

	//bloque para unidades de hora
	SBI PORTB,PB2
	LDI R16,0b1111_0000
	AND R16,count_unidades
	SWAP R16
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL,R16
	CLR R24
	LPM R24,Z //Load from program memory R16
	OUT PORTD,R24
	CALL delaybounce
	CBI PORTB,PB2
	CALL delaybounce
	CALL delaybounce

	//bloque para decenas de hora
	SBI PORTB,PB3
	LDI R16,0b1111_0000
	AND R16,count_decenas
	SWAP R16
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL,R16
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
	RJMP empieza
	RJMP SALTO

empieza:
	CLR segundos
	INC count_unidades
	LDI R16,0b0000_1111
	AND R16,count_unidades
	CPI R16, 0b0000_1010
	BREQ overflow
	RJMP SALTO

SALTO:
	POP R16
	OUT SREG,R16
	POP R16
	RETI

overflow:
	LDI R16,0b1111_0000
	AND count_unidades,R16
	INC count_decenas
	LDI R16,0b0000_1111
	AND R16,count_decenas
	CPI R16, 0b0000_0110
	BREQ overflow_decenas
	RJMP SALTO

overflow_decenas:
	;trabajar con unidades de hora
	LDI R16,0b1111_0000
	AND count_decenas,R16;pomner en 0 las unidades de minutos
	LDI R16,0b0000_1111
	SWAP count_unidades
	INC count_unidades
	AND R16,count_unidades
	SWAP count_unidades
	CPI R16,0b0000_0100
	BREQ verificar_hora
	CPI R16,0b0000_1010
	BREQ overflow_uhora
	RJMP SALTO

overflow_uhora:
	;trabajar con decenas de hora
	LDI R16,0b0000_1111
	AND count_unidades,R16
	SWAP count_decenas
	INC count_decenas
	AND R16,count_decenas
	SWAP count_decenas
	RJMP SALTO

verificar_hora:
	LDI R16,0b1111_0000
	AND R16,count_decenas
	SWAP R16
	CPI R16,0b0000_0010
	BREQ ultima_hora
	RJMP SALTO

ultima_hora:
	LDI count_unidades,0b0000_0000
	LDI count_decenas,0b0000_0000
	RJMP SALTO

delaybounce:
	LDI r16,250//250 para notar el valor de muestreo en los display
	delay:
		DEC r16
		BRNE delay
	RET

//*******************************************************************
//INTERRUPCIÓN DE BOTONES
//*******************************************************************
ISR_PCINT1:
	PUSH R16
	IN R16,SREG
	PUSH R16



	LDI R16,0b0001_1111 
	IN R17,PORTC
	COM R17
	AND R17,R16

	RJMP ISR_POP

/*INC_MODE:
	INC mode
	CPI mode,0b0100
	BREQ overflow_mode
	RJMP ISR_POP

ESTADOx1:
	SBRS mode,1
	RJMP ESTADO_01 ;configurar hora
	;RJMP ESTADO 11 ;configurar fecha
	RJMP ISR_POP

ESTADO_01:*/
	
overflow_mode:
	CLR mode
	RJMP ISR_POP

	
ISR_POP:
	POP R16
	OUT SREG,R16
	POP R16
	RETI

//*******************************************************************
//TABLA DE VALORES
//*******************************************************************
TABLA7SEG: .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71;


