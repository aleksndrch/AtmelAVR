/*
 * Keyboard.asm
 *
 *  Created: 09.04.2013 19:20:23
 *  Author: Aleksandr
 * ������: ����������� ���������� ����������� �������
 *		   � ������� ������, ��������� �������� �������������
 *		   � ��� ����� ������������ ����� ������ ������ ������.
 */ 

 
//��������� �������������
 #include "m8def.inc"

 //����������� ���������� (��������� .def)
 .def TMP = R16		//��������� ����������
 .def CNT = R17		//�������
 .def MSK = R18		//����� � ���������


 //����������� ��������   (��������� .equ)
 .equ KEYMSK  = 0b11011111		//����� ��� ������ �������� �� ��������
 .equ SCANMSK = 0b11100000		//����� ��� ���� ����� �� "�������" ���������� ����� �����

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

//������ - ����� � ������������ ������������� ���������� (PullUp)
	LDI TMP, 0b00001111
	OUT PORTD, TMP
//������� - ������ c ������� �������
	LDI TMP, 0b11100000
	OUT DDRB,  TMP
	OUT PORTB, TMP
//���� ������ ���������� - �����
	LDI TMP, 0b11111111
	OUT DDRC, TMP

MAIN:
RCALL KEYB_INIT		//�������� ��������� ������ ����������
CPI MSK,0			//���� ������ �� ���������� � ����� 0, ���������� �����
BREQ MAIN			//���� ��, ��������� � ������ ������

//OUT PORTC, MSK		//����� ������� �������� � ����
//RJMP MAIN				//��� �������� ������� ������������
//��� ������������� ����� � �������� ����������� �����
//�������� ��������!!!

RJMP FIND_SYMBOL_INIT
RJMP MAIN			//� ������

//������������� ������� �������������
FIND_SYMBOL_INIT:
CLR TMP			//�� ������ ������ �������� ��������� �������
LDI ZH,HIGH(Code_table*2)	//��������� ��������� �� ������
LDI ZL,LOW(Code_table*2)

//��������������� ����� �������
FIND_SYMBOL:
LPM TMP,Z+	//������� �������� �� ������ Z � �������������� �����(Z+)
//������ ��������� ��������� �� �������� ��������
CPI TMP,0xFF//����� �������?
BREQ MAIN	//��, ������� �� �������

CP MSK,TMP	//�������� ������� � �������?
BREQ DISPLAY_OUT	//�������

LPM TMP, Z+	//���� ���, �� ����� ����������� ����� ����� ����������
//����� � ������� ����� �������� �������� � ���������� �����
RJMP FIND_SYMBOL

DISPLAY_OUT:
LPM TMP,Z		//��������� �������� �� �������
OUT PORTC,TMP	//������� ���
RJMP MAIN

//������� ������������ ����������
KEYB_INIT:
	LDI CNT,3			//���������� ������� �������� (�� ���������� ��������)
	LDI MSK, KEYMSK		//��������� ����� ������

KEYB_SCAN:	
	IN  TMP, PORTB		//�� ��������� ������� ���������� �������� ������������� ����� (����� �� "���������")
	ORI TMP, SCANMSK	//���������� � 1 ��� ����� ������

	AND TMP, MSK		//���������� � �������� ������������ �����
	OUT PORTB, TMP		//������� � ����� � ����

	NOP					//�������� ��� ���� ����� ������� 
	NOP					//����� ������������
	NOP
	NOP

	NOP
	NOP
	NOP
	NOP


	SBIS PIND,0			//������ ������ � 1 ����?
	RJMP SB1

	SBIS PIND,1			//������ ������ � 2 ����?
	RJMP SB2

	SBIS PIND,2			//������ ������ � 3 ����?
	RJMP SB3

	SBIS PIND,3			//������ ������ � 4 ����?
	RJMP SB4

	ROL MSK				//�������� ������������ ��� �����
	
	DEC CNT				//��������� ������� ������

	BRNE KEYB_SCAN		//���� �� ����� 0, ���������� �����
	CLR MSK				//����� "������" �������� �����
	RET					//������������ � �������� ����

//������ ������ � 1 ����
SB1:
	ANDI MSK,SCANMSK	//��������� ������������� ��������, ������� �������� ����
	ORI MSK, 0x01		//������ ������ � ������ ����
RET

//������ ������ � 2 ����
SB2:
	ANDI MSK,SCANMSK	//��������� ������������� ��������, ������� �������� ����
	ORI MSK, 0x02		//������ ������ � ������ ����
RET

//������ ������ � 3 ����
SB3:
	ANDI MSK,SCANMSK	//��������� ������������� ��������, ������� �������� ����
	ORI MSK, 0x03		//������ ������ � ������ ����
RET

//������ ������ � 4 ����
SB4:
	ANDI MSK,SCANMSK	//��������� ������������� ��������, ������� �������� ����
	ORI MSK, 0x04		//������ ������ � ������ ����
RET

//������� ������������
Code_table:
.db 0xC1,0x01 //1
.db 0xA1,0x02 //2
.db 0x61,0x03 //3
.db 0xC2,0x04 //4
.db 0xA2,0x05 //5
.db 0x62,0x06 //6
.db 0xC3,0x07 //7
.db 0xA3,0x08 //8
.db 0x63,0x09 //9
.db 0xC4,0x0A //*(a)
.db 0xA4,0x00 //0
.db 0x64,0x0B //#(b)
.db 0xFF,0    //����� �������

//������� ����������������� ������ (EEPROM)
.ESEG



