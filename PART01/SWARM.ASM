;-----------------------------------------------------------------------------
; Kleiner Grafikeffekt, optimiert auf 256 Byte Codesize, position-independent
; und damit in BASIC einbettbar
; Braucht 386+ mit FPU (Math. Coprozessor)
;-----------------------------------------------------------------------------
.MODEL TINY
.386                                    ; Noetig fuer bestimmte FPU-Befehle
.data

.code
org 100h                                ; Nur wichtig, dass TASM ruhe gibt...
					; wenn er eine COM Datei erzeugen muss
start:
;-----------------------------------------------------------------------------
; Vorbereitungen                  
;-----------------------------------------------------------------------------
	pusha                           ; Alle Register sichern
	push    es                      ; ES Segmentregister sichern
	push    ds                      ; DS Segmentregister sichern

	push    cs                      ; DS = CS
	pop     ds

	jmp     trampolin               ; Sprungbrett zu Daten
					; Wir muessen so Sauereien machen, da
					; wir nicht wissen, wo BASIC den Code
					; letztendlich ablegt....
trampolin_back:     
	pop     bx                      ; Adresse der Daten holen, die entspricht
					; der Ruecksprungadresse des Call unten
					; bx ist unser Zeiger zu den Daten ab sofort

;-----------------------------------------------------------------------------
; Grafik initialisieren und Palette programmieren
;-----------------------------------------------------------------------------
	;--
	;jmp     dbg                    ; Grafikkram ueberspringen (fuer debugger)
	;--

	mov     ax, 13h                 ; Grafikmodus setzen
	int     10h

	mov     dx, 03C8h               ; Farbpalette umprogrammieren
	xor     ax, ax
	out     dx, al
	inc     dx                      ; Portadresse auf 3C9 erhoehen
	xor     cx, cx
	mov     cl, 255                 ; Wir programmieren alle 256 Farben
set_palette:   
	;xor     al, al                                     
	out     dx, al                  ; R
	mov     al, ah
	out     dx, al                  ; G  
	xor     al ,al
	out     dx ,al                  ; B
	cmp     ah, 63                  ; Farbe bei 63 (maximum) saettigen
	je      alreadymax
	inc     ah
alreadymax:        
	loop  set_palette

dbg:
	push    ax                      ; Platz auf dem Stack schaffen
	push    ax                      ; 2x push ist kleiner als sub sp, 4 
										
	mov     bp, sp                  ; Leider kann der 386 keine Adressierung
					; relativ zu sp, also brauchen wir den bp

	;mov     ax, 0a000h              ; Segmentregister auf Grafikspeicher
	mov     ah, 0a0h                ; Segmentregister auf Grafikspeicher
					; das klappt so nur, weil al dank dem 
					; Palettencode 0 ist. Wieder ein byte
					; gespart
	mov     es, ax

;-----------------------------------------------------------------------------
; FPU-Stack mit Werten fuellen
;-----------------------------------------------------------------------------
					; 01234567
	fild    WORD PTR [bx + 4]       ; M             Multiplikator
	fldpi                           ; PM            Pi
	fldpi                           ; PPM           Weiteres Pi
	fadd    st(1), st(0)            ; PTM           Pi * 2 = Tao
	fidiv   WORD PTR [bx + 2]       ; pTM           Pi / Intervall
	fldz                            ; 0pTM          Null als Platzhalter
										;                               fuer iteratorbackup
	fld     st(2)                   ; i0pTM         Iterator mit Tao initialisieren
	

;-----------------------------------------------------------------------------
; Mainloop
;-----------------------------------------------------------------------------
	
ol:
;-----------------------------------------------------------------------------
; FPU Magie...
;-----------------------------------------------------------------------------
					; 0123456
	fst     st(1)                   ; iipTM         Iterator sichern
	
	fmul    st(0), st(4)            ; fipTM         Wert multiplizieren
	fcos                            ; cipTM         Cosinus 
	fimul   WORD PTR [bx]           ; cipTM         Skalieren auf Bildschirm

	fld     st(1)                   ; icipTM        Iterator wiederherstellen
	fsincos                         ; CScipTM       Sinus+Cosinus
	fmul    st(0), st(2)            ; CScipTM       Cosinus mit Modifier 
	fistp   WORD PTR [bp]       ; ScipTM        Integer Auf Stack ablegen
	fmul    st(0), st(1)            ; ScipTM        Sinus mit Modifier
	fistp   WORD PTR [bp + 2]       ; cipTM         Integer auf Stack ablegen
	fxch    st(1)                   ; icpTM         Iterator nach oben holen
	fsub    st(0), st(2)            ; icpTM         Intervall subtrahieren
	fldz                            ; 0icpTM        Null fuer Vergleich
	fcomp                           ; icpTM         Vergleichen
	fstsw   ax                      ; icpTM         FPU Status in AX
	
	and     ax, 0100h               ;               Auf C0 (kleiner als) pruefen
	jnz     still_positive
	fadd    st(0), st(3)            ; icpTM         Wenn Iterater < 0, Tao draufaddieren
still_positive:

;-----------------------------------------------------------------------------
; Koordinaten in Bildschirmspeicher umrechnen
;-----------------------------------------------------------------------------
	mov     cl, 2
