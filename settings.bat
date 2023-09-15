@echo off
setlocal enabledelayedexpansion

rem Remove existing settings.
echo nctpp - CPU Threads Per Process. Recommended: 2
echo bucket - Enable buckets. Set 0 if not using.
echo min_bk_res - Minimum Bucket Resolution. Recommended: 384 or higher
echo max_bk_res - Maximum Bucket Resolution. Recommended: 768 or higher
echo bk_step - Bucket Resolution Step. Recommended: 128
echo w_res - Resolution (width). Recommended: 768
echo h_res - Resolution (height). Recommended: 768
echo net_alpha - Network Alpha. Recommended: 2X or equal to Network Dim
echo net_dim - Network Dim. Recommended: Half or equal to Network Alpha
echo rank_drop - Rank Dropout. Recommended: 0.15
echo mod_drop - Module Dropout. Recommended: 0.1
echo net_drop - Network Dropout. Recommended: 0.15
echo tenc_lr - Text Encoder Learning Rate. Recommended: 5e-05
echo unet_lr - UNet Learning Rate. Recommended: 1e-04
echo lr - Learning Rate. Recommended: 5e-05
echo lr_sched - Learning Rate Scheduler. Available values: constant, linear
echo lr_sched_cycle - Learning Rate Scheduler Cycle. Set to higher than 1 for cosine with restarts and polynomial.
echo scale_w_norm - Scale Weight Norm. Recommended: 1.2
echo train_batch - Training Batch Size. Set this to according to VRAM size.
echo data_worker - Data Loader Workers. Must be 1 or higher.
echo token_length - Token Length. Available values: 75, 150, 225
echo clip_skip - Clip Skip. Should be 2 for NAI
echo snr_gamma - SNR Gamma. Set this to 5 or 0.
echo mixed_precision - Mixed-precision training. Accepts these values: bf16 , fp16 , no
echo save_precision - Save model at this precision. Accepts these values: bf16 , fp16 , float
echo v2 - Stable Diffusion 2.X Training. Set to 0 if you're training for SD 1.5 or SDXL.
echo v_parameter - V Parameterization for SD 2.X. Set to 1 if you're using it, otherwise leave blank.
echo sdxl - Stable Diffusion XL Training. This will override some settings.

set nVariables=nctpp bucket min_bk_res max_bk_res bk_step w_res h_res net_alpha net_dim lr_sched_cycle scale_w_norm train_batch data_worker token_length clip_skip snr_gamma v2 v_parameter sdxl
set sVariables=rank_drop mod_drop net_drop tenc_lr unet_lr lr lr_sched mixed_precision save_precision

rem Initialize the settings file
echo. > settings

rem Loop through each variable and prompt the user for its value
for %%V in (!nVariables!) do (
    set /p "%%V=Enter integer value for %%V: "
    set /a %%V=!%%V!
    echo %%V=!%%V!>> settings
)
for %%V in (!sVariables!) do (
    set /p "%%V=Enter string or non-integer value for %%V: "
    echo %%V=!%%V!>> settings
)
cls
rem Notify the user that the settings have been saved
echo Settings saved.
endlocal
