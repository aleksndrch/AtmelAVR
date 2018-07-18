 /*
 * 
 *
 *  Created: 25.02.2013 19:50:15
 *  Author: Aleksandr
 *
 * Задача: Разработать устройство работающее с портами ввода/вывода.
 *		   Показать работу кнопок и светоидов. Организовать программную задержку.		 
 */ 
//Директивы препроцессора
 #include "m8def.inc"

//Определение переменных (директива .def)
 .def TMP     = R16		//Временная переменная
 .def CNT     = R17		//Счетчик
 .def CNT2    = R18		//Дополнительный счетчик
 .def SB_FLAG = R19		//Флаг нажатия кнопки

//Определение констант   (директива .equ)
.equ  LED_MSK  = 0b00010001
.equ  FST_PUSH = 1
	
//Сегмент ОЗУ (RAM)
.DSEG

 //Сегмент кода (Flash)
.CSEG
.ORG 0x0000
	RJMP RESET
//Таблица векторов прерываний:
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
//Конец таблицы векторов прерываний	

//Сегмент обработчиков прерываний

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


//Подключение линейки светоидов (PORTB) - все линии на выход
	LDI TMP, 0xFF
	OUT DDRB, TMP
//Подключение кнопок (PORTD)-линии 0,1,2 - вход с подтяжкой
	LDI TMP, 0b00000111
	OUT PORTD, TMP

MAIN:
//Проверяем нажата ли кнопка "ВВЕРХ"?
SBIS PIND,0
RJMP SB_UP

//Нажата ли кнопка "ВНИЗ"?
SBIS PIND,1
RJMP SB_DOWN

RJMP MAIN

//Нажата кнопка вверх
SB_UP:	
SBIS PIND,0		//Кнопка опущена?
RJMP SB_UP		//Нет, ждем отпускания, иначе продолжаем выполнять программу

INC SB_FLAG		//Установим флаг нажатия кнопки

CPI SB_FLAG,FST_PUSH	//Кнопка нажата первый раз?
BRNE CLR_MASK			//Нет? Надо остановиться и перейти к обнулению линейки

LDI TMP, LED_MSK		//Иначе запише во временный регистр маску движения светоидов

UP_CYCLE:				//Цикл движения вверх (фактически вправо)
ROR TMP					//Сдвигаем маску вправо
RCALL DELAYnS			//Для наглядности вводим маленькую задержку (на частоте 1МГц достаточно)
OUT PORTB,TMP			//Выводим маску в порт

//Проверяем нажимались ли кнопки, если да обрабатываем нажатие и останавливаем вывод
SBIS PIND,0				
RJMP SB_UP

SBIS PIND,1
RJMP SB_DOWN
//Если нет, продолжаем вывод в цикле
RJMP UP_CYCLE

//Нажата кнопка вниз (все процедуры аналогичны кнопке "ВВЕРХ")
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


//Отчистка флага кнопки и обнуление показаний на линейке 
CLR_MASK:
CLR SB_FLAG			//Устанавливаем флаг в 0
OUT PORTB,SB_FLAG	//Выводин на линейку 0
RJMP MAIN

//Задержка
DELAYnS:
	LDI CNT,255		//Записываем в счетчик 255
	LDI CNT2,255	//Записываем в дополнительный счетчик 255
DELAY_CYCLE:
	DEC CNT			 //Уменьшаем
	BRNE DELAY_CYCLE //Дошли до 0?
DELAY2_CYCLE:
	LDI CNT,255		//Загружаем в счетчик новое значение
	DEC CNT2		//Уменьшаем на еденицу дополнительный счетчик
	BRNE DELAY_CYCLE//Дошли до нуля? Если нет возвращаемся к первому циклу	
RET					 //Выходим



//Сегмент энергонезависимой памяти (EEPROM)
.ESEG