second:         
	mov     ax, WORD PTR [bp]       ; Y-Koordinate
	add     ax, 96                  ; In die Mitte schieben 
	mov     dx, 320                 ; Multiplikator fuer Y-Koorditate
	mul     dx
	add     ax, WORD PTR [bp + 2]   ; X-Koordinate addieren
	;add     ax, 157
	sub     ax, 156                 ; In die Mitte schieben, abz einer Zeile, 
										; die wird unten wieder addiert 
										; (Code-Groessenoptimierung :-))
	mov     di, ax                  ; destination index auf ax setzen
       
;-----------------------------------------------------------------------------
; Malen
;-----------------------------------------------------------------------------

	push    cx
	lea     si, [bx + 6]            ; Zeiger auf Komprimierte Brush
	mov     cl, 64                  ; 64 Pixel gross

pixel_loop:
	test    cl, 7h                  ; Checken ob eine Zeile gemalt
	jnz     same_line               ; Wenn nicht, Neu laden skippen
	lodsw                           ; Neue Zeile laden
	add     di, 312                 ; In naechste Zeile springen (abz. Brush Breite)
same_line:        
	push    ax                      ; ax sichern
	and     al, 3                   ; untere 2 Bits 
	shl     al, 2                   ; Ein wenig verstaerken
	add     al, BYTE PTR es:[di]    ; Bisherigen Bildschirminhalt draufaddieren
	stosb                           ; Neues Pixel in Grafikspeicher schreiben
	pop     ax                      ; ax wiederherstellen
	shr     ax, 2                   ; Bits fuer das naechste Pixel reinshiften
	loop    pixel_loop              ; Loop naechstes Pixel
		
	mov     ax, WORD PTR [bp]       ; Koordinaten tauschen...
	xchg    ax, WORD PTR [bp + 2]
	mov     WORD PTR [bp], ax
	pop     cx
	loop    second                  ; ... und dann noch eins malen

;-----------------------------------------------------------------------------
; Gemaltes verdunkeln
;-----------------------------------------------------------------------------
	;mov     cx, 32000               ; ueber alle 320*200 Pixel iterieren
	mov     ch, 7Dh                 ; cl ist vom loop vorher 0, also laden wir
					; nur das highbyte. Ein Byte gespart ;-)

	xor     di, di                  
darker:
	mov     ax, es:[di]             ; 2Pixel holen
	test    al, al                  ; ist es schon 0 (ganz dunkel)?
	jz      black1                  ; Wenn nicht, nichts tun
	dec     ax                      ; ansonsten dunkler machen (ja AX ist gewollt, ist 1 Byte kürzer)
black1:
	test    ah, ah                  ; ist es schon 0 (ganz dunkel)?
	jz      black2                  ; Wenn nicht, nichts tun
	dec     ah                      ; ansonsten dunkler machen
black2:

	stosw                           ; Pixel zurueckschreiben
	loop    darker                  ; Loop fuer dunkel
	

;-----------------------------------------------------------------------------
; Mit VGA-Vertikalrefresh synchronisieren    
;-----------------------------------------------------------------------------
	mov     dx, 3DAh                ; Basisadresse
       
sync1:
	in      al, dx                  ; VGA lesen
	test    al, 8h                  ; auf VSync testen
	jnz     sync1                   ; Noch im aktuellen Frame

sync2:
	in      al, dx                   ; Nochmal lesen
	test    al, 8h
	jz      sync2                    ; Jetzt sind wir in der Austastluecke
					 ; und koennen einen neuen Frame malen

;-----------------------------------------------------------------------------
; Auf Tastatureingabe pruefen                
;-----------------------------------------------------------------------------
	in      al, 060h                ; IO Keyboardcontroller lesen
	dec     ax                      ; Scancode ESC = 1, -1 ergibt 0, wie praktisch...
	jnz     ol                      ; kein ESC, also wieder alles von Vorn


;-----------------------------------------------------------------------------
; Aufraeumen                                 
;-----------------------------------------------------------------------------
	mov     al, 3h                  ; Zurueck zu Textmodus
	int     10h

	pop     ax                      ; Stackpointer wiederherstellen
	pop     ax

	pop     ds                      ; DS Segment wiederherstellen
	pop     es                      ; ES Segment wiederherstellen
	popa                            ; Alle Register wiederherstellen
IFDEF Basic
	retf                            ; Return Far (in BASIC ;-) )
ELSE
	ret                             ; Return near (fuer .COM Version)
ENDIF
	

trampolin:
	call    trampolin_back          ; Sprungbrett zurueck, Adresse der Daten ist jetzt auf den Stack


;-----------------------------------------------------------------------------
; Daten, werden nach dem Sprungbrett relativ zu bx adressiert                                 
;-----------------------------------------------------------------------------
	dw      90                      ; bx + 0        Bildschirm-Skalierungsfaktor
	dw      512                     ; bx + 2        Divisor fuer Kreisschritte
	dw      5                       ; bx + 4        Multiplikator fuer geschnorekel
	dw      0550h                   ; bx + 6        Komprimierte Brush
	dw      1AA4h                   ; Moeglicher Optimierungsspielraum: Die ist ja symmetrisch,
	dw      6BE9h                   ; da kann man auch nur ein Viertel speichern und den Rest 
	dw      6FF9h                   ; erzeugen... Wenn man den Algo dafuer in unter 12 Bytes
	dw      6FF9h                   ; bekommt ;-)
	dw      6BE9h
	dw      1AA4h
	dw      0550h

END start

