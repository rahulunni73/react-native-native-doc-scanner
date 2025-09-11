package com.nativedocscanner;

import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;

import java.util.HashMap;

public class Utils {
    
    public static HashMap<String, Object> convertReadableMapToHashMap(ReadableMap readableMap) {
        HashMap<String, Object> hashMap = new HashMap<>();
        
        if (readableMap == null) {
            return hashMap;
        }
        
        ReadableMapKeySetIterator iterator = readableMap.keySetIterator();
        
        while (iterator.hasNextKey()) {
            String key = iterator.nextKey();
            
            switch (readableMap.getType(key)) {
                case Null:
                    hashMap.put(key, null);
                    break;
                case Boolean:
                    hashMap.put(key, readableMap.getBoolean(key));
                    break;
                case Number:
                    hashMap.put(key, readableMap.getDouble(key));
                    break;
                case String:
                    hashMap.put(key, readableMap.getString(key));
                    break;
                case Map:
                    hashMap.put(key, convertReadableMapToHashMap(readableMap.getMap(key)));
                    break;
                case Array:
                    // For simplicity, we'll skip arrays. Add array handling if needed.
                    hashMap.put(key, readableMap.getArray(key));
                    break;
            }
        }
        
        return hashMap;
    }
}