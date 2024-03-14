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
;.org 0x0012 //interrupción timer0
;	JMP ISR_TIMER2
//*******************************************************************
//CONTADORES
//*******************************************************************
;.DEF al_flag=R14; no se puede utilizar
;fecha evaluarla en el registro 15
;registro 16 y 17 para usarlos como variables fáciles
.DEF uni_conf=R14
.DEF dec_conf=R15
.DEF modo_btn=R18
.DEF counter=R19
.DEF segundos=R20
.DEF count_unidades=R21
.DEF count_decenas=R22
;registro 24 único para mostrar valores
.DEF dia=R25
.DEF mes=R23
.DEF mes_config=R10
.DEF dia_config=R11
.DEF alarma_uni=R12
.DEF alarma_dec=R13
.DEF counter2=R5

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

	LDI R16,178
	OUT TCNT0,R16

	LDI R16,0b0000_0001
	STS TIMSK0,R16

	//TIMER2
	/*
	LDI R16, 0b0000_0111//preescaler de 1024
	OUT TCCR2B,R16

	LDI R16,217
	OUT TCNT2,R16

	LDI R16,0b0000_0001
	STS TIMSK2,R16*/


	//PINES RX0 y RX1
	LDI R16,0
	STS UCSR0B,R16

	CALL delayT0
	;CALL delayT2

	SEI //habilitamos interrupcoines

	;CLR count_state
	;CLR count_al_mode
	CLR count_unidades
	CLR counter2
	CLR count_decenas
	CLR counter
	CLR segundos
	CLR uni_conf ;contador para cambiar displays
	CLR dec_conf
	CLR modo_btn
	CLR mes_config
	CLR dia_config
	CLR alarma_uni
	CLR alarma_dec
	LDI dia,0b000_0001
	LDI mes,0b000_0001


LOOP:
	//enciende el display que tiene que mostrar y deja que los valores se muestren a tiempo completo
	SBRC alarma_dec,7
	JMP alarma_activada
	SBRC modo_btn,4
	JMP ESTADOx1
	JMP ESTADOx0
	JMP LOOP
alarma_activada:
	MOV R16,count_unidades
	MOV R17,alarma_uni
	SUB R16,R17
	CPI R16,0b0000_0000
	BRGE evaluar_hora_al
	JMP LOOP

evaluar_hora_al:
	MOV R16,count_decenas
	MOV R17,alarma_dec
	SUB R16,R17
	CPI R16,0b0000_0000
	BRGE prender_buzz
	JMP LOOP

prender_buzz:
	SBI PORTB,PB4
	RJMP LOOP

ALARMA:
	SBI PORTB,PB4
	LDI R16,0b0000_1111
	AND R16,alarma_uni
	MOV R0,R16; primer display

	LDI R16,0b0000_1111
	AND R16,alarma_dec
	MOV R1,R16;segundo display

	LDI R16,0b1111_0000
	AND R16,alarma_uni
	SWAP R16
	MOV R2,R16;tercer diplay

	LDI R16,0b1111_0000
	AND R16,alarma_dec
	SWAP R16
	MOV R3,R16 ;cuarto display
	CALL display
	JMP LOOP
ESTADOx1:
	SBRC modo_btn,5
	JMP ESTADO11 //en este estado se congigura la fecha
	//realiza el estado 01-->configurar hora
	SBI PORTB,PB4
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
	MOV R3,R16 ;cuarto display
	CALL display
	JMP LOOP
ESTADO11: 
	//configura fecha
	IN R16,PINB
	ORI R16,0b0001_0000
	OUT PORTB,R16

	LDI R16,0b0000_1111
	AND R16,dia_config
	MOV R0,R16; primer display

	LDI R16,0b1111_0000
	AND R16,dia_config
	SWAP R16
	MOV R1,R16;segundo display

	LDI R16,0b0000_1111
	AND R16,mes_config
	MOV R2,R16;tercer diplay

	LDI R16,0b1111_0000
	AND R16,mes
	SWAP R16
	MOV R3,R16 ;cuarto display
	CALL display
	JMP LOOP
ESTADO10:;muestra fecha
	CBI PORTB,PB4
	LDI R16,0b0000_1111
	AND R16,dia
	MOV R0,R16; primer display

	LDI R16,0b1111_0000
	AND R16,dia
	SWAP R16
	MOV R1,R16;segundo display

	LDI R16,0b0000_1111
	AND R16,mes
	MOV R2,R16;tercer diplay

	LDI R16,0b1111_0000
	AND R16,mes
	SWAP R16
	MOV R3,R16 ;cuarto display
	CALL display
	JMP LOOP
