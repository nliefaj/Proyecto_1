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
.DEF flags=R13
.DEF uni_conf=R14
.DEF dec_conf=R15
.DEF modo_btn=R18
.DEF counter=R19
.DEF segundos=R20
.DEF count_unidades=R21
.DEF count_decenas=R22
;.DEF count_umin=R23
;registro 24 único para mostrar valores
.DEF dia=R25
.DEF mes=R26

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
	
	LDI R16, 0b0010_0000//cambiar esto después de la prueba
	OUT DDRC, R16 //Set PINES C segpun esquema de entradas y salidas

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
	CLR uni_conf ;contador para cambiar displays
	CLR dec_conf
	CLR modo_btn
	LDI dia,0b000_0001
	LDI mes,0b001_0000


LOOP:
	//enciende el display que tiene que mostrar y deja que los valores se muestren a tiempo completo
	SBRC modo_btn,4
	RJMP ESTADOx1
	RJMP ESTADOx0
	RJMP LOOP
ESTADOx1:
	SBRC modo_btn,5
	RJMP ESTADO11 //en este estado se congigura la fecha
	//realiza el estado 01-->configurar hora
	LDI R16,0b0000_1111
	AND R16,uni_conf
	MOV R0,R16; primer display

	LDI R16,0b0000_1111
	AND R16,dec_conf
	MOV R1,R16;segundo display

	LDI R16,0b1111_0000
	AND R16,uni_conf
	SWAP R16
	MOV R2,R16;tercer diplay

	LDI R16,0b1111_0000
	AND R16,dec_conf
	SWAP R16
	MOV R12,R16 ;cuarto display
	CALL display
	RJMP LOOP
ESTADO11: 
	nop
	RJMP LOOP
ESTADO10:
	nop 
	RJMP LOOP
ESTADOx0:
	SBRC modo_btn,5
	RJMP ESTADO10 ;muestra la fecha
	//aquí se ejecuta el estado 00_mostrar hora
	LDI R16,0b0000_1111
	AND R16,count_unidades
	MOV R0,R16; primer display

	LDI R16,0b0000_1111
	AND R16,count_decenas
	MOV R1,R16;segundo display

	LDI R16,0b1111_0000
	AND R16,count_unidades
	SWAP R16
	MOV R2,R16;tercer diplay

	LDI R16,0b1111_0000
	AND R16,count_decenas
	SWAP R16
	MOV R12,R16 ;cuarto display
	CALL display
	RJMP LOOP

display:
	//MUESTRA EL RELOJ NORMAL
	SBI PORTB,PB0 
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL,R0
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
	ADD ZL,R1
	CLR R24
	LPM R24,Z //Load from program memory R16
	OUT PORTD,R24
	CALL delaybounce
	CBI PORTB,PB1
	CALL delaybounce
	CALL delaybounce

	//bloque para unidades de hora
	SBI PORTB,PB2
	SWAP R16
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL,R2
	CLR R24
	LPM R24,Z //Load from program memory R16
	OUT PORTD,R24
	CALL delaybounce
	CBI PORTB,PB2
	CALL delaybounce
	CALL delaybounce

	//bloque para decenas de hora
	SBI PORTB,PB3
	SWAP R16
	LDI ZH, HIGH(TABLA7SEG<<1)
	LDI ZL, LOW(TABLA7SEG<<1)
	ADD ZL,R12
	CLR R24
	LPM R24,Z //Load from program memory R16
	OUT PORTD,R24
	CALL delaybounce
	CBI PORTB,PB3
	CALL delaybounce
	CALL delaybounce

	RET
	
	//bloque unidades de minuto


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

	LDI R16,1
	OUT TCNT0,R16

	INC counter
	CPI counter, 1
	BRNE SALTO
	CLR counter

	;INC segundos
	;CPI segundos,60
	/*SBRC flags,0
	CALL set_hora*/
	RJMP empieza
	RJMP SALTO

/*set_hora:
	CLR count_unidades
	CLR count_decenas
	LDI R17,0b0000_1111
	AND R17,uni_conf*/


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
	INC dia
	MOV R16,dia
	ANDI R16,0b0000_1111
	CPI R16,0b0000_1001//verifica si dia es 
	BREQ verificar_feb
	CPI R16,0b0000_0001
	BREQ verificar_mes30
	CPI R16,0b0000_0010
	BREQ verificar_mes31
	RJMP SALTO

verificar_feb:
	MOV R16,mes 
	CPI R16,0b0000_0010//verificar si mes =0/2
	BREQ febrero
	RJMP SALTO

febrero:
	INC mes
	LDI dia,0b0000_0001
	RJMP SALTO

verificar_mes30
	MOV R16,mes
	CPI R16,0b0000_0100;verificar si mes es 0/4   
	BREQ mes30
	CPI R16,0b0000_0110;0/6   
	BREQ mes30
	CPI R16,0b0000_1001; 0/9  
	BREQ septiembre
	CPI R16, 0b0001_0001; 1/1
	BREQ mes_30
	RJMP SALTO

septiembre:
	MOV R16,mes
	SWAP R16
	INC R16
	SWAP R16
	MOV mes,R16
	LDI dia,0b0000_0001
	RJMP SALTO

