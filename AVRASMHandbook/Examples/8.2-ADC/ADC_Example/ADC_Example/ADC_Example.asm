 /*
 * ADC_Example.asm
 *
 *  Created: 25.02.2013 19:50:15
 *  Author: Aleksandr
 *
 * ������: ����������� ���������� ���������� ����������
 *		   �� 0 ������ ��� (ADC0) � ��������� ��������� 
 *		   ��������� �� �������������� �������. 
 */ 
//��������� �������������
 #include "m8def.inc"

//����������� ���������� (��������� .def)
 .def temp		=R16		//��������� ����������
 .def ADC_Res	=R17		//��������� �� ��������������


//����������� ��������   (��������� .equ)
//��������� �������� ��� ����������� ��������� �������� ���
//��� ��������� 0-5� � ����������� 8��� ��� ��������� ����� 0.02�
//��� ��������� �������� �� ������������ �����, ������������ �����
//����� "�������" � ����� �������� ������� �������� �� 2^8 � ��������
//�� ������ (0.02*2^8=5.1). ����� ���������� �������� �������� � ��� 
//�� ���������� �������� � ��������� �� ������� 2 ������� ������.
.equ ADC_Const  = 5		 
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
RJMP ADC_END		 //���������� �� ��������� �� ��������������
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
//���������� �� ��������� �� ��������������
ADC_END:
LDI temp,ADC_Const		//������� ��������� ��� ��������� ��������� �������� � ��� �� ��������� �������
IN  ADC_Res,ADCH		//��������� ��������� �������� ��� � ���
MUL ADC_Res,temp		//������� �� ��������� (��������� � R0-R1)
MOV ADC_Res,R1			//����� �� 8 �������� ������ ��� ���������� ������� �������� ������� � �������)
OUT PORTB, ADC_Res		//������� ���������� ��������
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

	LDI Temp, 0xFF
	OUT DDRB, Temp

//��������� ���
//ADLAR-������������ �� ������ ����
//REFS- ����� ��������� �������� ����������
//MUX-  ����� ������ ���
	LDI Temp, (1<<ADLAR|1<<REFS0)			//������������� ������ ��� ���� � 1
	OUT ADMUX,Temp							//���������� �������� � ����������� �������
	
//�������������� ���
//ADEN-�������� ���
//ADSC-������ ��������������
//ADFR-����� ����������� ���������
//ADIE-���������� ����������
//ADPS-������������ �������� ������� ���
	LDI Temp, (1<<ADEN|1<<ADSC|1<<ADFR|1<<ADIE|1<<ADPS0|1<<ADPS2)
	OUT ADCSRA, Temp

	SEI		//��������� ����������
MAIN:
			//������� ����������
RJMP MAIN

//������� ����������������� ������ (EEPROM)
.ESEG

