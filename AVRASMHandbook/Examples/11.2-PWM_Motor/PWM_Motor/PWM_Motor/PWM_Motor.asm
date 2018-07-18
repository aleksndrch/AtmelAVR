/*
 * PWM_Motor.asm
 *
 *  Created: 23.11.2014 18:51:00
 *   Author: Aleksandr

Устройство при нажатии на кнопку изменят положение двигателя на +45 по отношению 
к предыдущему, диапазон от 0 +180, при достижении максимального значения двигатель
возвращается в 0.
Обработка нажатия кнопки реализвана прерыванием (прерывание при спаду), поэтому
для того чтобы при запуске не было случайных срабатываний поддяжка обязательна 
даже в Proteus

Рачеты:
Минимальная длительность импульса  1мс
Максимальная длительность импульса 2мс
Частота МК – 2Мгц, делитель 8
Значение регистра ICR1 – 4999 
Градусы    Импульсы (мс)   В регистр OCR1A
0               1				250
45             1.25				312
90             1.5				375	
135            1.75				437
180             2				500	
 */ 

//Директивы препроцессора
 #include "m8def.inc"

//Определение переменных (директива .def)
 .def TMP     = R16		//Временная переменная
 .def CNT     = R17		//Счетчик


//Определение констант   (директива .equ)
//Определение констант   (директива .equ)
 .equ 	XTAL   = 2000000					//Частота контроллера
 .equ	T1_PSK = 8							//Предделитель таймера	
//Расчет констант для требуемой частоты ШИМ и необходимой скважности импульсов	
 .equ 	PWM = 50						//Необходимая частота ШИМ
 .equ 	PWM_const = (XTAL-T1_PSK*PWM)/(T1_PSK*PWM)		//Константа для частоты
//Расчет констант для определения угла вращения
 .equ   RP0   = 1000/4		//Вычисляется как длина импульса для угла поворота (в мкс)
 .equ   RP45  = 1250/4		//разделить на период работы таймера (в мкс)
 .equ   RP90  = 1500/4		//период работы таймера равен 1/(XTAL/T1_PSK)
 .equ   RP135 = 1750/4
 .equ   RP180 = 2000/4

	
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
INC CNT

CPI CNT,2
BREQ ROTATE90

CPI CNT,3
BREQ ROTATE135

CPI CNT,4
BREQ ROTATE180

CPI CNT,5
BREQ ROTATE0

//Поворот в 45
ROTATE45:
//Запишем необходимые значения в регистры сравнения (не забывая про порядок записи!)
	LDI TMP,HIGH(RP45)
	OUT OCR1AH,TMP

	LDI TMP,LOW(RP45)
	OUT OCR1AL,TMP
RETI

//Поворот в 90
ROTATE90:
//Запишем необходимые значения в регистры сравнения (не забывая про порядок записи!)
	LDI TMP,HIGH(RP90)
	OUT OCR1AH,TMP

	LDI TMP,LOW(RP90)
	OUT OCR1AL,TMP
RETI

//Поворот в 135
ROTATE135:
//Запишем необходимые значения в регистры сравнения (не забывая про порядок записи!)
	LDI TMP,HIGH(RP135)
	OUT OCR1AH,TMP

	LDI TMP,LOW(RP135)
	OUT OCR1AL,TMP
RETI

//Поворот в 180
ROTATE180:
//Запишем необходимые значения в регистры сравнения (не забывая про порядок записи!)
	LDI TMP,HIGH(RP180)
	OUT OCR1AH,TMP

	LDI TMP,LOW(RP180)
	OUT OCR1AL,TMP
RETI

//Поворот в 0
ROTATE0:
//Запишем необходимые значения в регистры сравнения (не забывая про порядок записи!)
	LDI TMP,HIGH(RP0)
	OUT OCR1AH,TMP

	LDI TMP,LOW(RP0)
	OUT OCR1AL,TMP

	CLR CNT
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

//Настроим линию OC1A на выход
	LDI TMP, 0b000000010
	OUT DDRB,TMP

//Настройка внешнего прерывания INT0 (для обработки нажатия на кнопку)
LDI TMP, 1<<ISC01		//Прериывание по спадающему фронту
OUT MCUCR, TMP
LDI TMP, 1<<INT0		//Разрешение прерывания
OUT GIMSK,TMP


//Настройка таймера TIM1 для работы в режиме ШИМ (режим 14, datasheet p.98)
//Данный режим сбрасывает ШИМ при достижении определенного значения что
//позволяет добиться необходимой частоты его работы 50Гц
	LDI TMP,HIGH(PWM_const)				//Записываем ранее вычесленное значени
	OUT ICR1H,TMP						//Не забывая о порядке записи		
	LDI TMP,LOW(PWM_const)
	OUT ICR1L,TMP
	
	LDI TMP, 1<<COM1A1|1<<WGM11	//Настроим ШИМ WGM11,WGM12,WGM13 - режим 14
	OUT TCCR1A, TMP				//COM1A1 - сброс линии при совпадении (non-inverting mode)

	LDI TMP, 1<<WGM12|1<<CS11|1<<WGM13		//CS11 - предделитель 8
	OUT TCCR1B, TMP

	SEI
	
MAIN:

RJMP MAIN


//Сегмент энергонезависимой памяти (EEPROM)
.ESEG

