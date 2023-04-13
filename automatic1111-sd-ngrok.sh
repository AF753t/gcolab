#!/bin/bash

SD=`realpath stable-diffusion-webui`
TMPDIR=${TMPDIR:-/tmp}

git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui "$SD"

mkdir -p \
  "$SD/extensions" \
  "$SD/embeddings" \
  "$SD/models/Stable-diffusion" \
  "$SD/models/Lora"

#rm -f -r "$SD/models/VAE-approx"

## Extensions
(cd "$SD/extensions"
git clone https://github.com/Iyashinouta/sd-model-downloader
#git clone https://github.com/camenduru/sd-civitai-browser
git clone https://github.com/kohya-ss/sd-webui-additional-networks
git clone https://github.com/hnmr293/posex sd-posex
git clone https://github.com/hnmr293/sd-webui-llul
git clone https://github.com/pharmapsychotic/clip-interrogator-ext
git clone https://github.com/pkuliyi2015/multidiffusion-upscaler-for-automatic1111
#git clone https://github.com/space-nuko/a1111-stable-diffusion-webui-vram-estimator
)
echo

download_model()
{
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
	[ -d "$SD/models/$1" ] || mkdir -p "$SD/models/$1"
	echo "=============================== Download information ==============================="
	echo "FILE: $filename"
	echo "SIZE: $size$suffix"
	if [ "$1" = "embeddings" ]
	then
		curl "$2" -L -k -o "$SD/$1/$filename" '-#' --retry 3
	else
		curl "$2" -L -k -o "$SD/models/$1/$filename" '-#' --retry 3
	fi
	echo
}

install_model=false
eval "SD_DRIVE_MODELS=$SD_DRIVE_MODELS"
eval "SD_DRIVE_OUTPUTS=$SD_DRIVE_OUTPUTS"
for x in "$SD/models"/* "$SD/embeddings"
do
	if [ ! -e "$SD_DRIVE_MODELS/${x##*/}" ]
	then
		mkdir -p "$SD_DRIVE_MODELS/${x##*/}"
		install_model=true
	fi
	mountpoint -q "$x" || mount -o rw,bind "$SD_DRIVE_MODELS/${x##*/}" "$x"
done
mkdir -p "$SD/outputs" "$SD_DRIVE_OUTPUTS"
mountpoint -q "$SD/outputs" || mount -o rw,bind "$SD_DRIVE_OUTPUTS" "$SD/outputs"

if $install_model
then
	## CHECKPOINT - ChilloutMix
	download_model Stable-diffusion https://huggingface.co/SakerLy/chilloutmix_NiPrunedFp32Fix/resolve/main/chilloutmix_NiPrunedFp32Fix.safetensors

	## CHECKPOINT - SunshineMix
	#download_model Stable-diffusion https://civitai.com/api/download/models/13510

	## LORA - Yae Miko Realistic (Mixed)
	#download_model Lora https://civitai.com/api/download/models/11523

	## CHECKPOINT - FacebombMix
	#download_model Stable-diffusion https://civitai.com/api/download/models/25993

	## CHECKPOINT - MeinaMix
	download_model Stable-diffusion https://huggingface.co/sakistriker/MeinaMix_V8/resolve/main/meinamix_meinaV8.safetensors

	## LORA - KoreanDoll v20
	download_model Lora https://civitai.com/api/download/models/31284

	## CHECKPOINT - Perfect World
	download_model Stable-diffusion https://huggingface.co/Juggernaut259/Perfect-World/resolve/main/perfectWorld_v2Baked.safetensors

	## TEXTUAL INVERSION - Ulzzang-6500 (Korean doll aesthetic)
	download_model embeddings https://civitai.com/api/download/models/10107

	## LORA - KoreanDoll v15
	download_model Lora https://civitai.com/api/download/models/29136

	## LORA - KoreanDoll v10
	download_model Lora https://civitai.com/api/download/models/22968

	## LORA - JapaneseDollLikeness v15
	download_model Lora https://civitai.com/api/download/models/34562

	## CHECKPOINT - RealDosMix
	download_model Stable-diffusion https://huggingface.co/mlida/RealDosMix/resolve/main/realdosmix_.safetensors
fi

cat > start.sh << EOF
#!/bin/sh

cd /tmp

pkill -9 ngrok
curl -s 'https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz' | tar -xzf-
echo "You can register or get and copy the authtoken from https://dashboard.ngrok.com/auth and paste it into following cell"
echo -n "Enter the ngrok authtoken: "

read token
chmod +x ngrok && ./ngrok authtoken "\$token" && (./ngrok http 7860 --region ap &)
sleep 1
echo
sleep 1
echo
sleep 1
echo "Click the link below if WebUI is really installed and running!"
echo "The sign is the appearance of the text "Running on local URL: http://0.0.0.0:7860", usually something like that"
curl -s 127.0.0.1:4040/api/tunnels | python3 -c "import sys, json; print(json.load(sys.stdin)['tunnels'][0]['public_url'])" | sed 's/^tcp:/http:/'

echo
echo
cd "$SD"
exec python3 launch.py --listen --theme dark
EOF

chmod +x start.sh
echo "The installation is complete, run './start.sh' to start."
