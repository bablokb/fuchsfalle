; fuchspi9.asm, mit Raspi 2 B / B+	 	Version 9.0		  18.11.2016
; (mit SMS-Programm-Teil/für Platine pi-pic-smd)
; ###############################################################
; Aufgabe:
; TxD Abfrage ändern auf GP10=LOW:
; 							geä. am 18.11.16, ab Zeile 486 und 640
; Unterspannungsgrenze neu 3500 mV:
; 							geä. am 05.12.16, ab Zeile 395
; Zeitverzögertes Abschalten des Raspi (8 Sek.) nach GP10=0:
;							geä. am 07.12.16, ab Zeile 492
; ###############################################################
; Schaltungsänderungen (alles wie fuchspi7):
; TxD bleibt frei
; GPIO22 an RA5 (Eingang, ohne Pull Up), Polling / I-O-C
; GPIO10 an RC0 (Eingang, ohne Pull Up), Polling
; entsprechende Änderungen auch am PIC-Tester
; UP NumCopy für die Nummerierung der Unterbrechungspunkte.
; UP SmsKorrekt korrigiert Register sms 
; in Abhängigkeit der abgeschickten SMS.
; Adressen für LCD 4x16 bzw. 4x20
; Siehe UP'e: LcdStart, LcdAusgabe
; ################################################################
; Bestückung geändert (wegen SMD-Header auf Platine: pi-pic-smd)
; PIC-Pull-up-Widerstände ein für Portpin RB7. RB6 1M extern !! 
; kein I-O-C für Port A und B, kein Interrupt an RA2/INT:
; Port A:
; 	RA0	Eingang, AN0, ADC, halbierte Betriebsspannung messen
;	RA1	Eingang, AN1, Uref=2,5V
;	RA2	Ausgang, MOSEA, über 10K an G vom P-Ch.-MOSFET T2 *)
;	RA3	MCLR\
;	RA4	Ausgang, RPIEA, über 10K an G vom P-Ch.-MOSFET T1 *)
;	RA5	Eingang, fragt GP22 des Pi ab (I-O-C)
;	*) Portpin=1, FET aus (gesperrt), Portpin=0, FET ein (leitend)
;
; Port B:
;	RB4	Ausgang, frei / Eingang, Taster Test.
;	RB5 Ausgang, frei / Ausgang LED blau gegen GND.
;	RB6	Eingang, Schalter S1 (Fallenklappe) gegen GND, ext.Pullup!
;	RB7	Eingang, I2CENA: RB7=0 erlaubt Software-I2C, int.Pullup!
;
; Port C:	Software-I2C-Modul für Prüfzwecke über ext. Adapter
;		(Wenn RB7=1, Modul deaktiviert, RC3-6 nicht beschaltet u.
;		wegen Aufladungsgefahr alles als Ausgänge geschaltet ! )
;		RB7=1, I2C inaktiv / RB7=0, I2C aktiv :
;	RC0	Eingang, fragt GP10 des Pi ab, ob er fertig ist.
;	RC1	Ausgang, Akkuspg.meldung an GPIO17 / LED gelb.
;	RC2	Ausgang, Fallenstatusmeldung an GPIO27 / LED grün.
;	RC3	Ausgang, frei / SCL in	\
;	RC4	Ausgang, frei / SDA out	 | für Software-I2C über
;	RC5	Ausgang, frei / SDA in	 | externe Adapter !
;	RC6	Ausgang, frei / SCL out	/
;	RC7	Eingang, frei
;
; 4 MHz-Quarz - interner Takt 1 MHz / Tintosc= 1 µs 
; 
; Autor: Dipl.-Ing. Lothar Hiller
;#################################################################
	list p=16F690
	#include <p16F690.inc>
	errorlevel -302
	radix hex
;
; PIC-Konfiguration:
; ext. Reset über Pin 1 (MCLR) erlauben u. INTOSCIO,
; WDT einschalten,
; alle anderen Config-Funktionen OFF:
 __CONFIG  _MCLRE_ON & _INTOSCIO & _PWRTE_OFF & _BOR_OFF & _WDT_OFF & _CP_OFF & _FCMEN_OFF & _IESO_OFF
;
;#################################################################
; UP-Variablen für Zeitverzögerungen, Modul: quarz_xMHz.asm
miniteil	equ	0x20	
miditeil	equ	0x21	
maxiteil	equ	0x22
time0		equ	0x23
time1		equ	0x24
time2		equ	0x25
;
zustand		equ	0x26	; Ereignisregister Unterspannung, Klappe
bytelcd0	equ	0x27	; Low-Byte UP spannung für LCD-Ausgabe
bytelcd1	equ	0x28	; High-Byte UP spannung für LCD-Ausgabe
USGL		equ	0x29	; Low-Byte US
USGH		equ	0x2a	; High-Byte US
bitnum		equ	0x2b	; UP bin8...
bin8reg		equ	0x2c	; UP bin8...
;
; Messungen:
;OffsetTemp	equ	0x2d	; Korrekturwert für Akku-U-Messung
;NrMessung	equ	0x2e	; Zähler für die 64 Temp.-Messungen
;Flags		equ	0x2f	; Negativ-Temp.
;
; Registerdefinitionen für Matheroutinen UP math_0.asm:
f0			equ	0x30
f1			equ	0x31
f2			equ	0x32
f3			equ	0x33
xw0			equ	0x34
xw1			equ	0x35
xw2			equ	0x36
xw3			equ	0x37
g0			equ	0x38
g1			equ	0x39
Fehler		equ	0x3a
counter		equ	0x3b
sw0			equ	0x3c
sw1			equ	0x3d
;
; für Tests:
testpi		equ	0x3e	; UP Raspi
nummer		equ	0x3f	; UP NumCopy (Nummer. Unterbr.punkte)
;
; Überwachung der SMS-Verschickung per Raspi
sms			equ	0x40
;
; Registerdefinitionen für I2C
buf			equ	0x41	; I2C-UP'e
count		equ	0x42	; I2C-UP'e
BcdDaten	equ	0x43	; UP Bcd4Bit
LcdByte		equ 0x44
LcdCon		equ	0x45
LcdDaten	equ	0x46
LcdStat		equ	0x47
;
; I2C-Adressen,  seriell mit 2x PCF8574:
PcfAdr1		equ	0x48	; LCD, seriell 
PcfAdr2		equ	0x49	; LCD, seriell
;
; Register für UP Hex2Dez16 und 8:
HdZT		equ	0x4a
HdT			equ	0x4b
HdH			equ	0x4c
HdZ			equ	0x4d
HdE			equ	0x4e
HdX			equ	0x4f
;
; ISR:
W_TEMP		equ	0x50	; W retten
P_TEMP		equ	0x51	; PCLATH retten
S_TEMP		equ	0x52	; STATUS retten
;
WDT_TEMP	equ	0xa0	; WDTCON retten (1. Speicherplatz in Bank1)
;
; Portpinzuweisung für MOSFET-Gates: 
#define	MOSEA	PORTA,2	; Gate von T2 (über 10k) (Akku-U-Messung)
#define	RPIEA	PORTA,4	; Gate von T1 (über 10k) (Boost-Konverter)
;
; Definitionen für Software-I2C-Portpin's:
; (Konstanten für I2C festlegen, Pinbelegung, für Port C)
; 	RC6	CLK out
;	RC3	CLK in
;	RC4	SDA out	
;	RC5 SDA in
#define	SCLi	PORTC,3		; Takt input
#define	SDAo	PORTC,4		; Daten output
#define	SDAi	PORTC,5		; Daten input
#define	SCLo	PORTC,6		; Takt output
#define	SCL		PORTC,6		; Takt
;
; LCD-Controller-Aktivierung/-Deaktivierung
#define	LC1		LcdCon,5	; 1. LCD-Controller (E/E1)
#define LC2		LcdCon,6	; 2. LCD-Controller (E2), hier unbenutzt
;
; LCD-Steuerbyte zum PCF8574 (IC2) für 2x16 (TC1602):
;#define	LcdSRs	LcdByte,4	; RS
;#define	LcdSRw	LcdByte,5	; RW
;#define	LcdSE1	LcdByte,6	; E/E1
;#define	LcdSE2	LcdByte,6	; E2 hier unbenutzt
;#define	LcdBel	LcdByte,7	; Beleuchtung
;
; LCD-Steuerbyte zum PCF8574 (IC2):
#define	LcdSRs	LcdByte,0	; RS
#define	LcdSRw	LcdByte,1	; RW
#define	LcdSE1	LcdByte,2	; E/E1	(ab 2 oder 4x16/20 u. 4x40)
#define	LcdSE2	LcdByte,3	; E2	(4x40, Zeile 3+4)
;
; Schalter für Software-I2C-Aktivierung/-Deaktivierung:
#define	I2CEN	PORTB,7		; I2CEN=0 erlaubt I2C (LCD)
#define	TEST	PORTB,4		; Testpunkt UP Raspi
;
; Register zustand:
#define unter_u		zustand,0	; Unterspannungsbit
#define falle_zu	zustand,1	; Fallenklappenstatusbit
#define	txd_pi		zustand,2	; Shutdown-Rückmeldung vom Pi
;
; Register sms:
#define	sms_wegU	sms,0	; SMS verschickt wegen Unterspg.
#define	sms_wegF	sms,1	; SMS verschickt wegen Falle zu
#define	sms_fehler	sms,7	; Fehler beim senden einer SMS
;
; Unterbrechungspunkte in UP RaspiW u. Schleife lcdausgaben:
#define	zust4		zustand,4	; Unterbrechungspunkt Bit4
#define	zust5		zustand,5	; Unterbrechungspunkt Bit5
#define	zust6		zustand,6	; Unterbrechungspunkt Bit6
#define	zust7		zustand,7	; Unterbrechungspunkt Bit7
;
; Status der Falle (Klappe) an RB6 (S1):
#define falle	PORTB,6		; falle=1 (leer), falle=0 (ausgelöst).
;
; Status der TxD-Leitung vom Raspi:
#define txdpin	PORTC,7		; PIC-Eingang,
							; überwacht das TxD-Pin des Raspi.
