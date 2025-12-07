@echo off
IF "%1"=="" (    echo Please provide a script file.
    exit /b 1)

dart run ../../bin/oche.dart %1