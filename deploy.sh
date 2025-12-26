#!/bin/bash

# AIn't Real - Web Deployment Script
# Deploys landing page + Flutter web app to Cloudflare Pages
#
# Structure:
#   /           -> Landing page (landing/index.html)
#   /play/      -> Flutter web app

set -e

echo "=== AIn't Real Web Deployment ==="

# Clean previous build
echo "Cleaning previous build..."
rm -rf build/deploy

# Build Flutter web with /play/ base href
echo "Building Flutter web..."
~/Library/flutter/bin/flutter build web --release --base-href "/play/"

# Create deployment directory
echo "Creating deployment structure..."
mkdir -p build/deploy/play

# Copy landing page to root
cp landing/index.html build/deploy/

# Copy Flutter web app to /play/
cp -r build/web/* build/deploy/play/

# Create _redirects for Cloudflare Pages SPA support
cat > build/deploy/_redirects << 'EOF'
# Flutter web SPA - serve index.html for all /play/* routes
/play/*  /play/index.html  200
EOF

# Deploy to Cloudflare Pages
echo "Deploying to Cloudflare Pages..."
cd build/deploy
npx wrangler pages deploy . --project-name=aintreal-web --branch=main

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "URLs:"
echo "  Landing:    https://aintreal-web.pages.dev"
echo "  Flutter:    https://aintreal-web.pages.dev/play/"
echo ""
echo "Custom domain: Configure aint-real.com in Cloudflare dashboard"
