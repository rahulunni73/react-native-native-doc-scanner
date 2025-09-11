import { NativeModules, TurboModuleRegistry, Platform } from 'react-native';
import type {
  ScannerConfig,
  ScannerResult,
  ScanSuccessCallback,
  ScanErrorCallback,
  ScannerPromiseResult,
  ScannerCapabilities,
  NativeDocScannerInterface,
} from './types';
import { ScannerError } from './types';

/**
 * Native Document Scanner Module
 * Provides cross-platform document scanning with automatic architecture detection
 */
class NativeDocumentScanner {
  private nativeModule: NativeDocScannerInterface | null = null;
  private isInitialized = false;
  private capabilities: ScannerCapabilities | null = null;

  constructor() {
    this.initializeModule();
  }

  /**
   * Initialize the native module with architecture detection
   */
  private initializeModule(): void {
    try {
      // Check if TurboModule Registry is available and functional (New Architecture)
      // @ts-ignore - global is available in React Native runtime
      if (global?.__turboModuleProxy != null && TurboModuleRegistry?.getEnforcing) {
        try {
          const turboModule = TurboModuleRegistry.getEnforcing('NativeDocScanner');
          this.nativeModule = turboModule as NativeDocScannerInterface;
          console.log('[NativeDocScanner] Using New Architecture (TurboModule)');
          this.capabilities = {
            isTurboModuleEnabled: true,
            features: this.getFeatures(),
            platform: Platform.OS as 'ios' | 'android',
            framework: this.getFramework(),
          };
        } catch (error) {
          console.log('[NativeDocScanner] TurboModule failed, falling back to Legacy Bridge:', error);
          this.initializeLegacyBridge();
        }
      } else {
        // Use Legacy Bridge (Old Architecture)
        this.initializeLegacyBridge();
      }

      this.isInitialized = true;
    } catch (error) {
      console.error('[NativeDocScanner] Failed to initialize native module:', error);
      this.isInitialized = false;
    }
  }

  /**
   * Initialize legacy bridge module
   */
  private initializeLegacyBridge(): void {
    const { NativeDocScanner } = NativeModules;
    
    if (!NativeDocScanner) {
      throw new Error(
        'NativeDocScanner native module is not available. Make sure the library is properly linked.'
      );
    }

    this.nativeModule = NativeDocScanner as NativeDocScannerInterface;
    console.log('[NativeDocScanner] Using Legacy Bridge Architecture');
    
    this.capabilities = {
      isTurboModuleEnabled: false,
      features: this.getFeatures(),
      platform: Platform.OS as 'ios' | 'android',
      framework: this.getFramework(),
    };
  }

  /**
   * Get platform-specific features
   */
  private getFeatures() {
    return {
      galleryImport: Platform.OS === 'android',
      pdfGeneration: true,
      multiPageScan: true,
      imageFiltering: true,
    };
  }

  /**
   * Get native framework being used
   */
  private getFramework(): 'VisionKit' | 'MLKit' | 'Unknown' {
    if (Platform.OS === 'ios') {
      return 'VisionKit';
    } else if (Platform.OS === 'android') {
      return 'MLKit';
    }
    return 'Unknown';
  }

  /**
   * Scan documents using callback-based API
   * @param config - Scanner configuration options
   * @param onSuccess - Callback for successful scanning
   * @param onError - Callback for errors
   */
  public scanDocument(
    config: ScannerConfig,
    onSuccess: ScanSuccessCallback,
    onError: ScanErrorCallback,
  ): void {
    if (!this.isInitialized || !this.nativeModule) {
      onError(ScannerError.MODULE_NOT_FOUND);
      return;
    }

    // Validate configuration
    const validationError = this.validateConfig(config);
    if (validationError) {
      onError(validationError);
      return;
    }

    try {
      this.nativeModule.scanDocument(
        config,
        (result: string) => {
          try {
            const parsedResult: ScannerResult = JSON.parse(result);
            onSuccess(parsedResult);
          } catch (parseError) {
            console.error('[NativeDocScanner] Failed to parse result:', parseError);
            onError(ScannerError.UNKNOWN_ERROR);
          }
        },
        (error: string) => {
          onError(error || ScannerError.UNKNOWN_ERROR);
        }
      );
    } catch (error) {
      console.error('[NativeDocScanner] Native module call failed:', error);
      onError(ScannerError.UNKNOWN_ERROR);
    }
  }

  /**
   * Scan documents using Promise-based API
   * @param config - Scanner configuration options
   * @returns Promise with scan result
   */
  public scanDocumentAsync(config: ScannerConfig): Promise<ScannerResult> {
    return new Promise((resolve, reject) => {
      this.scanDocument(
        config,
        (result: ScannerResult) => resolve(result),
        (error: string) => reject(new Error(error))
      );
    });
  }

  /**
   * Get scanner capabilities and information
   * @returns Scanner capabilities object
   */
  public getCapabilities(): ScannerCapabilities | null {
    return this.capabilities;
  }

  /**
   * Check if the native module is properly initialized
   * @returns True if module is ready for use
   */
  public isReady(): boolean {
    return this.isInitialized && this.nativeModule !== null;
  }

  /**
   * Validate scanner configuration
   * @param config - Configuration to validate
   * @returns Error message if invalid, null if valid
   */
  private validateConfig(config: ScannerConfig): string | null {
    if (!config) {
      return 'Scanner configuration is required';
    }

    if (typeof config.scannerMode !== 'number' || ![1, 2, 3].includes(config.scannerMode)) {
      return 'Invalid scanner mode. Must be 1 (FULL), 2 (BASE_WITH_FILTER), or 3 (BASE)';
    }

    if (typeof config.isGalleryImportRequired !== 'boolean') {
      return 'isGalleryImportRequired must be a boolean';
    }

    if (typeof config.pageLimit !== 'number' || (config.pageLimit !== -1 && (config.pageLimit < 1 || config.pageLimit > 50))) {
      return 'pageLimit must be a number between 1 and 50, or -1 for unlimited pages';
    }

    // Platform-specific validations
    if (Platform.OS === 'ios' && config.isGalleryImportRequired) {
      console.warn('[NativeDocScanner] Gallery import is not supported on iOS, ignoring setting');
    }

    return null;
  }
}

// Create singleton instance
const documentScanner = new NativeDocumentScanner();

export default documentScanner;