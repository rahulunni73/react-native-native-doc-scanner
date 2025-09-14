//
//  ScannerModule.swift
//  Ospyndocs
//
//  Created by Ospyn on 29/10/24.
//

import Foundation
import UIKit
import VisionKit
import PDFKit
import React


@objc(NativeDocScanner)
class NativeDocScanner: NSObject, RCTBridgeModule{
  
  static func moduleName() -> String! {
    return "NativeDocScanner"
  }
  
  // Optional properties to hold the callbacks
  var successCallback: RCTResponseSenderBlock?
  var errorCallback: RCTResponseSenderBlock?
  
  // Size tracking properties
  var cumulativeSize: Int64 = 0
  var sizeLimit: Int64 = 100 * 1024 * 1024 // 100MB default
  var imageSizes: [String: Int64] = [:]
  var scanConfig: NSDictionary?
  
  
  @objc func scanDocument(_ config:NSDictionary, onSuccess successCallback: @escaping RCTResponseSenderBlock, onError errorCallback: @escaping RCTResponseSenderBlock) {
    
    self.successCallback = successCallback
    self.errorCallback = errorCallback
    self.scanConfig = config
    
    // Reset size tracking
    self.cumulativeSize = 0
    self.imageSizes.removeAll()
    
    // Set custom size limit if provided
    if let maxSize = config["maxSizeLimit"] as? NSNumber {
      self.sizeLimit = maxSize.int64Value
    } else {
      self.sizeLimit = 100 * 1024 * 1024 // 100MB default
    }
    
    // Mark scan as started for crash recovery
    ScannerResultHolder.setScanInProgress(true)
    
    DispatchQueue.main.async {
      guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
        errorCallback(["E_NO_ROOT_VIEW", "Could not find root view controller"])
        return
      }
      
      if VNDocumentCameraViewController.isSupported {
        let documentCameraVC = VNDocumentCameraViewController()
        documentCameraVC.delegate = self
        rootViewController.present(documentCameraVC, animated: true, completion: nil)
      } else {
        errorCallback(["E_CAMERA_NOT_SUPPORTED", "Document scanning is not supported on this device"])
      }
    }
  }
  
}




extension NativeDocScanner:VNDocumentCameraViewControllerDelegate {
  
  func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
    controller.dismiss(animated: true, completion: nil)
    
    var scannedImages: [String] = []
    var result:[String:Any] = [String:Any]()
    let pdfDocument = PDFDocument()
    var totalImageSize: Int64 = 0
    var imageSizesDict: [String: Int64] = [:]
    
    // First pass: calculate total size and check limit
    for pageIndex in 0..<scan.pageCount {
      let image = scan.imageOfPage(at: pageIndex)
      let imageSize = self.calculateImageSize(image: image)
      
      if (totalImageSize + imageSize) > self.sizeLimit {
        // Size limit exceeded - show alert and stop processing
        DispatchQueue.main.async {
          self.showSizeExceededAlert(controller: controller, currentSize: totalImageSize, imageSize: imageSize, pageIndex: pageIndex)
        }
        return
      }
      
      totalImageSize += imageSize
      imageSizesDict["image \(pageIndex)"] = imageSize
    }
    
    // Second pass: process and save images if size check passed
    for pageIndex in 0..<scan.pageCount {
      let image = scan.imageOfPage(at: pageIndex)
      
      if let path = ScannerFileUtils.saveImage(image: image, withName: "scanned_document_page_\(pageIndex)") {
        scannedImages.append(path)
      }
      
      guard let resizedImage = ScannerFileUtils.resizeImage(image: image, targetSize: CGSize(width: 595, height: 842)) else{
        return
      }
      
      if let pdfPage = PDFPage(image: resizedImage) {
        pdfDocument.insert(pdfPage, at: pageIndex)
      }
    }
    
