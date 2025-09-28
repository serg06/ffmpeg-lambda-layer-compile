# Build FFmpeg 7 with static libmp3lame + static OpenSSL on Amazon Linux 2023
FROM amazonlinux:2023 AS build

ARG FFMPEG_VER=7.0.2
ARG LAME_VER=3.100
ARG OPENSSL_VER=3.3.1
ARG ZLIB_VER=1.3.1

# Build deps
RUN dnf -y update && dnf -y install --allowerasing \
    gcc gcc-c++ make autoconf automake libtool pkgconfig \
    yasm nasm git wget curl tar xz bzip2 which perl \
    # helpful but small
    ca-certificates && \
    dnf clean all

WORKDIR /opt/build
ENV PREFIX=/opt/ffbuild
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV PATH=$PREFIX/bin:$PATH
RUN mkdir -p $PREFIX

# -------- zlib (static) --------
RUN curl -L https://zlib.net/zlib-$ZLIB_VER.tar.xz | tar -xJ && \
    cd zlib-$ZLIB_VER && \
    ./configure --static --prefix=$PREFIX && \
    make -j$(nproc) && make install

# -------- OpenSSL (static) --------
RUN curl -L https://www.openssl.org/source/openssl-$OPENSSL_VER.tar.gz | tar -xz && \
    cd openssl-$OPENSSL_VER && \
    ./Configure no-shared linux-aarch64 --prefix=$PREFIX --libdir=lib && \
    make -j$(nproc) && make install_sw

# -------- LAME (static) --------
RUN curl -L https://downloads.sourceforge.net/project/lame/lame/$LAME_VER/lame-$LAME_VER.tar.gz | tar -xz && \
    cd lame-$LAME_VER && \
    ./configure --prefix=$PREFIX --enable-static --disable-shared --disable-decoder --disable-frontend && \
    make -j$(nproc) && make install

# -------- FFmpeg (mostly static, with static deps) --------
RUN curl -L https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VER.tar.xz | tar -xJ && \
    cd ffmpeg-$FFMPEG_VER && \
    PKG_CONFIG_PATH=$PKG_CONFIG_PATH \
    ./configure \
      --prefix=$PREFIX \
      --pkg-config-flags="--static" \
      --extra-cflags="-I$PREFIX/include" \
      --extra-ldflags="-L$PREFIX/lib" \
      --extra-libs="-lpthread -lm" \
      --enable-gpl --enable-version3 \
      --disable-debug --disable-doc --disable-ffplay \
      --enable-openssl \
      --enable-protocol=file,pipe,https,tls,crypto \
      --enable-libmp3lame \
      --enable-static --disable-shared \
      --enable-ffmpeg \
      --enable-avcodec --enable-avformat --enable-avutil --enable-swresample \
      --enable-decoder=pcm_s16le,pcm_s24le,mp3,aac,flac,alac,wavpack \
      --enable-encoder=libmp3lame,pcm_s16le \
      --enable-parser=mpegaudio,aac,flac \
      --enable-demuxer=wav,mp3,aac,flac,wv,matroska,mov \
      --enable-muxer=mp3,wav,adts,matroska \
      --enable-filter=aresample,aformat,anull,volume && \
    make -j$(nproc) && make install && \
    strip $PREFIX/bin/ffmpeg

# Final minimal image that just carries the artifact
FROM amazonlinux:2023 AS out
COPY --from=build /opt/ffbuild/bin/ffmpeg /usr/local/bin/ffmpeg
# Sanity: show it runs (comment out if you don't want a run at build time)
# RUN /usr/local/bin/ffmpeg -version
CMD ["/bin/bash"]