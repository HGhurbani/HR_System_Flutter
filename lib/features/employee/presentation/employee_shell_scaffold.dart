import 'package:flutter/material.dart';

final kEmployeeShellScaffoldKey = GlobalKey<ScaffoldState>();

void openEmployeeShellDrawer() {
  kEmployeeShellScaffoldKey.currentState?.openDrawer();
}