;
; Status der GPIO10-Leitung vom Raspi:
#define gp10pin	PORTC,0		; PIC-Eing., überwacht GP10 des
							; Raspi.
;
; Status der GPIO22-Leitung vom Raspi:
#define	gp22pin	PORTA,5		; PIC-Eing.,
							; überwacht GP22 des Raspi (I-O-C)
;
; Meldeleitung bei Unterspannung auf RC1 (UP UnterU):
#define	USmeld	PORTC,1		; USmeld=1, Unterspannung.
;
; Meldeleitung bei Fallenklappe zu (Falle ausgelöst) auf RC2:
#define	ZUmeld	PORTC,2		; ZUmeld=1, Falle ausgelöst.
;
; Melde-LED blau, UP Lesen (am TEST-Punkt angelangt):
#define PImeld	PORTB,5		; PImeld=1, Punkt erreicht.
;
;
;
;
; ###############################################################
; ###############################################################
; Hauptprogramm:
; ###############################################################
; ###############################################################
	org	0x00
; Systemstart
	goto	InitPic16F690
;
	org	0x04
; Platz für ISR
;
; ###############################################################
; ###############################################################
; #		 I N T E R R U P T - S E R V I C E R O U T I N E :		#
; ###############################################################
; ###############################################################
; die ISR überwacht den Ausgang GP22 des Raspi auf Fehlermeldung
; kein Fehler: GP22=HIGH, Fehler beim Absetzen der SMS: GP22=LOW
intserv
; Daten retten vor ISR-Aufruf:
	movwf	W_TEMP		; w retten
	swapf	STATUS,W	; STATUS nach w
	clrf	STATUS		; Bank0
	movwf	S_TEMP		; w (STATUS) nach S_TEMP
	movf	PCLATH,W	; PCLATH nach w
	movwf	P_TEMP		; w (PCLATH) nach P_TEMP
	clrf	PCLATH		; PCLATH=0
;
; ISR-Code:
	btfsc	gp22pin		; wenn gp22pin=0, überspringe nä. Bef.
	goto	isrend		; gp22pin=1, INT-Fehler, weiter überwachen 
;
						; gp22pin=0, Fehler beim SMS-Senden:
	bsf		sms_fehler	; sms_fehler=1 
	bcf		INTCON,RABIE ; I-O-C sperren
;
isrend
; ISR-Ende:
	bcf		INTCON,RABIF ; Int.flag löschen
;
; "alte Zustände" wieder herstellen:
	movf	P_TEMP,W	; PCLATH alt nach w
	movwf	PCLATH		; w nach PCLATH
	swapf	S_TEMP,W	; STATUS alt nach w
	movwf	STATUS		; w nach STATUS
	swapf	W_TEMP,F	; swap W_TEMP
	swapf	W_TEMP,W	; swap W_TEMP nach w
;
	retfie
;
; ###############################################################
; ###############################################################
; UP InitPic16F690 : Konfiguration des PIC's 16F690-I/P
; ###############################################################
; ###############################################################
InitPic16F690
	; Bank0
	bcf		STATUS,RP1
	bcf		STATUS,RP0
;
	clrf	PORTA		; Portinitialisierungen A, B u. C
	clrf	PORTB
	clrf	PORTC
	bsf		MOSEA		; T1 aus (Port A)
	bsf		RPIEA		; T2 aus (Port A)
;
; Bank2, Register ANSEL, ANSELH: 
	; nach POR stehen alle Bits auf 1 (1 = analog, 0 = digital)
	bsf		STATUS,RP1
	clrf	ANSEL		; AN0-7 digital I/O => RA0-7, außer:
	bsf		ANSEL,ANS0	; RA0 => AN0 (U-Mess.)
	bsf		ANSEL,ANS1	; RA1 => AN1 (Uref)
;
	clrf	ANSELH		; AN8-11 digital I/O
;
; Bank1, Richtungsregister TRISA-TRISC
	bcf		STATUS,RP1
	bsf		STATUS,RP0
	movlw	b'00100011'	; Eingänge für RA(0:1,5),
	movwf	TRISA		; der Rest Ausgänge
	movlw	b'11000000'	; RB7 u. RB6 sind Eingänge,
	movwf	TRISB		; der Rest Ausgänge
;
	movlw	b'10000001'	; Eingang für RC7 und RC0,
	movwf	TRISC		; der Rest Ausgänge
;
; Bank1, OPTION_REG
	; nach POR stehen alle bits des OPTION-Registers auf 1
	bcf		OPTION_REG,NOT_RABPU
				; bit 7 = 0, NOT_RABPU=0, PortA-B-pull-ups enable,
				; Achtung: gilt für beide Ports !
				; bit 3 = 1, Vorteilerzuweisung zum WDT (PSA)
				; bit  2:0 = 111, WDT-Vorteiler 1:128
;
; I-O-C und Pull Up:
	; NOT_RABPU im OPTION_REG muß erlaubt sein !
	; pull-up-Widerstände einschalten, 1=enable
	; alle Bits des Registers WPUA (Bank1) sind nach POR gesetzt !
	clrf	WPUA		; alle pull-ups disabled
;
; Int.-On-Change für RA5 einrichten (erlauben):
; Register IOCA (Bank1) ist nach POR gelöscht, also kein I-O-C
	bsf		IOCA,IOCA5	; an RA5 IOC eingerichtet
;
; für PortB, RB7 (I2CEN) ein pull-up aktivieren
; und keine I-O-C:
	; Bank2
	bsf		STATUS,RP1
	bcf		STATUS,RP0
	; alle Bits von WPUB (Bank2) sind nach POR gesetzt!
	clrf	WPUB		; keine pull-ups für PortB
	bsf		WPUB,WPUB7	; RB7 mit pull-up
;  Register IOCB ist nach POR gelöscht, also kein I-O-C
;
; Konfiguration des ADC an AN0 Meßeingang, AN1 Ref.-U-Eingang:
	;Bank0
	bcf		STATUS,RP1
	movlw	b'11000000' ; Daten rechtsbünd., Vref, AN0, ADC aus
	movwf	ADCON0
	; Bank1
	bsf		STATUS,RP0
	; nach POR sind alle bits von ADCON1 gelöscht
	bsf		ADCON1,ADCS0 ; ADC-Takt Fosz/8
	; kein ADC-Interrupt, weil Bit ADIE in Reg. PIE1 
	; nach POR gelöscht ist.
