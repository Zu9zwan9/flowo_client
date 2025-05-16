import 'package:hive/hive.dart';
import '../app_theme.dart';

class AppThemeAdapter extends TypeAdapter<AppTheme> {
  @override
  final int typeId = 20;

  @override
  AppTheme read(BinaryReader reader) {
    return AppTheme.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, AppTheme obj) {
    writer.writeInt(obj.index);
  }
}
