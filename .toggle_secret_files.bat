:: Toggle Secret Files/Folders on Windows PC
::
:: hss.wiki
::
:: Hiding files and folders in the same folder with this script by setting
:: their system and hidden attributes. Those "secret files" (and folders)
:: cannot be easily shown in file explorer or by using `dir` in CMD.
::
:: Basic usage: Put this BAT file in a folder that you want to hide its files
:: and subfolders. Double click to run the script, and all others will be
:: hidden. Refresh if needed to see the effect. To reveal those files and
:: folders, simply double click the script again.
::
:: Intermediate usage: Set a passphrase under the "Config" section of this
:: script. The files can be hided same as above, but revealing secret files
:: will require the passphrase you just set.
::
:: Advanced usage: Several flags can be specified in the filename of this
:: script in order to lock this "key" script into a ZIP file. For example, if
:: rename this script as `.toggle_secret_files -ppass -nname.zip -d.bat`, after
:: hiding its neighbouring files and folders, the script will lock itself in a
:: ZIP file called `name.zip` encrypted with password `pass`. The `-d` flag
:: asks the script to delete itself after zipped, so that it works like moving
:: to archive.
::
:: The installation of [7-Zip](https://www.7-zip.org/) (about 1.4 MB) is
:: required if want to zip and encrypt the script. See also the "Program logic"
:: section below for other advanced usage.

:: TODO:
::
:: - Update to use 7z -sdel switch to implement self-destruction feature.
:: - Check if 7z is available from the command line. Catch errors.

:: ############################################################################
::   Program logic
:: ############################################################################
::
:: If the current folder contains any visible files/subfolders:
::     Hide them all as secret files/folders.
::     If -p<password> is flagged:
::         Lock this script to a ZIP file encrypted with <password>.
::         If -n<name> is flagged:
::             Name the ZIP file as <name>.
::         If -d is flagged for self-destruction:
::             Self-delete the script, leaving only its encrypted ZIP file.
:: Else:
::     Reveal all hidden secret files/folders and turn them back to normal if
::     script passphrase is none. Otherwise, check passphrase first.
:: If -v is flagged for verbose:
::     Print execution details and leave the console open.

:: ############################################################################
::   Config
:: ############################################################################

set "script_passphrase=none"
:: Replace `none` with your passphrase. For example, `set
:: "script_passphrase=Alohomora"`. If configured, will request passphrase
:: before revealing any secret files or folders.

:: ############################################################################
::   Implementation
:: ############################################################################

cls
:: Clear screen

@echo off
:: @ symbol for less verbose. `echo off`: hide the prompt for each command.

:: ============================================================================
::   Main
:: ============================================================================

:: - Parse flags
:: - Catalog current files and folders
:: - Toggle secret files and folders
:: - After hiding secret files/folders, self encrypt and destruct if flagged
:: - End

:: ============================================================================
::   Parse flags
:: ============================================================================

set "filename_remaining_str=%~n0"
:: `%~n0` stores current file name without extension.
:: Ref: https://stackoverflow.com/a/15568171. Substitute 1 with 0.

:parse_next_flag
:: `:label` for goto statements to jump to.

:: Split filename string by whitespaces.
:: Ref: https://stackoverflow.com/a/19009701/13451354. Version 2.
for /f "tokens=1*" %%a in ("%filename_remaining_str%") do (
    set "flag_str=%%a"
    set filename_remaining_str=%%b
)
:: `%%a` and `%%b` are local iterator vars.

:: Note that if we access `flag_str`'s value within the loop, it can be off by
:: one round of iteration. It's because delayed expansion is still disabled.
:: See latter comments for details.

set "flag_prefix=%flag_str:~0,2%"
:: Substring slicing, starting from index 0 with length 2.

if "%flag_prefix%" == "-n" (set "zip_n=%flag_str:-n=%") else ^
if "%flag_prefix%" == "-p" (set "zip_pw=%flag_str:-p=%") else ^
if "%flag_prefix%" == "-d" (set "d=_true") else ^
if "%flag_prefix%" == "-v" (set "v=_true") else ^
if "%flag_str:~0,1%" == "-" echo Unrecognized flag in filename: `%flag_str%`.
:: `^` for line continuation.
:: `"%flag_str:-n=%"`: the latter part works like RegEx. `=` is the match.
if defined filename_remaining_str goto :parse_next_flag

if not defined zip_pw (
    if defined v echo Script will not be zipped since password is not flagged.
) else (
    if defined v echo Parsed ZIP password: `%zip_pw%`.
    if defined zip_n (
        if defined v echo Parsed ZIP filename: `%zip_n%`.
    ) else (
        set "zip_n=.toggle_secret_files.bat.zip"
        setlocal enableDelayedExpansion
        if defined v echo ZIP filename by default: `!zip_n!`.
        setlocal disableDelayedExpansion
    )
)
if defined v echo.
:: `echo:` or `echo.` to echo a blank line.

:: `setlocal Enable/DisableDelayedExpansion`: enabling will introduce `!var!`
:: syntax, which allows "re-evaluation" of var in runtime, but will slow down
:: the script. If disabled, the value of the var won't change after the point
:: of expansion/"evaluation".

:: ============================================================================
::   Catalog current files and folders
:: ============================================================================

:: Save names of files/folders under current directory as indexed variables.
:: Ref: https://stackoverflow.com/a/19542051

setlocal enableDelayedExpansion
set "script_filename_w_extension=%~nx0"

:: Catalog secret files and folders
set /a counter = 0
set /a n_secret_files = 0
:: `/a` for numeric.

for /f "tokens=1* delims=:" %%a in ('dir /ahs /b 2^>nul ^|findstr /n "^"') do (
    if not "%%b" == "%script_filename_w_extension%" if not "%%b" == "%zip_n%" (
        set /a counter += 1
        set "secret_file_number_!counter!=%%b"
        set "n_secret_files=!counter!"
    )
)

:: Excluding this script and its possible ZIP since we don't want to turn them
:: into secret files. Uses double quotes since filename can contain spaces.

:: `dir /ahs /b 2^>nul ^|findstr /n "^"` is a command-line command to list and
:: filter directories. `^` is used to escape special chars.

:: `dir /a`: display only with certain attributes. `d`: directories, `h`:
:: hidden, `s`: system. `/b`: bare list.
:: Ref: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/dir

:: `2^>nul` redirects the command's stderr (2. 0 for stdin, 1 for stdout.) and
:: discard it, in order to suppress the "File Not Found" error when there's no
:: results. `|` pipes the former's stdout to the latter's stdin.
:: Ref: https://stackoverflow.com/a/62268165, https://stackoverflow.com/a/46956193, https://stackoverflow.com/a/20298717

:: Catalog all files and folders
set /a counter = 0
set /a n_files = 0

for /f "tokens=1* delims=:" %%a in ('dir /a /b 2^> nul ^|findstr /n "^"') do (
    if not "%%b" == "%script_filename_w_extension%" if not "%%b" == "%zip_n%" (
        set /a counter += 1
        set "file_number_!counter!=%%b"
        set "n_files=!counter!"
    )
)

if defined v (
    echo Here we have %n_secret_files% secret files/folders out of ^
%n_files% files/folders in total.
    echo.
)

:: ============================================================================
::   Toggle secret files and folders
:: ============================================================================

if %n_files% gtr %n_secret_files% (
    @REM Boolean operators: https://stackoverflow.com/a/18499854
    @REM There's no and/or operators in batch script.
    if %n_files% == 0 goto end
    if defined v echo Will hide visible files and folders.
    goto hide_all_files
) else (
    if defined v echo Will reveal secret files and folders.

    if "%script_passphrase%" == "none" (
        @REM Double-quote in case passphrase contains whitespaces.
        if defined v echo Script passphrase not required.
        goto reveal_secret_files
    ) else (
        if defined v echo Script passphrase required.

        :require_passphrase_to_reveal_files
        echo Enter passphrase to reveal secret files and folders:
        set /p "user_input_passphrase=>"
        @REM `>` will show in the console.
        if "!user_input_passphrase!" == "%script_passphrase%" (
            @REM Note the use of delayed expansion here. Otherwise it won't
            @REM work in the first iteration even if the passphrase is correct.
            if defined v echo Passphrase match.
            goto reveal_secret_files
        ) else (
            echo Passphrase does not match.
            goto require_passphrase_to_reveal_files
        )
    )
)

:hide_all_files
for /l %%n in (1 1 %n_files%) do (
    attrib !file_number_%%n! +h +s
    if defined v echo Hided `!file_number_%%n!`.
)
echo Successfully hided all %n_files% files and folders.
echo.
goto self_encrypt_and_destruct_if_flagged

:reveal_secret_files
for /l %%n in (1 1 %n_secret_files%) do (
    attrib !secret_file_number_%%n! -h -s
    if defined v echo Revealed `!secret_file_number_%%n!`.
)
echo Successfully revealed all %n_secret_files% secret files and folders.
echo.
goto end

:: ============================================================================
::   After hiding secret files/folders, self encrypt and destruct if flagged
:: ============================================================================

:self_encrypt_and_destruct_if_flagged
if defined zip_pw (
    7z a "%zip_n%" "%script_filename_w_extension%" -p"%zip_pw%" > nul
    echo Zipped the script into `%zip_n%` with password `%zip_pw%`.
    echo.

    @REM Self-delete
    if defined d (
        if defined v (
            echo "MODE:D Self-Destruction Protocol Initiated."
            echo Self-destruct the script in 10 seconds...
            echo.
            choice /t 10 /c 01 /d 0 /m "0 to proceed, 1 to interrupt."
            if !ERRORLEVEL! == 2 (  @REM The 2nd choice, interrupt.
            @REM Note the use of delayed expansion here. Otherwise would be 0.
            @REM choice ref: https://stackoverflow.com/a/44999930/13451354
                set "is_interrupted=_true"
            )
            echo.
        )
        if defined is_interrupted (
            if defined v echo Self-distruction interrupted.
        ) else (
            if defined v (
                echo "Sayonara."
                timeout 1 > nul
            )
            goto 2>nul & del "%~f0"
            @REM Self-delete. Ref: https://stackoverflow.com/a/20333575
        )
    )
)

:: ============================================================================
::   End
:: ============================================================================

:end

if defined v (
    cmd /k  @REM Keep the CMD window open.
) else (
    echo This window will close in 5 seconds...
    timeout 5 > nul
)
:: Timeout ref: https://stackoverflow.com/a/42598287

:: ############################################################################
::   Coding notes
:: ############################################################################

:: Variable declaration

:: It's recommended to wrap set commands with double quotes to avoid spaces.
:: `set "a=1"` is the same as `set a=1`, but `set a="1"` is different. `set
:: "var="` to undeclare var.

:: Comment styles

:: REM can be used for in-line comments, but will slow down the script. While
:: label-style comments that start with :: won't influence the performance,
:: they can't be used in-line or within parentheses.
:: Ref: https://www.robvanderwoude.com/comments.php

:: Debugging snippets

@REM set "debug_filename=.toggle_secret_files -v -d -ppw -nname -extra"
@REM set "v="  @REM undeclare
@REM set "d="
