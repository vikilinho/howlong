import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar_models.dart';

class IsarService {
  IsarService._();

  static Future<Isar>? _instance;

  static Future<Isar> get instance {
    return _instance ??= _open();
  }

  static Future<Isar> _open() async {
    if (Isar.instanceNames.contains('howlong')) {
      return Future.value(Isar.getInstance('howlong')!);
    }

    final directory = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        TrackedEventSchema,
        TrackedHabitSchema,
        HabitCheckInSchema,
        DailyLogSchema,
      ],
      name: 'howlong',
      directory: directory.path,
    );
  }
}
