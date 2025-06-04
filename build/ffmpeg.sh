set -euo pipefail

CONF_FLAGS=(
  --disable-everything          # disable all features first
  
  # Core libraries needed
  --enable-avcodec
  --enable-avformat
  --enable-avutil
  --enable-swresample
  
  # External libraries
  --enable-gpl                  # enable GPL libraries
  --enable-libx264              # enable x264 for H264 encoding
  --enable-libmp3lame           # enable lame for MP3 encoding
  
  # Encoders
  --enable-encoder=libx264      # H264 encoder
  --enable-encoder=libmp3lame   # MP3 encoder  
  --enable-encoder=aac          # native AAC encoder
  
  # Decoders
  --enable-decoder=h264         # H264 decoder
  --enable-decoder=aac          # AAC decoder
  --enable-decoder=mp3          # MP3 decoder
  
  # Demuxers (input formats)
  --enable-demuxer=mpegts       # MPEGTS demuxer
  --enable-demuxer=mov          # MOV/MP4 demuxer
  
  # Muxers (output formats)
  --enable-muxer=mp4            # MP4 muxer
  --enable-muxer=mp3            # MP3 muxer
  
  # Parsers
  --enable-parser=h264          # H264 parser
  --enable-parser=aac           # AAC parser
  --enable-parser=mpegaudio     # MP3 parser
  
  # Bitstream filters for format conversion
  --enable-bsf=h264_mp4toannexb # H264 format conversion
  --enable-bsf=aac_adtstoasc    # AAC format conversion
  
  # Protocol
  --enable-protocol=file        # file I/O protocol

  --target-os=none              # disable target specific configs
  --arch=x86_32                 # use x86_32 arch
  --enable-cross-compile        # use cross compile configs
  --disable-asm                 # disable asm
  --disable-stripping           # disable stripping as it won't work
  --disable-programs            # disable ffmpeg, ffprobe and ffplay build
  --disable-doc                 # disable doc build
  --disable-debug               # disable debug mode
  --disable-runtime-cpudetect   # disable cpu detection
  --disable-autodetect          # disable env auto detect

  # assign toolchains and extra flags
  --nm=emnm
  --ar=emar
  --ranlib=emranlib
  --cc=emcc
  --cxx=em++
  --objcc=emcc
  --dep-cc=emcc

  # disable thread when FFMPEG_ST is NOT defined
  ${FFMPEG_ST:+ --disable-pthreads --disable-w32threads --disable-os2threads}
)


emconfigure ./configure "${CONF_FLAGS[@]}" $@
emmake make -j
