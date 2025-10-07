#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Anime Aggressors Quickstart"
echo "================================"

# Check prerequisites
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js 20+"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ npm not found. Please install npm 10+"
    exit 1
fi

echo "✅ Node.js $(node -v)"
echo "✅ npm $(npm -v)"

# Install root dependencies
echo "📦 Installing root dependencies..."
npm install

# Build packages
echo "🔨 Building packages..."
cd packages/messages && npm run build && cd ../..
cd packages/edgeio && npm run build && cd ../..

# Test EdgeIO library
echo "🧪 Testing EdgeIO library..."
cd packages/edgeio && npm test && cd ../..

echo "✅ All packages built and tested!"

# Web app
echo "🌐 Starting web app..."
cd apps/web
npm install
echo "Web app ready! Run 'npm run dev' to start development server"

# Mobile app  
echo "📱 Mobile app setup..."
cd ../mobile
npm install
echo "Mobile app ready! Run 'npx expo start' to start Expo"

# Cloud worker
echo "☁️  Cloud worker setup..."
cd ../../cloud/worker
npm install
echo "Cloud worker ready! Run 'npm run dev' for local development"

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  • Web: cd apps/web && npm run dev"
echo "  • Mobile: cd apps/mobile && npx expo start"  
echo "  • Cloud: cd cloud/worker && npm run dev"
echo "  • Hardware: cd firmware/ring && pio run -t upload"
