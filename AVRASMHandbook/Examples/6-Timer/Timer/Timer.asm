 /*
 * ADC_Example.asm
 *
 *  Created: 25.02.2013 19:50:15
 *  Author: Aleksandr
 *
 * Задача: Разработать простейший одноразрядный секундомер
 *		   на базе аппаратного таймера.
 *
 *При работе на 4МГц 8разрядный таймер с установленным предделитем 64, 
 *(частота таймера составит 62500Гц), переполнение будет наступать раз в 0.004с,
 *если в прерывание добавить дополнительный 8 разрядный счетчик то можно
 *отсчитывать 0.004с*256, то есть примерно 1.04с, что будем считать
 *достаточной точностью.
 */ 

//Директивы препроцессора
 #include "m8def.inc"

//Определение переменных (директива .def)
 .def TMP     = R16		//Временная переменная
 .def CNT     = R17		//Счетчик
 .def NUM	  = R18		//Значение выводимое на дисплей

//Определение констант   (директива .equ)
.equ MAX_V	  = 0xFF	//Максимально возможное значение регистра
.equ MAX_NUM  = 10		//Значение для того чтобы вовремя обнулить значение на дисплее
	
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

//Сегмент обработчиков прерываний
TIM0OVF:
	DEC CNT				//Уменьшаем счетчик
	BREQ DELAY1S		//Счетчик равен 0? (переполнение произошло 256 раз)
	RETI				//Нет, ждем

	DELAY1S:			
	LDI CNT,MAX_V		//Запишем в регистр-счетчик новое значение для задержки в 1 сек
	INC NUM				//Увеличим число которое собираемся выводить

	CPI NUM,MAX_NUM		//Дошли до предельного значения?
	BREQ ZERO			//Да, обнуляем

	OUT PORTC,NUM		//Нет, выводим на дисплей
RETI
ZERO:
	CLR NUM				//Обнуляем значение
	OUT PORTC,NUM		//Выводим на дисплей
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


//Подключение линейки дисплея (PORTC) - линии (0-4) на выход
	LDI TMP, 0b00001111
	OUT DDRC, TMP
//Подключение кнопок (PORTD)-линии 0,1 - вход с подтяжкой
	LDI TMP, 0b00000011
	OUT PORTD, TMP

//Настройка таймера TIM0
	LDI TMP, (1<<TOIE0)	//Разрешим прерывания по перепполнению таймера (по умолчанию запрещены)
	OUT TIMSK, TMP
	
	LDI CNT,MAX_V		//Запишем в регистр-счетчик значение для задержки в 1 сек

	SEI					//Разрешим прерывания

MAIN:
//Проверяем нажата ли кнопка "Старт"?
SBIS PIND,0
RJMP SB_START

//Нажата ли кнопка "Стоп"?
SBIS PIND,1
RJMP SB_STOP

RJMP MAIN

//Нажата кнопка "Старт"
SB_START:	
SBIS PIND,0		//Кнопка опущена?
RJMP SB_START	//Нет, ждем отпускания, иначе продолжаем выполнять программу

//Таймеры запускаются выставлением значения в предделителе (биты CSxx регистра TCCR0)
LDI TMP, (1<<CS00)|(1<<CS01)	// Предделитель (/64)
OUT TCCR0,TMP					// Записываем значение в регистр

RJMP MAIN

SB_STOP:	
SBIS PIND,0		//Кнопка опущена?
RJMP SB_STOP	//Нет, ждем отпускания, иначе продолжаем выполнять программу

//Останавливаем таймер обнуляя биты предделителя
LDI TMP, (0<<CS00)|(0<<CS01)	// Предделитель обнуляем
OUT TCCR0,TMP					// Записываем значение в регистр

RJMP MAIN
//Сегмент энергонезависимой памяти (EEPROM)
.ESEG

