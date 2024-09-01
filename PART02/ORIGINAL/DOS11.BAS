DECLARE SUB Menu ()
DECLARE SUB PressButton (ButtonX%, ButtonY%, ButtonColFore%, ButtonColBack%, ButtonColShad%, Backdrop%, Buttonlen%, COB%, ButtonText$)
DECLARE SUB StartDreamit (ButtonNr%)
DECLARE SUB DreamitScroll ()
DECLARE SUB MakeWindow (X%, Y%, XSize%, YSize%, Forecolor%, ShadColor%, BackColor%, TitBarFore%, TitBarBack%, Wintitle$)
DECLARE SUB MakeButton (ButtonX%, ButtonY%, ButtonColFore%, ButtonColBack%, ButtonColShad%, Backdrop%, Buttonlen%, ButtonText$)
DEFINT A-Z


'$INCLUDE: 'general.bi'       'In dieser Datei sind Register fÅr Interrupts
'$INCLUDE: 'mouse.bi'         'Und hier Maus-Zeug

   PALETTE 3, 8
   PALETTE 5, 63                 'Dunkelblau statt Magentha
   PALETTE 6, 32                 'Dunkelrot statt KackBraun

   COLOR 10, 3
   CLS

   DIM SHARED Btext$(3)

   CALL MouseInit
   CALL MouseBorder(1, 1, 25, 80)
   CALL MouseShow

   CALL DreamitScroll

   Btext$(1) = "JA"
   Btext$(2) = "NEIN"
   Btext$(3) = "EXIT"

   CALL Menu

   code$ = "        "

   WHILE code$ <> "kochtopf"
      c$ = INKEY$

      IF c$ <> "" THEN
         code$ = RIGHT$(code$, 7) + c$
      END IF

      CALL MousePoll(row, col, LButton, RButton)
      IF LButton = -1 THEN
         IF row = 11 THEN
            IF col <= 22 AND col >= 14 THEN
               CALL PressButton(11, 14, 7, 5, 6, 4, 8, COB, Btext$(1))
               IF COB = 1 THEN
                  CALL StartDreamit(1)
               END IF
               CALL MakeButton(11, 14, 7, 5, 6, 4, 8, Btext$(1))
            END IF
            IF col <= 43 AND col >= 35 THEN
               CALL PressButton(11, 35, 7, 5, 6, 4, 8, COB, Btext$(2))
               IF COB = 1 THEN
                  CALL StartDreamit(2)
               END IF
               CALL MakeButton(11, 35, 7, 5, 6, 4, 8, Btext$(2))
            END IF
            IF col <= 64 AND col >= 56 THEN
               CALL PressButton(11, 56, 7, 5, 6, 4, 8, COB, Btext$(3))
               IF COB = 1 THEN
                  CALL StartDreamit(3)
               END IF
               CALL MakeButton(11, 56, 7, 5, 6, 4, 8, Btext$(3))
            END IF
         END IF
      END IF
   WEND

   CALL MouseHide                                  'Aus, die Maus
   COLOR 7, 0                                      'DOS-Farben
   PALETTE                                         'Palette wird zurÅckgesetzt


   CLS                                             'Und CLS

END                                                'HÑchel!

SUB DreamitScroll

   DREAMIT$ = "** DREAMIT ** DREAMIT ** DREAMIT ** DREAMIT ** DREAMIT ** DREAMIT ** DREAMIT **"

   COLOR 9, 3

   FOR n = 1 TO LEN(DREAMIT$)

      CALL MouseHide

      FOR xxx& = 1 TO 30000: NEXT
      LOCATE 1, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");
      LOCATE 2, 1: PRINT STRING$(LEN(DREAMIT$) - n, " ") + LEFT$(DREAMIT$, n);
      LOCATE 3, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");
      LOCATE 4, 1: PRINT STRING$(LEN(DREAMIT$) - n, " ") + LEFT$(DREAMIT$, n);
      LOCATE 5, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");
      LOCATE 6, 1: PRINT STRING$(LEN(DREAMIT$) - n, " ") + LEFT$(DREAMIT$, n);
      LOCATE 7, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");
      LOCATE 8, 1: PRINT STRING$(LEN(DREAMIT$) - n, " ") + LEFT$(DREAMIT$, n);
      LOCATE 9, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");
      LOCATE 10, 1: PRINT STRING$(LEN(DREAMIT$) - n, " ") + LEFT$(DREAMIT$, n);
      LOCATE 11, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");
      LOCATE 12, 1: PRINT STRING$(LEN(DREAMIT$) - n, " ") + LEFT$(DREAMIT$, n);
      LOCATE 13, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");
      LOCATE 14, 1: PRINT STRING$(LEN(DREAMIT$) - n, " ") + LEFT$(DREAMIT$, n);
      LOCATE 15, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");
      LOCATE 16, 1: PRINT STRING$(LEN(DREAMIT$) - n, " ") + LEFT$(DREAMIT$, n);
      LOCATE 17, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");
      LOCATE 18, 1: PRINT STRING$(LEN(DREAMIT$) - n, " ") + LEFT$(DREAMIT$, n);
      LOCATE 19, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");
      LOCATE 20, 1: PRINT STRING$(LEN(DREAMIT$) - n, " ") + LEFT$(DREAMIT$, n);
      LOCATE 21, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");
      LOCATE 22, 1: PRINT STRING$(LEN(DREAMIT$) - n, " ") + LEFT$(DREAMIT$, n);
      LOCATE 23, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");
      LOCATE 24, 1: PRINT STRING$(LEN(DREAMIT$) - n, " ") + LEFT$(DREAMIT$, n);
      LOCATE 25, 1: PRINT RIGHT$(DREAMIT$, n) + STRING$(LEN(DREAMIT$) - n, " ");

      CALL MouseShow

   NEXT

