for i in *.wav; do ffmpeg -y -i $i -ar 5512 -f u8 -acodec pcm_u8 $(basename $i .wav).pcm; done
