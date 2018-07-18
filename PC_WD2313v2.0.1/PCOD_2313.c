/*
 * PCOD_2313.c 
 *
 * Created: 08.08.2016 12:00:00
 * Author: Aleksandr Uchaev
 *
 * ���������� ������������ �������� ������ ��, � ����������� ������ � ������� ����� ������.
 * ��������� ������ ���������� � ����� � ������ �������� � ������ EEPROM.
 * ��� ������� ���������� (����� ������) ������ �� EEPROM ���������� � SRAM ��� ��������� ������ ����������
 * ������ ����������:
 * 1. AtTiny2313a
 * 2. ������:
 *						SB_PASS   (1) - ������ ������ ����� ������,
 *						SB_CHANGE (2) - ������ ����� ������,
 *						SB_IND    (3) - ������ ��������� ��������� � ������ ������� �� �������
 * 3. ����������� ������:
 *						VSB_OPEN  (1) - �������� ������ ��
 *						VSB_POW   (2) - ��� �������
 * 4. ���������:
 *						LED_OPEN  (1) - ��������� ���� ��� ������ ���� ������
 *						LED_POW   (2) - ��������� ������� �� �������
 *						LED_BUZZ  (3) - ��������� ��������
 */ 

#define F_CPU 4000000L

//������������ �����
#include <avr/io.h>			//����/�����
#include <avr/interrupt.h>	//����������
#include <avr/eeprom.h>		//������ � EEPROM
#include <util/delay.h>		//��������

//����������� ������������ ��������� � �������� (��� ��������)
//�������� ������ � ����������� ������:
#define SB_PASS		4
#define SB_CHANGE	5
#define SB_IND		6

#define VSB_OPEN	2		//����� ���������� INT0
#define VSB_POW		0

#define SB_PORT     PORTD
#define SB_DDR		DDRD
#define SB_PIN		PIND

//���������:
#define LED_OPEN	0
#define LED_POW		1
#define LED_BUZZ    3

#define LED_PORT    PORTB
#define LED_DDR     DDRB

//��������� ������:
#define SB_PASS_R   (SB_PIN & 1<<SB_PASS)
#define SB_PASS_P   (!SB_PASS_R)


#define SB_CHANGE_R (SB_PIN & 1<<SB_CHANGE)
#define SB_CHANGE_P (!SB_CHANGE_R)

#define SB_IND_R    (SB_PIN & 1<<SB_IND)
#define SB_IND_P    (!SB_IND_R)

//��������� ��������:
#define PC_OPEN    (SB_PIN & 1<<VSB_OPEN)
#define PC_CLOSE   (!PC_OPEN)

#define POW_ON      (SB_PIN & 1<<VSB_POW)
#define BAT_ON	    (!POW_ON)

//����� ��������� � �����:
#define ON          1
#define OFF         0
#define PREOPENED   0x33
#define OPENED		0x66
#define CLOSED		0x99

#define blink_long  25*8
#define max_delay   6
#define pass_length 4

#define bounce_delay 50
#define pc_opn_delay 50
#define buzz_delay   300

#define ON_POW	    0	
#define ON_BAT 		1


#define pc_closed   0
#define pc_opened   1

//��������� �������
void SystemInit(void);
void PassCheck (void);
void PassChange(void);
void StartTIM0 (void);
void StopTIM0  (void);
void Test	   (void);
void StartBuzz(void);
void StopBuzz(void);

//���������� � ���������:
//��������� � �������� �������� ������ ��:
uint8_t pc_stat;					//��������� ������ ��
uint8_t pc_stat_adr EEMEM;			//� ��������� �� ����� �������� � EEPROM


//��������� � ������� ��� ������:
const uint8_t def_pass[] ={3,1,2,1};	//������ �� ���������
uint8_t pass[4];				    //������ � SRAM �� ��������� ������
uint8_t pass_adr 	EEMEM;  		//� ��������� �� ����� �������� � EEPROM
//������:
uint8_t temp;						//��� �������� � ������
uint8_t delay_cnt=0;
uint8_t pass_change_flag=0;
uint8_t pc_stat_flag;
uint8_t pow_stat_flag=0;

