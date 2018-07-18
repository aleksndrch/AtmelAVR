 /*
 * Dyn_Indication.asm
 *
 *  Created: 20.11.2014 20:50:15
 *  Author: Aleksandr
 *
 * ������: ����������� ���������� - .
 *		   ���������������� ���������� � ������������ ����������
 */ 

//��������� �������������
 #include "m8def.inc"

//����������� ���������� (��������� .def)
 .def TMP       = R16		//��������� ����������
 .def CNT_1N	= R17		//����� ��� �������� �� ������ (1 ������)
 .def CNT_2N	= R18		//����� ��� �������� �� ������ (2 ������)
 .def CNT_3N	= R19		//����� ��� �������� �� ������ (3 ������)
 .def CNT_4N	= R20		//����� ��� �������� �� ������ (4 ������)
 .def COUNTER	= R22		//����� �������� ���������� ������� �� ����������
 
 .def MASK		= R21		//����� ��� ������ �� ������� (�� FLASH)

//����������� ��������   (��������� .equ)
.equ IND_MSK = 0b00000001	
.equ MAX_CNT = 10			// ��� ����������� ������������ �������

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
RJMP TIM1M_A
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

//���������� �� ���������� �������� A ��� TIM1
//������������ ��� ������� ������
TIM1M_A:
START_1N:				//������ �� 1 �������
	INC CNT_1N			//����������� ��������
	CPI CNT_1N, MAX_CNT	//���������, ��������� �������  
	BREQ START_2N		//� ���������� ������� ��� ���
RETI

START_2N:				//����� ������� �������
	CLR CNT_1N			//�������� 1 ������
	INC CNT_2N			//����������� 2 ������
	CPI CNT_2N, MAX_CNT //��������� ������������
	BREQ START_3N
RETI

START_3N:
	CLR CNT_2N
	INC CNT_3N
	CPI CNT_3N, MAX_CNT
	BREQ START_4N
RETI

START_4N:
	CLR CNT_3N
	INC CNT_4N
	CPI CNT_4N, MAX_CNT
	BREQ END_CNT //���� ������������ ������ ����������
RETI

END_CNT:		//�������� ��� �������
	CLR CNT_1N
	CLR CNT_2N
	CLR CNT_3N
	CLR CNT_4N
RETI




//���������� �� ���������� ������������ ��� TIM0
//������������ ��� ������������ ���������
TIM0OVF:
//��������� ��������� �� ������ ������� � ���������
	LDI ZH,HIGH (N_mask*2)				
	LDI ZL,LOW (N_mask*2)
	
	CPI COUNTER,0
	BREQ DISP1

	CPI COUNTER,1
	BREQ DISP2

	CPI COUNTER,2
	BREQ DISP3

	CPI COUNTER,3
	BREQ DISP4

DISP1:
	INC COUNTER		//�������� �������, ��� ���� ����� � �������� ��������
					//�������� ������ ����� �������
	OUT PORTC,MASK  //������� ����������� �������

//����� �� ������� ������� �� ������ �� ������(ZL+CNT_xN) 
	ADD ZL,CNT_1N	//�������� � ��������� �� Flash ������ ��������
	LPM				//�������� ��� �� ������ (������� R0)
	OUT PORTD,R0	//�������
RETI

DISP2:				//����������
	INC COUNTER
	LSL MASK		//������� ����� �����
	OUT PORTC,MASK

	ADD ZL, CNT_2N
	LPM
	OUT PORTD,R0
RETI

DISP3:				//����������
	INC COUNTER
	LSL MASK
	OUT PORTC,MASK

	ADD ZL, CNT_3N
	LPM
	OUT PORTD,R0
RETI

DISP4:				//����������
	LSL MASK
	OUT PORTC,MASK

	ADD ZL, CNT_4N
	LPM
	OUT PORTD,R0

//�������� ������� �������� � ������ ����� � ���������� ��������
	CLR COUNTER
	LDI MASK,IND_MSK
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

//����������� 7 ���������� ��������(����� ����, ��������� ������ �������)
	LDI TMP,0xFF
	OUT DDRD,TMP		//8 ��� ������
	OUT PORTD,TMP

	LDI TMP,0x0F		//4 ���� ����������� (���� ������ ��������� �������)
	OUT DDRC,TMP

//����������� ������ SB_START, SB_STOP
	LDI TMP, 0b00000011
	OUT PORTB, TMP

//��������� �������� TIM0, TIM1
LDI TMP, 1<<TOIE0|1<<OCIE1A	//�������� ���������� TIM0 ������������ 
OUT TIMSK, TMP				//� TIM1 �� ���������� � A

LDI TMP, 1<<CS00|1<<CS01	//�������� ������ ������������ ���������
OUT TCCR0,TMP

LDI TMP, 1<<WGM12			//����� ������ ������� TIM1, ����� ��� ���������� ��������
OUT TCCR1B, TMP

//������ � 16-��������� ������� TCNT
LDI TMP, HIGH(62500)
OUT	OCR1AH, TMP		//������ ������� ������� ����
LDI TMP, LOW(62500)
OUT	OCR1AL, TMP		//������ �������

SEI

//��������� ������� ����������
LDI MASK, IND_MSK

MAIN:

//��������� ������ �� ������ "START"?
	SBIS PINB,0
	RJMP SB_START

//������ �� ������ "STOP"?
	SBIS PINB,1
	RJMP SB_STOP
RJMP MAIN

SB_START:	
	SBIS PINB,0		//������ �������?
RJMP SB_START		//���, ���� ����������, ����� ���������� ���������
	LDI TMP, 1<<CS00|1<<CS11
	OUT TCCR1B,TMP
RJMP MAIN

SB_STOP:	
	SBIS PINB,1		//������ �������?
RJMP SB_STOP		//���, ���� ����������, ����� ���������� ���������
	LDI TMP, 0<<CS00|0<<CS11
	OUT TCCR1B,TMP
RJMP MAIN

//����� ���� ��� ������ �� �������������� ������� (���������� �� FLASH ������),
//� ������� �� �������� (7seg) ������������
N_mask:
.db 0b11000000, 0b11111001, 0b10100100, 0b10110000, 0b10011001, 0b10010010, 0b10000010, 0b11111000, 0b10000000, 0b10010000

//������� ����������������� ������ (EEPROM)
.ESEG