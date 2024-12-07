@echo off
setlocal EnableDelayedExpansion

if "%1"=="" (
    echo Usage: build.bat project_name
    echo Example: build.bat blog
    exit /b 1
)

set NAME=%1
set TEMPLATE_DIR=template
set PROJECT_DIR=htmx_%NAME%

:: Create project directory structure
mkdir "%PROJECT_DIR%"
mkdir "%PROJECT_DIR%\src"
mkdir "%PROJECT_DIR%\www"
mkdir "%PROJECT_DIR%\launcher"
mkdir "%PROJECT_DIR%\launcher\default"
mkdir "%PROJECT_DIR%\launcher\any"

:: Convert NAME to uppercase for class names
set "upper_name=%NAME%"
for %%a in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
    set "upper_name=!upper_name:%%a=%%A!"
)

:: Copy and rename template files
call :process_template "template\htmx_demo.ecf" "%PROJECT_DIR%\htmx_%NAME%.ecf"
call :process_template "template\src\htmx_demo.e" "%PROJECT_DIR%\src\htmx_%NAME%.e"
call :process_template "template\src\htmx_demo_execution.e" "%PROJECT_DIR%\src\htmx_%NAME%_execution.e"
call :process_template "template\README.md" "%PROJECT_DIR%\README.md"

:: Copy files that don't need name replacement
xcopy "template\launcher" "%PROJECT_DIR%\launcher" /E /I /Y
xcopy "template\www" "%PROJECT_DIR%\www" /E /I /Y
copy "template\ewf.ini" "%PROJECT_DIR%\ewf.ini"

echo Project htmx_%NAME% created successfully!
exit /b 0

:process_template
set "src=%~1"
set "dst=%~2"
if not exist "%src%" (
    echo Template file not found: %src%
    exit /b 1
)
(for /f "delims=" %%i in ('type "%src%"') do (
    set "line=%%i"
    :: First handle target names in ECF files (should remain lowercase)
    set "line=!line:htmx_demo=htmx_%NAME%!"
    :: Then replace class names (uppercase)
    set "line=!line:HTMX_DEMO=HTMX_%upper_name%!"
    echo !line!
)) > "%dst%"
exit /b 0 