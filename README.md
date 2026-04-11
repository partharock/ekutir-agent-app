# ekutir-agent-app

Flutter implementation of the eK Acre Growth agent experience based on the exported Figma screens.

## Included
- App shell with `go_router`
- Mock data and in-memory state
- Auth, home, engagement, support, harvest/procurement, crop plan, and `MISA AI` placeholder flows
- Widget test scaffolding

## Local Development
Once Flutter is available locally, run:

```bash
flutter create . --platforms=android,ios
flutter pub get
flutter test
flutter run
```

## Web Testing
This repo includes Flutter web support and a Cloudflare Pages deployment path.

Build a web bundle for hosting:

```bash
MAPPLS_WEB_STATIC_KEY="your-mappls-web-static-key" \
bash tool/build_web_for_pages.sh
```

Deploy the built web app to Cloudflare Pages:

```bash
MAPPLS_WEB_STATIC_KEY="your-mappls-web-static-key" \
CLOUDFLARE_PAGES_PROJECT_NAME="ekutir-agent-app" \
bash tool/deploy_pages.sh
```

Notes:
- If `MAPPLS_WEB_STATIC_KEY` is empty, the web app still deploys, but plot map features remain disabled.
- The Cloudflare Pages hostname must be whitelisted in the Mappls web credential setup.
- `web/_redirects` is included so Flutter routes work on refresh and deep links.
