// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:device_preview/presets.dart';
import 'package:flutter/material.dart';

import 'app.dart';

Future<void> main() async {
  DevicePreview.enable(enabled: !kReleaseMode);
  await DevicePreview.controller.applyPreset(DevicePresets.iPhone16ProMax);
  runApp(const AppRoot());
}
