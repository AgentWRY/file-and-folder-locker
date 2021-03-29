:: Hide and Lock Files and Folders on Windows PC
::
:: hss@hss.wiki
::
:: Hiding files and folders in the same folder with this script by setting
:: their System and Hidden attributes. Those "secret files" (and folders)
:: cannot be easily shown in file explorer or by using `dir` in CMD.
::
:: Basic usage: Put this BAT file into the folder that you want to hide its
:: files and subfolders. Double click the script to hide the files. Refresh if
:: needed to see the effect. To reveal those files and folders, simply double
:: click the script again. Or, without risking to reveal the folder, you can
:: directly access the secret folder by typing its address in Win+R, or use
:: `explorer <folder_address>` command in CMD.
::
:: Intermediate usage: Set a passphrase under the "Config" section of this
:: script, and it will be asked before revealing any secret files. The files
:: can be hidden same as above.
::
:: Advanced usage: Set an EXE password under the "Config" section, and the
:: script will be locked into a self-extracting EXE after hiding files and
:: folders. To reveal the files, first, double click the EXE and enter the
:: password to release the BAT script. Then, double click the script to reveal
:: secret files. See the "Config" section for details.
::
:: The installation of [7-Zip](https://www.7-zip.org/) (about 1.4 MB) is
:: required if want to adopt the advanced usage. While script passphrase, EXE
:: filename, and password should work well with whitespaces, we advise you not
:: to, since they haven't been thoroughly tested. All of them are case
:: sensitive, but none of them supports special characters yet.

:: ############################################################################
::   Program logic
:: ############################################################################
::
:: If the current folder contains any visible files/subfolders:
::     Hide them all as secret files/folders. Note that this script will not be
::     hidden.
::
::     If `exe_password` is configured:
::         Lock this script into an EXE file encrypted with the given password.
::
::         If `exe_filename_w_extension` is configured:
::             Name the EXE file as given.
::
:: Else:
::     Reveal all secret files/folders in the current folder. Also, remove the
::     EXE where this script extracts from if possible.
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

set "exe_filename_w_extension=.toggle_secret_files.exe"

:: By default, the EXE file is named as `.toggle_secret_files.exe`. Note that
:: only when `exe_password` is defined, the BAT script will be locked into an
:: encrypted EXE named as above, after hiding secret files. Setting only the
:: EXE filename without password will not encrypt the BAT into EXE.

:: ============================================================================
::   Toggle verbose mode
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
:: - Lock the script into an encrypted EXE if required
:: - End

:: ============================================================================
::   Validate configs
:: ============================================================================

if defined v (
    if not defined exe_password (
        echo Script will not be encrypted since EXE password is not defined.
    ) else (
        echo EXE password: `%exe_password%`.
        echo EXE filename: `%exe_filename_w_extension%`.
    )
    echo.
)
:: `echo:` or `echo.` to echo a blank line.

:: Remove residual EXE file if possible. It may exist after self-extracting
:: to get this script.

del "%exe_filename_w_extension%" 2> nul

:: ============================================================================
::   Catalog current files and folders
:: ============================================================================

:: Save names of files/folders under current directory as indexed variables.
:: Ref: https://stackoverflow.com/a/19542051

setlocal enableDelayedExpansion
set "script_filename_w_extension=%~nx0"
:: `%~n0` stores current file name, x for extension.
:: Ref: https://stackoverflow.com/a/15568171. Substitute 1 with 0.

:: Catalog secret files and folders
set /a counter = 0
set /a n_secret_files = 0
:: `/a` for numeric.

for /f "tokens=1* delims=:" %%a in ('dir /ahs /b 2^>nul ^|findstr /n "^"') do (
    if not "%%b" == "%script_filename_w_extension%" (
        set /a counter += 1
        set "secret_file_number_!counter!=%%b"
        set "n_secret_files=!counter!"
    )
)
:: `%%a` and `%%b` are local iterator vars.

:: Excluding this script since we don't want to hide it. Uses double quotes
:: since filename can contain whitespaces.

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
    if not "%%b" == "%script_filename_w_extension%" (
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

if %n_files% == 0 (
    echo INFO: Current directory is empty.
    echo.
    goto terminate_and_display_error_message
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

    if defined script_passphrase (
        if defined v (
            echo Script passphrase required.
            echo.
        )
        :require_passphrase_to_reveal_files
        echo Enter passphrase to reveal secret files and folders:
        set /p "user_input_passphrase=>"
        @REM `>` will show in the console.
        if "!user_input_passphrase!" == "%script_passphrase%" (
            @REM Double-quote in case passphrase contains whitespaces.
            @REM Note the use of delayed expansion here. Otherwise it won't
            @REM work in the first iteration even if the passphrase is correct.
            if defined v echo Passphrase match.
            goto reveal_secret_files
        ) else (
            echo Passphrase does not match.
            goto require_passphrase_to_reveal_files
        )
    ) else (
        if defined v (
            echo Script passphrase disabled.
            echo.
        )
        goto reveal_secret_files
    )
)

:hide_all_files
for /l %%n in (1 1 %n_files%) do (
    attrib "!file_number_%%n!" +h +s
    @REM Note the double quotes in case filename contains whitespaces.
    if defined v echo Hid `!file_number_%%n!`.
)
if defined v (
    echo Successfully hid all %n_files% files and folders.
    echo.
)
goto self_encrypt_and_archive

:reveal_secret_files
for /l %%n in (1 1 %n_secret_files%) do (
    attrib "!secret_file_number_%%n!" -h -s
    if defined v echo Revealed `!secret_file_number_%%n!`.
)
if defined v (
    echo Successfully revealed all %n_secret_files% secret files and folders.
    echo.
)
goto end

:: ============================================================================
::   If applicable, self encrypt and archive after hiding secret files/folders
:: ============================================================================

:self_encrypt_and_archive
if defined exe_password (
    7z a -p"%exe_password%" -sdel -mhe=on ^
-sfx "%exe_filename_w_extension%" "%script_filename_w_extension%" > nul

    if defined v (
        echo Successfully locked the script into `%exe_filename_w_extension%` ^
with password `%exe_password%`.
        echo.
    )
)
:: `-sdel` to Self DELete files after archiving, `-sfx` to create a Self
:: EXtractable archive, `-mhe=on` to also encrypt archive HEaders (only works
:: for the 7z format, just leave it here for reference).

:: ============================================================================
::   End
:: ============================================================================

goto end
:terminate_and_display_error_message
cmd /k

:end

if defined v (
    cmd /k
)
:: Keep the CMD window open if verbose.

:: ############################################################################
::   Coding notes
:: ############################################################################

:: TODO:
::
:: - Move to PowerShell or Python, whichever works better with Mac.
:: - Set exe_filename_w_extension to be the same with BAT filename as default
:: - Error handling. Keep the window open for error message.
:: - Check if 7z is available from the command line. Catch errors.
:: - Support space and special chars in exe password, filename, passphrase.
:: - Disguise folder with Control Panel GUIDs?
::   - List of GUIDs:
::     https://docs.microsoft.com/en-us/windows/win32/shell/controlpanel-canonical-names
::   - To avoid showing file and folder names in CMD, recursively rename them
::     as GUIDs and encrypt the look-up table with 7z. When unhid, change back
::     file and folder names.
::   - All Control Panel tools: {ED7BA470-8E54-465E-825C-99712043E01C}

:: ============================================================================
::   Knowledge
:: ============================================================================

:: `^` for line continuation.
:: `:label` for goto statements to jump to.

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
