import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'models/event_model.dart';
import 'screens/home_screen.dart';
import 'blocs/calendar/calendar_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Isar isar;

  if (kIsWeb) {
    isar = await Isar.open([EventSchema], directory: 'isar');
  } else {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([EventSchema], directory: dir.path);
  }

  runApp(MyApp(isar: isar));
}

class MyApp extends StatelessWidget {
  final Isar isar;

  const MyApp({super.key, required this.isar});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CalendarCubit>(
          create: (context) => CalendarCubit(isar),
        ),
      ],
      child: MaterialApp(
        home: const HomeScreen(),
      ),
    );
  }
}