//MAIN:
int main(void){
SystemInit();	//������������� ���������, ����������
//_delay_ms(500);
sei();			//�������� ����������
	while(1)
	{

//����� ������� ������� � ����������� ������ ������ (�� ����/�������)
	if (BAT_ON)
	 {
	  LED_PORT=LED_PORT&~(1<<LED_OPEN);
	  LED_PORT=LED_PORT&~(1<<LED_POW);
	  StopBuzz();
	  pow_stat_flag=ON_BAT;
	 }


	if (POW_ON&&pow_stat_flag==ON_BAT)
	 {
	  pow_stat_flag=ON_POW;
	  LED_PORT=LED_PORT|(1<<LED_POW);
	  if (pc_stat==OPENED)
	  {
	   LED_PORT=LED_PORT|(1<<LED_OPEN);
	   StartBuzz();
	  }
	 }


//�������� ����������� �� ������ �� (��������� �� ���� ��������)
	if (PC_OPEN&&pc_stat==PREOPENED){
	  _delay_ms(pc_opn_delay);
	  if (PC_OPEN){
		LED_PORT=LED_PORT|(1<<LED_OPEN);
		StartBuzz();
		eeprom_write_byte(&pc_stat_adr, OPENED);
		pc_stat=OPENED;
	  }
	  else pc_stat=CLOSED;
	}
	 

//��������� ������� ������ SB_PASS (�� ����������)
	 if (SB_PASS_P){
		_delay_ms(bounce_delay);
	    if (SB_PASS_R&&pc_stat==OPENED){
		  StopBuzz();
		  PassCheck();
		  //Test();
	    }
     }
//��������� ������� ������ SB_CHANGE (�� ����������)
	 if (SB_CHANGE_P){
		_delay_ms(bounce_delay);
	    if (SB_CHANGE_R&&pc_stat!=OPENED&&POW_ON){
		  pass_change_flag=1;
		  PassCheck();
	    }
     }

//��������� ������� ������ SB_IND (�� ����������)
	 if (SB_IND_P){
		_delay_ms(bounce_delay);
	     while (BAT_ON&&SB_IND_P)
			{
			 LED_PORT=LED_PORT|(1<<LED_POW);
			 if (pc_stat==OPENED) LED_PORT=LED_PORT|(1<<LED_OPEN);			 
			}
	     if (SB_IND_R&&POW_ON)	StopBuzz();    
     }


    } 
}

//���� ����������
//����� ������� ������ ���������� ����� (�� ����������)
ISR(INT0_vect){
 if (pc_stat==OPENED){}
 else pc_stat=PREOPENED;
 
}

ISR(TIMER0_OVF_vect){
 static uint8_t blink_cnt;
 if (blink_cnt<blink_long){blink_cnt++;}
 else{
  if (pass_change_flag!=0) {LED_PORT=LED_PORT^(1<<LED_POW);}
  else 					   {LED_PORT=LED_PORT^(1<<LED_OPEN);}

 blink_cnt=0;
 delay_cnt++;
 }
}

ISR(TIMER1_COMPA_vect){
TCNT1H=0;
TCNT1L=0;
}

//���� �������������� �������:
void SystemInit (void){
//��������� ����������:
//������� ���������� VSB_OPEN - INT0:
MCUCR = 1<<ISC01|1<<ISC00;				//������������ �� ����������� ������
//MCUCR = 1<<ISC01|0<<ISC00;		    //������������ �� ����������� ������

 GIMSK = 1<<INT0;						//�������� ����������
//������:

 OCR1AH=0x27;
 OCR1AL=0x10;					


 TIMSK  = 1<<TOIE0|1<<OCIE1A;						//�������� ���������� TIM0
 TCCR1A = 1<<COM1A0|0<<COM1A1|0<<WGM11|0<<WGM10;
 TCCR1B = 0<<WGM13|1<<WGM12;
 //TCNT1=35000;	

//��������� ������ �����/������:
//����� ������ � ��������
 SB_DDR   = 0<<SB_PASS|0<<SB_CHANGE|0<<SB_IND|0<<VSB_OPEN|0<<VSB_POW;
 SB_PORT  = 1<<SB_PASS|1<<SB_CHANGE|1<<SB_IND|1<<VSB_OPEN|0<<VSB_POW;

//����� ���������
 LED_DDR  = 1<<LED_OPEN|1<<LED_POW|1<<LED_BUZZ;
 LED_PORT = 0<<LED_OPEN|1<<LED_POW|0<<LED_BUZZ;
;

//������������� ������:
 temp=eeprom_read_byte(&pass_adr);			//�������� �������� ������ ������ ������
 if (temp==0xFF){							//���� 0xFF �� ������ �� ��� ����������
//��������� ������ �� ��������� "3121":
	for (uint8_t adr_bias=0;adr_bias<pass_length;adr_bias++)
	{
	  eeprom_write_byte(&pass_adr+adr_bias,def_pass[adr_bias]); 	//� ������� ��� � EEPROM
	}	
 }
//���������� ������ �� EEPROM � ������ (� SRAM) ��� ��������
	for (uint8_t adr_bias=0;adr_bias<pass_length;adr_bias++)
	{
	 pass[adr_bias]=eeprom_read_byte(&pass_adr+adr_bias);
	}

//��������� ��������� �� �� EEPROM: 
 pc_stat=eeprom_read_byte(&pc_stat_adr);
 if (pc_stat==OPENED){
 	LED_PORT = LED_PORT|(1<<LED_OPEN);
	StartBuzz();
 }
 else pc_stat=CLOSED;

}

