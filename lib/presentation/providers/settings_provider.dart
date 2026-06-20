import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/settings_entity.dart';
import 'repository_providers.dart';

final appSettingsProvider = FutureProvider<SettingsEntity?>((ref) async {
  return ref.watch(settingsRepositoryProvider).get();
});
