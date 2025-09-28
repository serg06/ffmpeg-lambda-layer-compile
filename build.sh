#!/bin/bash

# Building it for amd64 since that's what my lambda runs on
docker build --platform=linux/amd64 -t ffmpeg7-audio-al2023 -f Dockerfile .
