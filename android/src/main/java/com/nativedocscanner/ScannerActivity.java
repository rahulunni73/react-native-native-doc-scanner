package com.nativedocscanner;
import android.app.Activity;
import android.content.Intent;
import android.content.IntentSender;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;

import androidx.activity.result.ActivityResult;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.IntentSenderRequest;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.FileProvider;

import com.google.gson.Gson;
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions;
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning;
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult;
import com.turbodocscanner.R;


import java.io.File;
import java.util.HashMap;
import java.util.Map;

public class ScannerActivity extends AppCompatActivity {

    private ActivityResultLauncher<IntentSenderRequest> scannerLauncher;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        scannerLauncher = registerForActivityResult(new ActivityResultContracts.StartIntentSenderForResult(), this::handleActivityResult);

        // Get the Intent and retrieve the HashMap
        Intent intent = getIntent();
        HashMap<String, Object> scannerConfig = (HashMap<String, Object>) intent.getSerializableExtra("scannerConfig");


        GmsDocumentScannerOptions options=null;

        if(scannerConfig != null ) {

            int pageLimit = (Integer) scannerConfig.get("pageLimit");

            boolean isGalleryImportRequired = (Boolean) scannerConfig.getOrDefault("isGalleryImportRequired", true);
            int scannerMode = (Integer) scannerConfig.getOrDefault("scannerMode", GmsDocumentScannerOptions.SCANNER_MODE_FULL);
            
            GmsDocumentScannerOptions.Builder builder = new GmsDocumentScannerOptions.Builder()
                    .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG, GmsDocumentScannerOptions.RESULT_FORMAT_PDF)
                    .setGalleryImportAllowed(isGalleryImportRequired)
                    .setScannerMode(scannerMode);
            
            if(pageLimit > 0) {
                builder.setPageLimit(pageLimit);
            }
            
            options = builder.build();

        }else{
            options = new GmsDocumentScannerOptions.Builder()
                    .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG, GmsDocumentScannerOptions.RESULT_FORMAT_PDF)
                    .setGalleryImportAllowed(true)
                    .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL)
                    .build();
        }

        GmsDocumentScanning.getClient(options)
                .getStartScanIntent(this)
                .addOnSuccessListener(intentSender -> {
                    scannerLauncher.launch(new IntentSenderRequest.Builder(intentSender).build());
                })
                .addOnFailureListener(e -> {
                    // Handle error
                    Intent data = new Intent();
                    data.putExtra("error", e.getMessage());
                    setResult(Activity.RESULT_CANCELED, data);
                    finish();
                });

    }


    @Override
    protected void onStart() {
        super.onStart();

    }

    private void handleActivityResult(ActivityResult activityResult) {
        int resultCode = activityResult.getResultCode();
        Intent data = new Intent();
        GmsDocumentScanningResult result =
                GmsDocumentScanningResult.fromActivityResultIntent(activityResult.getData());
        if (resultCode == Activity.RESULT_OK && result != null) {

            Log.d("Scanner",getApplicationContext().getString(R.string.scan_result, result));

            Map<String,Object> scanResult = new HashMap<String,Object>();

            if(result.getPages() != null) {

                Map<String,Object> imageUris = new HashMap<String,Object>();
                for(int index = 0; index < result.getPages().size();index++) {
                    imageUris.put("image "+index, String.valueOf(result.getPages().get(index).getImageUri()));
                }

                scanResult.put("imagePaths",imageUris);
            }


            if(result.getPdf() != null) {
                scanResult.put("isPdfAvailable",true);
                scanResult.put("PdfUri",String.valueOf(result.getPdf().getUri()));
                scanResult.put("PdfPageCount",result.getPdf().getPageCount());
            }
            data.putExtra("ScanResult", new Gson().toJson(scanResult));
            setResult(Activity.RESULT_OK, data);

        }
        else if (resultCode == Activity.RESULT_CANCELED) {
            data.putExtra("error", "Scan failed or canceled");
            setResult(Activity.RESULT_CANCELED, data);
            Log.d("Scanner Error",getString(R.string.error_scanner_cancelled));
            //resultInfo.setText(getString(R.string.error_scanner_cancelled));
        } else {
            data.putExtra("error", getString(R.string.error_default_message));
            setResult(Activity.RESULT_OK, data);
            //resultInfo.setText(getString(R.string.error_default_message));
            Log.d("Scanner Error",getString(R.string.error_default_message));
        }
        finish();
    }

}
