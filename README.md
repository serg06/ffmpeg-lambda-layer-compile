### Summary

The goal of this repository is to compile a functioning ffmpeg binary with the following properties:
- Static
- Runs on Amazon Lambda node22.x / Amazon Linux 2023
- Runs on x86 / amd64
- Can process common types of audio like mp3, aac, and mp4
- Supports https/tls
- Space-efficient since Lambda functions are limited to ~262MB

### Setup

You'll need to do some setup before running the build script:
- Install Docker Desktop

### Building

- Run `./build.sh` to compile `ffmpeg` and `ffprobe` in a docker image
- Run `./extract.sh` to extract them and zip them up
- (Optional) Upload the .zip to an AWS Lambda Layer

### Configuration

#### Switching between x86/arm64

AWS Lambda defaults to x86 so this compiles for x86 by default. To change this:
- Update `build.sh` and `extract.sh`
-- Replace `--platform=linux/amd64` with `--platform=linux/arm64`
- Update hardcoded compilation targets in `Dockerfile`
-- Replace `RUN ./Configure no-shared linux-x86_64 --prefix=$PREFIX --libdir=lib` with `RUN ./Configure no-shared linux-aarch64 --prefix=$PREFIX --libdir=lib`

#### Supporting additional formats / features of ffmpeg

Update the Dockerfile and run `build.sh` until it works.

### Alternatives

If you want to compile for other flavors of Linux, check out these docker images: https://github.com/jrottenberg/ffmpeg/tree/main/docker-images

If you don't need https/tls support, you can use [John Van Sickle's builds](https://www.johnvansickle.com/ffmpeg/). They work on Amazon Lambda 2023, but attempting to use https will trigger a segfault: `ffmpeg was killed with signal SIGSEGV`.

If you don't mind having a large binary, you can use https://github.com/BtbN/FFmpeg-Builds/releases. You can get a functioning ~240MB Lambda layer by doing the following:
- Download the shared build `ffmpeg-master-latest-linux64-gpl-shared`
- Delete `ffplay`
- Zip with symlinks disabled: `zip -r9 --symlinks ffmpeg-master-latest-linux64-gpl-shared.zip .`
- Upload it to S3
- Create a layer and point it to that S3 link