apagar_prender:
	CLR counter2
	SBIC PORTB,PB4
	CBI PORTB,PB4
    SBIS PORTB,PB4
	SBI PORTB,PB4
	JMP ESTADOx0
ESTADOx0:
	SBRC modo_btn,5
	JMP ESTADO10 ;muestra la fecha
	SBRC modo_btn,6; pregunto si el bit 6 esta en 0, si sí entonces muestra el reloj normal, sino significa que esta en modo config alamra
	JMP ALARMA 
	//aqui se ejecuta el estado 00_mostrar hora
	MOV R16,counter2
	CPI R16,50
	BREQ apagar_prender
	CBI PORTB,PB4
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
	MOV R3,R16 ;cuarto display
	CALL display
	JMP LOOP

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
	ADD ZL,R3
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

	LDI R16,178
	OUT TCNT0, R16

	RET
/*delayT2:
	LDI R16,0b0000_0111
	OUT TCCR2B, R16

	LDI R16,217
	OUT TCNT2, R16

	RET*/
ISR_TIMER:
	PUSH R16
	IN R16,SREG
	PUSH R16

	//SBI PORTB,PB5

	LDI R16,178
	OUT TCNT0,R16

	INC counter
	INC counter2
	CPI counter, 178
	BRNE SALTO
	CLR counter

	INC segundos
	CPI segundos,60
	BREQ empieza
	/*SBRC flags,0
	CALL set_hora*/
	JMP SALTO

/*set_hora:
	CLR count_unidades
	CLR count_decenas
	LDI R17,0b0000_1111
	AND R17,uni_conf*/


empieza:
	/*MOV R16,count_unidades
	MOV R17,alarma_uni
	SUB R16,R17
	CPI R16,0b0000_0000
	BREQ decenas_alarma*/
	CLR segundos
	INC count_unidades
	LDI R16,0b0000_1111
	AND R16,count_unidades
	CPI R16, 0b0000_1010
	BREQ overflow
	JMP SALTO

decenas_alarma:
	MOV R16,count_decenas
	MOV R17, alarma_dec
	SUB R16,R17
	CPI R16,0b0000_0000
	BREQ sonar_alarma
	RJMP SALTO

sonar_alarma:
	SBI PORTB,PB4

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
	JMP SALTO

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
	JMP SALTO

overflow_uhora:
	;trabajar con decenas de hora
	LDI R16,0b0000_1111
	AND count_unidades,R16
	SWAP count_decenas
	INC count_decenas
	AND R16,count_decenas
	SWAP count_decenas
	JMP SALTO

verificar_hora:
	LDI R16,0b1111_0000
	AND R16,count_decenas
	SWAP R16
	CPI R16,0b0000_0010
	BREQ ultima_hora
	JMP SALTO

ultima_hora:
	LDI count_unidades,0b0000_0000
	LDI count_decenas,0b0000_0000
	INC dia
	MOV R16,dia
	CPI R16,0b0010_1001//verifica si dia es 29
	BREQ verificar_feb
	CPI R16,0b0011_0001//dia 31
	BREQ verificar_mes30
	CPI R16,0b0011_0010//dia32
	BREQ verificar_mes31
	ANDI R16,0b0000_1111
	CPI R16,0b0000_1010//dia 9 en mes normal
	BREQ overflow_dia
	JMP SALTO

verificar_feb:
	MOV R16,mes 
	CPI R16,0b0000_0010//verificar si mes =0/2
	BREQ febrero
	JMP SALTO

febrero:
	INC mes
	LDI dia,0b0000_0001
	JMP SALTO

verificar_mes30:
	MOV R16,mes
	CPI R16,0b0000_0100;verificar si mes es 0/4   
	BREQ mes_30
	CPI R16,0b0000_0110;0/6   
	BREQ mes_30
	CPI R16,0b0000_1001; 0/9  
	BREQ septiembre
	CPI R16, 0b0001_0001; 1/1
	BREQ mes_30
	JMP SALTO

septiembre:
	MOV R16,mes
	SWAP R16
	INC R16
	SWAP R16
	MOV mes,R16
	LDI dia,0b0000_0001
	JMP SALTO

mes_30:
	INC mes
	LDI dia,0b0000_0001
	JMP SALTO

