REM: updating the mif files in the project

@ set QUARTUS_BIN=%QUARTUS_ROOTDIR%\bin

@ if not exist "%QUARTUS_BIN%" set QUARTUS_BIN=%QUARTUS_ROOTDIR%\bin64


%QUARTUS_BIN%\\quartus_cdb --update_mif led_mat3


pause
