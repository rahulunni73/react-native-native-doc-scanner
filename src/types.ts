/**
 * Configuration options for document scanning
 */
export interface ScannerConfig {
  /** 
   * Scanner mode determining quality and speed
   * FULL = 1 (highest quality, slower)
   * BASE_WITH_FILTER = 2 (medium quality, medium speed) 
   * BASE = 3 (basic quality, fastest)
   */
  scannerMode: SCANNER_MODE;
  
  /** Whether to allow importing images from gallery (Android only) */
  isGalleryImportRequired: boolean;
  
  /** Maximum number of pages to scan (1-50, or -1 for unlimited) */
  pageLimit: number;
  
  /** Maximum total file size in bytes (default: 100MB) */
  maxSizeLimit?: number;

  /** JPEG compression quality (0.0–1.0, default: 1.0). Lower = smaller file. 0.7–0.8 recommended for documents. */
  compressionQuality?: number;

  /** Max width or height in pixels. Image is scaled down proportionally if either dimension exceeds this. */
  maxImageDimension?: number;
}

/**
 * Scanner modes for different quality/speed tradeoffs
 */
export enum SCANNER_MODE {
  /** Highest quality scanning with advanced processing */
  FULL = 1,
  /** Medium quality with basic filtering */
  BASE_WITH_FILTER = 2,
  /** Basic quality, fastest scanning */
  BASE = 3,
}

/**
 * Result returned from document scanning operation
 */
export interface ScannerResult {
  /** 
   * Paths to scanned image files
   * Format: {"image 0": "/path/to/image1.jpg", "image 1": "/path/to/image2.jpg"}
   */
  imagePaths: {[key: string]: string};
  
  /** Whether PDF was successfully generated */
  isPdfAvailable: boolean;
  
  /** Path to generated PDF file */
  PdfUri: string;
  
  /** Number of pages in the generated PDF */
  PdfPageCount: number;
  
  /** Total size of all scanned images in bytes */
  totalImageSize: number;
  
  /** Size of the generated PDF in bytes */
  pdfSize: number;
  
  /** Individual image sizes in bytes */
  imageSizes: {[key: string]: number};
}

/**
 * Error types that can occur during scanning
 */
export enum ScannerError {
  /** User cancelled the scanning operation */
  USER_CANCELLED = 'USER_CANCELLED',
  
  /** Device camera is not available */
  CAMERA_NOT_AVAILABLE = 'CAMERA_NOT_AVAILABLE',
  
  /** Document scanning is not supported on this device */
  NOT_SUPPORTED = 'NOT_SUPPORTED',
  
  /** Permission denied for camera or storage */
  PERMISSION_DENIED = 'PERMISSION_DENIED',
  
  /** Failed to save scanned document */
  SAVE_FAILED = 'SAVE_FAILED',
  
  /** Native module is not properly linked */
  MODULE_NOT_FOUND = 'MODULE_NOT_FOUND',
  
  /** Unknown error occurred */
  UNKNOWN_ERROR = 'UNKNOWN_ERROR',
  
  /** File size limit exceeded */
  SIZE_LIMIT_EXCEEDED = 'SIZE_LIMIT_EXCEEDED',
}

/**
 * Callback function for successful scanning
 */
export type ScanSuccessCallback = (result: ScannerResult) => void;

/**
 * Callback function for scanning errors
 */
export type ScanErrorCallback = (error: string) => void;

/**
 * Promise-based API result
 */
export interface ScannerPromiseResult {
  success: boolean;
  data?: ScannerResult;
  error?: string;
}

/**
 * Crash recovery result from interrupted scan sessions
 */
export interface CrashRecoveryResult {
  /** Scan result data recovered from interrupted session */
  scanResult: string;
  /** Whether this result came from crash recovery */
  fromCrashRecovery: boolean;
}

/**
 * Last scan result wrapper
 */
export interface LastScanResult {
  /** Scan result data */
  scanResult: string;
}

/**
 * Native module interface for document scanning
 */
export interface NativeDocScannerInterface {
  /**
   * Scan documents using callback-based API
   * @param config - Scanner configuration options
   * @param onSuccess - Callback for successful scanning (receives JSON string)
   * @param onError - Callback for errors
   */
  scanDocument(
    config: ScannerConfig,
    onSuccess: (result: string) => void,
    onError: ScanErrorCallback,
  ): void;

  /**
   * Check for scan results from interrupted sessions (crash recovery)
   * Only returns results from the current interrupted scan session
   * @returns Promise resolving to recovery data or null if no pending results
   */
  checkForCrashRecovery(): Promise<CrashRecoveryResult | null>;

  /**
   * Get the last scan result (legacy method for backward compatibility)
   * @returns Promise resolving to last scan result or null
   */
  getLastScanResult(): Promise<LastScanResult | null>;

  /**
   * Clear all cached scan data
   * Useful for testing or manual cleanup
   * @returns Promise resolving to true when cleared
   */
  clearScanCache(): Promise<boolean>;
}

/**
 * Module capabilities and feature detection
 */
export interface ScannerCapabilities {
  /** Whether TurboModule architecture is being used */
  isTurboModuleEnabled: boolean;
  
  /** Platform-specific features available */
  features: {
    /** Gallery import support (Android only) */
    galleryImport: boolean;
    
    /** PDF generation capability */
    pdfGeneration: boolean;
    
    /** Multi-page scanning */
    multiPageScan: boolean;
    
    /** Image filtering and enhancement */
    imageFiltering: boolean;
  };
  
  /** Platform information */
  platform: 'ios' | 'android';
  
  /** Native scanner framework being used */
  framework: 'VisionKit' | 'MLKit' | 'Unknown';
}