@echo off
rem Pulls all branches (Opus 5.5, effort medium), then opens Claude Code
rem with Fable 5.2 at effort high. Extra arguments are passed through
rem (for example: open-claude-fable.bat --continue).
call "%~dp0tools\launch-claude.bat" claude-fable-5-2 high %*
