REM: assembling the project

@ set QUARTUS_BIN=%QUARTUS_ROOTDIR%\bin

@ if not exist "%QUARTUS_BIN%" set QUARTUS_BIN=%QUARTUS_ROOTDIR%\bin64


%QUARTUS_BIN%\\quartus_asm led_mat3


pause