END SUB

SUB MakeButton (ButtonX, ButtonY, ButtonColFore, ButtonColBack, ButtonColShad, Backdrop, Buttonlen, ButtonText$)

   CALL MouseHide

   LRADD = ((Buttonlen - LEN(ButtonText$)) / 2)
   LOCATE ButtonX, ButtonY
   COLOR ButtonColFore, ButtonColBack
   PRINT STRING$(LRADD, 32) + ButtonText$ + STRING$(LRADD, 32); : COLOR ButtonColShad, Backdrop: PRINT CHR$(220)
   LOCATE ButtonX + 1, ButtonY + 1
   PRINT STRING$(Buttonlen, 223)

   CALL MouseShow

END SUB

SUB MakeWindow (X, Y, XSize, YSize, Forecolor, ShadColor, BackColor, TitBarFore, TitBarBack, Wintitle$)

   BarChar = 196

   CALL MouseHide

   'XSize = XSize - 2

   COLOR Forecolor, BackColor
   LOCATE X, Y: PRINT "⁄" + STRING$(YSize - 2, 196); : COLOR ShadColor, BackColor: PRINT "ø";

   FOR n = X + 1 TO X + XSize
      COLOR Forecolor, BackColor
      LOCATE n, Y: PRINT "≥" + STRING$(YSize - 2, 32); : COLOR ShadColor, BackColor: PRINT "≥";
   NEXT

   COLOR Forecolor, BackColor
   LOCATE X + XSize + 1, Y: PRINT "¿"; : COLOR ShadColor, BackColor: PRINT STRING$(YSize - 2, 196) + "Ÿ";

   LOCATE X + 1, Y + 2
   COLOR TitBarFore, TitBarBack
   PRINT " " + STRING$(3, BarChar) + " " + Wintitle$ + " " + STRING$(YSize - 11 - LEN(Wintitle$), BarChar) + " "

   COLOR TitBarFore, BackColor
   LOCATE X + 2, Y + 2
   PRINT STRING$(YSize - 4, 196)

   CALL MouseShow

END SUB

SUB Menu

   CALL MakeWindow(5, 10, 8, 60, 12, 6, 4, 10, 6, "DOS (DreamIt Operating System) v1.1")

   CALL MouseHide
   LOCATE 9, 14
   COLOR 9, 4: PRINT "Willst du "; : COLOR 10, 4: PRINT "DREAMIT"; : COLOR 9, 4: PRINT " hîren ?!? (Echt gutes Lied) "
   CALL MouseShow

   CALL MakeButton(11, 14, 7, 5, 6, 4, 8, Btext$(1))
   CALL MakeButton(11, 35, 7, 5, 6, 4, 8, Btext$(2))
   CALL MakeButton(11, 56, 7, 5, 6, 4, 8, Btext$(3))

END SUB

SUB MouseBorder (row1, col1, row2, col2) STATIC

   MouseDriver 7, 0, (col1 - 1) * 8, (col2 - 1) * 8
   MouseDriver 8, 0, (row1 - 1) * 8, (row2 - 1) * 8

END SUB

