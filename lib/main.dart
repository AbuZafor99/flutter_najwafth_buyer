import 'package:flutter/material.dart';
import 'package:flutter_najwafth_buyer/app/app.dart';

import 'core/bootstrap/app_bootstrap.dart';

Future<void> main() async {
  final app = await AppBootstrap.createProviderScope(
    child: const NajwafthBuyerApp(),
  );
  runApp(app);
}
