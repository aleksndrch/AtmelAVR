 /*
 * EEPROM.asm
 *
 *  Created: 25.02.2013 19:50:15
 *  Author: Aleksandr
 *
 * Задача: Разработать устройство использующее память EEPROM для хранения констант.
   Есть три кнопки, вверх, чтение, запись, при нажатии кнопки вврех, на 1 дисплее меняется значение
   при нажатии кнопки запись, оно записывается, при нажатии кнопки чтение выводится на второй дисплей. 
   Дисплеи использую один порт МК 		 
 */ 
//Директивы препроцессора
 #include "m8def.inc"

//Определение переменных (директива .def)
 .def TMP     = R16		//Временная переменная
 .def CNT_U   = R17		//Счетчик первого дисплея
 .def CNT_L	  = R18		//Счетчик второго дисплея

 .def EE_AddrH = R19	//Адрес для записи (старший)
 .def EE_AddrL = R20	//Адрес для записи (младший)

//Определение констант   (директива .equ)
.equ CNT_MAX	=10		//Для ограничение вывода на дисплей значений (0-9)
.equ D1_MASK    =0b00001111
.equ D2_MASK    =0b11110000

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

//Подключение кнопок (PORTB)-линии 0,1,2 - вход с подтяжкой
	LDI TMP, 0b00000011
	OUT PORTB, TMP

	LDI TMP, 0xFF
	OUT DDRD, TMP

	LDI CNT_U,1 //Для правильного вывода числе (при запуске 0, первое нажатие 1)

MAIN:
//Проверяем нажата ли кнопка "SAVE"?
SBIS PINB,0
RJMP SB_SAVE

//Нажата ли кнопка "LOAD"?
SBIS PINB,1
RJMP SB_LOAD

//Нажата ли кнопка "UP"?
SBIS PINB,2
RJMP SB_UP

RJMP MAIN

//Нажата кнопка SAVE
SB_SAVE:
SBIS PINB,0		//Кнопка опущена?
RJMP SB_SAVE	//Нет, ждем отпускания, иначе продолжаем выполнять программу

RCALL EE_WRITE	//Вызываем функцию записи

RJMP MAIN


//Нажата кнопка LOAD (все процедуры аналогичны кнопке "SAVE")
SB_LOAD:
SBIS PINB,1
RJMP SB_LOAD

RCALL EE_READ	//Вызывем функцию чтения
	DEC CNT_L		//Уменьшаем так как в память записывается значение на 1 больше.
	SWAP CNT_L		//Переставляем тетрады (дисплеи на одном порту)
	IN TMP, PORTD	  //Сохраняем текущее значение порта (чтобы не испортить)
	ANDI TMP, D1_MASK //Маскируем
	OR TMP, CNT_L	  //Обновляем значение
OUT PORTD,TMP		  //И выводим

RJMP MAIN

//Нажата кнопка UP (все процедуры аналогичны кнопке "SAVE")
SB_UP:
SBIS PINB,2
RJMP SB_UP
	IN TMP, PORTD		//Аналогично SB_LOAD
	ANDI TMP, D2_MASK
	OR TMP, CNT_U
	OUT PORTD,TMP
	INC CNT_U
	CPI CNT_U, CNT_MAX
BREQ CLEAR_CNT			//Если дошли до 9, сбрасываем счетчик
RJMP MAIN

//Отчистка константы для перехода в 0.
CLEAR_CNT:
CLR CNT_U
RJMP MAIN

//Функция записи EEPROM
EE_WRITE:
SBIC EECR,EEWE	//Ожидаем готовность памяти к записи
RJMP EE_WRITE	//То есть установку флага EEWE

OUT EEARL, EE_AddrL	//Загружаем адрес необходимой ячейки (0)
OUT EEARH, EE_AddrH //(старший и младший)
OUT EEDR,  CNT_U	//и сами данные

SBI EECR, EEMWE		//Устанавливаем бит предохранитель
SBI EECR, EEWE		//Записываем байт

RET

//Функция чтения EEPROM
EE_READ:
SBIC EECR, EEWE		//Ждем окончания предыдущей записи
RJMP EE_READ

OUT EEARL, EE_AddrL	//Выставляем адрес
OUT EEARH, EE_AddrH

SBI EECR,EERE		//Выставляем бит чтения
IN CNT_L, EEDR		//Читаем бит из ячейки памяти
RET

//Сегмент энергонезависимой памяти (EEPROM)
.ESEG

