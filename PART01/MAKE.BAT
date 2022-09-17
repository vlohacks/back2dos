@ECHO OFF

echo *** Compiliere Assemblerprogramm ...
tasm SWARM.ASM,SW_COM.OBJ
tasm SWARM.ASM,SW_BAS.OBJ /dBasic
tlink /t SW_COM.OBJ,SWARM.COM
tlink /t SW_BAS.OBJ,SWBAS.BIN

echo *** Erzeuge DATA fuer BASIC ...
qbasic /RUN BIN2DATA.BAS

echo *** Erzeuge finales Programm HARDCORE.BAS ...
copy RUMPF.BAS + DATA.BAS HARDCORE.BAS

echo *** Mache sauber ...
del *.OBJ
del *.MAP
del DATA.BAS

echo *** Fertig, viel Spass mit HARDCORE.BAS :-)
