@echo off
rem Opens Claude Code in this project folder. Extra arguments are passed through
rem (for example: open-claude.bat --continue).
cd /d "%~dp0"

where claude >nul 2>nul
if %errorlevel%==0 (
    claude %*
) else if exist "%USERPROFILE%\.local\bin\claude.exe" (
    "%USERPROFILE%\.local\bin\claude.exe" %*
) else (
    echo claude was not found on PATH or in %USERPROFILE%\.local\bin
    pause
)