mes30:
	INC mes
	LDI dia,0b0000_0001
	RJMP SALTO

verificar_mes31:
	MOV R16,mes
	CPI R16,0b0000_0001;verificar si mes es 0/1  
	BREQ mes31
	CPI R16,0b0000_0101;0/3   
	BREQ mes31
	CPI R16,0b0000_0101; 0/5 
	BREQ mes_31
	CPI R16, 0b0000_1001; 07
	BREQ mes_31
	CPI R16, 0b0000_1000; 08
	BREQ mes_31
	CPI R16, 0b0001_0000; 10
	BREQ mes_31
	CPI R16, 0b0001_0010; 12
	BREQ diciembre
	RJMP SALTO

mes_31:
	INC mes
	LDI dia,0b0000_0001
	RJMP SALTO

diciembre:
	LDI mes,0b0000_0001
	LDI dia,0b0000_0001
	RJMP SALTO



overflow_udia:
	//trabajar con decenas de dias 0b1111_xxxx


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
	
	SBRS modo_btn,7
	RJMP INT_1
	RJMP INT_2
	RJMP ISR_POP
	
INT_1:
	LDI R16, 0b1000_0000
	OR modo_btn,R16
	IN R17,PINC
	RJMP ISR_POP

INT_2:
	LDI R16,0b0111_1111
	AND modo_btn,R16
	CPI R17,0b00001_1110
	BREQ btn1
	CPI R17,0b0001_1101
	BREQ btn2
	CPI R17,0b00001_1011
	BREQ btn3
	;CPI R17,0b0111
	;BREQ btn4
	RJMP ISR_POP

btn1:
	SBI PORTB,PB5
	SWAP modo_btn
	INC modo_btn
	LDI R16, 0b0000_1111
	AND R16,modo_btn
	SWAP modo_btn
	CPI R16,0b0000_0101
	BREQ overflow_modo
	RJMP ISR_POP

overflow_modo:
	LDI R16,0b0000_1111
	AND modo_btn,R16
	RJMP ISR_POP

btn2:
	MOV R16,modo_btn
	SWAP R16
	ANDI R16,0b0000_1111
	CPI R16, 0b0000_0001
	BREQ cambiar_display
	CPI r16,0b0000_0011
	BREQ cambiar_display
	CPI R16,0b0000_0100
	BREQ cambiar_display
	RJMP ISR_POP
cambiar_display:
	INC modo_btn
	MOV R16,modo_btn
	ANDI R16,0b0000_1111
	CPI R16,0b0000_0101
	BREQ overflow_displays
	RJMP ISR_POP
overflow_displays:
	LDI R16,0b1111_0000
	AND modo_btn,R16
	RJMP ISR_POP

btn3:
	MOV R16, modo_btn
	SWAP R16
	ANDI R16,0b0000_1111
	CPI R16,0b0000_0001
	BREQ configurar_hora
	RJMP ISR_POP

configurar_hora:
	LDI R17, 0b0000_1111
	AND R17,modo_btn
	CPI R17,1
	BREQ cambiar_disp1
	CPI R17,2
	BREQ cambiar_disp2
	CPI R17,3
	BREQ cambiar_disp3
	CPI R17,4
	BREQ cambiar_disp4
	RJMP LOOP

cambiar_disp1:
	INC uni_conf
	MOV R17,uni_conf
	ANDI R17,0b0000_1111
	CPI R17,0b0000_1010
	BREQ overflow_disp1
	RJMP ISR_POP

overflow_disp1:
	LDI R16,0b1111_0000
	AND R16,uni_conf
	MOV uni_conf, R16
	RJMP ISR_POP

cambiar_disp2:
	INC dec_conf
	MOV R17,dec_conf
	ANDI R17,0b0000_1111
	CPI R17,0b0000_0110
	BREQ overflow_disp2
	RJMP ISR_POP

overflow_disp2:
	LDI R16,0b1111_0000
	AND R16,dec_conf
	MOV dec_conf,R16
	RJMP ISR_POP

cambiar_disp3:
	SWAP uni_conf
	INC uni_conf
	MOV R17,uni_conf
	SWAP uni_conf
	ANDI R17,0b0000_1111
	CPI R17,0b0000_0100
	BREQ ver_horaconf
	CPI R17,0b0000_1010
	BREQ overflow_disp3
	RJMP ISR_POP

ver_horaconf:
	LDI R17,0b1111_0000
	AND R17,dec_conf
	SWAP R17
	CPI R17,0b0000_0010
	RJMP overflow_disp4
	RJMP ISR_POP

overflow_disp3:
	LDI R16,0b0000_1111
	AND R16,uni_conf
	MOV uni_conf,R16
	RJMP ISR_POP

cambiar_disp4:
	SWAP dec_conf
	INC dec_conf
	MOV R17,dec_conf
	SWAP dec_conf
	ANDI R17,0b0000_1111
	CPI R17,0b0000_0011
	BREQ overflow_disp4
	RJMP ISR_POP

overflow_disp4:
	CLR dec_conf
	CLR uni_conf
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


