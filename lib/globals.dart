import 'dart:io';

import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final kIsMobile = Platform.isAndroid || Platform.isIOS;
