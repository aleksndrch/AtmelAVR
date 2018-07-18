 /*
 * ADC_Example.asm
 *
 *  Created: 25.02.2013 19:50:15
 *  Author: Aleksandr
 *
 * Задача: Разработать устройство измеряющее напряжении
 *		   на 0 канале АЦП (ADC0) и выводящее результат 
 *		   измерения на семисегментный дисплей. 
 */ 
//Директивы препроцессора
 #include "m8def.inc"

//Определение переменных (директива .def)
 .def temp		=R16		//временная переменная
 .def ADC_Res	=R17		//результат АЦ преобразования


//Определение констант   (директива .equ)
//Расчитаем значение для определения релаьного значения АЦП
//При диапазоне 0-5В и разрядности 8бит шаг измерений будет 0.02В
//Для умножения значения на вещественное число, вещественное число
//Нужно "загнать" в целый диапазон умножив например на 2^8 и округлив
//До целого (0.02*2^8=5.1). Затем необходимо умножить значение с АЦП 
//На полученное значение и разделить на степень 2 сдвигом вправо.
.equ ADC_Const  = 5		 
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
RJMP ADC_END		 //Прерывание по окончанию АЦ преобразования
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
//Прерывание по окончанию АЦ преобразования
ADC_END:
LDI temp,ADC_Const		//Запишем константу для получения реального значения с АЦП во временный регистр
IN  ADC_Res,ADCH		//Перенесем полученое значение АЦП в РОН
MUL ADC_Res,temp		//Умножим на константу (результат в R0-R1)
MOV ADC_Res,R1			//Сдвиг на 8 разрядов вправо это фактически перенос старшего разряда в младший)
OUT PORTB, ADC_Res		//Выведем полученное значение
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

	LDI Temp, 0xFF
	OUT DDRB, Temp

//Настройка АЦП
//ADLAR-Выравнивание по левому краю
//REFS- Выбор источника опорного напряжения
//MUX-  Выбор канала АЦП
	LDI Temp, (1<<ADLAR|1<<REFS0)			//Устанавливаем нужные нам биты в 1
	OUT ADMUX,Temp							//Записываем значение в управляющий регистр
	
//Инициализируем АЦП
//ADEN-Включить АЦП
//ADSC-Начать преобразование
//ADFR-Режим непрерывных измерений
//ADIE-Разрешение прерывания
//ADPS-Предделитель тактовой частоты АЦП
	LDI Temp, (1<<ADEN|1<<ADSC|1<<ADFR|1<<ADIE|1<<ADPS0|1<<ADPS2)
	OUT ADCSRA, Temp

	SEI		//Разрешаем прерывания
MAIN:
			//Ожидаем прерывание
RJMP MAIN

//Сегмент энергонезависимой памяти (EEPROM)
.ESEG

