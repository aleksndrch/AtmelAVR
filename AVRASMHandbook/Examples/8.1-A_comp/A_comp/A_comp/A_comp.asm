/*
 * A_comp.asm
 *
 *  Created: 10.12.2014 19:40:57
 *   Author: Aleksandr
 */ 


 //��������� �������������
 #include "m8def.inc"

//����������� ���������� (��������� .def)
 .def TMP	=R16		//��������� ����������
 
//����������� ��������   (��������� .equ)

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
RJMP ACI_R
.ORG	TWIaddr		 ; 2-wire Serial Interface
RETI
.ORG	SPMRaddr	 ; Store Program Memory Ready
RETI
.org	INT_VECTORS_SIZE
//����� ������� �������� ����������	

//������� ������������ ����������
//��������� ������ �� ����������� �����������
ACI_R:
SBIS ACSR,ACO //���� ��� ACO ����������, �������� LED
RJMP RES_LED  //����� �����
SBI PORTB,0
RETI

RES_LED:
CBI PORTB,0
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

	LDI TMP, 0b00000001
	OUT DDRB, TMP

//�������� ���������� ����������
	LDI TMP, (1<<ACIE)
	OUT ACSR,TMP
	
	SEI		//��������� ����������
MAIN:
			//������� ����������
RJMP MAIN

//������� ����������������� ������ (EEPROM)
.ESEG
