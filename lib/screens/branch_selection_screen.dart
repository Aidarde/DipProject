import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/branch_provider.dart';
import 'main_screen.dart';

class BranchSelectionScreen extends StatelessWidget {
  const BranchSelectionScreen({super.key});

  final List<String> branches = const [
    'Центральный филиал',
    'Филиал на Юге',
    'Филиал на Севере',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите филиал'),
        backgroundColor: Colors.redAccent,
      ),
      body: ListView.builder(
        itemCount: branches.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(branches[index]),
            leading: const Icon(Icons.store),
            onTap: () {
              // Сохраняем выбор
              Provider.of<BranchProvider>(context, listen: false)
                  .setBranch(branches[index]);

              // Переход на главный экран
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MainScreen()),
              );
            },
          );
        },
      ),
    );
  }
}
