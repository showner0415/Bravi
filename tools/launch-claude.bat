@echo off
rem Shared launcher used by open-claude.bat and open-claude-fable.bat.
rem Usage: launch-claude.bat MODEL EFFORT [extra claude arguments...]
rem   1) Opus 5.5 at medium effort fast-forwards every local branch from the remote.
rem   2) Then Claude Code opens interactively with MODEL and EFFORT.
setlocal
chcp 65001 >nul
cd /d "%~dp0.."

set "TARGET_MODEL=%~1"
set "TARGET_EFFORT=%~2"
shift
shift
set "EXTRA_ARGS="
:collect
if "%~1"=="" goto collected
set "EXTRA_ARGS=%EXTRA_ARGS% %1"
shift
goto collect
:collected

set "CLAUDE=claude"
where claude >nul 2>nul && goto found
set "CLAUDE=%USERPROFILE%\.local\bin\claude.exe"
if exist "%CLAUDE%" goto found
echo claude was not found on PATH or in %USERPROFILE%\.local\bin
pause
exit /b 1
:found

set "PULL_PROMPT=Update every local git branch in this repository from its remote. First run git fetch --all --prune. Then, for each local branch that has an upstream: if it is the currently checked-out branch, run git pull --ff-only; otherwise fast-forward it without checking it out, using git fetch REMOTE REMOTEBRANCH:LOCALBRANCH. Never check out another branch, stash, merge, rebase, reset, force, or touch uncommitted changes. If a branch cannot be fast-forwarded, skip it and say why. Finish with one short line per branch, in Korean."

echo [1/2] Opus 5.5 (effort medium): pulling all branches...
"%CLAUDE%" -p "%PULL_PROMPT%" --model claude-opus-5-5 --effort medium --allowedTools "Bash(git:*)"
if errorlevel 1 echo Pull step failed. Opening Claude Code anyway.

echo.
echo [2/2] Opening Claude Code: %TARGET_MODEL% (effort %TARGET_EFFORT%)
"%CLAUDE%" --model %TARGET_MODEL% --effort %TARGET_EFFORT%%EXTRA_ARGS%
endlocal
