 /*
 * 
 *
 *  Created: 25.02.2013 19:50:15
 *  Author: Aleksandr
 *
 * ������: ����������� ���������� ���������� � ������� �����/������.
 *		   �������� ������ ������ � ���������. ������������ ����������� ��������.		 
 */ 
//��������� �������������
 #include "m8def.inc"

//����������� ���������� (��������� .def)
 .def TMP     = R16		//��������� ����������
 .def CNT     = R17		//�������
 .def CNT2    = R18		//�������������� �������
 .def SB_FLAG = R19		//���� ������� ������

//����������� ��������   (��������� .equ)
.equ  LED_MSK  = 0b00010001
.equ  FST_PUSH = 1
	
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


//����������� ������� ��������� (PORTB) - ��� ����� �� �����
	LDI TMP, 0xFF
	OUT DDRB, TMP
//����������� ������ (PORTD)-����� 0,1,2 - ���� � ���������
	LDI TMP, 0b00000111
	OUT PORTD, TMP

MAIN:
//��������� ������ �� ������ "�����"?
SBIS PIND,0
RJMP SB_UP

//������ �� ������ "����"?
SBIS PIND,1
RJMP SB_DOWN

RJMP MAIN

//������ ������ �����
SB_UP:	
SBIS PIND,0		//������ �������?
RJMP SB_UP		//���, ���� ����������, ����� ���������� ��������� ���������

INC SB_FLAG		//��������� ���� ������� ������

CPI SB_FLAG,FST_PUSH	//������ ������ ������ ���?
BRNE CLR_MASK			//���? ���� ������������ � ������� � ��������� �������

LDI TMP, LED_MSK		//����� ������ �� ��������� ������� ����� �������� ���������

UP_CYCLE:				//���� �������� ����� (���������� ������)
ROR TMP					//�������� ����� ������
RCALL DELAYnS			//��� ����������� ������ ��������� �������� (�� ������� 1��� ����������)
OUT PORTB,TMP			//������� ����� � ����

//��������� ���������� �� ������, ���� �� ������������ ������� � ������������� �����
SBIS PIND,0				
RJMP SB_UP

SBIS PIND,1
RJMP SB_DOWN
//���� ���, ���������� ����� � �����
RJMP UP_CYCLE

//������ ������ ���� (��� ��������� ���������� ������ "�����")
SB_DOWN:
SBIS PIND,1
RJMP SB_DOWN

INC SB_FLAG

CPI SB_FLAG,FST_PUSH
BRNE CLR_MASK

LDI TMP, LED_MSK

DOWN_CYCLE:
ROL TMP
RCALL DELAYnS
OUT PORTB,TMP

SBIS PIND,1
RJMP SB_DOWN

SBIS PIND,0
RJMP SB_UP

RJMP DOWN_CYCLE


//�������� ����� ������ � ��������� ��������� �� ������� 
CLR_MASK:
CLR SB_FLAG			//������������� ���� � 0
OUT PORTB,SB_FLAG	//������� �� ������� 0
RJMP MAIN

//��������
DELAYnS:
	LDI CNT,255		//���������� � ������� 255
	LDI CNT2,255	//���������� � �������������� ������� 255
DELAY_CYCLE:
	DEC CNT			 //���������
	BRNE DELAY_CYCLE //����� �� 0?
DELAY2_CYCLE:
	LDI CNT,255		//��������� � ������� ����� ��������
	DEC CNT2		//��������� �� ������� �������������� �������
	BRNE DELAY_CYCLE//����� �� ����? ���� ��� ������������ � ������� �����	
RET					 //�������



//������� ����������������� ������ (EEPROM)
.ESEG

