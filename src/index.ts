/**
 * React Native Native Document Scanner
 * 
 * High-performance cross-platform document scanner with native bridge architecture
 * and TurboModule compatibility.
 * 
 * Features:
 * - Cross-platform document scanning (iOS VisionKit + Android ML Kit)
 * - Automatic architecture detection (TurboModule vs Legacy Bridge)
 * - PDF generation from scanned documents
 * - Multi-page scanning support
 * - TypeScript support with full type definitions
 * - Promise and callback-based APIs
 * 
 * @packageDocumentation
 */

// Main scanner module
export { default as NativeDocScanner } from './DocumentScanner';

// Type definitions
export type {
  ScannerConfig,
  ScannerResult,
  ScanSuccessCallback,
  ScanErrorCallback,
  ScannerPromiseResult,
  ScannerCapabilities,
  NativeDocScannerInterface,
} from './types';

// Enums
export { SCANNER_MODE, ScannerError } from './types';

// Default export for convenience
export { default } from './DocumentScanner';

/**
 * Library version
 */
export const VERSION = '1.0.0';

/**
 * Library information
 */
export const LIBRARY_INFO = {
  name: 'react-native-native-doc-scanner',
  version: VERSION,
  description: 'High-performance cross-platform document scanner with native bridge architecture',
  repository: 'https://github.com/username/react-native-native-doc-scanner',
  author: 'Your Name',
  license: 'MIT',
} as const;