 /*
 * ADC_Example.asm
 *
 *  Created: 25.02.2013 19:50:15
 *  Author: Aleksandr
 *
 * ������: ����������� ���������� ������������� ����������
 *		   �� ���� ����������� �������.
 *
 *��� ������ �� 4��� 8��������� ������ � ������������� ����������� 64, 
 *(������� ������� �������� 62500��), ������������ ����� ��������� ��� � 0.004�,
 *���� � ���������� �������� �������������� 8 ��������� ������� �� �����
 *����������� 0.004�*256, �� ���� �������� 1.04�, ��� ����� �������
 *����������� ���������.
 */ 

//��������� �������������
 #include "m8def.inc"

//����������� ���������� (��������� .def)
 .def TMP     = R16		//��������� ����������
 .def CNT     = R17		//�������
 .def NUM	  = R18		//�������� ��������� �� �������

//����������� ��������   (��������� .equ)
.equ MAX_V	  = 0xFF	//����������� ��������� �������� ��������
.equ MAX_NUM  = 10		//�������� ��� ���� ����� ������� �������� �������� �� �������
	
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

//������� ������������ ����������
TIM0OVF:
	DEC CNT				//��������� �������
	BREQ DELAY1S		//������� ����� 0? (������������ ��������� 256 ���)
	RETI				//���, ����

	DELAY1S:			
	LDI CNT,MAX_V		//������� � �������-������� ����� �������� ��� �������� � 1 ���
	INC NUM				//�������� ����� ������� ���������� ��������

	CPI NUM,MAX_NUM		//����� �� ����������� ��������?
	BREQ ZERO			//��, ��������

	OUT PORTC,NUM		//���, ������� �� �������
RETI
ZERO:
	CLR NUM				//�������� ��������
	OUT PORTC,NUM		//������� �� �������
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


//����������� ������� ������� (PORTC) - ����� (0-4) �� �����
	LDI TMP, 0b00001111
	OUT DDRC, TMP
//����������� ������ (PORTD)-����� 0,1 - ���� � ���������
	LDI TMP, 0b00000011
	OUT PORTD, TMP

//��������� ������� TIM0
	LDI TMP, (1<<TOIE0)	//�������� ���������� �� ������������� ������� (�� ��������� ���������)
	OUT TIMSK, TMP
	
	LDI CNT,MAX_V		//������� � �������-������� �������� ��� �������� � 1 ���

	SEI					//�������� ����������

MAIN:
//��������� ������ �� ������ "�����"?
SBIS PIND,0
RJMP SB_START

//������ �� ������ "����"?
SBIS PIND,1
RJMP SB_STOP

RJMP MAIN

//������ ������ "�����"
SB_START:	
SBIS PIND,0		//������ �������?
RJMP SB_START	//���, ���� ����������, ����� ���������� ��������� ���������

//������� ����������� ������������ �������� � ������������ (���� CSxx �������� TCCR0)
LDI TMP, (1<<CS00)|(1<<CS01)	// ������������ (/64)
OUT TCCR0,TMP					// ���������� �������� � �������

RJMP MAIN

SB_STOP:	
SBIS PIND,0		//������ �������?
RJMP SB_STOP	//���, ���� ����������, ����� ���������� ��������� ���������

//������������� ������ ������� ���� ������������
LDI TMP, (0<<CS00)|(0<<CS01)	// ������������ ��������
OUT TCCR0,TMP					// ���������� �������� � �������

RJMP MAIN
//������� ����������������� ������ (EEPROM)
.ESEG

