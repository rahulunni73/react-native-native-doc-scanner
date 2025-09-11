# 📱 react-native-native-doc-scanner

[![npm version](https://badge.fury.io/js/react-native-native-doc-scanner.svg)](https://badge.fury.io/js/react-native-native-doc-scanner)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey.svg)](https://github.com/username/react-native-native-doc-scanner)

High-performance cross-platform document scanner for React Native with native bridge architecture and TurboModule compatibility.

## ✨ Features

- 📄 **Cross-Platform Document Scanning** - iOS VisionKit + Android ML Kit
- 🚀 **Architecture Agnostic** - Works with both Legacy Bridge and New Architecture (TurboModules)
- 📋 **Multi-Page Scanning** - Scan up to 50 pages in a single session (or unlimited with -1)
- 🎯 **PDF Generation** - Automatic PDF creation from scanned documents
- 📱 **Gallery Import** - Import images from gallery (Android only)
- ⚡ **High Performance** - Native implementation for optimal speed
- 🔧 **TypeScript Support** - Full type definitions included
- 🎨 **Customizable** - Multiple scanner modes and quality settings
- 📏 **Size Management** - Built-in file size validation with configurable limits

## 📦 Installation

```bash
npm install react-native-native-doc-scanner
```

### iOS Setup

Add the following permissions to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to scan documents</string>
```

### Android Setup

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## 🚀 Usage

### Basic Example

```typescript
import NativeDocScanner, { ScannerConfig, SCANNER_MODE } from 'react-native-native-doc-scanner';

const config: ScannerConfig = {
  scannerMode: SCANNER_MODE.FULL,
  isGalleryImportRequired: true, // Android only
  pageLimit: 5,
  maxSizeLimit: 50 * 1024 * 1024 // 50MB limit (optional)
};

// Callback-based API
NativeDocScanner.scanDocument(
  config,
  (result) => {
    console.log('Scan successful:', result);
    // result.imagePaths - paths to scanned images
    // result.PdfUri - path to generated PDF
    // result.PdfPageCount - number of pages scanned
  },
  (error) => {
    console.log('Scan failed:', error);
  }
);
```

### Promise-based API

```typescript
import NativeDocScanner, { ScannerConfig, SCANNER_MODE } from 'react-native-native-doc-scanner';

const scanDocuments = async () => {
  try {
    const config: ScannerConfig = {
      scannerMode: SCANNER_MODE.FULL,
      isGalleryImportRequired: false,
      pageLimit: 3,
      maxSizeLimit: 100 * 1024 * 1024 // 100MB limit
    };

    const result = await NativeDocScanner.scanDocumentAsync(config);
    console.log('Scanned documents:', result);
    console.log('Total size:', result.totalImageSize, 'bytes');
    console.log('PDF size:', result.pdfSize, 'bytes');
  } catch (error) {
    console.error('Scanning failed:', error);
  }
};
```

## ⚙️ Configuration Options

### ScannerConfig

| Property | Type | Description | Default |
|----------|------|-------------|---------|
| `scannerMode` | `SCANNER_MODE` | Quality/speed tradeoff | `SCANNER_MODE.FULL` |
| `isGalleryImportRequired` | `boolean` | Allow gallery import (Android only) | `false` |
| `pageLimit` | `number` | Maximum pages to scan (1-50, or -1 for unlimited) | `5` |
| `maxSizeLimit` | `number` | Maximum total file size in bytes (optional) | `104857600` (100MB) |

### Scanner Modes

| Mode | Value | Quality | Speed | Description |
|------|-------|---------|-------|-------------|
| `FULL` | `1` | Highest | Slower | Best quality with advanced processing |
| `BASE_WITH_FILTER` | `2` | Medium | Medium | Good quality with basic filtering |
| `BASE` | `3` | Basic | Fastest | Quick scanning with minimal processing |

### File Size Management

The library includes built-in file size validation to prevent large uploads:

- **Default Limit**: 100MB total size for all scanned images
- **Cross-Platform**: Works on both iOS and Android
- **Real-time Validation**: 
  - **iOS**: Checks size before processing each page during scanning
  - **Android**: Validates total size after scanning completes
- **User Alerts**: Native platform alerts when size limit is exceeded
- **Configurable**: Set custom limits via `maxSizeLimit` parameter
- **Size Reporting**: Returns detailed size information in scan results
- **Error Handling**: Returns `SIZE_LIMIT_EXCEEDED` error when limit exceeded

```typescript
// Configure size limit (50MB example)
const config: ScannerConfig = {
  scannerMode: SCANNER_MODE.FULL,
  pageLimit: 10,
  maxSizeLimit: 50 * 1024 * 1024 // 50MB limit
};

// Check sizes in result
NativeDocScanner.scanDocumentAsync(config)
  .then(result => {
    console.log(`Total images: ${result.totalImageSize} bytes`);
    console.log(`PDF size: ${result.pdfSize} bytes`);
    console.log('Individual sizes:', result.imageSizes);
  })
  .catch(error => {
    if (error.message === 'SIZE_LIMIT_EXCEEDED') {
      console.log('Scanning stopped due to size limit');
      // Handle size limit exceeded
      // iOS: User was alerted during scanning
      // Android: User was alerted after scanning
    }
  });
```

## 📋 API Reference

### Methods

#### `scanDocument(config, onSuccess, onError)`

Scan documents using callback-based API.

**Parameters:**
- `config: ScannerConfig` - Scanner configuration
- `onSuccess: (result: ScannerResult) => void` - Success callback
- `onError: (error: string) => void` - Error callback

#### `scanDocumentAsync(config): Promise<ScannerResult>`

Scan documents using Promise-based API.

**Parameters:**
- `config: ScannerConfig` - Scanner configuration

**Returns:** Promise resolving to `ScannerResult`

#### `getCapabilities(): ScannerCapabilities | null`

Get scanner capabilities and platform information.

**Returns:** Scanner capabilities object or null if not initialized

#### `isReady(): boolean`

Check if the native module is ready for use.

**Returns:** Boolean indicating readiness

### Types

#### ScannerResult

```typescript
interface ScannerResult {
  imagePaths: {[key: string]: string};  // Paths to scanned images
  isPdfAvailable: boolean;               // Whether PDF was generated
  PdfUri: string;                        // Path to generated PDF
  PdfPageCount: number;                  // Number of pages in PDF
  totalImageSize: number;                // Total size of all images in bytes
  pdfSize: number;                       // Size of generated PDF in bytes
  imageSizes: {[key: string]: number};   // Individual image sizes in bytes
}
```

#### ScannerCapabilities

```typescript
interface ScannerCapabilities {
  isTurboModuleEnabled: boolean;         // Architecture being used
  features: {
    galleryImport: boolean;              // Gallery import support
    pdfGeneration: boolean;              // PDF generation capability
    multiPageScan: boolean;              // Multi-page scanning
    imageFiltering: boolean;             // Image filtering support
  };
  platform: 'ios' | 'android';          // Current platform
  framework: 'VisionKit' | 'MLKit' | 'Unknown'; // Native framework
}
```

## 🏗️ Architecture

This library uses **automatic architecture detection** to provide optimal performance:

- **New Architecture (TurboModules)** - When available, automatically uses TurboModules for better performance
- **Legacy Bridge** - Falls back to traditional React Native bridge for maximum compatibility
- **Same API** - Your code remains identical regardless of architecture

### Platform Implementation

| Platform | Framework | Features |
|----------|-----------|----------|
| **iOS** | VisionKit | Document camera, automatic edge detection, multi-page, real-time size validation |
| **Android** | ML Kit | Document scanner, gallery import, image processing, post-scan size validation |

## 📱 Platform Support

| React Native | iOS | Android | New Architecture |
|--------------|-----|---------|------------------|
| 0.68+ | ✅ 15.1+ | ✅ API 21+ | ✅ Supported |
| 0.70+ | ✅ 15.1+ | ✅ API 21+ | ✅ Optimized |

## 🔧 Troubleshooting

### Common Issues

#### "Native module not found"
- Ensure the library is properly installed: `npm install react-native-native-doc-scanner`
- For React Native < 0.60, manually link the library
- Clean and rebuild your project

#### iOS Build Issues
- Make sure iOS deployment target is 15.1 or higher
- Verify VisionKit framework is available on your target devices
- Check camera permissions in Info.plist

#### Android Build Issues
- Ensure minSdkVersion is 21 or higher
- Verify Google Play Services is available
- Check camera and storage permissions

### Debug Information

Check if the library is working correctly:

```typescript
import NativeDocScanner from 'react-native-native-doc-scanner';

console.log('Scanner ready:', NativeDocScanner.isReady());
console.log('Capabilities:', NativeDocScanner.getCapabilities());
```

## 📄 License

MIT © [Your Name](https://github.com/username)

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/username/react-native-native-doc-scanner/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/username/react-native-native-doc-scanner/discussions)
- 📧 **Email**: your.email@example.com

---

**Made with ❤️ for the React Native community**