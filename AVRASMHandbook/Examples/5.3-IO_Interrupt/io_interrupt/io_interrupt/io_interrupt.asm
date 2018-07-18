 /*
 *
 *
 *  Created: 25.02.2013 19:50:15
 *  Author: Aleksandr
 *
 * ������: ����������� ���������� ���������� � ������� �����/������.
 *		   �������� ������ 7 ����������� �������. ������� ����������.		 
 */ 
//��������� �������������
 #include "m8def.inc"

//����������� ���������� (��������� .def)
 .def TMP       = R16		//��������� ����������
 .def L_Counter = R17		//������� ��������


//����������� ��������   (��������� .equ)
.equ END_STRING = 10
	
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
	
	CPI L_COUNTER, END_STRING	//���������, ����� �� ����� ������?
	BRNE STR_OUT				//���, ������� ��������� ������
	CLR L_Counter				//��, �������� �������
	
STR_OUT:
	ADD ZL,L_Counter		//������� ��������� �� ������� ������� �������� �� �������� ������ ������ ���������� � ������ �������
	LPM						//�������� ������ �� ������ �� ������� ��������� ���������
	OUT PORTC,R0			//������� ��� �� �������
	INC L_Counter			//�������� ����� ���������� ������� �� �������
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

//����������� 7 ����������� ������� (PORTB) - ��� ����� �� �����
	LDI TMP, 0xFF
	OUT DDRC, TMP
//����������� ������ (PORTD)-����� 2 - ���� � ���������
	LDI TMP, 0b00000100
	OUT PORTD, TMP

//��������� �������� ���������� INT0 (��� ��������� ������� �� ������)
LDI TMP, 1<<ISC01		//����������� �� ���������� ������
OUT MCUCR, TMP
LDI TMP, 1<<INT0		//���������� ����������
OUT GIMSK,TMP

SEI						//�� �������� ������ ��������� ����������

MAIN:
//��������� ��������� �� ������ ������� � ���������
	LDI ZH,HIGH (N_mask*2)				
	LDI ZL,LOW (N_mask*2)		

RJMP MAIN


//����� ���� ��� ������ �� �������������� ������� (���������� �� FLASH ������)
N_mask:
.db 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01101111



//������� ����������������� ������ (EEPROM)
.ESEG



