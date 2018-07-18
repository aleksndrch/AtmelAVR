/*
 * Keyboard.asm
 *
 *  Created: 09.04.2013 19:20:23
 *  Author: Aleksandr
 * Задача: Разработать устройство считывающее нажатие
 *		   с матрицы кнопок, считанное значение преобразовать
 *		   в код точно показывающий какая именно кнопка нажата.
 */ 

 
//Директивы препроцессора
 #include "m8def.inc"

 //Определение переменных (директива .def)
 .def TMP = R16		//Временная переменная
 .def CNT = R17		//Счетчик
 .def MSK = R18		//Маска и результат


 //Определение констант   (директива .equ)
 .equ KEYMSK  = 0b11011111		//Маска для снятия значения со столбцов
 .equ SCANMSK = 0b11100000		//Маска для того чтобы не "портить" оставшиеся линии порта

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

//Строки - входы с подключенным подтягивающим резистором (PullUp)
	LDI TMP, 0b00001111
	OUT PORTD, TMP
//Столбцы - выходы c высоким уровнем
	LDI TMP, 0b11100000
	OUT DDRB,  TMP
	OUT PORTB, TMP
//Порт вывода результата - выход
	LDI TMP, 0b11111111
	OUT DDRC, TMP

MAIN:
RCALL KEYB_INIT		//Вызываем процедуру опроса клавиатуры
CPI MSK,0			//Если кнопки не нажимались в маске 0, продолжаем опрос
BREQ MAIN			//Если да, переходим к началу опроса

//OUT PORTC, MSK		//Иначе выводим значение в порт
//RJMP MAIN				//Для создания таблицы соответствия
//При использовании порта с неполным количеством линий
//обратить внимание!!!

RJMP FIND_SYMBOL_INIT
RJMP MAIN			//К началу

//Инициализация функции декодирования
FIND_SYMBOL_INIT:
CLR TMP			//На всякий случай отчищаем временный регистр
LDI ZH,HIGH(Code_table*2)	//Загружаем указатель на массив
LDI ZL,LOW(Code_table*2)

//Непосредственно поиск символа
FIND_SYMBOL:
LPM TMP,Z+	//Считаем значение по адресу Z и инкрементируем адрес(Z+)
//Теперь указатель указывает на реальное значение
CPI TMP,0xFF//Конец массива?
BREQ MAIN	//Да, выходим из функции

CP MSK,TMP	//Значение найдено в массиве?
BREQ DISPLAY_OUT	//Выводим

LPM TMP, Z+	//Если нет, то снова увеличиваем адрес чтобы пропустить
//адрес в котором лежит реальное значение и продолжаем поиск
RJMP FIND_SYMBOL

DISPLAY_OUT:
LPM TMP,Z		//Загружаем значение из массива
OUT PORTC,TMP	//Выводим его
RJMP MAIN

//Функция сканирования клавиатуры
KEYB_INIT:
	LDI CNT,3			//Выставляем счетчик проходов (по количеству столбцов)
	LDI MSK, KEYMSK		//Загружаем маску опроса

KEYB_SCAN:	
	IN  TMP, PORTB		//Во временный регистр записываем значения опрашиваемого порта (чтобы не "испортить")
	ORI TMP, SCANMSK	//Выставляем в 1 все линии опроса

	AND TMP, MSK		//Логическим И выделяем опрашиваемую линию
	OUT PORTB, TMP		//Выводим в маску в порт

	NOP					//Задержка для того чтобы сигналы 
	NOP					//точно установились
	NOP
	NOP

	NOP
	NOP
	NOP
	NOP


	SBIS PIND,0			//Нажата кнопка в 1 ряду?
	RJMP SB1

	SBIS PIND,1			//Нажата кнопка в 2 ряду?
	RJMP SB2

	SBIS PIND,2			//Нажата кнопка в 3 ряду?
	RJMP SB3

	SBIS PIND,3			//Нажата кнопка в 4 ряду?
	RJMP SB4

	ROL MSK				//Сдвигаем опрашиваемый бит влево
	
	DEC CNT				//Уменьшаем счетчик циклов

	BRNE KEYB_SCAN		//Если не равен 0, продолжаем опрос
	CLR MSK				//Иначе "чистим" значение маски
	RET					//Возвращаемся в основной цикл

//Нажата кнопка в 1 ряду
SB1:
	ANDI MSK,SCANMSK	//Формируем сканированное значение, выделяя значащие биты
	ORI MSK, 0x01		//Кнопка нажата в первом ряду
RET

//Нажата кнопка в 2 ряду
SB2:
	ANDI MSK,SCANMSK	//Формируем сканированное значение, выделяя значащие биты
	ORI MSK, 0x02		//Кнопка нажата в первом ряду
RET

//Нажата кнопка в 3 ряду
SB3:
	ANDI MSK,SCANMSK	//Формируем сканированное значение, выделяя значащие биты
	ORI MSK, 0x03		//Кнопка нажата в первом ряду
RET

//Нажата кнопка в 4 ряду
SB4:
	ANDI MSK,SCANMSK	//Формируем сканированное значение, выделяя значащие биты
	ORI MSK, 0x04		//Кнопка нажата в первом ряду
RET

//Таблица соответствия
Code_table:
.db 0xC1,0x01 //1
.db 0xA1,0x02 //2
.db 0x61,0x03 //3
.db 0xC2,0x04 //4
.db 0xA2,0x05 //5
.db 0x62,0x06 //6
.db 0xC3,0x07 //7
.db 0xA3,0x08 //8
.db 0x63,0x09 //9
.db 0xC4,0x0A //*(a)
.db 0xA4,0x00 //0
.db 0x64,0x0B //#(b)
.db 0xFF,0    //Конец массива

//Сегмент энергонезависимой памяти (EEPROM)
.ESEG



