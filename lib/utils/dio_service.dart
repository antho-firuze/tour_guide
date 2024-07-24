import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:tour_guide/utils/dio_logger_interceptor.dart';

final busyProvider = StateProvider<bool>((ref) => false);

final dioProvider = Provider.autoDispose((ref) {
  final dio = Dio();

  dio.interceptors.add(DioLoggerInterceptor());

  return dio;
});
