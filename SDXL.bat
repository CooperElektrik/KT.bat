@echo off
setlocal EnableDelayedExpansion
echo This script will now override some settings for SDXL training.

set sConvert=min_bk_res max_bk_res w_res h_res

for %%V in (!sConvert!) do (
    set value=!%%V!
    if !value! lss 1024 (
        echo [Warn] Value of !%%V! is less than 1024 (!value!^)
        set /a %%V=1024
    )
)

set v2="0"