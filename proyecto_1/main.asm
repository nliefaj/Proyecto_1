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
//*******************************************************************
//CONTADORES
//*******************************************************************
.DEF count_mode=R18
.DEF count_al_mode=R19
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
	LDI R16, 0b0010_0000
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

	SEI //habilitamos interrupcoines

	CLR count_mode
	CLR count_al_mode

LOOP:
	OUT PORTB, count_mode

//*******************************************************************
//SUBRUTINAS DE INTERRUPCIÓN
//*******************************************************************

ISR_PCINT1:
	PUSH R16
	IN R16,SREG
	PUSH R16

	INC count_mode
	//interrupción de modos

	POP R16
	OUT SREG,R16
	POP R16
	RETI
//*******************************************************************
//TABLA DE VALORES
//*******************************************************************
TABLA7SEG: .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71;


