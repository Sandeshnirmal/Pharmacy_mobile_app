#!/bin/bash
# Automated build script for Pharmacy Mobile App

echo "🚀 Starting Pharmacy App Build Process..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Run code analysis
echo "🔍 Running code analysis..."
flutter analyze

# Run tests (if any)
echo "🧪 Running tests..."
flutter test

# Build for Android
echo "📱 Building Android APK..."
flutter build apk --release

# Build App Bundle for Play Store
echo "📦 Building Android App Bundle..."
flutter build appbundle --release

echo "✅ Build process completed!"
echo "📁 APK location: build/app/outputs/flutter-apk/app-release.apk"
echo "📁 Bundle location: build/app/outputs/bundle/release/app-release.aab"
