import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:enjoy/screens/cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final String branchName;

  const MenuScreen({super.key, required this.branchName});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final List<Map<String, dynamic>> menuItems = [
    {
      'name': 'Чизбургер',
      'price': 150,
      'image': 'assets/images/burger.png',
    },
    {
      'name': 'Картофель фри',
      'price': 100,
      'image': 'assets/images/fries.png',
    },
    {
      'name': 'Кола',
      'price': 80,
      'image': 'assets/images/cola.png',
    },
  ];

  void addToCart(Map<String, dynamic> item) {
    Provider.of<CartProvider>(context, listen: false).addItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item['name']} добавлен в корзину')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Меню - ${widget.branchName}'),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          )
        ],
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: ListTile(
              leading: Image.asset(item['image'], width: 50),
              title: Text(item['name']),
              subtitle: Text('${item['price']} сом'),
              trailing: IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () => addToCart(item),

              ),
            ),
          );
        },
      ),
    );
  }
}
