 /*
 * ADC_Example.asm
 *
 *  Created: 25.02.2013 19:50:15
 *  Author: Aleksandr
 *
 * ������: ������� � UART ������ ��������
 *		   
 *
 */ 

//��������� �������������
 #include "m8def.inc"

//����������� ���������� (��������� .def)
 .def TMP     = R16		//��������� ����������

//����������� ��������   (��������� .equ)
 .equ 	XTAL = 4000000					//������� �����������
//������ ��������� ��� ��������� ������� UART	
 .equ 	baudrate = 9600							//����������� ������� UART
 .equ 	baud_const = XTAL/(16*baudrate)-1		//��������� ��� �������

	
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
RJMP RX_OK
.ORG	UDREaddr	 ; USART Data Register Empty
RJMP UD_OK
.ORG	UTXCaddr	 ; USART, Tx Complete
RJMP TX_OK
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
RX_OK:			//����� ��������
IN TMP,UDR		//�������� ����� �� UDR
OUT PORTC,TMP	//������� � ����
RETI

TX_OK:			//�������� ���������
RETI

UD_OK:		//� �������� UDR ���� ������ ��� ��������
	LPM TMP, Z+1
	CPI TMP,0
	BREQ STOP_TX
	OUT UDR, TMP
RETI

STOP_TX:
	//�������� ���������� ��� ������� ������ ��� ��������
	LDI		TMP,(1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(1<<TXCIE)|(0<<UDRIE)
	OUT		UCSRB, TMP
	SEZ		//��������� 1 � ��� Z �������� SREG
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


//����������� ��������������� �����������
	LDI TMP, 0x0F
	OUT DDRC, TMP


//������������� UART:
	LDI 	TMP, LOW(baud_const)			//������� �������
	OUT 	UBRRL,TMP
	LDI 	TMP, HIGH(baud_const)			//������� �������
	OUT 	UBRRH,TMP

	LDI 	TMP, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(1<<TXCIE)|(0<<UDRIE) //���������� ���������, �����-�������� ��������
	OUT		UCSRB,TMP
	LDI 	TMP, (1<<URSEL)|(1<<UCSZ0)|(1<<UCSZ1)	//������ ����� - 8 ���, ��� �������� ��������
	OUT		UCSRC, TMP
	
	SEI					//�������� ����������

MAIN:
	LDI ZL, LOW (ServiceMsg*2)		//��������� ��������� �� ������� ������ � ����������		
	LDI ZH, HIGH(ServiceMsg*2)

H_MSG:
//�������� ���������� ��� ������� ������ ��� ��������
	LDI		TMP,(1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(1<<TXCIE)|(1<<UDRIE)
	OUT		UCSRB, TMP
BREQ STOP		//���� ������ ��� �������� �����������, ������������� ������
RJMP H_MSG		//����� ������� ��������� ������

STOP:
RJMP STOP

//��������� ��� ������ �� �������, �������� �� Flash-������
ServiceMsg: .db "ENTER NUMBER (0-9):",0x0D, 0,0


//������� ����������������� ������ (EEPROM)
.ESEG



