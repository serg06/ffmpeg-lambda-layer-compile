The goal of this repository is to compile a functioning ffmpeg binary with the following properties:
- Static
- Built on `amazonlinux:2023` docker image
- Can process common audio types like mp3, aac, and mp4
- Ffmpeg must have TLS/https support

Steps to build:
- Run `bash build.sh`

Steps to get the binary (don't do this until we're able to get the build working!)
- Manually copy the built ffmpeg file out of the image
