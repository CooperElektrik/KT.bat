@echo off
setlocal EnableDelayedExpansion

echo LoRA Autotrainer Script, by CooperElektrik.
echo ---

set num=0
set numt=0
set numall=0
set img_exist=0

if not exist settings (
   echo Settings file not found.
   call settings.bat
) else (
   echo Reusing settings from existing file. A notepad instance is now open for you to check.
   start notepad settings
   pause
)

set "pathLocation=path"
if not exist %pathLocation% (
set /p "trainerPath=Enter Trainer Path: "
set /p "mainModelPath=Enter Main Model Path: "
set /p "loraInferPath=Enter LoRA Inference Path: "
( echo !trainerPath!& echo !mainModelPath!& echo !loraInferPath!) > %pathLocation%
)
rem Write the values of trainerPath and dataPath to path.txt


rem Read and echo line 1
set /a "lineNum=1"
for /f "usebackq tokens=*" %%A in ("%pathLocation%") do (
    if !lineNum! equ 1 (
        set trainerLocation=%%A
        echo Trainer Path is %%A
    )
    set /a "lineNum+=1"
)

rem Read and echo line 2
set /a "lineNum=1"
for /f "usebackq tokens=*" %%A in ("%pathLocation%") do (
    if !lineNum! equ 2 (
        set modelLocation=%%A
        echo Model Path is !modelLocation!
        if not exist !modelLocation! (
         echo But the model is nowhere to be found.
        )
        rem echo Line 2: %%A
    )
    set /a "lineNum+=1"
)

set /a "lineNum=1"
for /f "usebackq tokens=*" %%A in ("%pathLocation%") do (
    if !lineNum! equ 3 (
        set loraDirLocation=%%A
        echo LoRA Inference Path is %%A
    )
    set /a "lineNum+=1"
)

:name
set /p "name=Name of concept/folder: "
echo Received folder name of !name!
if "!name!"=="" (
   echo Name cannot be blank.
   goto name
)

rem Accept a full folder path as input
set folderPath=%~dp0
set folderPath=!folderPath!!name!

set "imagePathK=!folderPath!\image"
set "logPath=!folderPath!\log"
set "modelPath=!folderPath!\model"

:epoch
set /p "epoch=Epoch count: "
echo Epoch number is !epoch!
if "!epoch!"=="" (
   echo Epoch number cannot be zero.
   goto epoch
)
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

    set img_exist=1
    goto checker
)

rem Use a for loop to check for JPG or PNG files
for %%F in (*.jpg *.png *.jpeg) do (
    set "img_exist=1"
    goto checker
)
goto eof

:checker
if !img_exist!==1 (
    echo Detected an image file in directory.
    echo Moving now.

    for %%F in (*.png *.jpg *.jpeg) do (
        copy "%%F" "!name!\image\!epoch!_!name!\%%~nF%%~xF"
        set /a num+=1
    )

    for %%F in (*.txt *.caption) do (
        copy "%%F" "!name!\image\!epoch!_!name!\%%~nF%%~xF"
        set /a numt+=1
    )

    set /a "numall=num-numt"
    if numall lss 0 (
        set /a numall=-numall
    )

    echo Moved !num! image files to !name!\image\!epoch!_!name!.
    echo Total: !num! image files, !numt! caption/tag files.

    if !numt! neq 0 (
        if !num! neq !numt! (
            if !num! lss !numt! (
                echo Redundant caption/tag files detected: !numall! files
            ) else (
                echo There seems to be some untagged image files: !numall! files
            )
            set count=0
            set missing=0

            for %%F in (*.jpg *.png *.jpeg) do (
                set "baseName=%%~nF"
                set /a count+=1

                if not exist !baseName!.txt (
                    echo No corresponding .txt file found for "%%F"
                    set /a missing+=1
                )
            )

            echo Checked !count! files, !missing! missing pair.
            echo Checking complete. Removing files from directory.
        )
    )

    for %%F in (*.png *.jpg *.jpeg *.txt) do (
        del "%%F"
    )
)


rem Find a subfolder with the name structure NUMBER_NAME in the 'image' folder
set "imageFolder="
for /d %%I in ("!folderPath!\image\*_*") do (
    set "imageFolder=%%I"
)


set variables=nctpp bucket min_bk_res max_bk_res bk_step w_res h_res net_alpha net_dim rank_drop mod_drop net_drop tenc_lr unet_lr lr lr_sched lr_sched_cycle scale_w_norm train_batch data_worker token_length clip_skip snr_gamma

