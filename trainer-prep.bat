@echo off
setlocal EnableDelayedExpansion

set num=0
set numt=0
set numall=0
set img-exist=0

set "pathLocation=path"
if not exist %pathLocation% (
set /p "trainerPath=Enter Trainer Path: "
set /p "mainModelPath=Enter Main Model Path: "
( echo !trainerPath!& echo !mainModelPath!) > %pathLocation%
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

:name
set /p "name=Name of concept/folder: "
echo Received folder name of !name!
if "!name!"=="" (
   echo Name cannot be blank.
   goto name
)

:epoch
set /p "epoch=Epoch count: "
echo Epoch number is !epoch!
if "!epoch!"=="" (
   echo Epoch number cannot be zero.
   goto epoch
)

if exist "!name!" (
   echo A directory with the same name is found. Exiting...
   goto eof
) else (
   echo Creating a directory with name !name!
   mkdir !name!\image\!epoch!_!name!
   mkdir !name!\model
   mkdir !name!\log
   echo Done.
)

rem Use a for loop to check for JPG or PNG files
for %%F in (*.jpg *.png *.jpeg) do (
    set "img-exist=1"
    goto checker
)
goto eof

:checker
if !img-exist!==1 (
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

rem Accept a full folder path as input
set folderPath=%~dp0
set folderPath=!folderPath!!name!

rem Find a subfolder with the name structure NUMBER_NAME in the 'image' folder
set "imageFolder="
for /d %%I in ("!folderPath!\image\*_*") do (
    set "imageFolder=%%I"
)

rem Export the paths into variables
set "imagePath=!imageFolder!"
set "imagePathK=!folderPath!\image"
set "logPath=!folderPath!\log"
set "modelPath=!folderPath!\model"

echo Image Path: !imagePath!
echo Log Path: !logPath!
echo Model Path: !modelPath!
set /a step=(epoch * num) / 4
set /a dropOutInterval=epoch / 10
rem This part will recheck if the result is the same
set /a stepCheck1=step * 4
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

set launchCommand=accelerate launch --num_cpu_threads_per_process=2 "./train_network.py" --enable_bucket --min_bucket_reso=384 --max_bucket_reso=1280 --pretrained_model_name_or_path="!modelLocation!" --train_data_dir="!imagePathK!" --resolution="960,960" --output_dir="!modelPath!" --logging_dir="!logPath!" --network_alpha="128" --save_model_as=safetensors --network_module=networks.lora --network_args rank_dropout="0.15" module_dropout="0.1" --text_encoder_lr=5e-05 --unet_lr=0.0001 --network_dim=64 --output_name="!name!" --lr_scheduler_num_cycles="1" --scale_weight_norms="1.2" --network_dropout="0.15" --no_half_vae --learning_rate="5e-05" --lr_scheduler="constant" --train_batch_size="4" --max_train_steps="!step!" --save_every_n_epochs="1" --mixed_precision="bf16" --save_precision="bf16" --seed="1234" --caption_extension=".txt" --cache_latents --optimizer_type="AdamW8bit" --max_data_loader_n_workers="1" --max_token_length=225 --clip_skip=2 --caption_dropout_every_n_epochs="!dropOutInterval!" --caption_dropout_rate="0.05" --bucket_reso_steps=128 --min_snr_gamma=5 --shuffle_caption --gradient_checkpointing --xformers --persistent_data_loader_workers --bucket_no_upscale --noise_offset=0.0

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
rem Create the script content
set "scriptContent=!launchCommand!"

rem Create the batch script in the target directory
echo "!targetDirectory!\!scriptFilename!"
echo %scriptContent% > "!targetDirectory!\!scriptFilename!"

echo Batch script '!scriptFilename!' created in '!targetDirectory!'.
echo Will now wait for 20 seconds. If you want to exit, please do now. If not, get a drink or something.
timeout /t 20
call %scriptFilename%

pause

:eof
endlocal