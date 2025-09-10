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


@objc(NativeDocScanner)
class NativeDocScanner: NSObject, RCTBridgeModule{
  
  static func moduleName() -> String! {
    return "NativeDocScanner"
  }
  
  // Optional properties to hold the callbacks
  var successCallback: RCTResponseSenderBlock?
  var errorCallback: RCTResponseSenderBlock?
  
  
  @objc func scanDocument(_ config:NSDictionary, onSuccess successCallback: @escaping RCTResponseSenderBlock, onError errorCallback: @escaping RCTResponseSenderBlock) {
    
    self.successCallback = successCallback
    self.errorCallback = errorCallback
    
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




extension ScannerModule:VNDocumentCameraViewControllerDelegate {
  
  func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
    controller.dismiss(animated: true, completion: nil)
    
    
    var scannedImages: [String] = [];
    var result:[String:Any] = [String:Any]();
    let pdfDocument = PDFDocument()
    
    for pageIndex in 0..<scan.pageCount {
      let image = scan.imageOfPage(at: pageIndex)
      
      if let path = ScannerFileUtils.saveImage(image: image, withName: "scanned_document_page_\(pageIndex)") {
        scannedImages.append(path);
      }
      
      
      guard let resizedImage = ScannerFileUtils.resizeImage(image: image, targetSize: CGSize(width: 595, height: 842)) else{
        return
      };
      
      
      if let pdfPage = PDFPage(image: resizedImage) {
        pdfDocument.insert(pdfPage, at: pageIndex)
      }
      
    }
    
    guard let pdfPath = ScannerFileUtils.savePDF(document: pdfDocument, withName: "scanned_pdf") else {
      return
    }
    
    result["imagePaths"] = scannedImages;
    result["isPdfAvailable"] = true;
    result["PdfUri"] = pdfPath;
    result["PdfPageCount"] = scan.pageCount;
    
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
      if let jsonString = String(data: jsonData, encoding: .utf8) {
        // Check if successCallback exists, and call it
        if let success = self.successCallback {
          success([jsonString])
        }
      } else {
        // Call the error callback if JSON encoding fails
        let error = NSError(domain: "com.myapp.error", code: 102, userInfo: [NSLocalizedDescriptionKey: "Failed to encode JSON string"])
        self.errorCallback?([error.localizedDescription])
      }
    } catch {
      // Call the error callback in case of an exception during JSON serialization
      self.errorCallback?([error.localizedDescription])
      print("Failed to convert dictionary to jsonString \(error)")
    }
    
  }
  
  func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
    controller.dismiss(animated: true, completion: nil)
    self.errorCallback?([error.localizedDescription]);
    //reject?("E_SCAN_FAILED", error.localizedDescription, error);
    //errorCallback(["E_SCAN_FAILED", error.localizedDescription,error])
  }
  
  func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    controller.dismiss(animated: true, completion: nil)
    self.errorCallback?(["E_SCAN_CANCELLED", "User cancelled document scan"]);
    //reject?("E_SCAN_CANCELLED", "User cancelled document scan", nil)
    //errorCallback(["E_SCAN_CANCELLED", "User cancelled document scan"])
  }
}


