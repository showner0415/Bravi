@echo off
rem Pulls all branches (Opus 5.5, effort medium), then opens Claude Code
rem with Opus 5.5 at effort high. Extra arguments are passed through
rem (for example: open-claude.bat --continue).
call "%~dp0tools\launch-claude.bat" claude-opus-5-5 high %*
