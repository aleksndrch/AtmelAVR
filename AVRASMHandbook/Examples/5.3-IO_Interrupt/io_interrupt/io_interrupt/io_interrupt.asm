 /*
 *
 *
 *  Created: 25.02.2013 19:50:15
 *  Author: Aleksandr
 *
 * Задача: Разработать устройство работающее с портами ввода/вывода.
 *		   Показать работу 7 сегментного дисплея. Внешние прерывания.		 
 */ 
//Директивы препроцессора
 #include "m8def.inc"

//Определение переменных (директива .def)
 .def TMP       = R16		//Временная переменная
 .def L_Counter = R17		//Счетчик символов


//Определение констант   (директива .equ)
.equ END_STRING = 10
	
//Сегмент ОЗУ (RAM)
.DSEG

 //Сегмент кода (Flash)
.CSEG
.ORG 0x0000
	RJMP RESET
//Таблица векторов прерываний:
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
//Конец таблицы векторов прерываний	

//Сегмент обработчиков прерываний
INT0I:
	
	CPI L_COUNTER, END_STRING	//Проверяем, дошли до конца строки?
	BRNE STR_OUT				//Нет, выводим следующий символ
	CLR L_Counter				//Да, обнуляем счетчик
	
STR_OUT:
	ADD ZL,L_Counter		//Сместим указатель на элемент массива символов на величину равную номеру требуемого к выводу символа
	LPM						//Достанем символ из адреса на который указывает указатель
	OUT PORTC,R0			//Выведем его на дисплей
	INC L_Counter			//Увеличим номер выводимого символа на единицу
RETI
//Конец сегмента обработчиков прерываний


RESET:
//Инициализация стека: (обязательно во всех МК с программным стеком AtMega)
	LDI R16, LOW(RAMEND)	//Загрузка указателя стека в конец SRAM
	OUT SPL, R16
	LDI R16, HIGH(RAMEND)	//Загрузка указателя стека в конец SRAM
	OUT SPH, R16

//Настройка портов ввода/вывода
//DDRx  - направление работы линии порта x (1-выход, 0-вход)
//PORTx - Значение уровня на линии порта x (1-высокий, 0-низкий)
//		  если порт x настроен как вход    (1-PullUp) 
//PINx  - Уровень сигнала на линии порта x (Только для чтения)		

//Подключение 7 сегментного дисплея (PORTB) - все линии на выход
	LDI TMP, 0xFF
	OUT DDRC, TMP
//Подключение кнопок (PORTD)-линии 2 - вход с подтяжкой
	LDI TMP, 0b00000100
	OUT PORTD, TMP

//Настройка внешнего прерывания INT0 (для обработки нажатия на кнопку)
LDI TMP, 1<<ISC01		//Прериывание по спадающему фронту
OUT MCUCR, TMP
LDI TMP, 1<<INT0		//Разрешение прерывания
OUT GIMSK,TMP

SEI						//Не забываем вообще разрешить прерывания

MAIN:
//Установим указатель на начало массива с символами
	LDI ZH,HIGH (N_mask*2)				
	LDI ZL,LOW (N_mask*2)		

RJMP MAIN


//Маска цифр для вывода на семисегментный дисплей (расположен во FLASH памяти)
N_mask:
.db 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01101111



//Сегмент энергонезависимой памяти (EEPROM)
.ESEG



