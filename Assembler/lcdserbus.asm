; Datei lcdserbus.asm					Stand:	### 01.01.2012
; ####################################################################
; Neue LCD-Steuerung seriell (I2C) mit PCF8574 (alt: LCD2C_2pcf.asm)
; ####################################################################
; max. Takt des PCF8574 <= 100 KHz
; Unterprogramme für I2C zu 8-Bit-Betrieb zum LCD mit 2 Controllern
; über 2x PCF8574, einfügen mit:
;	#include <lcdserbus.asm>
;
; setzt im Hauptprogramm voraus:
;	#include <I2C-PIC-Master.asm>	; Hardware-I2C für PIC als Master
;	oder 
;	#include	<software-iic.asm>	; Software-I2C für PIC als Master
;	#include <quarz_4MHz.asm>
;	oder 
;	#include <quarz_2097152Hz.asm>	;Zeitverzöger. je nach Quarz
;	#include <LCD_Out_1.asm> 	;für z.B. ASCII-Konvertierungen
;
;Definitionen:
;LcdDaten	equ	0x30	; Datenbyte für LCD
;LcdByte	equ	0x31	; Steuerbyte für LCD
;LcdStat	equ	0x32	; UP Busyabfrage, LCD-Statusregister
;LcdCon		equ	0x33	; LCD-Controllregister
;
;PcfAdr1	equ	0x40	; Adressregister für PCF8574 / IC1
;PcfAdr2	equ	0x41	; Adressregister für PCF8574 / IC2
;
; Anschlußbelegung 4-bit-Datenbus LCD D7:4 an PCF P7:4, 
; Steuerpins je nach LCD-Typ unterschiedlich:
;
; für TC1602E-01-Ser:
; ===================
;#define	LcdSRs	LcdByte,4	; Display RS Pin am PCF P4
;#define	LcdSRw	LcdByte,5	; Display R/W Pin am PCF P5
;#define	LcdSE1	LcdByte,6	; Display E/E1 Pin am PCF P6
;#define	LcdBel	LcdByte,7	; LCDbel. am PCF P7 n.a.(1=Aus,0=Ein)
;#define	LC1		LcdCon,5	; LC1=1, 1. Controller aktiv
;#define	LC2		LcdCon,6	; LC2=1, 2. Controller aktiv
;
; I2C-Adressen des Moduls TC1602 (0100A2...A0):
;	IC1 (Daten) 0100 000	IC2 (Steuer) 0100 111 mit 2 Contr.
;
; für MSP-C404DYSY-1N:
; ====================
;#define	LcdSRs	LcdByte,0	; Display RS Pin am PCF P0
;#define	LcdSRw	LcdByte,1	; Display R/W Pin am PCF P1
;#define	LcdSE1	LcdByte,2	; Display E/E1 Pin am PCF P2
;#define	LcdSE2	LcdByte,3	; Display E2 Pin am PCF P3
;#define	LcdBel	LcdByte,7	; LCDbel. am PCF P7 n.a.(1=Aus,0=Ein)
;#define	LC1		LcdCon,5	; LC1=1, 1. Controller aktiv
;#define	LC2		LcdCon,6	; LC2=1, 2. Controller aktiv
;
; I2C-Adressen des Moduls C404 (0100A2...A0):
;	IC1 (Daten) 0100 011	IC2 (Steuer) 0100 100 mit 2 Contr.
;
;Beispiel einer Wertzuweisung für Adressregister der PCF8574:
;	movlw	b'01000110'	; PCF-Adr. 1, lsb=0 (schreiben zum Slave)
;	movwf	PcfAdr1		; Adr.-Reg. für IC1
;	movlw	b'01001000'	; PCF-Adr. 2, lsb=0 (schreiben zum Slave)
;	movwf	PcfAdr2		; Adr.-Reg. für IC2
;
;##################################################################
; UP InitLcdSer: für LCD-Initialisierung, 3x Steuerbyte '00110000'
; senden. Bei LCD's mit 2 Controllern an LC1 und LC2 denken !
;##################################################################
InitLcdSer
	movlw	d'25'		; 25ms warten
	call	miditime	; auf LCD-Bereitschaft
	call	i2c_on
	movf	PcfAdr1,w	; Adr. IC1/schreiben zum Slave
	call	i2c_tx
	movlw	b'00110000'	; Steuerbyte zum LCD (DB7:0)
	call	i2c_tx
	call	i2c_off
