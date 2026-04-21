import 'package:flutter/material.dart';

import 'employees_list_screen.dart';

class SupervisorsListScreen extends StatelessWidget {
  const SupervisorsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmployeesListScreen(initialTab: 1);
  }
}
