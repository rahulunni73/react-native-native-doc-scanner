package com.nativedocscanner;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;

import java.util.HashMap;


public class NativeDocScannerModule extends ReactContextBaseJavaModule implements ActivityEventListener {

    ReactApplicationContext mContext;
    private static final int SCANNER_REQUEST_CODE = 1001;
    private Callback successCallback;
    private Callback errorCallback;
    private boolean callbackInvoked = false;

    NativeDocScannerModule(ReactApplicationContext context) {
        super(context);
        this.mContext = context;
        Log.d("Scanner Module","Constructed Executed - Enhanced with Crash Recovery v2.0.0");
        context.addActivityEventListener(this);
        
        // Check for pending results on module initialization (after process restart)
        checkForPendingResults();
    }

    @Override
    public String getName() {
        return "NativeDocScanner";
    }

    @ReactMethod
    public void scanDocument(ReadableMap scannerConfig, Callback successCallback, Callback errorCallback) {
        // Enhanced scanner with session-based crash recovery
        try {
            this.successCallback = successCallback;
            this.errorCallback = errorCallback;
            this.callbackInvoked = false; // Reset the flag for new scan

            Activity currentActivity = getCurrentActivity();

            if (currentActivity == null) {
                errorCallback.invoke("Activity doesn't exist");
                return;
            }
            
            // Mark scan as started for crash recovery with session tracking
            ScannerResultHolder.setScanInProgress(getReactApplicationContext(), true);
            
            HashMap<String,Object> config = Utils.convertReadableMapToHashMap(scannerConfig);
            Intent intent = new Intent(currentActivity, ScannerActivity.class);
            intent.putExtra("scannerConfig", config);
            
            // Pass configuration to scanner activity
            if (config.containsKey("pageLimit")) {
                intent.putExtra("pageLimit", (Integer) config.get("pageLimit"));
            }
            if (config.containsKey("isGalleryImportRequired")) {
                intent.putExtra("galleryImport", (Boolean) config.get("isGalleryImportRequired"));
            }
            if (config.containsKey("scannerMode")) {
                intent.putExtra("scannerMode", (Integer) config.get("scannerMode"));
            }
            
            Log.d("Scanner Module", String.format("Starting scan with config: pageLimit=%s, galleryImport=%s, scannerMode=%s",
                config.get("pageLimit"), config.get("isGalleryImportRequired"), config.get("scannerMode")));
                
            currentActivity.startActivityForResult(intent, SCANNER_REQUEST_CODE);

        } catch (Exception e) {
            errorCallback.invoke(e.getMessage());
            ScannerResultHolder.setScanInProgress(getReactApplicationContext(), false);
        }
    }


    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {
        Log.d("Scanner Module", "Activity result received - requestCode: " + requestCode + 
              ", resultCode: " + resultCode);

        if (requestCode == SCANNER_REQUEST_CODE && !callbackInvoked && successCallback != null && errorCallback != null) {
            callbackInvoked = true; // Mark callback as invoked to prevent multiple calls
            
            if (resultCode == Activity.RESULT_OK) {
                // Get result from ScannerResultHolder (enhanced with session tracking)
                String scannedDocumentPath = ScannerResultHolder.lastResult;
                if (scannedDocumentPath != null) {
                    successCallback.invoke(scannedDocumentPath);
                    
                    // Clear scan state after successful delivery
                    ScannerResultHolder.setScanInProgress(getReactApplicationContext(), false);
                    Log.d("Scanner Module", "Scan completed successfully");
                } else {
                    errorCallback.invoke("No document path received");
                    ScannerResultHolder.setScanInProgress(getReactApplicationContext(), false);
                }
            } else if (resultCode == Activity.RESULT_CANCELED) {
                String errorMessage = "Scan canceled";
                if (data != null && data.hasExtra("error")) {
                    errorMessage = data.getStringExtra("error");
                }
                errorCallback.invoke(errorMessage);
                ScannerResultHolder.setScanInProgress(getReactApplicationContext(), false);
                Log.d("Scanner Module", "Scan cancelled by user");
            } else {
                errorCallback.invoke("Scan failed");
                ScannerResultHolder.setScanInProgress(getReactApplicationContext(), false);
                Log.d("Scanner Module", "Scan failed with result code: " + resultCode);
            }
        }
    }

    @Override
    public void onNewIntent(Intent intent) {
        // Not needed for scanning functionality
    }
    
    /**
     * Check for pending scan results after process restart
     * This is called automatically when the module is initialized
     */
    private void checkForPendingResults() {
        try {
            if (ScannerResultHolder.hasPendingResult(getReactApplicationContext())) {
                Log.d("Scanner Module", "Found pending scan result after process restart");
                // Result will be available via getLastScanResult() or checkForCrashRecovery() method from JS
            } else {
                Log.d("Scanner Module", "No pending scan results found");
            }
        } catch (Exception e) {
            Log.e("Scanner Module", "Error checking for pending results", e);
        }
    }
    
    /**
     * Get the last scan result (legacy method for backward compatibility)
     * @param promise Promise to resolve with the last scan result or null
     */
    @ReactMethod
    public void getLastScanResult(Promise promise) {
        try {
            String result = ScannerResultHolder.getLastResult(getReactApplicationContext());
            if (result != null) {
                WritableMap map = Arguments.createMap();
                map.putString("scanResult", result);
                promise.resolve(map);
                Log.d("Scanner Module", "Returned last scan result");
            } else {
                promise.resolve(null);
                Log.d("Scanner Module", "No last scan result available");
            }
        } catch (Exception e) {
            promise.reject("E_GET_RESULT_FAILED", "Failed to get last scan result", e);
        }
    }
    
    /**
     * Enhanced crash recovery method - only returns results from interrupted current session
     * This is the key method that provides session-based crash recovery
     * 
     * @param promise Promise to resolve with recovery data or null
     */
    @ReactMethod
    public void checkForCrashRecovery(Promise promise) {
        try {
            boolean hasPending = ScannerResultHolder.hasPendingResult(getReactApplicationContext());
            
            if (hasPending) {
                // Get result ONLY from the current interrupted scan session
                String result = ScannerResultHolder.getCurrentSessionResult(getReactApplicationContext());
                
                if (result != null) {
                    WritableMap map = Arguments.createMap();
                    map.putString("scanResult", result);
                    map.putBoolean("fromCrashRecovery", true);
                    
                    // Clear the state after recovery
                    ScannerResultHolder.setScanInProgress(getReactApplicationContext(), false);
                    
                    promise.resolve(map);
                    Log.d("Scanner Module", "Recovered scan result from interrupted session");
                    return;
                }
            }
            
            Log.d("Scanner Module", "No pending results from current scan session");
            promise.resolve(null);
        } catch (Exception e) {
            Log.e("Scanner Module", "Error during crash recovery check", e);
            promise.reject("E_RECOVERY_FAILED", "Failed to recover scan result", e);
        }
    }
    
    /**
     * Clear all cached scan data
     * Useful for testing or manual cleanup
     */
    @ReactMethod  
    public void clearScanCache(Promise promise) {
        try {
            ScannerResultHolder.clearLastResult(getReactApplicationContext());
            promise.resolve(true);
            Log.d("Scanner Module", "Scan cache cleared successfully");
        } catch (Exception e) {
            Log.e("Scanner Module", "Error clearing scan cache", e);
            promise.reject("E_CLEAR_FAILED", "Failed to clear scan cache", e);
        }
    }
}