;
	call	i2c_on
	movf	PcfAdr2,w	; Adr. IC2/schreiben zum Slave
	call	i2c_tx
	clrf	LcdByte		; Bel=0, E2=0, E1=0, RW=0, RS=0
	movf	LcdByte,w
	call	i2c_tx
	call	ser_togg		; 1
	call	ser_togg		; 2
	call	ser_togg		; 3
	call	i2c_off
;
;Ab hier Busy-Abfrage verwenden
	movlw	b'00111000'	; 4 Systemset: 8bit, 2-zeil., 5x7
	call	OutLcdCon
	movlw	b'00001111'	; Display, Unterstrich-Cursor, blinkend Ein
	call	OutLcdCon
	movlw	b'00000110'	; Entry mode set, Cursor nach rechts
	call	OutLcdCon
	movlw	b'00000010'	; Cursor home
	call	OutLcdCon
	movlw	b'00000001'	; Display löschen
	call	OutLcdCon
	return
;
ser_togg				; Toggeln mit "E" zwecks Datenübernahme
	call	LcdConEnOn	; E1oder E2 setzen, entspricht E=1
	movf	LcdByte,w
	call	i2c_tx
	call	LcdConEnOut	; E1 oder E2 löschen, entspricht E=0
	movf	LcdByte,w
	call	i2c_tx
	movlw	d'5'		; x=5
	call	miditime		; Verzögerung um x mal 1 ms
	return
;
;##################################################################
; UP LcdBusySer: UP wartet auf Displaybereitschaft/mit Busy-Abfrage
;##################################################################
LcdBusySer
	call	i2c_on
	movf	PcfAdr1,w	; Adr. IC1/schreiben zum Slave
	call	i2c_tx		; Adresse senden
	movlw	b'11111111'	; IC1 vorbereiten zum Lesen vom LCD
	call	i2c_tx		; Byte senden
	call	i2c_off
BusyLoopS
	call	i2c_on
	movf	PcfAdr2,w	; IC2 anwählen/schreiben
	call	i2c_tx		; Adresse senden
	bsf		LcdSRw		; Bel=x, E2=0, E1=0, RW=1, RS=0
	movf	LcdByte,w
	call	i2c_tx		; Byte senden
	call	LcdConEnOn	; E1/2=1 (LcdByte) 
	movf	LcdByte,w	; LcdByte => w
	call	i2c_tx		; Byte (w) senden
; nun legt das LCD den Inhalt seines Steuerregisters an P7:0 von IC1
	call	i2c_off
	; hier wird das Display gelesen
	call	i2c_on
	movf	PcfAdr1,w	; IC1 anwählen, Displayausgabe lesen
	iorlw	b'00000001'	; lsb=1 / lesen vom Slave
	call	i2c_tx		; Adresse senden
	call	i2c_rx		; vom Slave lesen (Steuerreg.inhalt nach w)
	movwf	LcdStat		; von w Steuerregisterinhalt speichern
	call	i2c_off
;
	call	i2c_on
	movf	PcfAdr2,w	; IC2 anwählen/schreiben
	call	i2c_tx		; Adresse senden
	call	LcdConEnOut	; E1/2=0
	movf	LcdByte,w	
	call	i2c_tx		; Byte senden
	call	i2c_off
	btfsc	LcdStat,7	; wenn LcdStat,7=0, überspringe nä.Bef.
	goto	BusyLoopS	; Busy=1, neue Abfrage
;
	call	i2c_on
	movf	PcfAdr2,w	; IC2 anwählen, schreiben zum Display
	call	i2c_tx		; Adresse senden
	bcf		LcdSRw		; Bel=x, E2=0, E1=0, RW=0, RS=0
	movf	LcdByte,w
	call	i2c_tx		; Byte senden
	call	i2c_off
	return