;
; WDTCON (Bank1)
; WDT= 128*("WDT-Tf")/31000 = in sec Schlafzeit je Zyklus
;	WDTPS	WDT-Tf				Zyklus	WDTPS	WDT-Tf	Zyklus
;	<3:0>						sec		<3:0>			sec
;	0000	1:32				0,13	0110	1:2048	8,5
;	0001	1:64				0,26	0111	1:4096	17
;	0010	1:128				0,53	1000	1:8192	34
;	0011	1:256				1,1		1001	1:16384	68
;	0100	1:512 (nach Reset)	2,1		1010	1:32768	135
;	0101	1:1024				4,2		1011	1:65536	271
; Die Zeiten sind von PIC zu PIC unterschiedlich (Toleranzen),
; WDTCON,0=1 (SWDTEN-bit) => WDT ein
;	movlw	b'00010111'	; WDT-Zykluszeit ca. 271 sec. (4-5 min.)
	movlw	b'00010011'	; WDT-Zykluszeit ca. 1 min. zum testen !
	movwf	WDTCON		; (gemessen 5'15")
;
; PORTB u. C auf LOW (Bank0) 
	; Bank0
	bcf	STATUS,RP0
	clrf	PORTB	; alle Ausgänge von Port B auf Low
	clrf	PORTC	; alle Ausgänge von Port C auf Low
;
; Register INTCON (Bank0-3)
	clrf	INTCON	; alle INT.Flags löschen, alle INT. sperren.
;
; Ende InitPic
;
; ##############################################################
; I2C-Adressen des LCD-Moduls mit 2x PCF8574:
; PCF-Adr. 1, lsb=0 (schreiben zum Slave):
; LCD mit 1/2 Contr. (TC1602/PC1604/CMC420L/LXC4045-1)
	movlw	b'01000110'	; 0100 A2A1A0 0, siehe Datenblatt
	movwf	PcfAdr1		; IC1 Daten Adr.-Register
;
;
	movlw	b'01001000'	; 
	movwf	PcfAdr2		; IC2 Control Adr.-Register
;
; OffsetU1 für Meßfehlerkorrektur bei der Spannungsmessung:
#define	 OffsetU1	d'5'	;Offset in mV U-Messung 
;
; Lipo-Unterspannungsgrenzwert in mV=>hex-Wert (2 Byte):
; 3000=>0BB8, 3100=>0C1C, 3200=>0C80, 3300=>0CE4
; 3400=>0D48, 3500=>0DAC, 3600=>0E10, 4000=>0FA0
; Beispiel für 3000 mV: high byte=0x0b, low byte=0xb8
;	movlw	0x0b		; US high byte, USGH=0b, 3000mV
	movlw	0x0d		; 3500mV
	movwf	USGH		; 
;	movlw	0xb8		; US low byte, USGL=b8, 3000mV
	movlw	0xac		; 3500mV
	movwf	USGL		; 
;
; Spannungsmodul abschalten (Uref und U-Meß-Teiler):
	bsf	MOSEA			; MOSEA=1, P-CH-MOSFET (T2) aus 
;
; Step-Up-Regler (Pi u. Huawei) abschalten:
	bsf	RPIEA			; RPIEA=1, P-CH-MOSFET (T1) aus
;
; Register zustand, sms und testpi löschen:
	clrf	zustand
	clrf	sms
	clrf	testpi
;	
; Schalter für I2C Ein/Aus:
	btfss	I2CEN		; wenn I2CEN=1, überspringe nä. Bef.
	goto	wartung		; I2CEN=0, Jumper gesteckt, also Wartung
						; I2CEN=1, keine Wartung
; WDT ist im UP InitPic16F690 eingeschaltet worden!!
;
; ################################################################
loop					; Schleife, wenn I2C nicht aktiv ist
	clrwdt				; WDT löschen
; PIC in den Sleep-Modus versetzen:	
	sleep
; wecken durch INT WDT nach der vorprogrammierten Zeit:
; (dann weiter bei loopw)
	NOP
;
loopW					; Schleife, wenn I2CEN aktiv ist
	call	Spannung	; Akkuüberprüfung
	call	Falle		; Fallenstatus testen
;
;
; ################################################################
; LCD-Meßwerte ausgeben, wenn I2CEN=0:
	btfss	I2CEN		; wenn I2CEN=1, überspringe nä. Bef.
	goto	lcdausgaben	;I2CEN=0, Ausgabe Meßwerte
						;I2CEN=1, keine Ausgabe
;
; hier weiter, wenn keine LCD-Ausgabe erfolgt:
; (durch die UP'e Spannung und Falle wurden die aktuellen Meldepegel
; in Abhängigkeit von der "SMS-weg-Überwachung" des PIC im Register
; sms gesetzt bzw. gelöscht.) Es folgt nun die Entscheidung, ob der 
; Raspi eingeschaltet und eine SMS senden soll.
;
; Bit7:2 im Register zustand ausblenden u. in Reg. testpi speichern:
	movf	zustand,w	; zustand -> w,
	andlw	b'00000011'	; in w Bit7:2 ausblenden,
	movwf	testpi		; w-Ergebnis in testpi speichern
;
; zustand(1:0)=00	testpi=0 (00) ==> in diesem Fall PI nicht ein!
; zustand(1:0)=01	testpi=1 (01)
; zustand(1:0)=10	testpi=2 (10)
; zustand(1:0)=11	testpi=3 (11)
;
; testpi=0 (Z=1) testen, wenn Z=1, keine Aktion des Pi,
; wenn testpi>0 (Z=0), dann Pi einschalten.
 	movf	testpi,f	; wenn testpi=0 -> Status,Z=1; sonst Z=0
	btfsc	STATUS,Z	; wenn Z=0, überspringe nä. Bef.
	goto	raspiaus	; Z=1, testpi=0, Pi nicht einschalten,
	call	PiEin		; Z=0, testpi>0, Pi einschalten.
						; dies ist die Stelle, an der der Pi ein-
						; geschaltet wird, um eine SMS zusenden.
; hier weiter nach Ende von UP PiEin:
	clrf	testpi
;
; gp22pin=1 (UP PiEin), Interrupts erlauben:
	clrf	INTCON		; INTCON-Register löschen
	bsf		INTCON,GIE	; Interrupt global erlauben
	bsf		INTCON,RABIE ; Interrupt Port change (I-O-C) erlauben.
;
; ##################################################################
; Ab hier überwacht I-O-C den Pin GPIO22 auf gp22pin=0 (GP10=LOW).
; (Dieser Programm-Teil des Pi dauert ca. 30...60 Sek. ??
; ##################################################################
;	call	WDTein		; Zeitüberwachung ein
gpio10
	btfss	gp10pin		; wenn gp10pin=1, überspringe nä. Bef.
	goto	gpio10		; gp10pin=0, Pi noch in Arbeit, neue Abfrage
						; gp10pin=1, Pi ist fertig:
;	call	WDTaus		; Zeitüberwachung aus
	clrf	INTCON		; alle Interrupts sperren
;
; Herunterfahren des Pi abwarten, bevor er ausgeschaltet wird:
; wenn das Herunterfahren beendet ist, geht Pin GPIO10 auf LOW
; (gp10pin=0) u. der PIC schaltet 5 sek.darauf den Boostkonverter ab:
;	call	WDTein		; Zeitüberwachung ein
rpiaus
	btfsc	gp10pin		; wenn gp10pin=0, überspringe nä. Bef.
	goto	rpiaus		; gp10pin=1, Pi noch ein, neue Abfrage
						; gp10pin=0, Pi aus, fertig

;	call	WDTaus		; Zeitüberwachung aus
	movlw	d'32'		; warte noch 32 x 250 ms = 8 Sek.
	call	maxitime	; (Raspi-shutdown braucht nun noch 5-6 Sek.)
	bsf		RPIEA		; RPIEA=1,Boostkonverter aus
;
raspiaus				; Pi aus
	clrf	testpi
;
; Reg. sms korrigieren in Auswertung der Aktivitäten des Pi
; (welche SMS wurde bis hierher versandt ?!)
	call	SmsKorrekt	; Änderung sms=1000 00xx
	bcf		sms_fehler	; Bit sms_fehler löschen, falls gesetzt
	goto	loop		; PIC schlafen legen
;
; ################################################################
; LCD: Initialisierung und Ausgaben (wartung, lcdausgaben) #######
; ################################################################
wartung
; Bank1: WDT ausschalten, TRISC umschalten. 
; Bank 1
	bcf		STATUS,RP1
	bsf		STATUS,RP0
;
	bcf		WDTCON,SWDTEN	; WDT aus
;
;  Port B = b'11000000' in InitPic, zusätzlich RB4 (Ta):
	movlw	b'11010000'	; RB7 (I2CEN), RB6 (klappe) u. RB4 (Ta) 
	movwf	TRISB		; sind Eingänge, RB5 Ausgang (LED blau)
;
;  Port C = b'10000001' in InitPic, zusätzlich RC3 u. RC5 (I2C):
	movlw	b'10101001'	; RC0 (GP10), RC3 (SCL in), RC5 (SDA in)
	movwf	TRISC		; u. RC7 (TxD) auf Eingang schalten
;
; Bank 2 (Bank2: RP1=1,RP0=0)
	bsf		STATUS,RP1
	bcf		STATUS,RP0
; PullUp für den Tastereingang:
	bsf		WPUB,WPUB4	; RB4 mit pull-up
;
; Bank 0
	bcf		STATUS,RP1
	bcf		STATUS,RP0
;
	call	LcdStart	; LCD-Init. u. Startzeile ausgeben
	goto	loopW
;
; ################################################################
lcdausgaben			; zur Kontrolle Tabellen "Wartung" ausfüllen !
; Kontrollausgaben (je nach Ereignis xx=000 bis xx=111):
	movlw	d'0'		; zustand=0000 0xxx				xxx=
	call	NumCopy		; Löschen des oberen Nibble in zustand
	call	LcdAusgabe	; 0. Unterbrechung, Kontrollausgabe
	call	Lesen		; alle Register 0?/ LED blau/ => Ta drücken
;
; Bit7:2 im Register zustand ausblenden u. in Reg. testpi speichern:
	movf	zustand,w	; zustand -> w,
	andlw	b'00000011'	; in w Bit7:2 ausblenden,
	movwf	testpi		; w-Ergebnis in testpi speichern
;
; zustand(1:0)=00	testpi=0 (00) ==> in diesem Fall PI nicht ein!
; zustand(1:0)=01	testpi=1 (01)
; zustand(1:0)=10	testpi=2 (10)
; zustand(1:0)=11	testpi=3 (11)
;
; testpi=0 (Z=1) testen, wenn Z=1, keine Aktion des Pi,
; wenn testpi>0 (Z=0), dann Pi einschalten.
; STATUS retten wie bei ISR zwecks Anzeige:
 	movf	testpi,f	; wenn testpi=0 -> Status,Z=1; sonst Z=0
	swapf	STATUS,W	; STATUS nach w
	movwf	S_TEMP		; w (STATUS) nach S_TEMP
	swapf	S_TEMP,f
;
	movlw	d'1'		; zustand=0001 0xxx 			xxx=
	call	NumCopy		;
	call	LcdAusgabe	; Kontrollausgabe (x=Z-Flag)
	call	StempOut	; STATUS=0001 1x00				x=Z=
	call	Lesen		; Z notieren, => Ta drücken für weiter
;
	swapf	S_TEMP,w	; STATUS wieder herstellen
	movwf	STATUS		; für folgenden Sprungbefehl
	swapf	STATUS,f
; 
	btfsc	STATUS,Z	; wenn Z=0, überspringe nä. Bef.
	goto	raspiausw	; Z=1, testpi=0, Pi nicht einschalten,
	call	PiEin		; Z=0, testpi>0, Pi einschalten.
						; dies ist die Stelle, an der der Pi ein-
						; geschaltet wird, um eine SMS zusenden.
;
; hier weiter nach Ende von UP PiEin:
; Prüfen, ob RPIEA=0V  ===========> Pegel eintragen: RPIEA=
;
; Unterbrechung:		; 
; GP10=LOW. GP22=HIGH erfolgreich?
	movlw	d'2'		; zustand=0010 0xxx				xxx=
	call	NumCopy
	call	LcdAusgabe	; Kontrollausgaben
	call	Lesen		; LED blau ein, => Ta drücken für weiter 
	clrf	testpi
;
; gp22pin=1, Interrupts erlauben:
	clrf	INTCON		; INTCON-Register löschen
	bsf		INTCON,GIE	; Interupt global erlauben
	bsf		INTCON,RABIE ; Interrupt Port change (I-O-C) erlauben.
;
; 3. Unterbrechung, INTCON auf LCD anzeigen:
	movlw	d'3'		; zustand=0011 0xxx				xxx=
	call	NumCopy
	call	LcdAusgabe
	call	IntOut		; Ausgabe INTCON in Zeile 4		INTCON=
	call	Lesen
;
; ##################################################################
; Ab hier überwacht I-O-C den Pin GPIO22 auf gp22pin=0 (GP10=LOW).
; (Dieser Programm-Teil des Pi dauert ca. 30...60 Sek. ??
; Hier kann man testen, ob ein Interrupt ausgelöst wird:
; GP22 von HIGH nach LOW umstecken, ausprobieren?
; ##################################################################
;
; 4. Unterbrechung, 			nun GP10 von LOW auf HIGH umstecken:
; (wenn Pi fertig, meldet er über GP10=HIGH, daß er bereit
; zum herunterfahren) wenn fertig, Ta drücken:
	movlw	d'4'		; zustand=0100 0xxx				xxx=
	call	NumCopy
	call	LcdAusgabe
	call	IntOut		; Ausgabe INTCON				INTCON=
	call	Lesen
;
;	call	WDTein		; Zeitüberwachung ein
gpio10w
	btfss	gp10pin		; wenn gp10pin=1, überspringe nä. Bef.
	goto	gpio10w		; gp10pin=0, Pi noch in Arbeit, neue Abfrage
;
						; gp10pin=1, Pi ist fertig:
;	call	WDTaus		; Zeitüberwachung aus
	clrf	INTCON		; alle Interrupts sperren
;
; 5. Unterbrechung:
; GPIO10=HIGH, Pi ist fertig: nun GP10=LOW stecken, Ta drücken:
	movlw	d'5'		; zustand=0000 00xx				xxx=
	call	NumCopy
	call	LcdAusgabe
	call	IntOut		; Ausgabe INTCON				INTCON=
	call	Lesen
;
; Herunterfahren des Pi abwarten, bevor er ausgeschaltet wird:
; wenn das Herunterfahren beendet ist, geht Pin GP10 auf LOW
; (gp10pin=0) u. der PIC schaltet nach weiteren 5 Sek. den 
; Boostkonverter ab:
;	call	WDTein		; Zeitüberwachung ein
rpiausw
	btfsc	gp10pin		; wenn gp10pin=0, überspringe nä. Bef.
	goto	rpiausw		; gp10pin=1, Pi noch ein, neue Abfrage
						; gp10pin=0, Pi aus, fertig (Wartezeit ??)
;	call	WDTaus		; Zeitüberwachung aus
	movlw	d'4'		; warte 1 Sek. (nur in der Wartungsphase)
	call	maxitime	; auf shutdown des Raspi
	bsf		RPIEA		; RPIEA=1,Boostkonverter aus
;
; 6. Unterbrechung:
; Meßgerät kontrollieren: ==========>		Pegel eintragen: RPIEA=
; Wenn RPIEA=HIGH, Ta drücken
	movlw	d'6'		; zustand=0110 0xxx				xxx=
	call	NumCopy
	call	LcdAusgabe 
	call	Lesen
;
; Reg. sms korrigieren in Auswertung der Aktivitäten des Pi:
; (welche SMS wurde bis hierher versandt ?!)
raspiausw				; Pi aus
	clrf	testpi
;
; 7. Unterbrechung:
; Reg. sms korrigieren in Auswertung der Aktivitäten des Pi
; (welche SMS wurde bis hierher versandt ?!)
	call	SmsKorrekt	; Änderung sms=1000 0001 ?
	call	RcodeOut	; Rückkehrcodeausg. von UP SmsKorrekt
	movlw	d'7'		; zustand=0111 0xxx				xxx=
	call	NumCopy
	call	LcdAusgabe	; Reg. sms kontrollieren		sms=
	call	Lesen		; Ta drücken für weiter
;
; nun kann man in aller Ruhe kontrollieren,
; danach Testbedingungen für die nä. Runde einstellen,
; dann Ta drücken für weiter.
; 8. Unterbrechung:
	movlw	d'8'		; zustand=1000 0xxx
	call	NumCopy
	bcf		sms_fehler	; Bit sms_fehler löschen
	call	LcdAusgabe	; 
	call	Lesen		; Ta drücken für weiter
;
	movlw	d'0'
	call	RcodeOut	; Rückkehrcode im LCD auf Null
	movlw	d'0'		; zustand=0000 0xxx
	call	NumCopy		; einstellen für
	goto	loopW		; neuen Wartungszyklus
;
; ################################################################
; ################################################################
; INCLUDE für Hilfsprogramme:
	#include <quarz_4MHz.asm>	;Zeitverzög.-UP'e
	#include <software-iic.asm>	;Software-I2C für PIC16Fxxx
	#include <lcdserbus.asm>	;LCD (1/2 Contr.) mit 2x PCF8574
;
; ###############################################################
; #					U N T E R P R O G R A M M E :				#
; ###############################################################
;
;
; ###############################################################
; UP PiEin:
; Raspi einschalten bis GP22-Prüfung, mit Unterbrechungspunkten
; und LCD-Ausgaben.
; sms-Register sms(7:0):
; x7  0  0  0  0  0  x1  x0
; Bit x0: sms_wegF, Bit x1: sms_wegU, Bit x7: sms_fehler
;      (x1x0)
; sms=0 (00) ; es wurde noch keine SMS gesendet,
; sms=1 (01) ; SMS bezgl. Falle zu wurde gesendet,
; sms=2 (10) ; SMS bezgl. Unterspannung wurde gesendet,
; sms=3 (11) ; beide SMS gesendet. ==> Raspi nicht einschalten!)
; ################################################################
PiEin
; dies ist die Stelle, an der der Pi eingeschaltet wird.
; zustand(1:0)>0 heißt, eine oder beide SMS noch nicht gesendet.
; Da die USmeld und/oder ZUmeld gesetzt sind, weiß der Pi nach dem
; einschalten und lesen dieser beiden Meldeleitungen, welche SMS 
; gesendet werden soll. Pi einschalten:
	bcf		RPIEA		; RPIEA=0, Boostkonverter ein (T1 P-Ch.)
;									Spannungswert notieren für RPIEA=
;
; Boost-Konverter ein, Raspi fährt hoch (TxD=0, GP22=0, GP10=0),
; nachdem Pi und fuchsfalle.sh gestartet, wird TxD=1 u. GP22=1:
;
; Schalter für I2C Ein/Aus (Wartungszyklus) u. Ju setzen:
	btfss	I2CEN		; wenn I2CEN=1, überspringe nä. Bef.
	call	Lesen		; I2CEN=0, Jumper gesteckt, also Wartung:
						; zustand=0001 0xxx
; jetzt Jumper GP22=1 einstellen,	=>	dann Ta drücken
;
; I2CEN=1, keine Wartung:
;	call	WDTein		; Kontrolle Zeitüberschreitung 5 min. ein
;
; Raspi arbeitet sein Programm ab (fuchsfalle.sh), schaltet GP22 
; zum Start auf HIGH u. sendet SMS über Internetstick:
gpio22w
	btfss	gp22pin		; wenn gp22pin=1, überspringe nä. Bef.
	goto	gpio22w		; gp22pin=0, neue Abfrage
;
;	call	WDTaus		; Kontrolle Zeitüberschreitung aus
; das Hochfahren des Pi und das SMS senden von gammu darf nicht
; länger als 5 min dauern, sonst erfolgt RESET durch PIC !!!
	return
;
; #################################################################
; UP SmsKorrekt:
; setzen der Bits im Reg. sms, welche SMS eben gesendet wurde,
; aber in Abhängigkeit vom Bit sms_fehler (wird in ISR beeinflußt):
; #################################################################
SmsKorrekt
	btfsc	ZUmeld		; wenn ZUmeld=0, überspringe nä. Bef.
	goto	fehlerFw	; ZUmeld=1, Sprung zu fehlerFw:
;
weiterUSw				; ZUmeld=0
	btfsc	USmeld		; wenn USmeld=0, überspringe nä. Bef.
	goto	fehlerUw	; USmeld=1, Sprung zu fehlerUw:
;
						; USmeld=0
; hier UP-Ende bei ZUmeld=0 u. USmeld=0, es wurde nichts verändert!
	retlw	4			; fertig
;
fehlerFw
	bsf		sms_wegF	; sms_wegF=1
	btfss	sms_fehler	; wenn sms_fehler=1, überspringe nä. Bef.
	goto	weiterUSw	; sms_fehler=0, Sprung zu weiterUSw:
;
	bcf		sms_wegF	; sms_fehler=1, sms_wegF=0
	goto	weiterUSw	; Sprung zu weiterUSw:
;
fehlerUw
	bsf		sms_wegU	; sms_wegU=1
	btfss	sms_fehler	; wenn sms_fehler=1, überspringe nä. Bef.
	retlw	5			; sms_fehler=0, fertig
;
	bcf		sms_wegU	; sms_fehler=1, sms_wegU=0
	retlw	6
;
; ###############################################################
; UP NumCopy:
; kopiert eine Nummer in das Register zustand (oberes Halbbyte)
; obere 4 Bits löschen und über w mit einer Dezimal-Zahl x von 
; 0 bis 15 belegen mit movlw d'0...15', z.B. nummer=9=b'00001001'
; ###############################################################
NumCopy
	movwf	nummer		; w (0-f) in nummer sichern
	movf	zustand,w	; oberes	; w=zustand=b'1000xxxx'
	andlw	0x0f		; Halbbyte	; literal=b'00001111'
	movwf	zustand		; löschen	; zustand=w=b'0000xxxx'
	swapf	nummer,w	; Halbbytes tauschen, => w=b'10010000'
	addwf	zustand,f	; zustand = zustand + w=b'1001xxxx'
	return
;
; ###############################################################
; UP WDTein: schaltet in Reg. WDTCON (Bank1) den WDT ein.
; angegebene Laufzeit setzt Vorteiler 1:128 im OPTION_REG voraus!
; WDT_TEMP speichert alten Reg.inhalt WDTCON in WDT_TEMP für
; Wiederherstellung in UP WDTaus.
; ###############################################################
WDTein
	; Bank1
	bcf		STATUS,RP1
	bsf		STATUS,RP0
;
	movf	WDTCON,w	; Reg.-Inhalt retten
	movwf	WDT_TEMP
	movlw	b'00010111'	; Teilerfaktor '1011' laden und
	movwf	WDTCON		; WDT einschalten (mit ca. 5min Laufzeit)
	; Bank0
	bcf		STATUS,RP1
	bcf		STATUS,RP0
;
	clrwdt					; WDT zurücksetzen
	return
;
; ###############################################################
; UP WDTaus: schaltet in Reg. WDTCON (Bank1) den WDT aus.
; Setzt Zuweisung Vorteiler 1:128 in OPTION_REG zum WDT voraus!
; UP stellt alten Reg.inhalt WDTCON aus WDT_TEMP (UP WDTein)
; wieder her.
; ###############################################################
WDTaus
	; Bank1
	bcf		STATUS,RP1
	bsf		STATUS,RP0
;
	movf	WDT_TEMP,w	; alten Reg.inhalt wieder herstellen
	movwf	WDTCON
	bcf		WDTCON,SWDTEN	; WDT aus
	; Bank0
	bcf		STATUS,RP1
	bcf		STATUS,RP0
;
	return
;
; ###############################################################
; UP LcdStart: LCD initialisieren, Startüberschrift ausgeben
; ###############################################################
LcdStart
;
; LCD einschalten, Überschrift ausgeben:
	bsf		LC1			; 1. Controller
	call	InitLcdSer	; initialisieren (für z.B. LCD 4x16, 4x20)
	bcf		LC1
;
; ##### bei LCD mit 2 Controller:
;	bsf		LC2			; 2. Controller
;	call	InitLcdSer	; initialisieren (nur bei LCD 4x27, 4x40)
;	bcf		LC2
;
	bsf		LC1			; 1. Controller ein
	movlw	0x80		; Cursor auf Zeile 1, Spalte 0
	call	OutLcdCon	; einstellen
;
	movlw	'f'			; Text "fuchspi" ausgeben
	call	OutLcdDat
	movlw	'u'
	call	OutLcdDat
	movlw	'c'
	call	OutLcdDat
	movlw	'h'
	call	OutLcdDat
	movlw	's'
	call	OutLcdDat
	movlw	'p'
	call	OutLcdDat
	movlw	'i'
	call	OutLcdDat
	movlw	' '
	call	OutLcdDat
	bcf		LC1			; 1. Controller aus
;
	return
;
; ###############################################################
; UP LcdAusgabe: LCD-Ausgabe Akkuspannung und Reg. zustand
; ###############################################################
LcdAusgabe
; Ausgabe Akkuspannungswert in Zeile 1, ab Spalte 9
	call	UAkkuOut
;
; Ausgabe Reg. zustand in Zeile 2, ab Spalte 0
	call	ZustandOut
;
; Ausgabe Reg. sms in Zeile 3, ab Spalte 4
	call	SmsOut
;
; Ausgabe Reg. testpi in Zeile 4, ab Spalte 0
	call	TestPiOut
;
	return
;
; ###############################################################
; UP Lesen: Unterbrechungspunkt, Ta drücken, Verzögerungszeit
; ###############################################################
Lesen
	bsf		PImeld	; LED blau ein
taster
	btfsc	TEST	; wenn TEST=0, überspr. nä. Bef.
	goto	taster	; TEST=1, Ta nicht gedrückt
					; TEST=0, Ta gedrückt, weiter:
	bcf		PImeld	; LED blau aus
	movlw	d'4'	; 4x250ms Wartezeit
	call	maxitime
;
	return
;
; ###############################################################
; UP UAkkuOut: LCD-Ausgabe Akkuspannung Zeile 1, Spalte 9
; ###############################################################
UAkkuOut
; Ausgaben in Zeile 1 u. 2 (Controller 1 / E1
	bsf		LC1			; LCD-Controller 1 ein
	movlw	0x88		; Ausgabe in Zeile 1, ab Spalte 8:
	call	OutLcdCon
;
; Ausgabe der Akkuspannung:
	movf	bytelcd0,w
	movwf	f0
	movf	bytelcd1,w
	movwf	f1
	call	OutDez4		; Daten für UP über f1, f0
	movlw	' '
	call	OutLcdDat
	movlw	'm'
	call	OutLcdDat
	movlw	'V'
	call	OutLcdDat
	bcf		LC1
;
	return
;
; ###############################################################
; UP ZustandOut: LCD-Ausgabe Reg. zustand in Zeile 2
; ###############################################################
ZustandOut
	bsf		LC1			; LCD-Controller 1 ein
	movlw	0xc0		; Ausgabe in Zeile 2, ab Spalte 0:
	call	OutLcdCon
; 
	movlw	'z'			; Text "zustand" ausgeben
	call	OutLcdDat
	movlw	'u'
	call	OutLcdDat
	movlw	's'
	call	OutLcdDat
	movlw	't'
	call	OutLcdDat
	movlw	'a'
	call	OutLcdDat
	movlw	'n'
	call	OutLcdDat
	movlw	'd'
	call	OutLcdDat
	movlw	' '
	call	OutLcdDat
;
	movf	zustand,w	; Ausgabe Inhalt von Register zustand
	call	bin8_out_ascii ; in binärer Schreibweise
	bcf		LC1			; Controller1 aus
;
	return
;
; ###############################################################
; UP RcodeOut: LCD-Ausg. Rückkehrcode von UP'en in Z. 3/0,
; das Hexbyte (unteres Halbbyte!) muß in w übergeben werden.
; (Wird für UP SmsKorrekt und ZustKorrekt verwendet.)
; ###############################################################
RcodeOut
	movwf	BcdDaten
; Ausgaben in Zeile 3 (4x16, Controller 1 / E1:
	bsf		LC1			; Controller1 ein
	movlw	0x90		; Ausgabe in Zeile 3, ab Spalte 0
	call	OutLcdCon
;
	movf	BcdDaten,w
	call	Bcd4Bit		; Ausgabe Hexbyte in w, 2-stellig auf LCD
;
	return
;
; ###############################################################
; UP SmsOut: LCD-Ausgabe Reg. sms in Zeile 3 / Spalte 4
; ###############################################################
SmsOut
; Ausgaben in Zeile 3 (4x16, Controller 1 / E1:
	bsf		LC1			; Controller1 ein
	movlw	0x94		; Ausgabe in Zeile 3, ab Spalte 4
	call	OutLcdCon
;
	movlw	's'			; Text "sms" ausgeben
	call	OutLcdDat
	movlw	'm'
	call	OutLcdDat
	movlw	's'
	call	OutLcdDat
;
	movlw	0x98		; Ausgabe in Zeile 3, ab Spalte 8:
	call	OutLcdCon
;
	movf	sms,w		; Register sms
	call	bin8_out_ascii ; in binärer Schreibweise
	bcf		LC1			; LCD mit 1 Controller
;
	return
;
; ###############################################################
; UP TestPiOut: LCD-Ausgabe Reg. testpi in Zeile 4
; ###############################################################
TestPiOut
; Ausgaben in Zeile 4 (4x16, Controller 1 / E1)
	bsf		LC1			; Controller1 ein
	movlw	0xd0		; Ausgabe in Zeile 4, ab Spalte 0:
	call	OutLcdCon
;
	movlw	't'			; Text "testpi" ausgeben
	call	OutLcdDat
	movlw	'e'
	call	OutLcdDat
	movlw	's'
	call	OutLcdDat
	movlw	't'
	call	OutLcdDat
	movlw	'p'
	call	OutLcdDat
	movlw	'i'
	call	OutLcdDat
;
	movlw	0xd8		; Ausgabe in Zeile 4, ab Spalte 9:
	call	OutLcdCon
;
	movf	testpi,w	; Register testpi in
	call	bin8_out_ascii ; binärer Schreibweise ausgeben
	bcf		LC1			; LCD mit 1 Controller
;	bcf		LC2			; LCD mit 2 Controller
;
	return
;
; ###############################################################
; UP IntOut: LCD-Ausgabe Register INTCON in Zeile 4
; ###############################################################
IntOut
; Ausgaben in Zeile 4 (4x16, Controller 1 / E1)
	bsf		LC1			; Controller1 ein
	movlw	0xd0		; Ausgabe in Zeile 4, ab Spalte 0:
	call	OutLcdCon
;
	movlw	'I'			; Text "INTCON" ausgeben
	call	OutLcdDat
	movlw	'N'
	call	OutLcdDat
	movlw	'T'
	call	OutLcdDat
	movlw	'C'
	call	OutLcdDat
	movlw	'O'
	call	OutLcdDat
	movlw	'N'
	call	OutLcdDat
;
	movlw	0xd8		; Ausgabe in Zeile 3, ab Spalte 9:
	call	OutLcdCon
;
	movf	INTCON,w	; Register INTCON in
	call	bin8_out_ascii ; binärer Schreibweise ausgeben
	bcf		LC1			; LCD mit 1 Controller
;	bcf		LC2			; LCD mit 2 Controller
;
	return
;
; ###############################################################
; UP StempOut: LCD-Ausgabe Register STATUS in Zeile 4
; ###############################################################
StempOut
; Ausgaben in Zeile 4 (4x16, Controller 1 / E1)
	bsf		LC1			; Controller1 ein
	movlw	0xd0		; Ausgabe in Zeile 4, ab Spalte 0:
	call	OutLcdCon
;
	movlw	'S'			; Text "INTCON" ausgeben
	call	OutLcdDat
	movlw	'T'
	call	OutLcdDat
	movlw	'A'
	call	OutLcdDat
	movlw	'T'
	call	OutLcdDat
	movlw	'U'
	call	OutLcdDat
	movlw	'S'
	call	OutLcdDat
;
	movlw	0xd8		; Ausgabe in Zeile 3, ab Spalte 9:
	call	OutLcdCon
;
	movf	S_TEMP,w	; Register STATUS in
	call	bin8_out_ascii ; binärer Schreibweise ausgeben
	bcf		LC1			; LCD mit 1 Controller
;	bcf		LC2			; LCD mit 2 Controller
;
	return
;
; ###############################################################
; UP PiTxd : Shutdown-Rückmeldungsabfrage des Pi-Pin TxD.
; speichern in Bit txd_pi, Register zustand.
; Im Normalbetrieb des Pi ist TxD=HIGH, nach dem Shut down LOW.
; ###############################################################
PiTxd
	bsf		txd_pi	; txd_pi=1, Raspi läuft.
	btfsc	txdpin	; wenn txdpin=0, überspringe nä. Bef.
	return			; txdpin=1, dann txd_pi=1
	bcf		txd_pi	; txdpin=0, dann txd_pi=0,
					; meldet Raspi-ShutDown beendet.
	return
;
; ###############################################################
; UP Falle : testet den Status der Fallenklappe (S1=Kugelschalt.)
; in Abhängigkeit von sms_wegF.
; Setzt oder löscht das bit falle_zu im Reg. zustand und signa-
; lisiert am Portpin ZUmeld über Pegelanpassg. mit Invertierung
; den Zustand von S1 an den Raspi GPIO27.:
; S1 offen (Falle offen => falle=1),
; falle_zu=0 (Reg. zustand), Ausgabe ZUmeld=0
; S1 geschlossen (Falle ausgelöst => falle=0),
; falle_zu=1 (Reg. zustand), Ausgabe ZUmeld=1
; (Die gewählte Zuordnung S1 => falle u. Falle zu/offen ist bedingt
; durch die Stromaufnahme des PIC im Sleep-Zustand.)
; ###############################################################
Falle
	bsf		falle_zu	; falle=0 (S1), falle_zu=1
	btfsc	falle		; wenn falle=0 (S1), überspringe nä. Bef.
	bcf		falle_zu	; falle=1 (S1), falle_zu=0
;
	bcf		ZUmeld		; ZUmeld=0 (signalisiert Falle offen)
	btfsc	falle_zu	; wenn falle_zu=0, überspringe nä. Bef.
	bsf		ZUmeld		; ZUmeld=1 (signalisiert Falle ausgelöst)
;
; alt:
;	btfsc	sms_wegF	; wenn sms_wegF=0, überspringe nä. Bef.
;	bcf		ZUmeld		; sms_wegF=1, ZUmeld=0
;
						; sms_wegF=0, ZUmeld=1 bleibt.
; neu:
	btfss	sms_wegF	; wenn sms_wegF=1, überspringe nä. Bef.
	return				; sms_wegF=0, falle_zu=1, Zumeld=1 bleiben
						; sms_wegF=1, falle_zu u. Zumeld löschen:
	bcf		falle_zu
	bcf		ZUmeld
;
; damit wird, wenn ZUmeld einmal gemeldet, eine Wiederholung
; der gleichen SMS unterbunden.
	return
;
; ###############################################################
; UP Spannung : Messung Akkuspannung, Test auf Unterspg., 
; Setzen oder löschen des Bits unter_u im Register zustand und  
; des Pegels von USmeld in Abhängigkeit von sms_wegU
; ###############################################################
Spannung
; 1. an AN0 Akkuspannung überprüfen:
	; Spannungsmodul einschalten
	bcf		MOSEA		; MOSEA=0, P-CH. MOSFET ein
	; ADC einschalten
	bsf		ADCON0,ADON	; ADC ein
	; Messung durchführen:
	clrf	f1
	clrf	f0
	clrf	xw1
	clrf	xw0
	call	UMessen1 	; ADC mißt Spannung, wandeln nach xw1, xw0
	; Spannungsmodul ausschalten
	bsf		MOSEA		; MOSEA=1, P-CH. MOSFET aus
;
	movf	xw1,w		; UP mv verlangt Werte in f1, f0
	movwf	f1
	movf	xw0,W
	movwf	f0
	call	mv			; Ergebnis in  in f1, f0
;
; Spannungsteiler- und Meßfühlerkorrektur:
	clrf	xw1
	movlw	OffsetU1
	movwf	xw0
	call	Sub16		; 16-bit-Subtraktion: f = f-xw
;	call	Add16		; 16-bit-Addition: f = f+xw
						; Ergebnis der Add. in Registern f1, f0
	movfw	f1			; Umspeichern, für LCD-Ausgabe
	movwf	bytelcd1
	movfw	f0
	movwf	bytelcd0
;
; 2. Meßwert auf Unterspannung testen:
; Ist gemessener Wert im erlaubten Bereich, dann wird im Reg. 
; zustand Bit unter_u=0, im Falle von Unterspannung unter_u=1.
	call	UnterU		; f Spannungswerte, USGL,H US-Grenzwert
	return				; Bit unter_u in zustand wurde beeinflußt!
;
; ###############################################################
; UP UnterU : eine gemessene Akku-Spannung f1, f0 prüfen,
; ob sie über dem Grenzwert Unterspannung xw1, xw0 liegt.
; Bei Unterspannung unter_u=1, Akku o.k., dann unter_u=0.
; ###############################################################
UnterU
; Das UP Sub16 verlangt die Daten wie folgt f:=f-xw, also
; Reg. f Spannungsmeßwerte (vom UP , xw gewünschter US-Grenzwert:
	movf	USGL,w		; US-Grenze, low byte
	movwf	xw0
	movf	USGH,w		; US-Grenze, high byte
	movwf	xw1
	call	Sub16
; sinkt der Meßwert unter den Grenzwert, ist das Ergebnis der
; Subtraktion negativ:
; SFehler,C und STATUS,C=1, nur für UP Sub16 !
	bcf		unter_u		; unter_u=0, keine Unterspg.
	bcf		USmeld		; USmeld=0
	btfss	STATUS,C	; wenn C=1, überspringe nä. Bef.
	return				; C=0, keine Unterspg., UP beenden.
						; C=1, Unterspg.:
	bsf		unter_u		; unter_u=1, Akku-Spg. < Grenzwert.
	bsf		USmeld		; USmeld=1
;
; alt:
;	btfsc	sms_wegU	; wenn sms_wegU=0, überspringe nä. Bef.
;	bcf		USmeld		; sms_wegU=1, USmeld=0
						; sms_wegU=0, USmeld=1 bleibt.
;neu:
	btfss	sms_wegU	; wenn sms_wegU=1, überspringe nä. Bef.
	return				; sms_wegU=0, unter_u=1, USmeld=1 bleiben
						; sms_wegU=1, unter_u u. USmeld löschen
	bcf		unter_u
	bcf		USmeld
;	
; damit wird, wenn USmeld einmal gemeldet, eine Wiederholung
; der gleichen SMS unterbunden.
	return
;
; ###############################################################
; UP UMessen1: ADC misst Spannung, wandeln nach xw1, xw0 
; >>>>>>>  Messzyklusstart hier mit bsf ADCON0,1  (PIC16F690)  !!
; ###############################################################
UMessen1
	clrf	counter
UM_aqui				; 0,3 ms ADC Aquisitionszeit nach Eingangswahl
	decfsz	counter,f
	goto	UM_aqui
;
	bsf	ADCON0,1	; ADC starten
UM_loop
	btfsc	ADCON0,1 ; ist der ADC fertig?
	goto	UM_loop	; nein, weiter warten
	movfw	ADRESH	; obere  2 Bit auslesen
	movwf	xw1		; obere  2-Bit nach xw1
	bsf	STATUS,RP0	; Bank1
	movfw	ADRESL	; untere 8 Bit auslesen
	bcf	STATUS,RP0 	; Bank0
	movwf	xw0		; untere 8-Bit nach xw0
;
	clrf	counter	; warten, damit der ADC sich erholen kann
UM_warten
	decfsz	counter,f
	goto	UM_warten
	return
;
; ##############################################################
; UP mv: Wandlung des ADC-Wert in Millivolt (binär)
; Der ADC-Wert steht in f1,f0
; Ergebnis steht in f1,f0
; ##############################################################
mv	; zunächst die Multiplikation mal 5
	movf	f0,W
	movwf	xw0
	movf	f1,W
	movwf	xw1
	call	Add16		; f := 2xADC
	call	Add16		; f := 3xADC
	call	Add16		; f := 4xADC
	call	Add16		; f := 5xADC
	; ADC * 5 nach xw kopieren
	movf	f0,W
	movwf	xw0
	movf	f1,W
	movwf	xw1		; xw := 5xADC
	; xw durch 64 dividieren (6 mal durch 2)
	; dann ist xw = 5xADC/64
	movlw	0x06
	call	Div2
	call	Sub16		; f := 5xADC - 5xADC/64
	; xw auf 5xADC/128 verringern
	movlw	0x01
	call	Div2
	call	Sub16		; f := 5xADC - 5xADC/64 - 5xADC/128 
	return
;
; #############################################################
; #				L C D - A U S G A B E - U P ' e				  #
; #############################################################
;
; #############################################################
; UP bin8_out_ascii: wandelt ein Byte (8bit),in 8 einzelne Bits
; um und gibt jedes einzeln als ASCII-Zeichen auf LCD aus.
; EQU's: bin8reg, bitnum, Übergabe des Bytes an UP in w.
; #############################################################
bin8_out_ascii
	movwf	bin8reg		; ein Byte aus W laden
	movlw	d'8'		; Anzahl umzuwandelnder Bits
	movwf	bitnum
top1
	bcf		STATUS,C	;C=0
	rlf		bin8reg,F	;mit Bit 0 beginnend
	btfss	STATUS,C
	goto	null_out	;C=0
eins_out				;C=1
	movlw	'1'			;ascii 1 
	call	OutLcdDat	;ausgeben
	goto	bit_stelle
null_out
	movlw	'0'			;ascii 0
	call	OutLcdDat	;ausgeben
bit_stelle
	decfsz	bitnum,F	;bitnum dekrementieren
	goto	top1		;nächste Bitstelle
	return				;alle 8 Bits ausgegeben; fertig!
;
; #############################################################
; 16 Bit Wert (f1,f0) auf LCD dezimal 4-stellig anzeigen mit,
; Vornullen-Unterdrückung
; #############################################################
OutDez4				;16-bit (f0,f1) als 4-st. Dez (BCD) zum Lcd
	call	Hex2Dez16	;Wandlung
	clrf	Fehler
	movfw	HdT		;1.000er Ausgabe
	call	Vornull		;
	movfw	HdH		;100er Ausgabe
	call	Vornull
	movfw	HdZ		;10er Ausgabe
	call	Vornull
	movfw	HdE		;1er Ausgabe
	Call	Bcd4Bit
	return
;
; #############################################################
; 16 Bit Wert (f1,f0) auf LCD dezimal 3-stellig anzeigen,
; mit Vornullen-Unterdrückung
; #############################################################
OutDez3				;16-bit (f0,f1) als 3-st. Dez (BCD) zum Lcd
	call	Hex2Dez8	;Wandlung
	clrf	Fehler
	movfw	HdH		;100er Ausgabe
	call	Vornull
	movfw	HdZ		;10er Ausgabe
	call	Vornull
	movfw	HdE		;1er Ausgabe
	Call	Bcd4Bit
	return
;
Vornull
	iorwf	Fehler,F
	movf	Fehler,F	;Test auf 0
	btfss	STATUS,Z	;bisher alles 0 ?
	goto	Bcd4Bit		;nein, UP sichert Rücksprungadr.
	movlw	' '			;ja, Leerzeichen ausgeben
	goto	OutLcdDat	;UP sichert Rücksprungadr.
	; Das return fehlt hier absichtlich, weil die beiden GOTO-
	; Sprünge zu je einem UP führen, das mit der gespeicherten
	; Rückkehradresse des UP Vornull den Rücksprung sichert.
;
; #############################################################
; UP Bcd4Bit: low-4-Bit als BCD-Zahl (Dez. 0-9) ausgeben
; #############################################################
Bcd4Bit				;low-4 Bit als BCD ausgeben
	movwf	BcdDaten
	movlw	B'00110000'
	ADDwf	BcdDaten,F	;ASCII-wandeln (+48)
	movlw	B'00111010'
	subwf	BcdDaten,W
	btfss	STATUS,C	;Test auf A ... F
	goto	BcdOk
	movlw	.7
	addwf	BcdDaten,F	;korrigiere A...F (+7)
BcdOk
	movfw	BcdDaten
	call	OutLcdDat
	return
;
; ##############################################################
; UP Hex2Dez16 und 8: wandelt 16 o. 8-bit (f1, f0)
; in einstell. Dez.zahl. (BCD) um.
; ##############################################################
; 16-bit(f1,f0) in 5-stellen Bcd (ZT,T,H,Z,E):
;     10 000 = 0000 2710 h
;      1 000 = 0000 03E8 h
;        100 = 0000 0064 h
;         10 = 0000 000A h
;          1 = 0000 0001 h
; ##############################################################
Hex2Dez16			; 16-bit(f1,f0) in 5-stellen Bcd (ZT,T,H,Z,E)				
	movlw	0x27		; 10 000 = 00 00 27 10 h
	movwf	xw1
	clrf	xw2
	movlw	0x10
	movwf	xw0
	call	Hex2Dez1	; 10 000er
	movfw	HdX
	movwf	HdZT
;
	movlw	0x03		; 1 000 = 00 00 03 E8 h
	movwf	xw1
	clrf	xw2
	movlw	0xE8
	movwf	xw0
	call	Hex2Dez1	; 1000er
	movfw	HdX
	movwf	HdT
Hex2Dez8
	movlw	0x00		; 100 = 00 00 00 64 h
	movwf	xw2
	movwf	xw1
	movlw	0x64
	movwf	xw0
	call	Hex2Dez1	; 100er
	movfw	HdX
	movwf	HdH
;
	movlw	0x00		; 10 = 00 00 00 0A h
	movwf	xw2
	movwf	xw1
	movlw	0x0A
	movwf	xw0
	call	Hex2Dez1	; 10er
	movfw	HdX
	movwf	HdZ
;
	movfw	f0
	movwf	HdE
	return
;
Hex2Dez1
	clrf	HdX
	decf	HdX,F
HdLoop
	incf	HdX,F
	call	Sub16		;
	btfss	STATUS,C	;Überlauf
	goto	HdLoop		;Stelle 1 mehr
	call	Add16
	return
;
; #############################################################
; #				M A T H E M A T I K - U P ' e				  #
; #############################################################
;
; #############################################################
; UP Add16: 16 bit Adition, C-Flag bei Überlauf gesetzt
; #############################################################
Add16 		; 16-bit add: f = f + xw
	movf	xw0,W		;low byte
	addwf	f0,F 		;low byte add
;
	movf	xw1,W 		;next byte
	btfsc	STATUS,C 	;skip to simple add if C was reset
	incfsz	xw1,W 		;add C if it was set
	addwf	f1,F 		;high byte add if NZ
	return
;
; #############################################################
; UP Sub16: 16 Bit Subtraktion, C-Flag bei Überlauf gesetzt
; #############################################################
Sub16				;16 bit f:=f-xw   calc=xw cnt=f
	clrf	Fehler		;bcf	Fehler,C   ;extraflags löschen
	movf	xw0,W		;f0=f0-xw0
	subwf	f0,F
	btfsc	STATUS,C
	goto	sub16A
	movlw	0x01		;borgen von f1
	subwf	f1,F
	btfss	STATUS,C
	bsf	Fehler,C		;Unterlauf
sub16A
	movf	xw1,w		;f1=f1-xw1
	subwf	f1,F
	btfss	STATUS,C
 	bsf	Fehler,C		;Unterlauf
	bcf	STATUS,C
	btfsc	Fehler,C
	bsf	STATUS,C
	return
;
; #############################################################
; UP Div2: Division durch 2 wird w-mal ausgeführt,
; die zu dividierende Zahl steht in xw
; #############################################################
Div2 
	movwf	counter		;Anzahl der Divisionen speichern
Div2a				;16 bit xw:=xw/2
	bcf	STATUS,C	; carry löschen
	rrf	xw1,F
	rrf	xw0,F
	decfsz	counter,F		;fertig?
	goto	Div2a		;nein: noch mal
	return
;
; Anwendung:
;	movf	f0,W	;f ==> W ==> xw
;	movwf	xw0
;	movf	f1,W
;	movwf	xw1		;
;			;z.B. xw durch 64 dividieren (6 mal durch 2),also:
;			;W=6
;	movlw	0x06
;	call	Div2
;
; ################################################################
; ################################################################
; ################################################################
	end
;=============Ende Datei fuchspi9.asm=============
