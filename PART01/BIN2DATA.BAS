'=============================================================================
' Achtung, Falls du das hier jetzt siehst, nachdem du MAKE.BAT ausgefuehrt
' hast, einfach beenden. Leider kann man kein BASIC Programm mit QBASIC
' ausfuehren, ohne dass der Editor anschliessend gestartet wird.
'=============================================================================

DIM byte AS STRING * 1

OPEN "SWBAS.BIN" FOR BINARY AS #1
OPEN "DATA.BAS" FOR OUTPUT AS #2

FileLen = LOF(1)

PRINT #2, "DATA ";
FOR i = 1 TO FileLen
        GET #1, i, byte

        DataHex$ = HEX$(ASC(byte))
        IF LEN(DataHex$) = 1 THEN
                DataHex$ = "0" + DataHex$
        END IF

        
        IF i MOD 32 = 0 THEN
                PRINT #2, "&H" + DataHex$;
                PRINT #2, ""
                IF i < FileLen THEN
                        PRINT #2, "DATA ";
                END IF
        ELSE
                PRINT #2, "&H" + DataHex$;
                PRINT #2, ", ";
        END IF

NEXT i

CLOSE #2
CLOSE #1



