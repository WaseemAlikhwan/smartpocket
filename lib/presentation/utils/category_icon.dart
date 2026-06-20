import 'package:flutter/material.dart';

IconData resolveCategoryIcon(String key) {
  const map = <String, IconData>{
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'local_cafe': Icons.local_cafe,
    'coffee': Icons.coffee,
    'attach_money': Icons.attach_money,
    'category': Icons.category,
    'local_gas_station': Icons.local_gas_station,
    'shopping_bag': Icons.shopping_bag,
    'theaters': Icons.theater_comedy,
    'home': Icons.home,
    'medical_services': Icons.medical_services,
    'smoking_rooms': Icons.smoking_rooms,
    'local_drink': Icons.local_drink,
    'shield': Icons.shield,
    'diamond': Icons.diamond,
    'checkroom': Icons.checkroom,
    'phone_android': Icons.phone_android,
    'hiking': Icons.hiking,
    'flight': Icons.flight,
    'atm': Icons.atm,
  };
  return map[key] ?? Icons.label_outline;
}
