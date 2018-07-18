 /*
 * Dyn_Indication.asm
 *
 *  Created: 20.11.2014 20:50:15
 *  Author: Aleksandr
 *
 * Задача: Разработать устройство - .
 *		   четырехразрядный секундомер с динамической индикацией
 */ 

//Директивы препроцессора
 #include "m8def.inc"

//Определение переменных (директива .def)
 .def TMP       = R16		//Временная переменная
 .def CNT_1N	= R17		//Число для загрузки из памяти (1 разряд)
 .def CNT_2N	= R18		//Число для загрузки из памяти (2 разряд)
 .def CNT_3N	= R19		//Число для загрузки из памяти (3 разряд)
 .def CNT_4N	= R20		//Число для загрузки из памяти (4 разряд)
 .def COUNTER	= R22		//Выбор текущего выводимого разряда на индикаторе
 
 .def MASK		= R21		//Маска для вывода на дисплей (из FLASH)

//Определение констант   (директива .equ)
.equ IND_MSK = 0b00000001	
.equ MAX_CNT = 10			// Для определения переполнения разряда

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
RJMP TIM1M_A
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
//Конец таблицы векторов прерываний	

//Сегмент обработчиков прерываний:

//Прерывание по достижению значения A для TIM1
//Используется для отсчета секунд
TIM1M_A:
START_1N:				//Данные на 1 дисплее
	INC CNT_1N			//Увеличиваем значение
	CPI CNT_1N, MAX_CNT	//Проверяем, требуется переход  
	BREQ START_2N		//к следующему разряду или нет
RETI

START_2N:				//Вывод второго разряда
	CLR CNT_1N			//Отчищаем 1 разряд
	INC CNT_2N			//Увеличиваем 2 разряд
	CPI CNT_2N, MAX_CNT //Проверяем переполнение
	BREQ START_3N
RETI

START_3N:
	CLR CNT_2N
	INC CNT_3N
	CPI CNT_3N, MAX_CNT
	BREQ START_4N
RETI

START_4N:
	CLR CNT_3N
	INC CNT_4N
	CPI CNT_4N, MAX_CNT
	BREQ END_CNT //Если максимальный разряд переполнен
RETI

END_CNT:		//Обнуляем все разряды
	CLR CNT_1N
	CLR CNT_2N
	CLR CNT_3N
	CLR CNT_4N
RETI




//Прерывание по достижению переполнению для TIM0
//Используется для динамической индикации
TIM0OVF:
//Установим указатель на начало массива с символами
	LDI ZH,HIGH (N_mask*2)				
	LDI ZL,LOW (N_mask*2)
	
	CPI COUNTER,0
	BREQ DISP1

	CPI COUNTER,1
	BREQ DISP2

	CPI COUNTER,2
	BREQ DISP3

	CPI COUNTER,3
	BREQ DISP4

DISP1:
	INC COUNTER		//Увеличим счетчик, для того чтобы в следущей итерации
					//обновить другую часть дисплея
	OUT PORTC,MASK  //Выберем необходимый дисплей

//Вывод на дисплей символа из памяти по адресу(ZL+CNT_xN) 
	ADD ZL,CNT_1N	//Прибавим к указателю на Flash нужное значение
	LPM				//Достанем его из памяти (регистр R0)
	OUT PORTD,R0	//Выведем
RETI

DISP2:				//Аналогично
	INC COUNTER
	LSL MASK		//Сместим маску влево
	OUT PORTC,MASK

	ADD ZL, CNT_2N
	LPM
	OUT PORTD,R0
RETI

DISP3:				//Аналогично
	INC COUNTER
	LSL MASK
	OUT PORTC,MASK

	ADD ZL, CNT_3N
	LPM
	OUT PORTD,R0
RETI

DISP4:				//Аналогично
	LSL MASK
	OUT PORTC,MASK

	ADD ZL, CNT_4N
	LPM
	OUT PORTD,R0

//Отчистим счетчик итераций и вернем маску к начальному значению
	CLR COUNTER
	LDI MASK,IND_MSK
RETI

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

//Подключение 7 сегментных дисплеев(общий анод, включение низким уровнем)
	LDI TMP,0xFF
	OUT DDRD,TMP		//8 бит данных
	OUT PORTD,TMP

	LDI TMP,0x0F		//4 бита управляющих (биты выбора активного дисплея)
	OUT DDRC,TMP

//Подключение кнопок SB_START, SB_STOP
	LDI TMP, 0b00000011
	OUT PORTB, TMP

//Настройка таймеров TIM0, TIM1
LDI TMP, 1<<TOIE0|1<<OCIE1A	//Разрешим прерывание TIM0 переполнению 
OUT TIMSK, TMP				//и TIM1 по совпадению с A

LDI TMP, 1<<CS00|1<<CS01	//Запустим таймер динамической индикации
OUT TCCR0,TMP

LDI TMP, 1<<WGM12			//Режим работы таймера TIM1, сброс при достижении значения
OUT TCCR1B, TMP

//Запись в 16-разрядный регистр TCNT
LDI TMP, HIGH(62500)
OUT	OCR1AH, TMP		//Первым пишется старший байт
LDI TMP, LOW(62500)
OUT	OCR1AL, TMP		//Вторым младший

SEI

//Установка базовых переменных
LDI MASK, IND_MSK

MAIN:

//Проверяем нажата ли кнопка "START"?
	SBIS PINB,0
	RJMP SB_START

//Нажата ли кнопка "STOP"?
	SBIS PINB,1
	RJMP SB_STOP
RJMP MAIN

SB_START:	
	SBIS PINB,0		//Кнопка опущена?
RJMP SB_START		//Нет, ждем отпускания, иначе продолжаем выполнять
	LDI TMP, 1<<CS00|1<<CS11
	OUT TCCR1B,TMP
RJMP MAIN

SB_STOP:	
	SBIS PINB,1		//Кнопка опущена?
RJMP SB_STOP		//Нет, ждем отпускания, иначе продолжаем выполнять
	LDI TMP, 0<<CS00|0<<CS11
	OUT TCCR1B,TMP
RJMP MAIN

//Маска цифр для вывода на семисегментный дисплей (расположен во FLASH памяти),
//в отличии от программ (7seg) инвертирован
N_mask:
.db 0b11000000, 0b11111001, 0b10100100, 0b10110000, 0b10011001, 0b10010010, 0b10000010, 0b11111000, 0b10000000, 0b10010000

//Сегмент энергонезависимой памяти (EEPROM)
.ESEG