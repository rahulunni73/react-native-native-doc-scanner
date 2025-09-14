//
//  ScannerResultHolder.swift
//  ReactNativeNativeDocScanner
//
//  Enhanced session-based crash recovery system for iOS
//  Provides consistency with Android implementation
//

import Foundation

class ScannerResultHolder {
    
    private static let CACHE_KEY = "last_scan_result"
    private static let STATE_KEY = "scan_state"
    private static let SESSION_KEY = "scan_session"
    private static let SESSION_RESULT_PREFIX = "scan_result_"
    
    // Static properties for current session tracking
    static var lastResult: String?
    static var isScanInProgress = false
    static var currentScanStartTime: Int64 = 0
    
    // MARK: - Public Methods
    
    /**
     * Save result to memory + UserDefaults with current session timestamp
     */
    static func setLastResult(_ result: String) {
        lastResult = result
        saveToUserDefaults(result)
        
        // Save result with session timestamp for crash recovery
        saveScanResultWithSession(result, sessionTimestamp: currentScanStartTime)
        print("[ScannerResultHolder] Scan result saved with session timestamp: \(currentScanStartTime)")
    }
    
    /**
     * Get result (from memory if possible, otherwise from UserDefaults)
     */
    static func getLastResult() -> String? {
        if let result = lastResult {
            return result
        }
        return readFromUserDefaults()
    }
    
    /**
     * Clear both memory + UserDefaults + session data
     */
    static func clearLastResult() {
        lastResult = nil
        isScanInProgress = false
        currentScanStartTime = 0
        
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: CACHE_KEY)
        defaults.removeObject(forKey: STATE_KEY)
        defaults.removeObject(forKey: SESSION_KEY)
        
        // Clean up session-specific result files
        cleanupSessionResults()
        
        print("[ScannerResultHolder] All scan data cleared")
    }
    
    /**
     * Mark scan as started with timestamp tracking
     */
    static func setScanInProgress(_ inProgress: Bool) {
        isScanInProgress = inProgress
        if inProgress {
            currentScanStartTime = Int64(Date().timeIntervalSince1970 * 1000)
            saveScanSession(currentScanStartTime)
            print("[ScannerResultHolder] Scan session started with timestamp: \(currentScanStartTime)")
        } else {
            print("[ScannerResultHolder] Scan session ended")
        }
        saveScanState(inProgress)
    }
    
    /**
     * Check if scan was in progress before app restart/crash
     */
    static func wasScanInProgress() -> Bool {
        return readScanState()
    }
    
    /**
     * Check if there's a pending result from the CURRENT scan session only
     */
    static func hasPendingResult() -> Bool {
        if !wasScanInProgress() {
            print("[ScannerResultHolder] No scan was in progress, no pending results")
            return false
        }
        
        let sessionStartTime = readScanSession()
        if sessionStartTime == 0 {
            print("[ScannerResultHolder] No valid session timestamp found")
            return false
        }
        
        let sessionResult = getScanResultFromSession(sessionStartTime)
        let hasPending = sessionResult != nil
        
        print("[ScannerResultHolder] Pending result check - Session: \(sessionStartTime), Has Result: \(hasPending)")
        return hasPending
    }
    
    /**
     * Get scan result only if it belongs to the current interrupted session
     */
    static func getCurrentSessionResult() -> String? {
        if !wasScanInProgress() {
            print("[ScannerResultHolder] No scan in progress, returning nil")
            return nil
        }
        
        let sessionStartTime = readScanSession()
        if sessionStartTime == 0 {
            print("[ScannerResultHolder] No session timestamp, returning nil")
            return nil
        }
        
        let sessionResult = getScanResultFromSession(sessionStartTime)
        print("[ScannerResultHolder] Current session result retrieved for session: \(sessionStartTime) (result available: \(sessionResult != nil))")
        
        return sessionResult
    }
    
    // MARK: - Private Methods
    
    private static func saveToUserDefaults(_ result: String) {
        UserDefaults.standard.set(result, forKey: CACHE_KEY)
        print("[ScannerResultHolder] Saved scan result to UserDefaults")
    }
    
    private static func readFromUserDefaults() -> String? {
        return UserDefaults.standard.string(forKey: CACHE_KEY)
    }
    
    private static func saveScanState(_ inProgress: Bool) {
        UserDefaults.standard.set(inProgress, forKey: STATE_KEY)
        print("[ScannerResultHolder] Saved scan state: \(inProgress)")
    }
    
    private static func readScanState() -> Bool {
        return UserDefaults.standard.bool(forKey: STATE_KEY)
    }
    
    private static func saveScanSession(_ timestamp: Int64) {
        UserDefaults.standard.set(timestamp, forKey: SESSION_KEY)
        print("[ScannerResultHolder] Saved scan session timestamp: \(timestamp)")
    }
    
    private static func readScanSession() -> Int64 {
        return UserDefaults.standard.object(forKey: SESSION_KEY) as? Int64 ?? 0
    }
    
    private static func saveScanResultWithSession(_ result: String, sessionTimestamp: Int64) {
        let sessionData: [String: Any] = [
            "result": result,
            "sessionTimestamp": sessionTimestamp,
            "resultTimestamp": Int64(Date().timeIntervalSince1970 * 1000),
            "version": "2.0.0"
        ]
        
        let sessionKey = "\(SESSION_RESULT_PREFIX)\(sessionTimestamp)"
        UserDefaults.standard.set(sessionData, forKey: sessionKey)
        print("[ScannerResultHolder] Saved scan result for session \(sessionTimestamp)")
    }
    
    private static func getScanResultFromSession(_ sessionTimestamp: Int64) -> String? {
        let sessionKey = "\(SESSION_RESULT_PREFIX)\(sessionTimestamp)"
        
        guard let sessionData = UserDefaults.standard.dictionary(forKey: sessionKey) else {
            print("[ScannerResultHolder] Session result does not exist for key: \(sessionKey)")
            return nil
        }
        
        guard let savedSessionTimestamp = sessionData["sessionTimestamp"] as? Int64,
              savedSessionTimestamp == sessionTimestamp else {
            print("[ScannerResultHolder] Session timestamp mismatch")
            return nil
        }
        
        guard let result = sessionData["result"] as? String else {
            print("[ScannerResultHolder] No result found in session data")
            return nil
        }
        
        print("[ScannerResultHolder] Successfully retrieved result for session: \(sessionTimestamp)")
        return result
    }
    
    private static func cleanupSessionResults() {
        let defaults = UserDefaults.standard
        let allKeys = Array(defaults.dictionaryRepresentation().keys)
        
        for key in allKeys {
            if key.hasPrefix(SESSION_RESULT_PREFIX) {
                defaults.removeObject(forKey: key)
                print("[ScannerResultHolder] Removed session result: \(key)")
            }
        }
    }
}