    guard let pdfPath = ScannerFileUtils.savePDF(document: pdfDocument, withName: "scanned_pdf") else {
      return
    }
    
    // Calculate PDF size
    let pdfSize = self.calculatePDFSize(pdfPath: pdfPath)
    
    result["imagePaths"] = scannedImages
    result["isPdfAvailable"] = true
    result["PdfUri"] = pdfPath
    result["PdfPageCount"] = scan.pageCount
    result["totalImageSize"] = totalImageSize
    result["pdfSize"] = pdfSize
    result["imageSizes"] = imageSizesDict
    
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
      if let jsonString = String(data: jsonData, encoding: .utf8) {
        // Save result for crash recovery
        ScannerResultHolder.setLastResult(jsonString)
        
        // Check if successCallback exists, and call it
        if let success = self.successCallback {
          success([jsonString])
          
          // Clear scan state after successful delivery
          ScannerResultHolder.setScanInProgress(false)
          print("Scan completed successfully")
        }
      } else {
        // Call the error callback if JSON encoding fails
        let error = NSError(domain: "com.myapp.error", code: 102, userInfo: [NSLocalizedDescriptionKey: "Failed to encode JSON string"])
        self.errorCallback?([error.localizedDescription])
        ScannerResultHolder.setScanInProgress(false)
      }
    } catch {
      // Call the error callback in case of an exception during JSON serialization
      self.errorCallback?([error.localizedDescription])
      ScannerResultHolder.setScanInProgress(false)
      print("Failed to convert dictionary to jsonString \(error)")
    }
    
  }
  
  func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
    controller.dismiss(animated: true, completion: nil)
    ScannerResultHolder.setScanInProgress(false)
    self.errorCallback?([error.localizedDescription]);
    //reject?("E_SCAN_FAILED", error.localizedDescription, error);
    //errorCallback(["E_SCAN_FAILED", error.localizedDescription,error])
  }
  
  func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    controller.dismiss(animated: true, completion: nil)
    ScannerResultHolder.setScanInProgress(false)
    self.errorCallback?(["E_SCAN_CANCELLED", "User cancelled document scan"]);
    //reject?("E_SCAN_CANCELLED", "User cancelled document scan", nil)
    //errorCallback(["E_SCAN_CANCELLED", "User cancelled document scan"])
  }
  
  // MARK: - Size Calculation Methods
  
  private func calculateImageSize(image: UIImage) -> Int64 {
    guard let imageData = image.jpegData(compressionQuality: 1.0) else {
      return 0
    }
    return Int64(imageData.count)
  }
  
  private func calculatePDFSize(pdfPath: String) -> Int64 {
    do {
      let fileAttributes = try FileManager.default.attributesOfItem(atPath: pdfPath)
      if let fileSize = fileAttributes[FileAttributeKey.size] as? NSNumber {
        return fileSize.int64Value
      }
    } catch {
      print("Error calculating PDF size: \(error)")
    }
    return 0
  }
  
  private func formatSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
  
  // MARK: - Size Limit Alert
  
  private func showSizeExceededAlert(controller: VNDocumentCameraViewController, currentSize: Int64, imageSize: Int64, pageIndex: Int) {
    let alert = UIAlertController(
      title: "Size Limit Exceeded",
      message: "Adding page \(pageIndex + 1) would exceed the \(formatSize(sizeLimit)) limit.\n\nCurrent total: \(formatSize(currentSize))\nPage size: \(formatSize(imageSize))",
      preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "Cancel Scanning", style: .destructive) { _ in
      ScannerResultHolder.setScanInProgress(false)
      self.errorCallback?(["SIZE_LIMIT_EXCEEDED", "File size limit exceeded. Scanning cancelled."])
    })
    
    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
      ScannerResultHolder.setScanInProgress(false)
      self.errorCallback?(["SIZE_LIMIT_EXCEEDED", "File size limit exceeded. Scanning cancelled."])
    })
    
    controller.present(alert, animated: true)
  }
  
  private func processPagesUpToLimit(scan: VNDocumentCameraScan?, maxPages: Int) {
    guard let scan = scan, maxPages > 0 else {
      self.errorCallback?(["SIZE_LIMIT_EXCEEDED", "No pages could be processed within size limit."])
      return
    }
    
    var scannedImages: [String] = []
    var result:[String:Any] = [String:Any]()
    let pdfDocument = PDFDocument()
    var totalImageSize: Int64 = 0
    var imageSizesDict: [String: Int64] = [:]
    
    // Process only pages up to the limit
    for pageIndex in 0..<min(maxPages, scan.pageCount) {
      let image = scan.imageOfPage(at: pageIndex)
      let imageSize = self.calculateImageSize(image: image)
      
      totalImageSize += imageSize
      imageSizesDict["image \(pageIndex)"] = imageSize
      
      if let path = ScannerFileUtils.saveImage(image: image, withName: "scanned_document_page_\(pageIndex)") {
        scannedImages.append(path)
      }
      
      guard let resizedImage = ScannerFileUtils.resizeImage(image: image, targetSize: CGSize(width: 595, height: 842)) else{
        continue
      }
      
      if let pdfPage = PDFPage(image: resizedImage) {
        pdfDocument.insert(pdfPage, at: pageIndex)
      }
    }
    
    guard let pdfPath = ScannerFileUtils.savePDF(document: pdfDocument, withName: "scanned_pdf") else {
      self.errorCallback?(["SAVE_FAILED", "Failed to save PDF document."])
      return
    }
    
    let pdfSize = self.calculatePDFSize(pdfPath: pdfPath)
    
    result["imagePaths"] = scannedImages
    result["isPdfAvailable"] = true
    result["PdfUri"] = pdfPath
    result["PdfPageCount"] = maxPages
    result["totalImageSize"] = totalImageSize
    result["pdfSize"] = pdfSize
    result["imageSizes"] = imageSizesDict
    
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
      if let jsonString = String(data: jsonData, encoding: .utf8) {
        if let success = self.successCallback {
          success([jsonString])
        }
      } else {
        let error = NSError(domain: "com.myapp.error", code: 102, userInfo: [NSLocalizedDescriptionKey: "Failed to encode JSON string"])
        self.errorCallback?([error.localizedDescription])
      }
    } catch {
      self.errorCallback?([error.localizedDescription])
      print("Failed to convert dictionary to jsonString \(error)")
    }
  }
  
  // MARK: - Crash Recovery Methods
  
  /**
   * Check for scan results from interrupted sessions (crash recovery)
   * Only returns results from the current interrupted scan session
   */
  @objc func checkForCrashRecovery(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    let hasPending = ScannerResultHolder.hasPendingResult()
    
    if hasPending {
      if let result = ScannerResultHolder.getCurrentSessionResult() {
        let recoveryData: [String: Any] = [
          "scanResult": result,
          "fromCrashRecovery": true
        ]
        
        // Clear the state after recovery
        ScannerResultHolder.setScanInProgress(false)
        
        resolve(recoveryData)
        print("Recovered scan result from interrupted session")
        return
      }
    }
    
    print("No pending results from current scan session")
    resolve(nil)
  }
  
  /**
   * Get the last scan result (legacy method for backward compatibility)
   */
  @objc func getLastScanResult(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    if let result = ScannerResultHolder.getLastResult() {
      let resultData: [String: Any] = [
        "scanResult": result
      ]
      resolve(resultData)
      print("Returned last scan result")
    } else {
      resolve(nil)
      print("No last scan result available")
    }
  }
  
  /**
   * Clear all cached scan data
   * Useful for testing or manual cleanup
   */
  @objc func clearScanCache(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    ScannerResultHolder.clearLastResult()
    resolve(true)
    print("Scan cache cleared successfully")
  }
}


