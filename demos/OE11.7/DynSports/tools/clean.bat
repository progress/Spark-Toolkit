@echo off
set DLC=C:\Progress\OpenEdge
set WRKDIR=C:\Progress\WRK
set PATH=%DLC%\BIN;%DLC%\PERL\BIN;%PATH%
set LIB=%DLC%\LIB;%LIB%

pasman clean -v -A -I SportsPASOE