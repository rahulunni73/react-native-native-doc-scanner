/**
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow strict
 * @format
 */

'use strict';

import type {TurboModule} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

export type ScannerConfig = {
  scannerMode: number,
  isGalleryImportRequired: boolean,
  pageLimit: number,
  ...
};

/**
 * Flow-based TurboModule specification for React Native Codegen
 * 
 * This spec is used by React Native's Codegen to generate the native
 * TurboModule implementation when New Architecture is enabled.
 */
export interface Spec extends TurboModule {
  +scanDocument(
    config: ScannerConfig,
    onSuccess: (result: string) => void,
    onError: (error: string) => void,
  ): void;
  
  +getCapabilities(): string;
  +isAvailable(): boolean;
}

export default (TurboModuleRegistry.getEnforcing<Spec>('NativeDocScanner'): Spec);