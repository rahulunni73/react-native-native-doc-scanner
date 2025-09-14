//
//  NativeDocScannerBridge.m
//  ReactNativeNativeDocScanner
//
//  Bridge file for exposing Swift module to React Native
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(NativeDocScanner, NSObject)

RCT_EXTERN_METHOD(scanDocument:(NSDictionary *)config
                  onSuccess:(RCTResponseSenderBlock)successCallback
                  onError:(RCTResponseSenderBlock)errorCallback)

RCT_EXTERN_METHOD(checkForCrashRecovery:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getLastScanResult:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(clearScanCache:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end