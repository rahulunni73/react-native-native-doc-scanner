package com.nativedocscanner;

import android.content.Context;
import android.util.Log;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;

/**
 * Enhanced session-based crash recovery system for document scanning
 * 
 * This class provides comprehensive crash recovery by tracking scan sessions
 * and ensuring only results from the current interrupted session are recovered.
 * 
 * Features:
 * - Session-based result tracking with timestamps
 * - Process kill detection and recovery
 * - Memory management during low-memory conditions
 * - Cross-platform result format consistency
 * 
 * @version 2.0.0 with session-based crash recovery
 */
public class ScannerResultHolder {

    private static final String TAG = "ScannerResultHolder";
    private static final String CACHE_FILE = "last_scan.json";
    private static final String STATE_FILE = "scan_state.json";
    private static final String SESSION_FILE = "scan_session.json";

    // Keeps result in memory for current process
    public static String lastResult = null;
    
    // Enhanced session tracking
    public static boolean isScanInProgress = false;
    public static long currentScanStartTime = 0;

    /** 
     * Save result to memory + file with current session timestamp 
     * This ensures results are associated with the correct scan session
     */
    public static void setLastResult(Context context, String result) {
        lastResult = result;
        saveToCache(context, result);
        
        // Save result with session timestamp for crash recovery
        saveScanResultWithSession(context, result, currentScanStartTime);
        Log.d(TAG, "Scan result saved with session timestamp: " + currentScanStartTime);
    }

    /** 
     * Get result (from memory if possible, otherwise from cache) 
     * This is the legacy method for backward compatibility
     */
    public static String getLastResult(Context context) {
        if (lastResult != null) return lastResult;
        return readFromCache(context);
    }

