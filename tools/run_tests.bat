@echo off
REM Runs the automated gameplay tests. Set GODOT to your Godot 4.3 console executable.
if "%GODOT%"=="" set GODOT=C:\Godot\Godot_v4.3-stable_win64_console.exe
"%GODOT%" --headless --path "%~dp0.." --fixed-fps 60 res://tests/run_tests.tscn
echo Exit code: %ERRORLEVEL%
pause
