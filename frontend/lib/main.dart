import 'package:flutter/material.dart';
import 'app/app.dart';
import 'di/injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const BirthChainApp());
}