verificar_mes31:
	MOV R16,mes
	CPI R16,0b0000_0001;verificar si mes es 0/1  
	BREQ mes_31
	CPI R16,0b0000_0011;0/3   
	BREQ mes_31
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
	JMP SALTO

mes_31:
	INC mes
	LDI dia,0b0000_0001
	JMP SALTO

diciembre:
	LDI mes,0b0000_0001
	LDI dia,0b0000_0001
	JMP SALTO

overflow_dia:
	MOV R16,dia
	ANDI R16,0b1111_0000
	SWAP R16
	INC R16
	SWAP R16
	MOV dia,R16
	JMP SALTO


delaybounce:
	LDI r16,250//250 para notar el valor de muestreo en los display
	delay:
		DEC r16
		BRNE delay
	RET

//*******************************************************************
//TIMER2
//*******************************************************************
/*ISR_TIMER2:
	PUSH R16
	IN R16,SREG
	PUSH R16

	//SBI PORTB,PB5

	LDI R16,217
	OUT TCNT2,R16

	INC counter2
	CPI counter2, 217
	BRNE TIMER2_POP
	CLR counter

	SBIC PORTC,PC5
	CBI PORTC,PC5
	SBI PORTC,PC5
	
	RJMP TIMER2_POP

TIMER2_POP:
	POP R16
	OUT SREG,R16
	POP R16
	RETI*/
//*******************************************************************
//INTERRUPCIÓN DE BOTONES
//*******************************************************************
ISR_PCINT1:
	PUSH R16
	IN R16,SREG
	PUSH R16
	
	SBRS modo_btn,7
	JMP INT_1
	JMP INT_2
	JMP ISR_POP
	
INT_1:
	LDI R16, 0b1000_0000
	OR modo_btn,R16
	IN R17,PINC
	JMP ISR_POP

INT_2:
	LDI R16,0b0111_1111
	AND modo_btn,R16
	CPI R17,0b00001_1110
	BREQ btn1
	CPI R17,0b0001_1101
	BREQ btn2
	CPI R17,0b00001_1011
	BREQ btn3
	CPI R17,0b0001_0111
	BREQ ir_a_btn4
	CPI R17,0b0000_1111
	BREQ ir_a_btn5
	JMP ISR_POP

ir_a_btn5:
	JMP btn5

btn1:
	SWAP modo_btn
	INC modo_btn
	LDI R16, 0b0000_1111
	AND R16,modo_btn
	SWAP modo_btn
	CPI R16,0b0000_0001
	BREQ set_horaconf_clear
	CPI R16,0b0000_0011
	BREQ set_fechaconf_clear
	CPI R16,0b0000_0100
	BREQ configurar_alarma_jmp
	CPI R16,0b0000_0101 
	BREQ overflow_modo
	JMP ISR_POP

configurar_alarma_jmp:
	JMP configurar_alarma

set_horaconf_clear:
	CLR  uni_conf
	CLR dec_conf
	JMP ISR_POP

set_fechaconf_clear:
	CLR mes_config
	CLR dia_config
	JMP ISR_POP

overflow_modo:
	LDI R16,0b0000_1111
	AND modo_btn,R16
	JMP ISR_POP

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
	JMP ISR_POP
cambiar_display:
	INC modo_btn
	MOV R16,modo_btn
	ANDI R16,0b0000_1111
	CPI R16,0b0000_0100
	BREQ overflow_displays
	JMP ISR_POP
overflow_displays:
	LDI R16,0b1111_0000
	AND modo_btn,R16
	JMP ISR_POP
ir_a_btn4:
	JMP btn4
btn3:
	MOV R16, modo_btn
	SWAP R16
	ANDI R16,0b0000_1111
	CPI R16,0b0000_0001
	BREQ configurar_hora
	CPI R16,0b0000_0011
	BREQ configurar_fecha
	CPI R16,0b0000_0100
	BREQ configurar_alarma
	JMP ISR_POP

configurar_hora:
	LDI R17, 0b0000_1111
	AND R17,modo_btn
	CPI R17,0
	BREQ cambiar_disp1
	CPI R17,1
	BREQ cambiar_disp2_jmp
	CPI R17,2
	BREQ cambiar_disp3_jmp
	CPI R17,3
	BREQ cambiar_disp4_jmp
	JMP ISR_POP

cambiar_disp2_jmp:
	JMP cambiar_disp2
