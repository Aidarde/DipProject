import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:enjoy/providers/branch_provider.dart';
import 'package:enjoy/screens/menu_screen.dart';
import 'package:enjoy/screens/branch_selection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final branchProvider = Provider.of<BranchProvider>(context);
    final branchName = branchProvider.selectedBranch;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: branchName == null
            ? ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BranchSelectionScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Выбрать филиал'),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Выбран: $branchName',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuScreen(branchName: branchName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Перейти в меню'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                branchProvider.clearBranch();
              },
              child: const Text(
                'Сменить филиал',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
