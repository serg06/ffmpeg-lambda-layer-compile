# Save as: Dockerfile

# -------- Stage 1: build in amazonlinux:2023 ----------
FROM amazonlinux:2023 AS build

# Pick your FFmpeg version explicitly
ARG FFMPEG_VER=7.1

# Toolchain + only the audio/TLS deps we need
RUN dnf -y update && dnf install -y --allowerasing \
  gcc gcc-c++ make automake autoconf libtool pkgconfig cmake \
  yasm nasm curl tar xz \
  gnutls-devel zlib-devel zlib-static \
  fdk-aac-free-devel opus-devel libvorbis-devel libogg-devel flac-devel \
  && dnf clean all

WORKDIR /tmp

# Fetch and unpack FFmpeg 7.x source
RUN curl -L -o ffmpeg.tar.xz https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VER}.tar.xz && \
    tar -xf ffmpeg.tar.xz

# Configure: static, small, audio-only, HTTPS/TLS via GnuTLS
# If you want the absolute-min build, see the comments below.
RUN cd ffmpeg-${FFMPEG_VER} && \
    ./configure \
      --prefix=/opt/ffmpeg \
      --extra-libs="-lm -lz -ldl -lpthread" \
      --disable-shared --enable-static \
      --disable-debug --disable-doc --disable-ffplay \
      --enable-small \
      \
      # Protocols / I/O
      --enable-protocol=file,pipe,tcp,http,https,tls \
      --enable-gnutls \
      \
      # Demuxers / muxers for common audio
      --enable-demuxer=mp3,aac,ogg,flac,wav,opus,mp4 \
      --enable-muxer=mp3,aac,ogg,flac,wav,opus,mp4 \
      \
      # Decoders / encoders (audio only)
      --enable-decoder=mp3,aac,opus,vorbis,flac,wavpack,pcm_s16le,pcm_f32le \
      --enable-encoder=aac,libfdk_aac,libopus,libvorbis,pcm_s16le,pcm_f32le \
      \
      # Essential filters
      --enable-filter=aresample,anull \
      \
      # Build only the ffmpeg CLI (not ffprobe/ffplay)
      --disable-programs --enable-ffmpeg \
    && make -j$(nproc) \
    && make install \
    && strip /opt/ffmpeg/bin/ffmpeg \
    && cd / && rm -rf /tmp/ffmpeg*

# -------- Stage 2: runtime with the binary ----------
FROM amazonlinux:2023
RUN dnf install -y gnutls && dnf clean all
COPY --from=build /opt/ffmpeg/bin/ffmpeg /usr/local/bin/ffmpeg
CMD ["/bin/bash"]

