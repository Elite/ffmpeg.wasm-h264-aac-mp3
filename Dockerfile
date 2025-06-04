# Base emsdk image with environment variables.
FROM emscripten/emsdk:3.1.40 AS emsdk-base
ARG EXTRA_CFLAGS
ARG EXTRA_LDFLAGS
ARG FFMPEG_ST
ARG FFMPEG_MT
ENV INSTALL_DIR=/opt
# We cannot upgrade to n6.0 as ffmpeg bin only supports multithread at the moment.
ENV FFMPEG_VERSION=n5.1.4
ENV CFLAGS="-I$INSTALL_DIR/include $CFLAGS $EXTRA_CFLAGS"
ENV CXXFLAGS="$CFLAGS"
ENV LDFLAGS="-L$INSTALL_DIR/lib $LDFLAGS $CFLAGS $EXTRA_LDFLAGS"
ENV EM_PKG_CONFIG_PATH=$EM_PKG_CONFIG_PATH:$INSTALL_DIR/lib/pkgconfig:/emsdk/upstream/emscripten/system/lib/pkgconfig
ENV EM_TOOLCHAIN_FILE=$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake
ENV PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$EM_PKG_CONFIG_PATH
ENV FFMPEG_ST=$FFMPEG_ST
ENV FFMPEG_MT=$FFMPEG_MT
RUN apt-get update && \
      apt-get install -y pkg-config autoconf automake libtool ragel

# Build x264 (for H264 support)
FROM emsdk-base AS x264-builder
ENV X264_BRANCH=4-cores
ADD https://github.com/ffmpegwasm/x264.git#$X264_BRANCH /src
COPY build/x264.sh /src/build.sh
RUN bash -x /src/build.sh

# Build lame (for MP3 encoding)
FROM emsdk-base AS lame-builder
ENV LAME_BRANCH=master
ADD https://github.com/ffmpegwasm/lame.git#$LAME_BRANCH /src
COPY build/lame.sh /src/build.sh
RUN bash -x /src/build.sh

# Base ffmpeg image with minimal dependencies and source code populated.
FROM emsdk-base AS ffmpeg-base
RUN embuilder build sdl2 sdl2-mt
ADD https://github.com/FFmpeg/FFmpeg.git#$FFMPEG_VERSION /src
COPY --from=x264-builder $INSTALL_DIR $INSTALL_DIR
COPY --from=lame-builder $INSTALL_DIR $INSTALL_DIR

# Build ffmpeg with minimal configuration
FROM ffmpeg-base AS ffmpeg-builder
COPY build/ffmpeg.sh /src/build.sh
RUN bash -x /src/build.sh \
      --enable-gpl \
      --disable-everything \
      --enable-avcodec \
      --enable-avformat \
      --enable-avutil \
      --enable-swresample \
      --enable-libx264 \
      --enable-libmp3lame \
      --enable-encoder=libx264 \
      --enable-encoder=libmp3lame \
      --enable-encoder=aac \
      --enable-decoder=h264 \
      --enable-decoder=aac \
      --enable-decoder=mp3 \
      --enable-demuxer=mpegts \
      --enable-demuxer=mov \
      --enable-muxer=mp4 \
      --enable-muxer=mp3 \
      --enable-parser=h264 \
      --enable-parser=aac \
      --enable-parser=mpegaudio \
      --enable-bsf=h264_mp4toannexb \
      --enable-bsf=aac_adtstoasc \
      --enable-protocol=file

# Build ffmpeg.wasm
FROM ffmpeg-builder AS ffmpeg-wasm-builder
COPY src/bind /src/src/bind
COPY src/fftools /src/src/fftools
COPY build/ffmpeg-wasm.sh build.sh
# libraries to link
RUN mkdir -p /src/dist/umd && bash -x /src/build.sh \
      -o dist/umd/ffmpeg-core.js
RUN mkdir -p /src/dist/esm && bash -x /src/build.sh \
      -sEXPORT_ES6 \
      -o dist/esm/ffmpeg-core.js

# Export ffmpeg-core.wasm to dist/, use `docker buildx build -o . .` to get assets
FROM scratch AS exportor
COPY --from=ffmpeg-wasm-builder /src/dist /dist
