/*
 * PWM_Motor.asm
 *
 *  Created: 23.11.2014 18:51:00
 *   Author: Aleksandr

���������� ��� ������� �� ������ ������� ��������� ��������� �� +45 �� ��������� 
� �����������, �������� �� 0 +180, ��� ���������� ������������� �������� ���������
������������ � 0.
��������� ������� ������ ���������� ����������� (���������� ��� �����), �������
��� ���� ����� ��� ������� �� ���� ��������� ������������ �������� ����������� 
���� � Proteus

������:
����������� ������������ ��������  1��
������������ ������������ �������� 2��
������� �� � 2���, �������� 8
�������� �������� ICR1 � 4999 
�������    �������� (��)   � ������� OCR1A
0               1				250
45             1.25				312
90             1.5				375	
135            1.75				437
180             2				500	
 */ 

//��������� �������������
 #include "m8def.inc"

//����������� ���������� (��������� .def)
 .def TMP     = R16		//��������� ����������
 .def CNT     = R17		//�������


//����������� ��������   (��������� .equ)
//����������� ��������   (��������� .equ)
 .equ 	XTAL   = 2000000					//������� �����������
 .equ	T1_PSK = 8							//������������ �������	
//������ �������� ��� ��������� ������� ��� � ����������� ���������� ���������	
 .equ 	PWM = 50						//����������� ������� ���
 .equ 	PWM_const = (XTAL-T1_PSK*PWM)/(T1_PSK*PWM)		//��������� ��� �������
//������ �������� ��� ����������� ���� ��������
 .equ   RP0   = 1000/4		//����������� ��� ����� �������� ��� ���� �������� (� ���)
 .equ   RP45  = 1250/4		//��������� �� ������ ������ ������� (� ���)
 .equ   RP90  = 1500/4		//������ ������ ������� ����� 1/(XTAL/T1_PSK)
 .equ   RP135 = 1750/4
 .equ   RP180 = 2000/4

	
//������� ��� (RAM)
.DSEG

 //������� ���� (Flash)
.CSEG
.ORG 0x0000
	RJMP RESET
//������� �������� ����������:
.ORG	INT0addr	 ; External Interrupt Request 0
RJMP INT0I
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
RETI
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

//������� ������������ ����������
INT0I:
INC CNT

CPI CNT,2
BREQ ROTATE90

CPI CNT,3
BREQ ROTATE135

CPI CNT,4
BREQ ROTATE180

CPI CNT,5
BREQ ROTATE0

//������� � 45
ROTATE45:
//������� ����������� �������� � �������� ��������� (�� ������� ��� ������� ������!)
	LDI TMP,HIGH(RP45)
	OUT OCR1AH,TMP

	LDI TMP,LOW(RP45)
	OUT OCR1AL,TMP
RETI

//������� � 90
ROTATE90:
//������� ����������� �������� � �������� ��������� (�� ������� ��� ������� ������!)
	LDI TMP,HIGH(RP90)
	OUT OCR1AH,TMP

	LDI TMP,LOW(RP90)
	OUT OCR1AL,TMP
RETI

//������� � 135
ROTATE135:
//������� ����������� �������� � �������� ��������� (�� ������� ��� ������� ������!)
	LDI TMP,HIGH(RP135)
	OUT OCR1AH,TMP

	LDI TMP,LOW(RP135)
	OUT OCR1AL,TMP
RETI

//������� � 180
ROTATE180:
//������� ����������� �������� � �������� ��������� (�� ������� ��� ������� ������!)
	LDI TMP,HIGH(RP180)
	OUT OCR1AH,TMP

	LDI TMP,LOW(RP180)
	OUT OCR1AL,TMP
RETI

//������� � 0
ROTATE0:
//������� ����������� �������� � �������� ��������� (�� ������� ��� ������� ������!)
	LDI TMP,HIGH(RP0)
	OUT OCR1AH,TMP

	LDI TMP,LOW(RP0)
	OUT OCR1AL,TMP

	CLR CNT
RETI

//����� �������� ������������ ����������


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

//�������� ����� OC1A �� �����
	LDI TMP, 0b000000010
	OUT DDRB,TMP

//��������� �������� ���������� INT0 (��� ��������� ������� �� ������)
LDI TMP, 1<<ISC01		//����������� �� ���������� ������
OUT MCUCR, TMP
LDI TMP, 1<<INT0		//���������� ����������
OUT GIMSK,TMP


//��������� ������� TIM1 ��� ������ � ������ ��� (����� 14, datasheet p.98)
//������ ����� ���������� ��� ��� ���������� ������������� �������� ���
//��������� �������� ����������� ������� ��� ������ 50��
	LDI TMP,HIGH(PWM_const)				//���������� ����� ����������� �������
	OUT ICR1H,TMP						//�� ������� � ������� ������		
	LDI TMP,LOW(PWM_const)
	OUT ICR1L,TMP
	
	LDI TMP, 1<<COM1A1|1<<WGM11	//�������� ��� WGM11,WGM12,WGM13 - ����� 14
	OUT TCCR1A, TMP				//COM1A1 - ����� ����� ��� ���������� (non-inverting mode)

	LDI TMP, 1<<WGM12|1<<CS11|1<<WGM13		//CS11 - ������������ 8
	OUT TCCR1B, TMP

	SEI
	
MAIN:

RJMP MAIN


//������� ����������������� ������ (EEPROM)
.ESEG

