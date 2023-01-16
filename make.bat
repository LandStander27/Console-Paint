@echo off
echo Compiling

mkdir bin 1>NUL 2>NUL

v paint.v -cc tcc -prod -o ".\bin\paint.exe"
echo Compiled