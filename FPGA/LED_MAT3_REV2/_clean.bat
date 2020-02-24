rmdir "db" /S /Q 
rmdir "system" /S /Q 
rmdir "incremental_db" /S /Q 
rmdir "greybox_tmp" /S /Q
cd output_files 
del system.html
del *.bak /S
del *.tcl~ /S
del *.rpt
del *.smsg
del *.summary
del *.done
del *.bsf
del *.pin
del *.jdi
del *.pof
del *.sof

