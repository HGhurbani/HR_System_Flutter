import 'package:flutter/material.dart';

/// [ScaffoldState] for [AdminShell] so nested admin screens can open the drawer.
final GlobalKey<ScaffoldState> kAdminShellScaffoldKey =
    GlobalKey<ScaffoldState>();

void openAdminShellDrawer() =>
    kAdminShellScaffoldKey.currentState?.openDrawer();