;
;#################################################################
; UP OutLcdCon: Steuerbyte-Ausgabe zum LCD mit Busy-Abfrage
; Übergabe des Steuerbyte in w
;#################################################################
OutLcdCon
	movwf	LcdDaten	; Byte in LcdDaten zwischenspeichern
	call	LcdBusySer	; warten, bis Display bereit ist
;
	;Übertragung Steuerbyte zum IC1 ( 1. PCF8574)
	call	i2c_on
	movf	PcfAdr1,w	; Adr. IC1/schreiben zum Slave
	call	i2c_tx
	movf	LcdDaten,w	; Byte zurück nach w holen
	call	i2c_tx		; zum IC1 senden
	call	i2c_off	
	;Toggeln mit E am IC2 ( 2. PCF8574)
	call	i2c_on
	movf	PcfAdr2,w	; Adr. IC2/schreiben zum Slave
	call	i2c_tx
	call	LcdConEnOn	; E1/2=1
	movf	LcdByte,w
	call	i2c_tx
	call	LcdConEnOut	; E1/2=0
	movf	LcdByte,w
	call	i2c_tx
	call	i2c_off
	return
;
;#################################################################
; UP OutLcdDat: Datenbyte-Ausgabe zum LCD mit Busy-Abfrage
; Übergabe des Datenbyte in w. Vor Aufruf muß in LcdCon,0 stehen,
; welcher Controller aktiv sein soll.
;#################################################################
OutLcdDat
	movwf	LcdDaten	; Byte in LcdDaten zwischenspeichern
	call	LcdBusySer	; warten, bis Display bereit ist
;
;Übertragung Steuerbyte zum IC1 ( 1. PCF8574)
	call	i2c_on
	movf	PcfAdr1,w	; Adr. IC1/schreiben zum Slave
	call	i2c_tx
	movf	LcdDaten,w	; Byte zurück nach w holen
	call	i2c_tx		; zum IC1 senden
	call	i2c_off	
;Toggeln mit E am IC2 ( 2. PCF8574)
	call	i2c_on
	movf	PcfAdr2,w	; Adr. IC2/schreiben zum Slave
	call	i2c_tx
	bsf	LcdSRs		; Bel=x, E2=0, E1=0, RW=0, RS=1,
	movf	LcdByte	,w	; Datenbyte ins Display schreiben
	call	i2c_tx
	call	LcdConEnOn	; E1/2=1
	movf	LcdByte,w
	call	i2c_tx
	call	LcdConEnOut	; E1/2=0
	movf	LcdByte,w
	call	i2c_tx
;	clrf	LcdByte
	bcf	LcdSRs
	movf	LcdByte,w
	call	i2c_tx
	call	i2c_off
	return
;
;#################################################################
; UP LcdConEnOn: wählt je nach Controller LcdE oder LcdE2 aus
; und setzt dieses Bit. Wurde die Auswahl (LC1=1 oder LC2=1)
; vergessen, wird automatisch Controller 1 aktiviert.
;#################################################################
LcdConEnOn
	btfsc	LC1
	goto	control1on
	btfsc	LC2
	goto	control2on
;
control1on
	bsf	LcdSE1
	return
control2on
	bsf	LcdSE2
	return
;
;#################################################################
; UP LcdConEnOut: wählt je nach Controller LcdE oder LcdE2 aus
; und löscht dieses Bit. Wurde die Auswahl (LC1=1 oder LC2=1)
; vergessen, wird automatisch E/E1=0 (Controller 1 deaktiviert).
;#################################################################
LcdConEnOut
	btfsc	LC1
	goto	control1out
	btfsc	LC2
	goto	control2out
;
control1out
	bcf	LcdSE1
	return
control2out
	bcf	LcdSE2
	return
;
;#################################################################
; UP ClrLcdSer: löscht den LCD-Bildschirm, Cursor Home 
;#################################################################
ClrLcdSer
	bsf	LC1
	movlw	b'00000010'	; Cursor home
	call	OutLcdCon
	movlw	b'00000001'	; Display löschen
	call	OutLcdCon
	bcf	LC1
;
	bsf	LC2
	movlw	b'00000010'	; Cursor home
	call	OutLcdCon
	movlw	b'00000001'	; Display löschen
	call	OutLcdCon
	bcf	LC2
	return
;
;#################################################################
;Ende Datei  lcdserbus.asm