cambiar_disp3_jmp:
	JMP cambiar_disp3
cambiar_disp4_jmp:
	JMP cambiar_disp4


configurar_fecha:
	LDI R17, 0b0000_1111
	AND R17,modo_btn
	CPI R17,0
	BREQ cambiar_disp1_fjmp
	CPI R17,1
	BREQ cambiar_disp2_fjmp
	CPI R17,2
	BREQ cambiar_disp3_fjmp
	CPI R17,3
	BREQ cambiar_disp4_fjmp
	JMP ISR_POP

cambiar_disp1_fjmp:
	JMP cambiar_disp1_f
cambiar_disp2_fjmp:
	JMP cambiar_disp2_f
cambiar_disp3_fjmp:
	JMP cambiar_disp3_f
cambiar_disp4_fjmp:
	JMP cambiar_disp4_f

configurar_alarma:
	LDI R17, 0b0000_1111
	AND R17,modo_btn
	CPI R17,0
	BREQ cambiar_disp1_ajmp
	CPI R17,1
	BREQ cambiar_disp2_ajmp
	CPI R17,2
	BREQ cambiar_disp3_ajmp
	CPI R17,3
	BREQ cambiar_disp4_ajmp
	JMP ISR_POP
	JMP ISR_POP

cambiar_disp1_ajmp:
	JMP cambiar_disp1_a
cambiar_disp2_ajmp:
	JMP cambiar_disp2_a
cambiar_disp3_ajmp:
	JMP cambiar_disp3_a
cambiar_disp4_ajmp:
	JMP cambiar_disp4_a

//CONFIGURACION SUMAR HORA

cambiar_disp1:
	;CLR segundos
	INC uni_conf
	MOV R17,uni_conf
	ANDI R17,0b0000_1111
	CPI R17,0b0000_1010
	BREQ overflow_disp1
	MOV count_unidades,uni_conf
	MOV count_decenas,dec_conf
	CLR segundos
	JMP ISR_POP

overflow_disp1:
	LDI R16,0b1111_0000
	AND R16,uni_conf
	MOV uni_conf, R16
	JMP ISR_POP


cambiar_disp2:
	INC dec_conf
	MOV R17,dec_conf
	ANDI R17,0b0000_1111
	CPI R17,0b0000_0110
	BREQ overflow_disp2
	MOV count_unidades,uni_conf
	MOV count_decenas,dec_conf
	CLR segundos
	JMP ISR_POP

overflow_disp2:
	LDI R16,0b1111_0000
	AND R16,dec_conf
	MOV dec_conf,R16
	JMP ISR_POP

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
	MOV count_unidades,uni_conf
	MOV count_decenas,dec_conf
	CLR segundos
	JMP ISR_POP

ver_horaconf:
	LDI R17,0b1111_0000
	AND R17,dec_conf
	SWAP R17
	CPI R17,0b0000_0010
	BREQ overflow_disp4_a
	JMP ISR_POP

overflow_disp3:
	LDI R16,0b0000_1111
	AND R16,uni_conf
	MOV uni_conf,R16
	JMP ISR_POP

cambiar_disp4:
	LDI R16,0b1111_0000
	AND R16,uni_conf
	SWAP dec_conf
	INC dec_conf
	MOV R17,dec_conf
	SWAP dec_conf
	ANDI R17,0b0000_1111
	CPI R17,0b0000_0010
	BREQ desfase_hora
	CPI R17,0b0000_0011
	BREQ overflow_disp4_a
	MOV count_unidades,uni_conf
	MOV count_decenas,dec_conf
	CLR segundos
	JMP ISR_POP

overflow_disp4_a:
	CLR dec_conf
	CLR uni_conf
	JMP ISR_POP

desfase_hora:
	CPI R16,0b0000_0011
	BRGE overflow_uni_dec
	RJMP ISR_POP

overflow_uni_dec:
	MOV R17,uni_conf
	ANDI R17,0b0000_1111
	ORI R17,0b0011_0000
	MOV uni_conf,R17
	RJMP ISR_POP


//CONFIGURACION PARA SUMAR FECHA
cambiar_disp1_f:
	INC dia_config
	MOV R16, dia_config
	ANDI R16,0b0000_1111
	CPI R16,0b0000_1010
	BREQ overflow_disp1_f
	MOV dia,dia_config
	MOV mes,mes_config
	JMP ISR_POP
