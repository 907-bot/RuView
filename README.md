# RuView Scaffold (demo)

This repository contains a minimal scaffold for a RuView demo application: a small FastAPI backend, a static frontend, Dockerfiles for both, docker-compose for local testing, and deploy assets for common free hosting providers.

Files added:
- Dockerfile.backend — multi-stage Python image for the backend
- Dockerfile.frontend — Node build + nginx static runtime
- backend/* — minimal FastAPI server with /health
- frontend/index.html — simple demo client
- docker-compose.yml — local compose to run backend + frontend
- deploy/ — nginx config for static frontend

Next steps:
1. Build locally: `docker compose up --build`
2. Install pre-commit hooks: `pip install pre-commit && pre-commit install`
3. Push to a Git repository and let the CI build + publish images.
4. Frontend GitHub Pages: the repo includes a workflow to publish the `frontend/` directory to the `gh-pages` branch on push to `main`. Enable GitHub Pages from your repo settings (use `gh-pages` branch).
5. Set secrets in GitHub:
   - `FLY_API_TOKEN` (used by CI to deploy to Fly)
   - `BACKEND_URL` (used by the Pages workflow to generate frontend/config.js so the static site knows where to reach the backend; e.g. `https://ruview-sensing-server.onrender.com`)
5. Deploy to Fly.io / Render / Railway using the provided examples in SKILL.md
