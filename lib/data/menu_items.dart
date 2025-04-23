import '../models/menu_item.dart';

final List<MenuItem> sampleMenuItems = [
  MenuItem(
    id: '1',
    name: 'Чизбургер',
    description: 'Сочный бургер с сыром и котлетой',
    price: 199.0,
    imageUrl: 'https://cdn-icons-png.flaticon.com/512/3075/3075977.png',
    category: 'Бургеры',
  ),
  MenuItem(
    id: '2',
    name: 'Картошка фри',
    description: 'Хрустящая картошка фри',
    price: 99.0,
    imageUrl: 'https://cdn-icons-png.flaticon.com/512/3075/3075975.png',
    category: 'Гарниры',
  ),
  MenuItem(
    id: '3',
    name: 'Кока-Кола',
    description: 'Прохладительный напиток 0.5л',
    price: 69.0,
    imageUrl: 'https://cdn-icons-png.flaticon.com/512/3075/3075966.png',
    category: 'Напитки',
  ),
];
