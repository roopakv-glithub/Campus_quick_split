import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

final dbServiceProvider = Provider((ref) => DatabaseService());
