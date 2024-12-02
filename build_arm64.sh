#!/bin/bash
set -e

cp ./arm64.override.Dockerfile ./webhook.site/Dockerfile
docker buildx build --platform linux/arm64 -t webhooksite/webhook.site:latest ./webhook.site
