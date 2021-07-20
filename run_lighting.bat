@echo off

IF "%~2" == "" (GOTO fail)
IF "%~3" == "" (GOTO fail)
IF "%~4" == "" (GOTO fail)
%1 -e --no-window --path %~dp0 -s bake_lighting.gd %cd%/%2 %cd%/%3 %4
exit /b

:fail 
echo "Usage: godot -s bake_lighting.gd <map file> <target .lmbakex file> <game texture folder>"\
exit /b 1
