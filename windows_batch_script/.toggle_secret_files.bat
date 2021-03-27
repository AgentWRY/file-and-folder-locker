:: Hide and Lock Files and Folders on Windows PC
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
:: script. The files can be hid same as above, but revealing secret files will
:: require the passphrase you just set.
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
:: section below for other advanced usage. While script passphrase can contain
:: whitespaces, flags in the filename of this script cannot. All of them are
:: case sensitive, but none of them supports special characters yet.

:: ############################################################################
::   Program logic
:: ############################################################################
::
:: If the current folder contains any visible files/subfolders:
::     Hide them all as secret files/folders. Note that this script will not be
::     hid.
::
::     If `exe_password` is configured:
::         Lock this script into an EXE file encrypted with the given password.
::
::         If `exe_filename` is configured:
::             Name the EXE file as given.
::
:: Else:
::     Reveal all secret files/folders in the current folder.
::
::     If `exe_remove_code` is configured:
::         Remove the EXE file if possible.
::
::     If `script_passphrase` is configured:
::         Request passphrase before revealing any secret files or folders.
::
:: If `v` is configured:
::     Run the script in verbose mode.

:: ############################################################################
::   Config
:: ############################################################################

:: ============================================================================
::   Request passphrase before revealing any secret files or folders
:: ============================================================================

set "script_passphrase="

:: Add your passphrase after the equal sign. For example, `set
:: "script_passphrase=Alohomora"`. To turn off passphrase verification, edit it
:: back to `set "script_passphrase="`.

:: ============================================================================
::   Lock this script into an encrypted EXE file after hiding secret files
:: ============================================================================

set "exe_password="

:: After the equal sign, add your password to encrypt the BAT script into an
:: EXE. To keep the BAT script as is after hiding secret files, edit it back to
:: `set "exe_password="`.

:: ============================================================================
::   Name the EXE file
:: ============================================================================

set "exe_filename=.toggle_secret_files.exe"

:: By default, the EXE file is named as `.toggle_secret_files.exe`. Note that
:: only when `exe_password` is defined, the BAT script will be locked into an
:: encrypted EXE named as above, after hiding secret files. Setting only the
:: EXE filename without password will not encrypt the BAT into EXE.

:: ============================================================================
::   Handle the EXE file after self-extracting
:: ============================================================================

:: TODO: update doc from here, also the header
set "exe_remove_code=d"

:: d to del, r to recycle,
:: Toggle verbose mode

:: ============================================================================
::   Run the script in verbose mode
:: ============================================================================

set "v="

:: Turn on to print logging messages to the console and leave the console open
:: upon finish. For example, `set "v=_true"` will turn it on, and `set "v="`
:: will turn it off.

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

:: - Validate configs
:: - Catalog current files and folders
:: - Toggle secret files and folders
:: - Lock the script into an encrypted ZIP if required
:: - End

:: ============================================================================
::   Validate configs
:: ============================================================================

if "%exe_remove_code%" == "d" (

) else if "%exe_remove_code%" == "r" (

)

if defined v (
    if not defined exe_password (
        echo Script will not be encrypted since EXE password is not defined.
    ) else (
        echo EXE password: `%exe_password%`.
        echo EXE filename: `%exe_filename%`.
    )
    echo.
)
:: `echo:` or `echo.` to echo a blank line.


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
:: `%%a` and `%%b` are local iterator vars.

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

    if "%script_passphrase%" == "_none" (
        @REM Double-quote in case passphrase contains whitespaces.
        if defined v echo Script passphrase disabled.
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
:: `:label` for goto statements to jump to.
for /l %%n in (1 1 %n_files%) do (
    attrib !file_number_%%n! +h +s
    if defined v echo Hid `!file_number_%%n!`.
)
if defined v (
    echo Successfully hid all %n_files% files and folders.
    echo.
)
goto self_encrypt_and_destruct_if_flagged

:reveal_secret_files
for /l %%n in (1 1 %n_secret_files%) do (
    attrib !secret_file_number_%%n! -h -s
    if defined v echo Revealed `!secret_file_number_%%n!`.
)
if defined v (
    echo Successfully revealed all %n_secret_files% secret files and folders.
    echo.
)
goto end

:: ============================================================================
::   After hiding secret files/folders, self encrypt and destruct if flagged
:: ============================================================================

:self_encrypt_and_destruct_if_flagged
if defined zip_pw (
    if defined d (
        if defined v (
            echo "MODE:D Self-Destruction Protocol Initiated. Sayonara."
            echo.
        )
        7z a "%zip_n%" "%script_filename_w_extension%" -p"%zip_pw%" -sdel > nul
        @REM `-sdel` to self delete files after compression.
    ) else (
        @REM Encrypt only. Leave one copy of the script outside.
        7z a "%zip_n%" "%script_filename_w_extension%" -p"%zip_pw%" > nul
    )
    if defined v (
        echo Successfully locked the script into `%zip_n%` with password ^
`%zip_pw%`.
        echo.
    )
)

:: ============================================================================
::   End
:: ============================================================================

:end

if defined v (
    cmd /k
)
:: Keep the CMD window open.

:: ############################################################################
::   Coding notes
:: ############################################################################

:: TODO:
::
:: - Move to PowerShell
:: - Error handling. Keep the window open for error message.
:: - Check if 7z is available from the command line. Catch errors.
:: - Support special characters in zip password, filename, passphrase.

:: ============================================================================
::   Knowledge
:: ============================================================================

:: `^` for line continuation.

:: Variable declaration

:: It's recommended to wrap set commands with double quotes to avoid spaces.
:: `set "a=1"` is the same as `set a=1`, but `set a="1"` is different. `set
:: "var="` to undeclare var. If `set "a=1"`, use `if "%a%" == "1"` to check.
:: Note the double quotes.

:: Comment styles

:: REM can be used for in-line comments, but will slow down the script. While
:: label-style comments that start with :: won't influence the performance,
:: they can't be used in-line or within parentheses.
:: Ref: https://www.robvanderwoude.com/comments.php

:: Delayed Expansion

:: `setlocal Enable/DisableDelayedExpansion`: enabling will introduce `!var!`
:: syntax, which allows "re-evaluation" of var in runtime, but will slow down
:: the script. If disabled, the value of the var won't change after the point
:: of expansion/"evaluation".

:: Move to recycle bin

:: echo (new-object -comobject Shell.Application).Namespace(0).ParseName("C:\fullpath\a.txt").InvokeVerb("delete") | powershell -command -
:: Ref: https://superuser.com/a/1514767

:: ============================================================================
::   Debugging snippets
:: ============================================================================

@REM set "debug_filename=.toggle_secret_files -v -d -ppw -nname -extra"
@REM set "v="  @REM undeclare
@REM set "d="
