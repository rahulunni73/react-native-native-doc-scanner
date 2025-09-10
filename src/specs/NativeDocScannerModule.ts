import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface ScannerConfig {
  scannerMode: number;
  isGalleryImportRequired: boolean;
  pageLimit: number;
}

/**
 * TurboModule specification for Native Document Scanner
 * 
 * This spec defines the interface for the New Architecture (TurboModule)
 * implementation of the document scanner module.
 */
export interface Spec extends TurboModule {
  /**
   * Scan documents with the native camera interface
   * @param config - Scanner configuration options
   * @param onSuccess - Success callback with JSON result string
   * @param onError - Error callback with error message
   */
  scanDocument(
    config: ScannerConfig,
    onSuccess: (result: string) => void,
    onError: (error: string) => void,
  ): void;

  /**
   * Get scanner capabilities and platform information
   * @returns JSON string with capability information
   */
  getCapabilities?(): string;

  /**
   * Check if the native scanner is available on this device
   * @returns boolean indicating availability
   */
  isAvailable?(): boolean;
}

/**
 * TurboModule registry lookup
 * This will be used when TurboModules are fully supported
 */
export default TurboModuleRegistry.getEnforcing<Spec>('NativeDocScanner');