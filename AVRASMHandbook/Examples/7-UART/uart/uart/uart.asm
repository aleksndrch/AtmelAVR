 /*
 * ADC_Example.asm
 *
 *  Created: 25.02.2013 19:50:15
 *  Author: Aleksandr
 *
 * Задача: Вывести в UART строку символов
 *		   
 *
 */ 

//Директивы препроцессора
 #include "m8def.inc"

//Определение переменных (директива .def)
 .def TMP     = R16		//Временная переменная

//Определение констант   (директива .equ)
 .equ 	XTAL = 4000000					//Частота контроллера
//Расчет константы для требуемой частоты UART	
 .equ 	baudrate = 9600							//Необходимая частота UART
 .equ 	baud_const = XTAL/(16*baudrate)-1		//Константа для частоты

	
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
//Конец таблицы векторов прерываний	

//Сегмент обработчиков прерываний
RX_OK:			//Прием завершен
IN TMP,UDR		//Забираем число из UDR
OUT PORTC,TMP	//Выводим в порт
RETI

TX_OK:			//Передача завершена
RETI

UD_OK:		//В регистре UDR есть данные для передачи
	LPM TMP, Z+1
	CPI TMP,0
	BREQ STOP_TX
	OUT UDR, TMP
RETI

STOP_TX:
	//Запретим прерывание при наличии данных для передачи
	LDI		TMP,(1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(1<<TXCIE)|(0<<UDRIE)
	OUT		UCSRB, TMP
	SEZ		//Установим 1 в бит Z регистра SREG
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


//Подключение семисегментного индиикатора
	LDI TMP, 0x0F
	OUT DDRC, TMP


//Инициализация UART:
	LDI 	TMP, LOW(baud_const)			//Регистр частоты
	OUT 	UBRRL,TMP
	LDI 	TMP, HIGH(baud_const)			//Регистр частоты
	OUT 	UBRRH,TMP

	LDI 	TMP, (1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(1<<TXCIE)|(0<<UDRIE) //Прерывания разрешены, прием-передача разрешен
	OUT		UCSRB,TMP
	LDI 	TMP, (1<<URSEL)|(1<<UCSZ0)|(1<<UCSZ1)	//Формат кадра - 8 бит, без проверки четности
	OUT		UCSRC, TMP
	
	SEI					//Разрешим прерывания

MAIN:
	LDI ZL, LOW (ServiceMsg*2)		//Установим указатель на область памяти с сообщением		
	LDI ZH, HIGH(ServiceMsg*2)

H_MSG:
//Разрешим прерывание при наличии данных для передачи
	LDI		TMP,(1<<RXEN)|(1<<TXEN)|(1<<RXCIE)|(1<<TXCIE)|(1<<UDRIE)
	OUT		UCSRB, TMP
BREQ STOP		//Если данные для передачи закончились, останавливаем работу
RJMP H_MSG		//Иначе выводим следующий символ

STOP:
RJMP STOP

//Сообщение для вывода на дисплей, хранится во Flash-памяти
ServiceMsg: .db "ENTER NUMBER (0-9):",0x0D, 0,0


//Сегмент энергонезависимой памяти (EEPROM)
.ESEG



