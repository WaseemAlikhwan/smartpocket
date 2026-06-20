import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);
