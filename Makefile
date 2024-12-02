build-arm64:
	sed -i '' 's|node:11|arm64v8/node:11|g' webhook.site/Dockerfile
	docker buildx build --platform linux/arm64 -t webhooksite/webhook.site:latest ./webhook.site