rem Read values from settings.txt and set the variables
for /f "usebackq tokens=1* delims==" %%A in ("settings") do (
    for %%V in (!variables!) do (
        if "%%A"=="%%V" (
            set "%%A=%%B"
        )
    )
)

rem Echo the values of the variables
echo Using settings from file.
for %%V in (!variables!) do (
    echo %%V: !%%V!
)

rem Export the paths into variables
set "imagePath=!imageFolder!"

echo Image Path: !imagePath!
echo Log Path: !logPath!
echo Model Path: !modelPath!
set /a step=(epoch * num) / train_batch
set /a dropOutInterval=epoch / 10
rem This part will recheck if the result is the same
set /a stepCheck1=step * train_batch
set /a stepCheck2=epoch * num

if !stepCheck1! neq !stepCheck2! (
   if !stepCheck1! lss !stepCheck2! (
      echo Lost some precision during division.
      set /a step+=1
   ) else (
      echo What the hell happend?
      set /a step-=1
   )
) else (
   echo All numbers correct.
)

echo Step count: !step!
echo Dropout interval: !dropOutInterval!

echo Will start trainer after this part. If you don't want to, press CTRL+C.
pause

rem Set the target directory and script filename
set "targetDirectory=!trainerLocation!"
set "scriptFilename=start-train.bat"
echo Moving to !targetDirectory!
rem Extract the first 2 characters
set "driveLocation=!targetDirectory:~0,2!"
echo Automatically determined drive location: !driveLocation!
!driveLocation!
cd !targetDirectory!
call .\venv\Scripts\activate.bat
if exist %scriptFilename% (
   echo Found existing %scriptFilename% script, removing it now.
   del %scriptFilename%
)

echo accelerate launch --num_cpu_threads_per_process=!nctpp! "./train_network.py" --pretrained_model_name_or_path="!modelLocation!" --train_data_dir="!imagePathK!" --resolution="!w_res!,!h_res!" --output_dir="!modelPath!" --logging_dir="!logPath!" --network_alpha="!net_alpha!" --save_model_as=safetensors --network_module=networks.lora --network_args rank_dropout="!rank_drop!" module_dropout="!mod_drop!" --text_encoder_lr=!tenc_lr! --unet_lr=!unet_lr! --network_dim=!net_dim! --output_name="!name!" --lr_scheduler_num_cycles="!lr_sched_cycle!" --scale_weight_norms="!scale_w_norm!" --network_dropout="!net_drop!" --no_half_vae --learning_rate="!lr!" --lr_scheduler="!lr_sched!" --train_batch_size="!train_batch!" --max_train_steps="!step!" --save_every_n_epochs="1" --mixed_precision="bf16" --save_precision="bf16" --seed="1234" --caption_extension=".txt" --cache_latents --optimizer_type="AdamW8bit" --max_data_loader_n_workers="!data_worker!" --max_token_length=!token_length! --clip_skip=!clip_skip! --caption_dropout_every_n_epochs="!dropOutInterval!" --caption_dropout_rate="0.05" --bucket_reso_steps=!bk_step! --min_snr_gamma=!snr_gamma! --shuffle_caption --gradient_checkpointing --xformers --persistent_data_loader_workers --noise_offset=0.0 > temp
rem SD 2.X training
if "%v2%"=="1" (
    if "%v_parameter%"=="1" (
    echo --v2 --v_parameterization >> temp
    ) else (
        echo --v2 >> temp
    )
)
rem Bucketing
if "%bucket%"=="1" (
    echo --enable_bucket --min_bucket_reso=!min_bk_res! --max_bucket_reso=!max_bk_res! --bucket_no_upscale >> temp
)

for /f "usebackq delims=" %%A in ("temp") do (
    set "scriptContent=!scriptContent!%%A"
)

rem Create the batch script in the target directory
echo "!targetDirectory!\!scriptFilename!"
echo !scriptContent! > "!targetDirectory!\!scriptFilename!"

echo Batch script '!scriptFilename!' created in '!targetDirectory!'.
echo Will now wait for 20 seconds. If you want to exit, please do now. If not, get a drink or something.
timeout /t 20
call %scriptFilename%

rem Move LoRA to your specified WebUI directory
echo Copying to your LoRA inference path.
copy "%modelPath%\%name%.safetensors" "%loraDirLocation%"
rem Removing temp
del temp
pause

:eof
endlocal