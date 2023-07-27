import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final kIsMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