    /** 
     * Clear both memory + cache + session data
     * Comprehensive cleanup of all scan-related files
     */
    public static void clearLastResult(Context context) {
        lastResult = null;
        isScanInProgress = false;
        currentScanStartTime = 0;
        
        // Clean up cache file
        File cacheFile = new File(context.getCacheDir(), CACHE_FILE);
        if (cacheFile.exists()) {
            boolean deleted = cacheFile.delete();
            Log.d(TAG, "Cache file deleted: " + deleted);
        }
        
        // Clean up state file
        File stateFile = new File(context.getCacheDir(), STATE_FILE);
        if (stateFile.exists()) {
            boolean deleted = stateFile.delete();
            Log.d(TAG, "State file deleted: " + deleted);
        }
        
        // Clean up session file
        File sessionFile = new File(context.getCacheDir(), SESSION_FILE);
        if (sessionFile.exists()) {
            boolean deleted = sessionFile.delete();
            Log.d(TAG, "Session file deleted: " + deleted);
        }
        
        // Clean up session-specific result files
        try {
            File[] sessionResults = context.getCacheDir().listFiles(
                (dir, name) -> name.startsWith("scan_result_") && name.endsWith(".json")
            );
            if (sessionResults != null) {
                for (File sessionFile : sessionResults) {
                    boolean deleted = sessionFile.delete();
                    Log.d(TAG, "Session result file deleted: " + sessionFile.getName() + " (" + deleted + ")");
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error cleaning session result files", e);
        }
    }
    
    /** 
     * Mark scan as started with timestamp tracking
     * This creates a unique session identifier for crash recovery
     */
    public static void setScanInProgress(Context context, boolean inProgress) {
        isScanInProgress = inProgress;
        if (inProgress) {
            currentScanStartTime = System.currentTimeMillis();
            saveScanSession(context, currentScanStartTime);
            Log.d(TAG, "Scan session started with timestamp: " + currentScanStartTime);
        } else {
            Log.d(TAG, "Scan session ended");
        }
        saveScanState(context, inProgress);
    }
    
    /** 
     * Check if scan was in progress before process restart 
     */
    public static boolean wasScanInProgress(Context context) {
        return readScanState(context);
    }
    
    /** 
     * Check if there's a pending result from the CURRENT scan session only
     * This prevents showing old results from previous scan attempts
     */
    public static boolean hasPendingResult(Context context) {
        if (!wasScanInProgress(context)) {
            Log.d(TAG, "No scan was in progress, no pending results");
            return false;
        }
        
        // Get the session timestamp from when scan started
        long sessionStartTime = readScanSession(context);
        if (sessionStartTime == 0) {
            Log.d(TAG, "No valid session timestamp found");
            return false;
        }
        
        // Check if there's a scan result from this specific session
        String sessionResult = getScanResultFromSession(context, sessionStartTime);
        boolean hasPending = sessionResult != null;
        
        Log.d(TAG, "Pending result check - Session: " + sessionStartTime + ", Has Result: " + hasPending);
        return hasPending;
    }
    
    /** 
     * Get scan result only if it belongs to the current interrupted session
     * This is the key method that ensures crash recovery accuracy
     */
    public static String getCurrentSessionResult(Context context) {
        if (!wasScanInProgress(context)) {
            Log.d(TAG, "No scan in progress, returning null");
            return null;
        }
        
        long sessionStartTime = readScanSession(context);
        if (sessionStartTime == 0) {
            Log.d(TAG, "No session timestamp, returning null");
            return null;
        }
        
        String sessionResult = getScanResultFromSession(context, sessionStartTime);
        Log.d(TAG, "Current session result retrieved for session: " + sessionStartTime + 
              " (result available: " + (sessionResult != null) + ")");
        
        return sessionResult;
    }

    // ---------- Enhanced File Management ----------

    /**
     * Save scan result to legacy cache (for backward compatibility)
     */
    private static void saveToCache(Context context, String json) {
        try {
            File file = new File(context.getCacheDir(), CACHE_FILE);
            FileWriter writer = new FileWriter(file, false);
            writer.write(json);
            writer.close();
            Log.d(TAG, "Saved scan result to legacy cache: " + file.getAbsolutePath());
        } catch (IOException e) {
            Log.e(TAG, "Error saving scan cache", e);
        }
    }

    /**
     * Read scan result from legacy cache
     */
    private static String readFromCache(Context context) {
        try {
            File file = new File(context.getCacheDir(), CACHE_FILE);
            if (!file.exists()) return null;
            byte[] bytes = Files.readAllBytes(file.toPath());
            return new String(bytes, StandardCharsets.UTF_8);
        } catch (Exception e) {
            Log.e(TAG, "Error reading scan cache", e);
            return null;
        }
    }
    
    /**
     * Save current scan state (in progress or not)
     */
    private static void saveScanState(Context context, boolean inProgress) {
        try {
            File file = new File(context.getCacheDir(), STATE_FILE);
            FileWriter writer = new FileWriter(file, false);
            writer.write(String.valueOf(inProgress));
            writer.close();
            Log.d(TAG, "Saved scan state: " + inProgress);
        } catch (IOException e) {
            Log.e(TAG, "Error saving scan state", e);
        }
    }
    
    /**
     * Read current scan state
     */
    private static boolean readScanState(Context context) {
        try {
            File file = new File(context.getCacheDir(), STATE_FILE);
            if (!file.exists()) return false;
            byte[] bytes = Files.readAllBytes(file.toPath());
            String state = new String(bytes, StandardCharsets.UTF_8);
            return Boolean.parseBoolean(state);
        } catch (Exception e) {
            Log.e(TAG, "Error reading scan state", e);
            return false;
        }
    }
    
    /**
     * Save scan session timestamp
     */
    private static void saveScanSession(Context context, long timestamp) {
        try {
            File file = new File(context.getCacheDir(), SESSION_FILE);
            FileWriter writer = new FileWriter(file, false);
            writer.write(String.valueOf(timestamp));
            writer.close();
            Log.d(TAG, "Saved scan session timestamp: " + timestamp);
        } catch (IOException e) {
            Log.e(TAG, "Error saving scan session", e);
        }
    }
    
    /**
     * Read scan session timestamp
     */
    private static long readScanSession(Context context) {
        try {
            File file = new File(context.getCacheDir(), SESSION_FILE);
            if (!file.exists()) return 0;
            byte[] bytes = Files.readAllBytes(file.toPath());
            String timestamp = new String(bytes, StandardCharsets.UTF_8);
            return Long.parseLong(timestamp);
        } catch (Exception e) {
            Log.e(TAG, "Error reading scan session", e);
            return 0;
        }
    }
    
    /**
     * Save scan result with session information for precise crash recovery
     */
    private static void saveScanResultWithSession(Context context, String result, long sessionTimestamp) {
        try {
            // Create a JSON object that includes both result and session info
            org.json.JSONObject sessionData = new org.json.JSONObject();
            sessionData.put("result", result);
            sessionData.put("sessionTimestamp", sessionTimestamp);
            sessionData.put("resultTimestamp", System.currentTimeMillis());
            sessionData.put("version", "2.0.0"); // Track format version
            
            String filename = "scan_result_" + sessionTimestamp + ".json";
            File file = new File(context.getCacheDir(), filename);
            FileWriter writer = new FileWriter(file, false);
            writer.write(sessionData.toString());
            writer.close();
            Log.d(TAG, "Saved scan result for session " + sessionTimestamp + " to " + filename);
        } catch (Exception e) {
            Log.e(TAG, "Error saving scan result with session", e);
        }
    }
    
    /**
     * Get scan result from specific session (crash recovery core logic)
     */
    private static String getScanResultFromSession(Context context, long sessionTimestamp) {
        try {
            String filename = "scan_result_" + sessionTimestamp + ".json";
            File file = new File(context.getCacheDir(), filename);
            if (!file.exists()) {
                Log.d(TAG, "Session result file does not exist: " + filename);
                return null;
            }
            
            byte[] bytes = Files.readAllBytes(file.toPath());
            String json = new String(bytes, StandardCharsets.UTF_8);
            
            org.json.JSONObject sessionData = new org.json.JSONObject(json);
            long savedSessionTimestamp = sessionData.getLong("sessionTimestamp");
            
            // Verify this result belongs to the requested session
            if (savedSessionTimestamp == sessionTimestamp) {
                String result = sessionData.getString("result");
                Log.d(TAG, "Successfully retrieved result for session: " + sessionTimestamp);
                return result;
            } else {
                Log.w(TAG, "Session timestamp mismatch: expected " + sessionTimestamp + 
                      ", found " + savedSessionTimestamp);
                return null;
            }
        } catch (Exception e) {
            Log.e(TAG, "Error reading scan result from session " + sessionTimestamp, e);
            return null;
        }
    }
}