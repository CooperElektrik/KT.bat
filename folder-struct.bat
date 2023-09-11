rem Accept a full folder path as input
set folderPath=%~dp0
set folderPath=!folderPath!!name!

set "imagePathK=!folderPath!\image"
set "logPath=!folderPath!\log"
set "modelPath=!folderPath!\model"
if not exist "!name!" (
    echo Creating a directory with name !name!
    mkdir !name!\image\!epoch!_!name!
    mkdir !name!\model
    mkdir !name!\log
    echo Done.
) else (
    echo A directory with the name "!name!" already exists. Reusing it.

    rem Rename directory using the move command.
    move "%name%\image\*_*" "%name%\image\%epoch%_%name%"

    if not exist "%modelPath%\old\" (
        mkdir "%modelPath%\old\"
    )
 
    for %%F in ("%modelPath%\*.safetensors") do (
        move "%%F" "%modelPath%\old\"
        echo %%F
    )
)
for %%V in (!fStructVariables!) do (
    echo %%V=!%%V!>> fStructPaths
)