/*
 * SM_Control.asm
 *
 *  Created: 22.11.2014 16:06:42
 *   Author: Aleksandr
 * ��������� ��������� ���������� ������� ���������� � ����������� ������, ����� ��������� ��������� ��� � ������ �����������, 
 * ��� � � �������, ����� ���������� ���������, ������ �������� � ���� ����������� �������� �� ���������� ������� TIM0,
 * ����� ������� ������� �������� ��������� ����� �������� �� ���� ��� ����� ���������� ���������� �� ������������ �������. 
 * � ��������� ������������ ������� ��������� �� 1024, ������� �� ������������ 4���, �� ���� ������ ����� ������������� 
 * �������� 15 ��� � �������, � ��������� ����� ���������� � ��������� ��������� (����� �� 8).
 */ 

//��������� �������������
 #include "m8def.inc"

//����������� ���������� (��������� .def)
 .def TMP       = R16		//��������� ����������
 .def CNT       = R17		//������� ���������
 .def FR_FLAG	= R18		//���� ����������� ��������

//����������� ��������   (��������� .equ)
.equ CNT_MAX    = 8			//��� ����������� ������������ �������
.equ F_FLAG_EN  = 1			//������ ���
.equ R_FLAG_EN  = 2			//������

//������� ��� (RAM)
.DSEG

 //������� ���� (Flash)
.CSEG
.ORG 0x0000
	RJMP RESET
//������� �������� ����������:
.ORG	INT0addr	 ; External Interrupt Request 0
RETI
.ORG	INT1addr	 ; External Interrupt Request 1
RETI
.ORG	OC2addr		 ; Timer/Counter2 Compare Match
RETI
.ORG	OVF2addr	 ; Timer/Counter2 Overflow
RETI
.ORG	ICP1addr	 ; Timer/Counter1 Capture Event
RETI
.ORG	OC1Aaddr	 ; Timer/Counter1 Compare Match A
RETI
.ORG	OC1Baddr	 ; Timer/Counter1 Compare Match B
RETI
.ORG	OVF1addr	 ; Timer/Counter1 Overflow
RETI
.ORG	OVF0addr	 ; Timer/Counter0 Overflow
RJMP TIM0OVF
.ORG	SPIaddr		 ; Serial Transfer Complete
RETI
.ORG	URXCaddr	 ; USART, Rx Complete
RETI
.ORG	UDREaddr	 ; USART Data Register Empty
RETI
.ORG	UTXCaddr	 ; USART, Tx Complete
RETI
.ORG	ADCCaddr	 ; ADC Conversion Complete
RETI
.ORG	ERDYaddr	 ; EEPROM Ready
RETI
.ORG	ACIaddr		 ; Analog Comparator
RETI
.ORG	TWIaddr		 ; 2-wire Serial Interface
RETI
.ORG	SPMRaddr	 ; Store Program Memory Ready
RETI
.org	INT_VECTORS_SIZE
//����� ������� �������� ����������	

//������� ������������ ����������:
//���������� �� ���������� ������������ ��� TIM0

TIM0OVF:
MOTOR_CONTROL:				//����������� ������ ������
	CPI FR_FLAG,R_FLAG_EN	//���� ������� ������?
	BREQ SM_REVERSE			//��, �������� � SM_REVERSE
//������ �������� ���������
SM_FORWARD:
	ADD ZL, CNT				//��������� �� ������ ��������
	LPM
	OUT PORTD,R0			//������� � ����
	INC CNT					//�����������
	CPI CNT,CNT_MAX			//�������� ���������?
	BREQ RES_CNT			//���������� �������
RETI

//������ (���������� ������� ����)
SM_REVERSE:
	ADD ZL, CNT
	LPM
	OUT PORTD,R0
	DEC CNT
	CPI CNT,0
	BREQ RES_CNTR
	CPI CNT,-1		//�� ������ ���� ������� �� �������
	BREQ RES_CNTR
