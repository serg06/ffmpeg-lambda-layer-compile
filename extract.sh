#!/bin/bash

# This extracts the ffmpeg/ffprobe binaries from the built image
mkdir -p bin
docker run --platform=linux/amd64 --rm -v $(pwd)/bin:/output ffmpeg7-audio-al2023:latest cp /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /output/

# Now we can build the zip for the layer
zip -r9 ffmpeg7-audio-al2023.zip bin
