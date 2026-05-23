CI and Deploy

This repo's CI builds multi-arch images and, when pushing to main, publishes images to GitHub Container Registry (GHCR) and deploys to Fly.io.

Required secrets (GitHub repository settings → Secrets):
- FLY_API_TOKEN — API token from Fly (used by CI to deploy). Create via `flyctl auth token`.

GHCR uses the built-in GITHUB_TOKEN for authentication from Actions; no additional secret is required for publishing to GHCR in this workflow.

To disable automatic deploy, remove or unset `FLY_API_TOKEN` from repository secrets.
