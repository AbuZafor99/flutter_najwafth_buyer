import 'package:dio/dio.dart';

import '../errors/app_failure.dart';
import '../errors/result.dart';
import '../utils/typedefs.dart';

final class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  String get baseUrl => _dio.options.baseUrl;

  Future<Result<T>> get<T>(
    String path, {
    JsonMap? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) {
    return _request(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
      parser,
    );
  }

  Future<Result<T>> post<T>(
    String path, {
    Object? data,
    JsonMap? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) {
    return _request(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      parser,
    );
  }

  Future<Result<T>> put<T>(
    String path, {
    Object? data,
    JsonMap? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) {
    return _request(
      () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      parser,
    );
  }

  Future<Result<T>> patch<T>(
    String path, {
    Object? data,
    JsonMap? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) {
    return _request(
      () => _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      parser,
    );
  }

  Future<Result<T>> delete<T>(
    String path, {
    Object? data,
    JsonMap? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) {
    return _request(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      parser,
    );
  }

  Future<Result<T>> _request<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data)? parser,
  ) async {
    try {
      final response = await request();
      final value = parser == null ? response.data as T : parser(response.data);
      return Success(value);
    } on Object catch (error, stackTrace) {
      return ResultFailure(AppFailure.fromObject(error, stackTrace));
    }
  }
}
