// lib/models/reward_item.dart
class RewardItem {
  final String id;
  final String name;
  final String image;
  final int cost;

  RewardItem({
    required this.id,
    required this.name,
    required this.image,
    required this.cost,
  });

  factory RewardItem.fromMap(String id, Map<String, dynamic> data) {
    return RewardItem(
      id: id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      cost: data['cost'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'cost': cost,
    };
  }
}