RETI

//����� �������� ������� ����
RES_CNT:
LDI CNT,0
RETI

//����� �������� �������
RES_CNTR:
LDI CNT,CNT_MAX
RETI



RESET:
//������������� �����: (����������� �� ���� �� � ����������� ������ AtMega)
	LDI R16, LOW(RAMEND)	//�������� ��������� ����� � ����� SRAM
	OUT SPL, R16
	LDI R16, HIGH(RAMEND)	//�������� ��������� ����� � ����� SRAM
	OUT SPH, R16

//��������� ������ �����/������
//DDRx  - ����������� ������ ����� ����� x (1-�����, 0-����)
//PORTx - �������� ������ �� ����� ����� x (1-�������, 0-������)
//		  ���� ���� x �������� ��� ����    (1-PullUp) 
//PINx  - ������� ������� �� ����� ����� x (������ ��� ������)		

//��������� ����� ������������ ������� ���������
	LDI TMP,0x0F		//������ �������� ����� �� �����
	OUT DDRD,TMP		
	LDI TMP,0x0F		//������� ������� (���������� ������)
	OUT PORTD,TMP

//����������� ������ SB_STOP, SB_FORWARD, SB_REVERSE
	LDI TMP, 0b00000111
	OUT PORTB, TMP

//��������� �������� TIM0
	LDI TMP, 1<<TOIE0	//�������� ���������� TIM0 ������������ 
	OUT TIMSK, TMP				

	SEI 
MAIN:
	LDI ZH,HIGH (SM_mask*2)				
	LDI ZL,LOW (SM_mask*2)
//��������� ������ �� ������ "STOP"?
	SBIS PINB,2
	RJMP SB_STOP
//������ �� ������ "FORWARD"?
	SBIS PINB,0
	RJMP SB_FORWARD
//��������� ������ �� ������ "REVERSE"?
	SBIS PINB,1
	RJMP SB_REVERSE
RJMP MAIN

//���������� ������ STOP
SB_STOP:
	SBIS PINB,2					//������ �������?
RJMP SB_STOP					//���, ���� ����������, ����� ���������� ���������	
	LDI TMP, 0<<CS00|0<<CS02	//������������� ������
	OUT TCCR0,TMP
	CLR FR_FLAG					//�������� ����� ����������� ��������
RJMP MAIN

//���������� ������ FORWARD
SB_FORWARD:
	SBIS PINB,0		//������ �������?
RJMP SB_FORWARD		//���, ���� ����������, ����� ���������� ���������	
	LDI FR_FLAG,F_FLAG_EN		//������������� ���� ������� ��������
	LDI TMP, 1<<CS00|1<<CS02	//��������� ������
	OUT TCCR0,TMP
RJMP MAIN

//���������� ������ REVERSE
SB_REVERSE:	
	SBIS PINB,1		//������ �������?
RJMP SB_REVERSE		//���, ���� ����������, ����� ���������� ���������

//��� ���� ����� ������ �������� � ������� � ��� ������� ������� ���� 
//� ���������� ������ ������� (���� �� ����� ��������� ��������)	
	CPI FR_FLAG, F_FLAG_EN		//��������� �������� �� �� ����� ���������
	BREQ REVERSE_CONTINUE		//��? ���������� ������������� ������
//������������� ������ �������
	LDI CNT,CNT_MAX				//��������� � ������� �������� ����������� �� ����� �������
	LDI TMP, 1<<CS00|1<<CS02	//�������� ������ 
	OUT TCCR0,TMP

REVERSE_CONTINUE:
	LDI FR_FLAG,R_FLAG_EN
RJMP MAIN

//����� �������� ��� �������� ���������
SM_mask:
.db  0b00001110,0b00001100, 0b00001101, 0b00001001, 0b00001011, 0b00000011, 0b00000111, 0b00000110, 0b00001110,0

//������� ����������������� ������ (EEPROM)
.ESEG