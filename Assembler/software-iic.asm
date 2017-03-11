; ##################################################################
; Software-I2C-Routinen für PIC16Fxxx				22.12.2011
; ##################################################################
;	
;******************************
; Prozessor-Takt (Quarz)	I2C-Takt
;----------------------------------------
;	  4 MHz		  85 KHz
;	  8 MHz		170 KHz
;	10 MHz		210 KHz
;	12 MHz		250 KHz
;	16 MHz		340 KHz
;	20 MHz		420 KHz
;******************************
; für Slaves im Standard-Mode bis 100 KHz (bei 4 MHz), 
; im Fast-Mode bis 400 KHz (4-16 MHz).
;
; ##################################################################
;
; Variablen festlegen
;buf	equ	0x20	; Puffer für I2C
;count	equ	0x21	; Zähler für 8 bits
;
; Konstanten für I2C festlegen, Pinbelegung, z.B. für Port C:
; 	RC0	CLK out
;	RC1	CLK in
;	RC6	SDA out
;	RC7	CLK in
;
;#define	SDAo	PORTC,6	;Daten output
;#define	SDAi	PORTC,7	;Daten input
;#define	SCL	PORTC,0	;Takt
;#define	SCLo	PORTC,0	;Takt output
;#define	SCLi	PORTA,1	;Takt input
;
;******************************************************
; UP-Routinen für I2C:
;	Bus-Reset	i2c_reset
;	Bus übernehmen	i2c_on
;	W senden	i2c_tx
;	Byte empfangen	i2c_rx (nach w und RXData und SSPBUF)
;	Bus freigeben	i2c_off
;******************************************************
;
; ##################################################################
; UP i2c_reset: Bus zurücksetzen (Bus-Reset), 
; bringt den I2C-Bus in einen definierten Anfangszustand
; ##################################################################
i2c_reset
	bsf	SDAo
	bsf	SCLo
	nop
	movlw	9
	movwf	buf
i2c_reset1
	nop
	bcf	SCLo
	nop
	nop
	nop
	nop
	nop
	bsf	SCLo
	nop
	decfsz	buf, f
	goto	i2c_reset1
	nop
	call	i2c_on
	nop
	bsf	SCLo
	nop
	nop
	bcf	SCLo
	nop
	call	i2c_off
	return
;
; ##################################################################
; UP i2c_on: Busübernahme durch den PIC
; ##################################################################
i2c_on
	; wenn SDA und SCL beide High, dann SDA auf Low ziehen
	bsf	SCL		; failsave
	bsf	SDAo		; failsave
	;testen, ob der Bus frei ist
	btfss	SCLi
	goto	i2c_on		; Taktleitung frei?
	btfss	SDAi
	goto	i2c_on		; Datenleitung frei?
	bcf	SDAo
	nop
	bcf	SCL
	return
;
; ##################################################################
; UP i2c_tx: schreiben auf den Bus
; ##################################################################
i2c_tx
	; w über i2c senden, takt ist unten, daten sind unten
	call	WrI2cW		; 8 Bit aus W nach I2C
	; ACK muß nun empfangen werden, Takt ist low
	bsf	SDAo		;Datenleitung loslassen
	bsf	SCL		; ACK Takt high
i2c_tx2
	btfss	SCLi
	goto	i2c_tx2
	nop
;i2c_tx1
;	btfsc	SDAi		; ACK empfangen?
;	goto	i2c_tx1		; nein SDA ist high
	bcf	SCL		; ja , Takt beenden
	bcf	SDAo
	return 
;
; ##################################################################
; UP i2c_rx: lesen vom Bus, gelesenes Byte in W
; ##################################################################
i2c_rx
	; Takt ist unten, Daten sind unten
	call	RdI2cW		; 8 von I2C nach W
	; Takt ist unten, kein ACK
	nop
	nop
	bsf	SDAo
	nop
	bsf	SCL
i2c_rx1
	btfss	SCLi
	goto	i2c_rx1
	nop
	bcf	SCL
	bcf	SDAo
	return
;
; ##################################################################
; UP i2c_rxack: liest ein Byte vom Bus u. 
; erzeugt anschließend ein Ack-Signal für den gelesenen I2C-Baustein.
; (wenn ein weiteres Byte gelesen werden soll)
; ##################################################################
i2c_rxack
	; takt ist unten, daten sind unten
	call	RdI2cW		; 8 von I2C nach W
	; Takt ist unten, ACK muß nun gesendet werden
	bcf	SDAo
	nop
	nop
	nop
	nop
	bsf	SCL
i2c_rxack1
	btfss	SCLi
	goto	i2c_rxack1
	nop
	bcf	SCL
	bcf	SDAo
	return
;
; ##################################################################
; UP i2c_off: Busfreigabe (wenn Datentransfer beendet ist)
; ##################################################################
i2c_off
	; SCL ist Low und SDA ist Low
	nop
	nop
	bsf	SCL
	nop
	bsf	SDAo
	return
;
; ##################################################################
; UP WrI2cW: schiebt das Byte aus W in den I2C, MSB zuerst.
; I2C-Periode ist 2,5 µs
; PIC-Zyklus ist 4/10MHz = 0,4µs
; -> Takt muß für 3 Zyklen H und für 3 Zyklen L sein
;     + 1 Zyklus Reserve
; 78 Takte
; ##################################################################
WrI2cW
	; Takt unten, Daten unten
	; Datenbyte in w
	movwf	buf
	movlw	8
	movwf	count		; 8 Bits
WrI2cW1
	; Datenleitung setzen
	bcf	SDAo
	rlf	buf,f
	btfsc	STATUS,C	; 0?
	bsf	SDAo		; nein, 1
	nop
	bsf	SCL		; Taht high
WrI2cW2
	btfss	SCLi
	goto	WrI2cW2
	bcf	SCL		; Takt low
	decfsz	count,f		; 8 Bits raus?
	goto	WrI2cW1	; nein
	return			; ja
;			
; ##################################################################
; UP RdI2cW: liest das Byte aus I2C nach W
; Takt ist unten
; Daten sind unten
; ##################################################################
RdI2cW
	clrf	buf
	movlw	8
	movwf	count
	bsf	SDAo		;failsave
RdI2cW1
	nop
	clrc
	btfsc	SDAi
	setc
	rlf	buf,f
	bsf	SCL		; Takt high
RdI2cW2
	btfss	SCLi
	goto	RdI2cW2
	bcf	SCL		; Takt low
	decfsz	count,f		; 8 Bits drinn?
	goto	RdI2cW1	; nein
	movfw	buf		; ja fertig
	return
;
; ##################################################################
; 	Ende Datei software-iic.asm
;		
