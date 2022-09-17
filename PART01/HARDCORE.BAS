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
DATA &H60, &H06, &H1E, &H0E, &H1F, &HE9, &HDF, &H00, &H5B, &HB8, &H13, &H00, &HCD, &H10, &HBA, &HC8, &H03, &H33, &HC0, &HEE, &H42, &H33, &HC9, &HB1, &HFF, &HEE, &H8A, &HC4, &HEE, &H32, &HC0, &HEE
DATA &H80, &HFC, &H3F, &H74, &H04, &H90, &H90, &HFE, &HC4, &HE2, &HEE, &H50, &H50, &H8B, &HEC, &HB4, &HA0, &H8E, &HC0, &HDF, &H47, &H04, &HD9, &HEB, &HD9, &HEB, &HDC, &HC1, &HDE, &H77, &H02, &HD9
DATA &HEE, &HD9, &HC2, &HDD, &HD1, &HD8, &HCC, &HD9, &HFF, &HDE, &H0F, &HD9, &HC1, &HD9, &HFB, &HD8, &HCA, &HDF, &H5E, &H00, &HD8, &HC9, &HDF, &H5E, &H02, &HD9, &HC9, &HD8, &HE2, &HD9, &HEE, &HD8
DATA &HD9, &H9B, &HDF, &HE0, &H25, &H00, &H01, &H75, &H04, &H90, &H90, &HD8, &HC3, &HB1, &H02, &H8B, &H46, &H00, &H05, &H60, &H00, &HBA, &H40, &H01, &HF7, &HE2, &H03, &H46, &H02, &H2D, &H9C, &H00
DATA &H8B, &HF8, &H51, &H8D, &H77, &H06, &HB1, &H40, &HF6, &HC1, &H07, &H75, &H07, &H90, &H90, &HAD, &H81, &HC7, &H38, &H01, &H50, &H24, &H03, &HC0, &HE0, &H02, &H26, &H02, &H05, &HAA, &H58, &HC1
DATA &HE8, &H02, &HE2, &HE4, &H8B, &H46, &H00, &H87, &H46, &H02, &H89, &H46, &H00, &H59, &HE2, &HBF, &HB5, &H7D, &H33, &HFF, &H26, &H8B, &H05, &H84, &HC0, &H74, &H03, &H90, &H90, &H48, &H84, &HE4
DATA &H74, &H04, &H90, &H90, &HFE, &HCC, &HAB, &HE2, &HEB, &HBA, &HDA, &H03, &HEC, &HA8, &H08, &H75, &HFB, &HEC, &HA8, &H08, &H74, &HFB, &HE4, &H60, &H48, &H0F, &H85, &H66, &HFF, &HB0, &H03, &HCD
DATA &H10, &H58, &H58, &H1F, &H07, &H61, &HCB, &HE8, &H1E, &HFF, &H5A, &H00, &H00, &H02, &H05, &H00, &H50, &H05, &HA4, &H1A, &HE9, &H6B, &HF9, &H6F, &HF9, &H6F, &HE9, &H6B, &HA4, &H1A, &H50, &H05