void PassCheck(void){
 uint8_t cnt=0;
 uint8_t error_flag=0;

//LED_PORT=LED_PORT&~(1<<LED_OPEN);
StartTIM0();

while (cnt<pass_length&&delay_cnt!=max_delay)
{
 //��������� ������� ������ SB_PASS (�� ����������)
	 if (SB_PASS_P){
		_delay_ms(bounce_delay);
	    if (SB_PASS_R){
		    		
			if (pass_change_flag==2)
			{
			 pass[cnt]=1;
			}

			else if (pass[cnt]!=1){error_flag=1;}
			
			delay_cnt=0;
		    cnt++;
	    }
     }


//��������� ������� ������ SB_CHANGE (�� ����������)
	 if (SB_CHANGE_P){
		_delay_ms(bounce_delay);
	    if (SB_CHANGE_R){
			if (pass_change_flag==2)
			{
			 pass[cnt]=2;
			}

			else if (pass[cnt]!=2){error_flag=1;}

			delay_cnt=0;
		    cnt++;
	    } 
     }

//��������� ������� ������ SB_IND (�� ����������)
	 if (SB_IND_P){
		_delay_ms(bounce_delay);
	    if (SB_IND_R){
			if (pass_change_flag==2)
			{
			 pass[cnt]=3;
			}

			else if (pass[cnt]!=3){error_flag=1;}

			delay_cnt=0;
		    cnt++;
	    }
     }
}


	if ((error_flag==1||delay_cnt==max_delay)&&pass_change_flag!=2)
	{
	 if (pc_stat==OPENED)
	 {
	 LED_PORT=LED_PORT|(1<<LED_OPEN);
	 StartBuzz();
	 }
	  
	delay_cnt=0;
	pass_change_flag=0;
	StopTIM0();
	LED_PORT=LED_PORT|(1<<LED_POW);
	}

	else if (error_flag==0&&pass_change_flag==1)
	{
    pass_change_flag=2;
	delay_cnt=0;
	StopTIM0();
	StartBuzz();
	_delay_ms(buzz_delay);
	StopBuzz();

	PassCheck();
	}

	else if (pass_change_flag==2)
	{
     if (delay_cnt==max_delay)	//������ ����� ������ �������� ������
	 {
	    pass_change_flag=0;
		delay_cnt=0;
		StopTIM0();
		LED_PORT=LED_PORT|(1<<LED_POW);
	   	for (uint8_t adr_bias=0;adr_bias<pass_length;adr_bias++)
		{
		 pass[adr_bias]=eeprom_read_byte(&pass_adr+adr_bias);
		}

	 }
	 else						//���� ����������� ������ (�������� ����� ������ � EEPROM)
	 {

		StartBuzz();
		_delay_ms(buzz_delay);
		StopBuzz();

	    pass_change_flag=0;
		delay_cnt=0;
		StopTIM0();
		LED_PORT=LED_PORT|(1<<LED_POW);
	   	for (uint8_t adr_bias=0;adr_bias<pass_length;adr_bias++)
		{
	 	 eeprom_write_byte(&pass_adr+adr_bias,pass[adr_bias]); 	//� ������� ��� � EEPROM
		}
	 }	

	}
	 
	else
	{
	delay_cnt=0;
	StopTIM0();
	eeprom_write_byte(&pc_stat_adr, CLOSED);
	pc_stat=CLOSED;
	LED_PORT = LED_PORT&~(1<<LED_OPEN);
	StopBuzz();
	}


}


void StartTIM0(void){
	TCCR0B = 0<<CS02|1<<CS01|1<<CS00;
}

void StopTIM0 (void){
	TCCR0B = 0<<CS02|0<<CS01|0<<CS00;
}

void StartBuzz(void){
	TCCR1B=0<<CS12|0<<CS11|1<<CS10;
}

void StopBuzz(void){
	TCCR1B=0<<CS12|0<<CS11|0<<CS10;
	LED_PORT=LED_PORT&~(1<<LED_BUZZ);
}