overflow_disp1_f:
	MOV R16,dia_config
	ANDI R16,0b1111_0000
	MOV dia_config,R16
	JMP ISR_POP
cambiar_disp2_f:
	SWAP dia_config
	INC dia_config
	MOV R16,dia_config
	SWAP dia_config
	ANDI R16,0b0000_1111
	CPI R16,0b0000_0010
	BREQ verificar_udia
	CPI R16,0b0000_0011
	BREQ no_mas_de_31d
	CPI R16,0b0000_0100
	BREQ overflow_disp2_f
	MOV dia,dia_config
	MOV mes,mes_config
	JMP ISR_POP
no_mas_de_31d:
	MOV R17,mes_config
	CPI R17,0b0000_0100
	BREQ mes_30_dias
	CPI R17,0b0000_0110
	BREQ mes_30_dias
	CPI R17,0b0000_1001
	BREQ mes_30_dias
	CPI R17,0b0001_0001
	BREQ mes_30_dias
	MOV R16,dia_config
	CPI R16,0b0011_0010
	BRGE mes_31_dias
	JMP ISR_POP
mes_31_dias:
	MOV R16,dia_config
	ANDI R16,0b1111_0000
	MOV dia_config,R16
	JMP ISR_POP
mes_30_dias:
	MOV R16,dia_config
	ANDI R16,0b1111_0000
	MOV dia_config,R16
	JMP ISR_POP
overflow_disp2_f:
	MOV R16,dia_config
	ANDI R16,0b0000_1111
	MOV dia_config,R16
	RJMP ISR_POP
verificar_udia:
	MOV R16,mes_config
	CPI R16,0b0000_0010
	BREQ febrero_28d
	JMP ISR_POP
febrero_28d:
	MOV R17,dia_config
	ANDI R17,0b0000_1111
	CPI R17,0b0000_1001
	BREQ febrero_invalido
	RJMP ISR_POP
febrero_invalido:
	MOV R16,dia_config
	ANDI R16,0b1111_0000
	MOV dia_config,R16
	RJMP ISR_POP
cambiar_disp3_f:
	INC mes_config
	MOV R17,mes_config
	ANDI R17,0b0000_1111
	CPI R17,0b0000_1010
	BREQ overflow_disp3_f
	CPI R17,0b0000_0011
	BREQ overflow_mes_hasta_12
	MOV dia,dia_config
	MOV mes,mes_config
	JMP ISR_POP
overflow_mes_hasta_12:
	MOV R16,mes_config
	ANDI R16,0b1111_0000
	SWAP R16
	SBRS R16,0
	RJMP ISR_POP
	JMP overflow_disp3_f

overflow_disp3_f:
	ANDI R17,0b1111_0000
	JMP ISR_POP

cambiar_disp4_f:
	SBRS mes_config,4
	JMP poner1_decmes
	MOV R16,mes_config
	ANDI R16,0b0000_1111
	MOV mes_config,R16
	MOV dia,dia_config
	MOV mes,mes_config
	JMP ISR_POP
poner1_decmes:
	SWAP mes_config
	INC mes_config
	SWAP mes_config
	RJMP ISR_POP

//RESTA DISPLAYS HORA
btn4:
	MOV R16, modo_btn
	SWAP R16
	ANDI R16,0b0000_1111
	CPI R16,0b0000_0001
	BREQ configurar_hora_resta
	;CPI R16,0b0000_0011
	;BREQ configurar_fecha
	JMP ISR_POP

configurar_hora_resta:
	LDI R17, 0b0000_1111
	AND R17,modo_btn
	CPI R17,1
	BREQ restar_disp1
	CPI R17,2
	BREQ restar_disp2
	CPI R17,3
	BREQ restar_disp3
	CPI R17,4
	BREQ restar_disp4_jmp
	JMP ISR_POP

restar_disp4_jmp:
	JMP restar_disp4

restar_disp1:
	MOV R17,uni_conf
	ANDI R17,0b0000_1111
	DEC R17
	CPI R17,0xFF
	BREQ underflow_disp1
	DEC uni_conf
	MOV count_unidades,uni_conf
	MOV count_decenas,dec_conf
	CLR segundos
	JMP ISR_POP

underflow_disp1:
	LDI R16,0b1111_0000
	AND R16,uni_conf
	ORI R16,0b0000_1001
	MOV uni_conf, R16
	JMP ISR_POP

