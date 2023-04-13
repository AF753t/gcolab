#!/bin/bash

eval "SD=$SD"
eval "DRIVE=$DRIVE"

add_ext()
{
	if [ "$2" ]
	then
		[ -d "$SD/extensions/${2##*/}" ] && return
		git clone "$1" "$SD/extensions/${2##*/}"
	else
		local dir
		dir=${1##*/}
		dir=${dir%.git*}
		[ -d "$SD/extensions/$dir" ] && return
		git clone "$1" "$SD/extensions/$dir"
	fi
}

add_model()
{
	# Huggingface - Civitai url support
	local filename size suffix=B
	eval "$(curl -s --head -L -X GET "$2"|grep -E -io 'filename=.*'|sed 's/;.*//g')"
	size=`curl -s --head -L -X GET "$2"|grep -i content-length|awk '{print $2}'`
	filename=${filename//$'\r'}
	size=${size//$'\r'}
	[ "$(tail -n +2 <<< "$size")" ] && size=`tail -n +2 <<< "$size"`
	if ((size >= 1024))
	then
		suffix=KiB
		size=$((size/1024))
	fi
	if ((size >= 1024))
	then
		suffix=MiB
		size=$((size/1024))
	fi
	if ((size >= 1024))
	then
		suffix=GiB
		size=$((size/1024))
	fi
	echo "=============== Download Info ==============="
	echo "File: $filename"
	echo "Size: $size$suffix"
	if [ "$1" = "embeddings" ]
	then
		[ -d "$SD/embeddings" ] || mkdir -p "$SD/embeddings"
		curl --location --retry 3 --insecure "$2" --output "$SD/embeddings/$filename"
	else
		[ -d "$SD/models/$1" ] || mkdir -p "$SD/models/$1"
		curl --location --retry 3 --insecure "$2" --output "$SD/models/$1/$filename"
	fi
	echo
}

install_model=true

pip install -q torch==1.13.1+cu116 torchvision==0.14.1+cu116 torchaudio==0.13.1 torchtext==0.14.1 torchdata==0.5.1 --extra-index-url https://download.pytorch.org/whl/cu116 -U
pip install -q xformers==0.0.16 triton==2.0.0 -U

## base
git clone -b v2.1 https://github.com/camenduru/stable-diffusion-webui "$SD"

mydrive_sd="$DRIVE/MyDrive/Stable Diffusion"
mkdir -p "$mydrive_sd/"{models,outputs} "$SD/"{models,outputs}
mountpoint -q "$SD/models" || mount -o rw,bind "$mydrive_sd/models" "$SD/models"
mountpoint -q "$SD/outputs" || mount -o rw,bind "$mydrive_sd/outputs" "$SD/outputs"
[ -e "$mydrive_sd/models/Stable-diffusion" ] && install_model=false

git clone https://huggingface.co/embed/negative "$SD/embeddings/negative"
git clone https://huggingface.co/embed/lora "$SD/models/Lora/positive"
curl https://raw.githubusercontent.com/camenduru/stable-diffusion-webui-scripts/main/run_n_times.py -L -k -o "$SD/scripts/run_n_times.py"

add_ext https://github.com/deforum-art/deforum-for-automatic1111-webui
add_ext https://github.com/camenduru/stable-diffusion-webui-images-browser
add_ext https://github.com/camenduru/stable-diffusion-webui-huggingface
add_ext https://github.com/Iyashinouta/sd-model-downloader
add_ext https://github.com/kohya-ss/sd-webui-additional-networks
add_ext https://github.com/Mikubill/sd-webui-controlnet
add_ext https://github.com/camenduru/openpose-editor
add_ext https://github.com/jexom/sd-webui-depth-lib
add_ext https://github.com/DominikDoom/a1111-sd-webui-tagcomplete
add_ext https://github.com/hnmr293/posex
add_ext https://github.com/dbolya/tomesd
add_ext https://github.com/camenduru/sd-webui-tunnels
add_ext https://github.com/etherealxx/batchlinks-webui
add_ext https://github.com/camenduru/stable-diffusion-webui-catppuccin
add_ext https://github.com/KohakuBlueleaf/a1111-sd-webui-locon
add_ext https://github.com/AUTOMATIC1111/stable-diffusion-webui-rembg
add_ext https://github.com/ashen-sensored/stable-diffusion-webui-two-shot

if $install_model
then
	#instal-Controlnet
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/control_canny-fp16.safetensors -d "$SD/extensions/sd-webui-controlnet/models" -o control_canny-fp16.safetensors
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/control_depth-fp16.safetensors -d "$SD/extensions/sd-webui-controlnet/models" -o control_depth-fp16.safetensors
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/control_hed-fp16.safetensors -d "$SD/extensions/sd-webui-controlnet/models" -o control_hed-fp16.safetensors
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/control_mlsd-fp16.safetensors -d "$SD/extensions/sd-webui-controlnet/models" -o control_mlsd-fp16.safetensors
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/control_normal-fp16.safetensors -d "$SD/extensions/sd-webui-controlnet/models" -o control_normal-fp16.safetensors
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/control_openpose-fp16.safetensors -d "$SD/extensions/sd-webui-controlnet/models" -o control_openpose-fp16.safetensors
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/control_scribble-fp16.safetensors -d "$SD/extensions/sd-webui-controlnet/models" -o control_scribble-fp16.safetensors
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/control_seg-fp16.safetensors -d "$SD/extensions/sd-webui-controlnet/models" -o control_seg-fp16.safetensors
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/hand_pose_model.pth -d "$SD/extensions/sd-webui-controlnet/annotator/openpose" -o hand_pose_model.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/body_pose_model.pth -d "$SD/extensions/sd-webui-controlnet/annotator/openpose" -o body_pose_model.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/dpt_hybrid-midas-501f0c75.pt -d "$SD/extensions/sd-webui-controlnet/annotator/midas" -o dpt_hybrid-midas-501f0c75.pt
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/mlsd_large_512_fp32.pth -d "$SD/extensions/sd-webui-controlnet/annotator/mlsd" -o mlsd_large_512_fp32.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/mlsd_tiny_512_fp32.pth -d "$SD/extensions/sd-webui-controlnet/annotator/mlsd" -o mlsd_tiny_512_fp32.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/network-bsds500.pth -d "$SD/extensions/sd-webui-controlnet/annotator/hed" -o network-bsds500.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/upernet_global_small.pth -d "$SD/extensions/sd-webui-controlnet/annotator/uniformer" -o upernet_global_small.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/t2iadapter_style_sd14v1.pth -d "$SD/extensions/sd-webui-controlnet/models" -o t2iadapter_style_sd14v1.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/t2iadapter_sketch_sd14v1.pth -d "$SD/extensions/sd-webui-controlnet/models" -o t2iadapter_sketch_sd14v1.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/t2iadapter_seg_sd14v1.pth -d "$SD/extensions/sd-webui-controlnet/models" -o t2iadapter_seg_sd14v1.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/t2iadapter_openpose_sd14v1.pth -d "$SD/extensions/sd-webui-controlnet/models" -o t2iadapter_openpose_sd14v1.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/t2iadapter_keypose_sd14v1.pth -d "$SD/extensions/sd-webui-controlnet/models" -o t2iadapter_keypose_sd14v1.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/t2iadapter_depth_sd14v1.pth -d "$SD/extensions/sd-webui-controlnet/models" -o t2iadapter_depth_sd14v1.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/t2iadapter_color_sd14v1.pth -d "$SD/extensions/sd-webui-controlnet/models" -o t2iadapter_color_sd14v1.pth
	aria2c --console-log-level=error -c -x 16 -s 16 -k 1M https://huggingface.co/ckpt/ControlNet/resolve/main/t2iadapter_canny_sd14v1.pth -d "$SD/extensions/sd-webui-controlnet/models" -o t2iadapter_canny_sd14v1.pth

	## CHECKPOINT - RealDosMix
	add_model Stable-diffusion https://huggingface.co/vorstcavry/realdosmix/resolve/main/realdosmix_.safetensors

	## CHECKPOINT - ChilloutMix
	add_model Stable-diffusion https://huggingface.co/ckpt/chilloutmix/resolve/main/chilloutmix_NiPrunedFp32Fix.safetensors

	## VAE
	add_model VAE https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.ckpt
	add_model VAE https://huggingface.co/vorstcavry/vaecollection/resolve/main/clearvae_main.safetensors

	## LORA - KoreanDoll v20
	add_model Lora https://civitai.com/api/download/models/31284

	## CHECKPOINT - Perfect World
	add_model Stable-diffusion https://huggingface.co/Juggernaut259/Perfect-World/resolve/main/perfectWorld_v2Baked.safetensors

	## TEXTUAL INVERSION - Ulzzang-6500 (Korean doll aesthetic)
	add_model embeddings https://civitai.com/api/download/models/10107

	## LORA - KoreanDoll v15
	add_model Lora https://civitai.com/api/download/models/29136

	## LORA - KoreanDoll v10
	add_model Lora https://civitai.com/api/download/models/22968

	## LORA - JapaneseDollLikeness v15
	add_model Lora https://civitai.com/api/download/models/34562

	## ESRGAN - 4x
	add_model ESRGAN https://huggingface.co/embed/upscale/resolve/main/4x-UltraSharp.pth
fi

sed -i -e '''/    prepare_environment()/a\    os.system\(f\"""sed -i -e ''\"s/dict()))/dict())).cuda()/g\"'' "$SD/repositories/stable-diffusion-stability-ai/ldm/util.py""")''' "$SD/launch.py"
sed -i -e 's/fastapi==0.90.1/fastapi==0.89.1/g' "$SD/requirements_versions.txt"

sed -i -e 's/\"sd_model_checkpoint\"\,/\"sd_model_checkpoint\,sd_vae\,CLIP_stop_at_last_layers\"\,/g' "$SD/modules/shared.py"

cat > "start.sh" << EOF
#!/bin/sh

cd "$SD"
python launch.py --listen --xformers --enable-insecure-extension-access --theme dark --gradio-queue --multiple
EOF

chmod +x start.sh
