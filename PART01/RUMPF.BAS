DIM buf%(0 TO 127)

' Segmentregister auf das der Variable setzen
DEF SEG = VARSEG(buf%(0))

' Buffer mit Magie fuellen
FOR i% = 0 TO 255
        READ b%
        POKE VARPTR(buf%(0)) + i%, b%
NEXT i%

' Jetzt geht's los, Spaetzla mit Soss...
CALL ABSOLUTE(VARPTR(buf%(0)))

' Segmentregister zuruecksetzen
DEF SEG

' Magie