SUB MouseDriver (m0, m1, m2, m3) STATIC

    DIM regs AS RegType

    IF MouseChecked = FALSE THEN
        DEF SEG = 0

        MouseSegment& = 256& * PEEK(207) + PEEK(206)
        MouseOffset& = 256& * PEEK(205) + PEEK(204)

        DEF SEG = MouseSegment&

        IF (MouseSegment& = 0 AND MouseOffset& = 0) OR PEEK(MouseOffset&) = 207 THEN
            MousePresent = FALSE
            MouseChecked = TRUE
            DEF SEG
        END IF
    END IF

    IF MousePresent = FALSE AND MouseChecked = TRUE THEN
        EXIT SUB
    END IF

   ' Aufruf des Interrupt 51 fÅr MS-Mausfunktionen
    
    regs.ax = m0
    regs.bx = m1
    regs.cx = m2
    regs.dx = m3

    Interrupt 51, regs, regs

    m0 = regs.ax
    m1 = regs.bx
    m2 = regs.cx
    m3 = regs.dx

    IF MouseChecked THEN EXIT SUB

   ' Ist Åberhaupt eine Maus Vorhanden?? Oder etwa eine Katze ?!

    IF m0 AND NOT MouseChecked THEN
        MousePresent = TRUE
    END IF

    MouseChecked = TRUE
    
END SUB

SUB MouseHide

   MouseDriver 2, 0, 0, 0

END SUB

SUB MouseInit

   'Maus zurÅcksetzen

    MouseDriver 0, 0, 0, 0

END SUB

SUB MousePoll (row, col, LButton, RButton) STATIC

   'Maus abfragen

    MouseDriver 3, Button, col, row
    row = row / 8 + 1
    col = col / 8 + 1
                                                
    IF Button AND 1 THEN
        LButton = TRUE
    ELSE
        LButton = FALSE
    END IF

    IF Button AND 2 THEN
        RButton = TRUE
    ELSE
        RButton = FALSE
    END IF

END SUB

SUB MouseShow

    MouseDriver 1, 0, 0, 0

END SUB

SUB PressButton (ButtonX, ButtonY, ButtonColFore, ButtonColBack, ButtonColShad, Backdrop, Buttonlen, COB, ButtonText$)

   CALL MousePoll(row, col, LButton, RButton)
   CALL MouseHide

   LRADD = ((Buttonlen - LEN(ButtonText$)) / 2)
   LOCATE ButtonX, ButtonY
   COLOR Backdrop, Backdrop
   PRINT " "; : COLOR ButtonColFore, ButtonColBack: PRINT STRING$(LRADD, 32) + ButtonText$ + STRING$(LRADD, 32); : COLOR Backdrop, Backdrop: PRINT CHR$(220)
   COLOR Backdrop, Backdrop
   LOCATE ButtonX + 1, ButtonY + 1
   PRINT STRING$(Buttonlen, 223)

   CALL MouseShow

   WHILE LButton = -1
      CALL MousePoll(row, col, LButton, RButton)
      IF row = ButtonX THEN
         IF col >= ButtonY AND col <= (ButtonY + (Buttonlen + 1)) THEN
            COB = 1
         ELSE
            COB = 0
         END IF
      ELSE
         COB = 0
      END IF

   WEND

END SUB

SUB StartDreamit (ButtonNr)

   modfile$ = "DREAMIT.MOD"

   CALL MakeWindow(16, 10, 5, 60, 9, 3, 1, 10, 3, "DOS - Executing DREAMIT")

   CALL MouseHide

   IF ButtonNr = 1 THEN
      COLOR 10, 1
      LOCATE 20, 12: PRINT "                    Wird gemacht . . ."
   END IF

   IF ButtonNr = 2 THEN
      COLOR 10, 1
      LOCATE 20, 12: PRINT "Ich spiele es aber trotzdem rotzdem!"
      LOCATE 21, 12: PRINT "HAHAHAHAHAHAHAHAHAHAHAHAHAHAAAAHA!!!"
   END IF

   IF ButtonNr = 3 THEN
      COLOR 10, 1
      LOCATE 20, 12: PRINT "Wieso soll ich beenden? Da spielen wir doch"
      LOCATE 21, 12: PRINT "lieber DREAMIT !!! Du stimmst mir doch zu, oder?"
   END IF

   CALL MouseShow

   FOR xxx& = 1 TO 10000000: NEXT

   IF modfile$ <> "DREAMIT.MOD" THEN
      CALL MouseHide
      LOCATE 20, 12: PRINT "WAS ?!? Kein DREAMIT auf der Festplatte?        "
      LOCATE 21, 12: PRINT "Dann mu· halt ein Ersatzmod gespielt werden! HAHAHAA!!"
      CALL MouseShow
      FOR xxx& = 1 TO 10000000: NEXT
   END IF

   SHELL "DMP -x " + modfile$

   CLS


   CALL MouseHide
   COLOR 9, 3
   CLS
   CALL MakeWindow(16, 10, 5, 60, 9, 3, 1, 10, 3, "DOS - DREAMIT stopped")
   LOCATE 20, 12: PRINT "AHA!! Du hast DREAMIT nicht ganz / garnicht angehîrt !"
   CALL MouseShow

   FOR xxx& = 1 TO 10000000: NEXT

   CALL DreamitScroll

   CALL Menu

END SUB

