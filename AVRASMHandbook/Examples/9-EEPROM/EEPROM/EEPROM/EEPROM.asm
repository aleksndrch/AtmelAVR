 /*
 * EEPROM.asm
 *
 *  Created: 25.02.2013 19:50:15
 *  Author: Aleksandr
 *
 * ������: ����������� ���������� ������������ ������ EEPROM ��� �������� ��������.
   ���� ��� ������, �����, ������, ������, ��� ������� ������ �����, �� 1 ������� �������� ��������
   ��� ������� ������ ������, ��� ������������, ��� ������� ������ ������ ��������� �� ������ �������. 
   ������� ��������� ���� ���� �� 		 
 */ 
//��������� �������������
 #include "m8def.inc"

//����������� ���������� (��������� .def)
 .def TMP     = R16		//��������� ����������
 .def CNT_U   = R17		//������� ������� �������
 .def CNT_L	  = R18		//������� ������� �������

 .def EE_AddrH = R19	//����� ��� ������ (�������)
 .def EE_AddrL = R20	//����� ��� ������ (�������)

//����������� ��������   (��������� .equ)
.equ CNT_MAX	=10		//��� ����������� ������ �� ������� �������� (0-9)
.equ D1_MASK    =0b00001111
.equ D2_MASK    =0b11110000

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

//����������� ������ (PORTB)-����� 0,1,2 - ���� � ���������
	LDI TMP, 0b00000011
	OUT PORTB, TMP

	LDI TMP, 0xFF
	OUT DDRD, TMP

	LDI CNT_U,1 //��� ����������� ������ ����� (��� ������� 0, ������ ������� 1)

MAIN:
//��������� ������ �� ������ "SAVE"?
SBIS PINB,0
RJMP SB_SAVE

//������ �� ������ "LOAD"?
SBIS PINB,1
RJMP SB_LOAD

//������ �� ������ "UP"?
SBIS PINB,2
RJMP SB_UP

RJMP MAIN

//������ ������ SAVE
SB_SAVE:
SBIS PINB,0		//������ �������?
RJMP SB_SAVE	//���, ���� ����������, ����� ���������� ��������� ���������

RCALL EE_WRITE	//�������� ������� ������

RJMP MAIN


//������ ������ LOAD (��� ��������� ���������� ������ "SAVE")
SB_LOAD:
SBIS PINB,1
RJMP SB_LOAD

RCALL EE_READ	//������� ������� ������
	DEC CNT_L		//��������� ��� ��� � ������ ������������ �������� �� 1 ������.
	SWAP CNT_L		//������������ ������� (������� �� ����� �����)
	IN TMP, PORTD	  //��������� ������� �������� ����� (����� �� ���������)
	ANDI TMP, D1_MASK //���������
	OR TMP, CNT_L	  //��������� ��������
OUT PORTD,TMP		  //� �������

RJMP MAIN

//������ ������ UP (��� ��������� ���������� ������ "SAVE")
SB_UP:
SBIS PINB,2
RJMP SB_UP
	IN TMP, PORTD		//���������� SB_LOAD
	ANDI TMP, D2_MASK
	OR TMP, CNT_U
	OUT PORTD,TMP
	INC CNT_U
	CPI CNT_U, CNT_MAX
BREQ CLEAR_CNT			//���� ����� �� 9, ���������� �������
RJMP MAIN

//�������� ��������� ��� �������� � 0.
CLEAR_CNT:
CLR CNT_U
RJMP MAIN

//������� ������ EEPROM
EE_WRITE:
SBIC EECR,EEWE	//������� ���������� ������ � ������
RJMP EE_WRITE	//�� ���� ��������� ����� EEWE

OUT EEARL, EE_AddrL	//��������� ����� ����������� ������ (0)
OUT EEARH, EE_AddrH //(������� � �������)
OUT EEDR,  CNT_U	//� ���� ������

SBI EECR, EEMWE		//������������� ��� ��������������
SBI EECR, EEWE		//���������� ����

RET

//������� ������ EEPROM
EE_READ:
SBIC EECR, EEWE		//���� ��������� ���������� ������
RJMP EE_READ

OUT EEARL, EE_AddrL	//���������� �����
OUT EEARH, EE_AddrH

SBI EECR,EERE		//���������� ��� ������
IN CNT_L, EEDR		//������ ��� �� ������ ������
RET

//������� ����������������� ������ (EEPROM)
.ESEG

