# Build FFmpeg 7 with static libmp3lame + static OpenSSL on Amazon Linux 2023
FROM amazonlinux:2023 AS build

ARG FFMPEG_VER=7.0.2
ARG LAME_VER=3.100
ARG OPENSSL_VER=3.3.1
ARG ZLIB_VER=1.3.1

# Install build dependencies
RUN dnf -y update
RUN dnf -y install --allowerasing \
    gcc gcc-c++ make autoconf automake libtool pkgconfig \
    yasm nasm git wget curl tar xz bzip2 which perl \
    ca-certificates
RUN dnf clean all

# Set up build environment
WORKDIR /opt/build
ENV PREFIX=/opt/ffbuild
ENV PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
ENV PATH=$PREFIX/bin:$PATH
RUN mkdir -p $PREFIX

# Download and extract zlib
RUN curl -L https://zlib.net/zlib-$ZLIB_VER.tar.xz | tar -xJ

# Build zlib (static)
WORKDIR /opt/build/zlib-$ZLIB_VER
RUN ./configure --static --prefix=$PREFIX
RUN make -j$(nproc)
RUN make install

# Download and extract OpenSSL
WORKDIR /opt/build
RUN curl -L https://www.openssl.org/source/openssl-$OPENSSL_VER.tar.gz | tar -xz

# Build OpenSSL (static)
WORKDIR /opt/build/openssl-$OPENSSL_VER
RUN ./Configure no-shared linux-x86_64 --prefix=$PREFIX --libdir=lib
RUN make -j$(nproc)
RUN make install_sw

# Download and extract LAME
WORKDIR /opt/build
RUN curl -L https://downloads.sourceforge.net/project/lame/lame/$LAME_VER/lame-$LAME_VER.tar.gz | tar -xz

# Build LAME (static)
WORKDIR /opt/build/lame-$LAME_VER
RUN ./configure --prefix=$PREFIX --enable-static --disable-shared --disable-decoder --disable-frontend
RUN make -j$(nproc)
RUN make install

# Download and extract FFmpeg
WORKDIR /opt/build
RUN curl -L https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VER.tar.xz | tar -xJ

# Configure FFmpeg
WORKDIR /opt/build/ffmpeg-$FFMPEG_VER
RUN PKG_CONFIG_PATH=$PKG_CONFIG_PATH \
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
      --enable-filter=aresample,aformat,anull,volume

# Build FFmpeg
RUN make -j$(nproc)

# Install FFmpeg
RUN make install

# Strip the binaries
RUN strip $PREFIX/bin/ffmpeg $PREFIX/bin/ffprobe

# Final minimal image that just carries the artifacts
FROM amazonlinux:2023 AS out
COPY --from=build /opt/ffbuild/bin/ffmpeg /usr/local/bin/ffmpeg
COPY --from=build /opt/ffbuild/bin/ffprobe /usr/local/bin/ffprobe
CMD ["/bin/bash"]