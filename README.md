# 📱 react-native-native-doc-scanner

[![npm version](https://badge.fury.io/js/react-native-native-doc-scanner.svg)](https://badge.fury.io/js/react-native-native-doc-scanner)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey.svg)](https://github.com/rahulunni73/react-native-native-doc-scanner)

High-performance cross-platform document scanner for React Native with **session-based crash recovery**, native bridge architecture, and TurboModule compatibility.

> ⚠️ **Educational Purpose Disclaimer**: This library is provided for educational and learning purposes only. It is not intended for use in production applications without thorough testing and validation in your specific environment. Use at your own risk.

## ✨ Features

- 📄 **Cross-Platform Document Scanning** - iOS VisionKit + Android ML Kit
- 🔄 **Session-Based Crash Recovery** - Automatic recovery of scan results after app crashes or memory kills
- 🚀 **Architecture Agnostic** - Works with both Legacy Bridge and New Architecture (TurboModules)
- 📋 **Multi-Page Scanning** - Scan up to 50 pages in a single session (or unlimited with -1)
- 🎯 **PDF Generation** - Automatic PDF creation from scanned documents
- 📱 **Gallery Import** - Import images from gallery (Android only)
- ⚡ **High Performance** - Native implementation for optimal speed
- 🔧 **TypeScript Support** - Full type definitions included
- 🎨 **Customizable** - Multiple scanner modes and quality settings
- 📏 **Size Management** - Built-in file size validation with configurable limits
- 🛡️ **Process Kill Protection** - Handles Android memory pressure and process termination gracefully

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

1. **Add permissions** to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

2. **Add the ScannerActivity** to your `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

```xml
<application>
    <!-- Your existing activities -->
    
    <!-- Document Scanner Activity -->
    <activity
        android:name="com.nativedocscanner.ScannerActivity"
        android:exported="false"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar" />
        
</application>
```

3. **For React Native 0.60+**: The library should auto-link. For older versions, manually link the library.

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

## 🔄 Crash Recovery System

This library includes a **session-based crash recovery system** that automatically handles app crashes and memory kills during scanning operations, ensuring users never lose their scan results.

### How It Works

The crash recovery system tracks scan sessions with timestamps and persists results to device storage. When your app restarts after a crash or memory kill, you can automatically recover the scan results from the interrupted session.

**Key Features:**
- ✅ **Session-based tracking** - Only recovers results from the current interrupted scan session
- ✅ **Cross-platform** - Works on both iOS and Android
- ✅ **Automatic persistence** - No manual intervention required
- ✅ **Memory kill protection** - Specifically designed for Android memory pressure scenarios
- ✅ **Clean state management** - Clears recovery data after successful delivery

### Basic Crash Recovery Usage

```typescript
import NativeDocScanner, { CrashRecoveryResult } from 'react-native-native-doc-scanner';

// Check for crash recovery when your app starts or component mounts
const checkForRecovery = async () => {
  try {
    const recoveryResult: CrashRecoveryResult | null = await NativeDocScanner.checkForCrashRecovery();
    
    if (recoveryResult && recoveryResult.fromCrashRecovery) {
      console.log('🔄 Recovered scan result from interrupted session!');
      
      // Parse the recovered result
      const scanResult = JSON.parse(recoveryResult.scanResult);
      
      // Handle the recovered result (same as normal scan result)
      console.log('Recovered documents:', scanResult.imagePaths);
      console.log('Recovered PDF:', scanResult.PdfUri);
      
      // Show user notification about recovery
      Alert.alert(
        'Scan Recovered',
        'Your previous scan was automatically recovered!',
        [{ text: 'OK', onPress: () => handleRecoveredScan(scanResult) }]
      );
    } else {
      console.log('No pending scan results to recover');
    }
  } catch (error) {
    console.error('Crash recovery check failed:', error);
  }
};

// Call this when your app starts
useEffect(() => {
  checkForRecovery();
}, []);
```

### React Component Integration

```typescript
import React, { useEffect, useState } from 'react';
import { View, Text, Alert, TouchableOpacity } from 'react-native';
import NativeDocScanner, { ScannerConfig, SCANNER_MODE } from 'react-native-native-doc-scanner';

const DocumentScannerScreen = () => {
  const [hasRecoveredResult, setHasRecoveredResult] = useState(false);
  const [recoveredResult, setRecoveredResult] = useState(null);

  useEffect(() => {
    checkForCrashRecovery();
  }, []);

  const checkForCrashRecovery = async () => {
    try {
      const recovery = await NativeDocScanner.checkForCrashRecovery();
      
      if (recovery?.fromCrashRecovery) {
        const scanResult = JSON.parse(recovery.scanResult);
        setRecoveredResult(scanResult);
        setHasRecoveredResult(true);
        
        // Show recovery banner
        Alert.alert(
          '🔄 Scan Recovered',
          'Your previous scan was automatically recovered after the app restart.',
          [
            { text: 'View Result', onPress: () => handleScanResult(scanResult) },
            { text: 'Dismiss', onPress: () => setHasRecoveredResult(false) }
          ]
        );
      }
    } catch (error) {
      console.error('Recovery check failed:', error);
    }
  };

  const startScanning = async () => {
    const config: ScannerConfig = {
      scannerMode: SCANNER_MODE.FULL,
      isGalleryImportRequired: false,
      pageLimit: 5
    };

    try {
      const result = await NativeDocScanner.scanDocumentAsync(config);
      handleScanResult(result);
    } catch (error) {
      console.error('Scanning failed:', error);
    }
  };

  const handleScanResult = (result) => {
    console.log('Scan successful:', result);
    // Process your scan result here
  };

  return (
    <View>
      {hasRecoveredResult && (
        <View style={{ backgroundColor: '#e3f2fd', padding: 10 }}>
          <Text>🔄 Recovered scan result available</Text>
        </View>
      )}
      
      <TouchableOpacity onPress={startScanning}>
        <Text>Start Scanning</Text>
      </TouchableOpacity>
    </View>
  );
};
```

### Advanced Crash Recovery Methods

#### `checkForCrashRecovery(): Promise<CrashRecoveryResult | null>`

Checks for scan results from interrupted sessions and returns only results from the current session.

```typescript
const recoveryResult = await NativeDocScanner.checkForCrashRecovery();
if (recoveryResult) {
  const { scanResult, fromCrashRecovery } = recoveryResult;
  // scanResult: JSON string of the scan result
  // fromCrashRecovery: Always true when recovery data is available
}
```

#### `getLastScanResult(): Promise<LastScanResult | null>`

Legacy method for backward compatibility. Gets the last scan result regardless of session.

```typescript
const lastResult = await NativeDocScanner.getLastScanResult();
if (lastResult) {
  const scanResult = JSON.parse(lastResult.scanResult);
  // Process the last scan result
}
```

#### `clearScanCache(): Promise<boolean>`

Manually clear all cached scan data. Useful for testing or cleanup.

```typescript
const cleared = await NativeDocScanner.clearScanCache();
console.log('Cache cleared:', cleared);
```

### When Crash Recovery Triggers

**Android Scenarios:**
- 📱 App process killed by Android due to memory pressure during ML Kit scanning
- 🔄 App force-closed or restarted during scanning
- ⚡ System-initiated memory cleanup (TRIM_MEMORY_COMPLETE events)
- 🔋 Low memory conditions during document processing

**iOS Scenarios:**
- 📱 App terminated while VisionKit scanner is active
- 🔄 App backgrounded and memory reclaimed during scanning
- ⚡ Manual app termination during document processing

### Important Notes

- ✅ **Session-based**: Only recovers results from the **current interrupted scan session**, not previous completed scans
- ✅ **Automatic cleanup**: Recovery data is automatically cleared after successful delivery
- ✅ **Cross-platform consistency**: Same API and behavior on both iOS and Android
- ✅ **No false positives**: Won't show old results from previous app sessions
- ✅ **Memory efficient**: Uses minimal storage for recovery data

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

#### `checkForCrashRecovery(): Promise<CrashRecoveryResult | null>`

Check for scan results from interrupted sessions (crash recovery). Only returns results from the current interrupted scan session.

**Returns:** Promise resolving to crash recovery data or null if no pending results

#### `getLastScanResult(): Promise<LastScanResult | null>`

Get the last scan result (legacy method for backward compatibility).

**Returns:** Promise resolving to last scan result or null

#### `clearScanCache(): Promise<boolean>`

Clear all cached scan data. Useful for testing or manual cleanup.

**Returns:** Promise resolving to true when cleared successfully

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

#### CrashRecoveryResult

```typescript
interface CrashRecoveryResult {
  scanResult: string;                    // Scan result data recovered from interrupted session
  fromCrashRecovery: boolean;            // Whether this result came from crash recovery (always true)
}
```

#### LastScanResult

```typescript
interface LastScanResult {
  scanResult: string;                    // Scan result data (JSON string)
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


## 📄 License

MIT © [rahulunni73](https://github.com/rahulunni73)

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/rahulunni73/react-native-native-doc-scanner/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/rahulunni73/react-native-native-doc-scanner/discussions)
- 📧 **Email**: rahulunni73@gmail.com

---

**Made with ❤️ for the React Native community**
