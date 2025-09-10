package com.nativedocscanner;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;
import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReadableMap;

import java.util.HashMap;


public class NativeDocScannerModule extends ReactContextBaseJavaModule implements ActivityEventListener {

    ReactApplicationContext mContext;
    private static final int SCANNER_REQUEST_CODE = 1001;
    private Callback successCallback;
    private Callback errorCallback;

    NativeDocScannerModule(ReactApplicationContext context) {

        super(context);
        this.mContext = context;
        Log.d("Scanner Module","Constructed Executed");
        context.addActivityEventListener(this);

    }

    @Override
    public String getName() {
        return "NativeDocScanner";
    }

    @ReactMethod
    public void scanDocument(ReadableMap scannerConfig,Callback successCallback, Callback errorCallback) {
        // Call your existing scanner functionality here
        try {
            this.successCallback = successCallback;
            this.errorCallback = errorCallback;

            Activity currentActivity = getCurrentActivity();

            if (currentActivity == null) {
                errorCallback.invoke("Activity doesn't exist");
                return;
            }
            HashMap<String,Object> config = Utils.convertReadableMapToHashMap(scannerConfig);
            Intent intent = new Intent(currentActivity, ScannerActivity.class); // Replace with your activity class
            intent.putExtra("scannerConfig", config);
            currentActivity.startActivityForResult(intent, SCANNER_REQUEST_CODE);

        } catch (Exception e) {
            errorCallback.invoke(e.getMessage());
        }
    }


    @Override
    public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {

        Log.d("Scanner Module","called" );

        if (requestCode == SCANNER_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                String scannedDocumentPath = data.getStringExtra("ScanResult");
                if (scannedDocumentPath != null) {
                    successCallback.invoke(scannedDocumentPath);
                } else {
                    errorCallback.invoke("No document path received");
                }
            } else if (resultCode == Activity.RESULT_CANCELED) {
                errorCallback.invoke("Scan canceled");
            } else {
                errorCallback.invoke("Scan failed");
            }
        }
    }

    @Override
    public void onNewIntent(Intent intent) {

    }
}