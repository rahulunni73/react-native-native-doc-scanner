# Changelog

All notable changes to `react-native-native-doc-scanner` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-09-10

### Added
- 🎉 **Initial Release** - Cross-platform document scanner with native bridge architecture
- 📱 **iOS Support** - VisionKit document camera integration
- 🤖 **Android Support** - Google ML Kit document scanner integration
- 🏗️ **Architecture Detection** - Automatic TurboModule vs Legacy Bridge detection
- 📄 **Multi-Page Scanning** - Support for up to 10 pages per scan session
- 🎯 **PDF Generation** - Automatic PDF creation from scanned documents
- 📋 **Gallery Import** - Image import from gallery (Android only)
- ⚡ **Performance Optimized** - Native implementation for optimal speed
- 🔧 **TypeScript Support** - Full type definitions and IntelliSense support
- 🎨 **Multiple Scanner Modes** - FULL, BASE_WITH_FILTER, BASE quality options
- 📚 **Promise & Callback APIs** - Both async/await and callback-based usage
- 🧪 **Capability Detection** - Runtime feature and platform detection
- 📦 **Auto-linking Support** - React Native 0.60+ automatic native module linking
- 🏛️ **Legacy Compatibility** - Support for React Native 0.68+

### Features
- Cross-platform consistent API between iOS and Android
- Automatic edge detection and document enhancement
- Configurable page limits (1-10 pages)
- Real-time camera preview with document boundaries
- High-quality image processing and compression
- Structured JSON response format with image paths and PDF URI
- Error handling with descriptive error messages
- Memory-efficient file handling and cleanup

### Platform Support
- **iOS**: 15.1+ with VisionKit framework
- **Android**: API level 21+ with Google Play Services ML Kit
- **React Native**: 0.68+ with New Architecture readiness

### Documentation
- Comprehensive README with usage examples
- TypeScript type definitions
- API reference documentation
- Platform-specific setup instructions
- Troubleshooting guide