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
class NativeDocScanner: NSObject, RCTBridgeModule {
  
  static func moduleName() -> String! {
    return "NativeDocScanner"
  }
  
  // MARK: - Properties
  var successCallback: RCTResponseSenderBlock?
  var errorCallback: RCTResponseSenderBlock?
  var cumulativeSize: Int64 = 0
  var sizeLimit: Int64 = 100 * 1024 * 1024 // 100MB default
  var imageSizes: [String: Int64] = [:]
  var scanConfig: NSDictionary?
  var compressionQuality: CGFloat = 1.0
  var maxImageDimension: CGFloat? = nil
  
  // MARK: - React Method
    @objc func scanDocument(
      _ config: NSDictionary,
      onSuccess successCallback: @escaping RCTResponseSenderBlock,
      onError errorCallback: @escaping RCTResponseSenderBlock
    ) {
      self.successCallback = successCallback
      self.errorCallback = errorCallback
      self.scanConfig = config
      
      self.cumulativeSize = 0
      self.imageSizes.removeAll()
      
      if let maxSize = config["maxSizeLimit"] as? NSNumber {
        self.sizeLimit = maxSize.int64Value
      } else {
        self.sizeLimit = 100 * 1024 * 1024
      }

      if let quality = config["compressionQuality"] as? NSNumber {
        self.compressionQuality = CGFloat(quality.doubleValue)
      } else {
        self.compressionQuality = 1.0
      }

      if let maxDim = config["maxImageDimension"] as? NSNumber {
        self.maxImageDimension = CGFloat(maxDim.doubleValue)
      } else {
        self.maxImageDimension = nil
      }
      
      DispatchQueue.main.async {
        guard let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let rootViewController = windowScene.windows
                .first(where: { $0.isKeyWindow })?.rootViewController else {
          errorCallback(["E_NO_ROOT_VIEW", "Could not find root view controller"])
          return
        }
        
        guard VNDocumentCameraViewController.isSupported else {
          errorCallback(["E_CAMERA_NOT_SUPPORTED", "Document scanning is not supported on this device"])
          return
        }
        
        let documentCameraVC = VNDocumentCameraViewController()
        documentCameraVC.delegate = self
        documentCameraVC.modalPresentationStyle = .fullScreen
        
        if let topVC = self.topViewController(from: rootViewController) {
          topVC.present(documentCameraVC, animated: true, completion: nil)
        } else {
          rootViewController.present(documentCameraVC, animated: true, completion: nil)
        }
      }
    }


  
  // MARK: - Presentation Helper
  private func presentScanner(_ scanner: VNDocumentCameraViewController, from viewController: UIViewController) {
    DispatchQueue.main.async {
      viewController.present(scanner, animated: true, completion: nil)
    }
  }
  
  // MARK: - Top View Controller Finder
  private func topViewController(from root: UIViewController?) -> UIViewController? {
    if let presented = root?.presentedViewController {
      return topViewController(from: presented)
    }
    if let nav = root as? UINavigationController {
      return topViewController(from: nav.visibleViewController)
    }
    if let tab = root as? UITabBarController {
      return topViewController(from: tab.selectedViewController)
    }
    return root
  }
}

// MARK: - VNDocumentCameraViewControllerDelegate
extension NativeDocScanner: VNDocumentCameraViewControllerDelegate {
  
  func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
    controller.dismiss(animated: true, completion: nil)
    
    var scannedImages: [String] = []
    var result: [String: Any] = [:]
    let pdfDocument = PDFDocument()
    var totalImageSize: Int64 = 0
    var imageSizesDict: [String: Int64] = [:]
    
    // First pass: size check
    for pageIndex in 0..<scan.pageCount {
      let image = scan.imageOfPage(at: pageIndex)
      let imageSize = self.calculateImageSize(image: image)
      
      if (totalImageSize + imageSize) > self.sizeLimit {
        DispatchQueue.main.async {
          self.showSizeExceededAlert(
            controller: controller,
            currentSize: totalImageSize,
            imageSize: imageSize,
            pageIndex: pageIndex
          )
        }
        return
      }
      totalImageSize += imageSize
      imageSizesDict["image \(pageIndex)"] = imageSize
    }
    
    // Second pass: save & build PDF
    for pageIndex in 0..<scan.pageCount {
      let image = scan.imageOfPage(at: pageIndex)
      
      if let path = ScannerFileUtils.saveImage(image: image, withName: "scanned_document_page_\(pageIndex)", compressionQuality: self.compressionQuality, maxImageDimension: self.maxImageDimension) {
        scannedImages.append(path)
      }
      
      guard let resizedImage = ScannerFileUtils.resizeImage(image: image, targetSize: CGSize(width: 595, height: 842)),
            let pdfPage = PDFPage(image: resizedImage) else { continue }
      
      pdfDocument.insert(pdfPage, at: pageIndex)
    }
    
    guard let pdfPath = ScannerFileUtils.savePDF(document: pdfDocument, withName: "scanned_pdf") else {
      self.errorCallback?(["E_SAVE_FAILED", "Failed to save PDF document."])
      return
    }
    
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
        self.successCallback?([jsonString])
      } else {
        throw NSError(domain: "com.ospyndocs.error", code: 102, userInfo: [NSLocalizedDescriptionKey: "Failed to encode JSON string"])
      }
    } catch {
      self.errorCallback?([error.localizedDescription])
    }
  }
  
  func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
    controller.dismiss(animated: true, completion: nil)
    self.errorCallback?([error.localizedDescription])
  }
  
  func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    controller.dismiss(animated: true, completion: nil)
    self.errorCallback?(["E_SCAN_CANCELLED", "User cancelled document scan"])
  }
}

// MARK: - Utilities
extension NativeDocScanner {
  
  private func calculateImageSize(image: UIImage) -> Int64 {
    let processedImage: UIImage
    if let maxDim = self.maxImageDimension {
      processedImage = ScannerFileUtils.resizeImageToMaxDimension(image: image, maxDimension: maxDim) ?? image
    } else {
      processedImage = image
    }
    guard let imageData = processedImage.jpegData(compressionQuality: self.compressionQuality) else { return 0 }
    return Int64(imageData.count)
  }
  
  private func calculatePDFSize(pdfPath: String) -> Int64 {
    do {
      let attrs = try FileManager.default.attributesOfItem(atPath: pdfPath)
      return (attrs[.size] as? NSNumber)?.int64Value ?? 0
    } catch {
      print("Error calculating PDF size: \(error)")
      return 0
    }
  }
  
  private func formatSize(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
  
  private func showSizeExceededAlert(controller: VNDocumentCameraViewController, currentSize: Int64, imageSize: Int64, pageIndex: Int) {
    let alert = UIAlertController(
      title: "Size Limit Exceeded",
      message: "Adding page \(pageIndex + 1) would exceed the \(formatSize(sizeLimit)) limit.\n\nCurrent total: \(formatSize(currentSize))\nPage size: \(formatSize(imageSize))",
      preferredStyle: .alert
    )
    
    alert.addAction(UIAlertAction(title: "OK", style: .destructive) { _ in
      self.errorCallback?(["SIZE_LIMIT_EXCEEDED", "File size limit exceeded. Scanning cancelled."])
    })
    
    controller.present(alert, animated: true)
  }
}
