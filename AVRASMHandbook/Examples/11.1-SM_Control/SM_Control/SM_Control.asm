/*
 * SM_Control.asm
 *
 *  Created: 22.11.2014 16:06:42
 *   Author: Aleksandr
 * Программа реализует управление шаговым двигателем в полушаговом режиме, можно запускать двигатель как в прямом направлении, 
 * так и в реверсе, можно остановить двигатель, подача сигналов в порт реализована циклично по прерыванию таймера TIM0,
 * таким образом частота вращения двигателя будет зависеть от того как часто происходит прерывание по переполнению таймера. 
 * в программе предделитель таймера выставлен на 1024, частота МК предполается 4МГц, то есть таймер будет переполняться 
 * примерно 15 раз в секунду, и двигатель будет переходить в следующее положение (всего их 8).
 */ 

//Директивы препроцессора
 #include "m8def.inc"

//Определение переменных (директива .def)
 .def TMP       = R16		//Временная переменная
 .def CNT       = R17		//Счетчик указатель
 .def FR_FLAG	= R18		//Флаг направления вращения

//Определение констант   (директива .equ)
.equ CNT_MAX    = 8			//Для определения переполнения разряда
.equ F_FLAG_EN  = 1			//Прямой ход
.equ R_FLAG_EN  = 2			//Реверс

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

//Сегмент обработчиков прерываний:
//Прерывание по достижению переполнению для TIM0

TIM0OVF:
MOTOR_CONTROL:				//Определение режима работы
	CPI FR_FLAG,R_FLAG_EN	//Флаг реверса поднят?
	BREQ SM_REVERSE			//Да, переодим к SM_REVERSE
//Прямое вращение двигателя
SM_FORWARD:
	ADD ZL, CNT				//Считываем из памяти значение
	LPM
	OUT PORTD,R0			//Выводим в порт
	INC CNT					//Увеличиваем
	CPI CNT,CNT_MAX			//Достигли максимума?
	BREQ RES_CNT			//Сбрасываем счетчик
RETI

//Реверс (аналогично прямому ходу)
SM_REVERSE:
	ADD ZL, CNT
	LPM
	OUT PORTD,R0
	DEC CNT
	CPI CNT,0
	BREQ RES_CNTR
	CPI CNT,-1		//На случай если вылезли за границу
	BREQ RES_CNTR
RETI

//Сброс счетчика прямого хода
RES_CNT:
LDI CNT,0
RETI

//Сброс счетчика реверса
RES_CNTR:
LDI CNT,CNT_MAX
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

//Настройка порта управляющего шаговым двигателм
	LDI TMP,0x0F		//Первая половина порта на вывод
	OUT DDRD,TMP		
	LDI TMP,0x0F		//Высокий уровень (управление низким)
	OUT PORTD,TMP

//Подключение кнопок SB_STOP, SB_FORWARD, SB_REVERSE
	LDI TMP, 0b00000111
	OUT PORTB, TMP

//Настройка таймеров TIM0
	LDI TMP, 1<<TOIE0	//Разрешим прерывание TIM0 переполнению 
	OUT TIMSK, TMP				

	SEI 
MAIN:
	LDI ZH,HIGH (SM_mask*2)				
	LDI ZL,LOW (SM_mask*2)
//Проверяем нажата ли кнопка "STOP"?
	SBIS PINB,2
	RJMP SB_STOP
//Нажата ли кнопка "FORWARD"?
	SBIS PINB,0
	RJMP SB_FORWARD
//Проверяем нажата ли кнопка "REVERSE"?
	SBIS PINB,1
	RJMP SB_REVERSE
RJMP MAIN

//Обработчик кнопки STOP
SB_STOP:
	SBIS PINB,2					//Кнопка опущена?
RJMP SB_STOP					//Нет, ждем отпускания, иначе продолжаем выполнять	
	LDI TMP, 0<<CS00|0<<CS02	//Останавливаем таймер
	OUT TCCR0,TMP
	CLR FR_FLAG					//Отчищаем флаги направления вращения
RJMP MAIN

//Обработчик кнопки FORWARD
SB_FORWARD:
	SBIS PINB,0		//Кнопка опущена?
RJMP SB_FORWARD		//Нет, ждем отпускания, иначе продолжаем выполнять	
	LDI FR_FLAG,F_FLAG_EN		//Устанавливаем влаг прямого вращения
	LDI TMP, 1<<CS00|1<<CS02	//Запускаем таймер
	OUT TCCR0,TMP
RJMP MAIN

//Обработчик кнопки REVERSE
SB_REVERSE:	
	SBIS PINB,1		//Кнопка опущена?
RJMP SB_REVERSE		//Нет, ждем отпускания, иначе продолжаем выполнять

//Для того чтобы начать вращения в реверсе с той позиции которая была 
//в предыдущий момент времени (если до этого двигатель вращался)	
	CPI FR_FLAG, F_FLAG_EN		//Проверяем вращался ли до этого двигатель
	BREQ REVERSE_CONTINUE		//Да? Пропускаем инициализацию режима
//Инициализация режима реверса
	LDI CNT,CNT_MAX				//Загружаем в счетчик значение указывающее на конец массива
	LDI TMP, 1<<CS00|1<<CS02	//Запустим таймер 
	OUT TCCR0,TMP

REVERSE_CONTINUE:
	LDI FR_FLAG,R_FLAG_EN
RJMP MAIN

//Маска значений для вращения двигателя
SM_mask:
.db  0b00001110,0b00001100, 0b00001101, 0b00001001, 0b00001011, 0b00000011, 0b00000111, 0b00000110, 0b00001110,0

//Сегмент энергонезависимой памяти (EEPROM)
.ESEG