restar_disp2:
	MOV R17,dec_conf
	ANDI R17,0b0000_1111
	DEC R17
	CPI R17,0xFF
	BREQ underflow_disp2
	DEC dec_conf
	MOV count_unidades,uni_conf
	MOV count_decenas,dec_conf
	CLR segundos
	JMP ISR_POP

underflow_disp2:
	LDI R16,0b1111_0000
	AND R16,dec_conf
	ORI R16,0b0000_0101
	MOV dec_conf,R16
	JMP ISR_POP

restar_disp3:
	SWAP uni_conf
	MOV R17,uni_conf
	SWAP uni_conf
	ANDI R17,0b0000_1111
	DEC R17
	CPI R17,0xFF
	BREQ underflow_disp3
	SWAP uni_conf
	DEC uni_conf
	SWAP uni_conf
	MOV count_unidades,uni_conf
	MOV count_decenas,dec_conf
	CLR segundos
	JMP ISR_POP

underflow_disp3:
	MOV R17,dec_conf
	ANDI R17,0b1111_0000
	SWAP R17
	CPI R17,0b0000_0010
	BREQ hora20

	LDI R16,0b0000_1111
	AND R16,uni_conf
	ORI R16,0b1001_0000
	MOV uni_conf,R16
	JMP ISR_POP

hora20:
	LDI R16,0b0000_1111
	AND R16,uni_conf
	ORI R16,0b0011_0000
	MOV uni_conf,R16
	JMP ISR_POP

restar_disp4:
	SWAP dec_conf
	MOV R17,dec_conf
	SWAP dec_conf
	ANDI R17,0b0000_1111
	DEC R17
	CPI R17,0xFF
	BREQ underflow_disp4
	swap dec_conf
	dec dec_conf
	swap dec_conf
	MOV count_unidades,uni_conf
	MOV count_decenas,dec_conf
	CLR segundos
	JMP ISR_POP

underflow_disp4:
	MOV R16, dec_conf
	ANDI R16,0b0000_1111
	ORI R16,0b0010_0000
	MOV dec_conf,r16
	JMP ISR_POP


//ALARMA
cambiar_disp1_a:
	INC alarma_uni
	MOV R17,alarma_uni
	ANDI R17,0b0000_1111
	CPI R17,0b0000_1010
	BREQ overflow_disp1_a
	JMP ISR_POP

overflow_disp1_a:
	LDI R16,0b1111_0000
	AND R16,alarma_uni
	MOV alarma_uni, R16
	JMP ISR_POP

cambiar_disp2_a:
	INC alarma_dec
	MOV R17,alarma_dec
	ANDI R17,0b0000_1111
	CPI R17,0b0000_0110
	BREQ overflow_disp2_a
	JMP ISR_POP

overflow_disp2_a:
	LDI R16,0b1111_0000
	AND R16,alarma_dec
	MOV dec_conf,R16
	JMP ISR_POP

cambiar_disp3_a:
	SWAP alarma_uni
	INC alarma_uni
	MOV R17,alarma_uni
	SWAP alarma_uni
	ANDI R17,0b0000_1111
	CPI R17,0b0000_0100
	BREQ ver_horaconf_a
	CPI R17,0b0000_1010
	BREQ overflow_disp3_a
	MOV count_unidades,alarma_uni
	MOV count_decenas,dec_conf
	JMP ISR_POP

ver_horaconf_a:
	LDI R17,0b1111_0000
	AND R17,alarma_dec
	SWAP R17
	CPI R17,0b0000_0010
	BREQ overflow_disp4
	JMP ISR_POP

overflow_disp3_a:
	LDI R16,0b0000_1111
	AND R16,alarma_uni
	MOV alarma_uni,R16
	JMP ISR_POP

cambiar_disp4_a:
	SWAP alarma_dec
	INC alarma_dec
	MOV R17,alarma_dec
	SWAP alarma_dec
	ANDI R17,0b0000_1111
	CPI R17,0b0000_0011
	BREQ overflow_disp4
	JMP ISR_POP

overflow_disp4:
	CLR alarma_uni
	CLR alarma_dec
	JMP ISR_POP

btn5:
	CBI PORTB,PB4
	JMP ISR_POP

ISR_POP:
	POP R16
	OUT SREG,R16
	POP R16
	RETI

//*******************************************************************
//TABLA DE VALORES
//*******************************************************************
TABLA7SEG: .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F,0x77,0x7C,0x39,0x5E,0x79,0x71;


