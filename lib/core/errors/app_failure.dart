import 'dart:io';

import 'package:dio/dio.dart';

import 'app_exception.dart';

final class AppFailure {
  const AppFailure({
    required this.message,
    this.code,
    this.statusCode,
    this.cause,
    this.stackTrace,
    this.isNetworkError = false,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Object? cause;
  final StackTrace? stackTrace;   
  final bool isNetworkError;

  factory AppFailure.fromObject(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) {
      return error;
    }

    if (error is AppException) {
      return AppFailure(
        message: error.message,
        code: error.code,
        cause: error.cause,
        stackTrace: error.stackTrace ?? stackTrace,
      );
    }

    if (error is DioException) {
      return AppFailure(
        message: _messageFromDio(error),
        code: error.type.name,
        statusCode: error.response?.statusCode,
        cause: error,
        stackTrace: error.stackTrace,
        isNetworkError: _isConnectivityError(error),
      );
    }

    if (error is SocketException) {
      return AppFailure(
        message: 'No internet connection.',
        cause: error,
        stackTrace: stackTrace,
        isNetworkError: true,
      );
    }

    return AppFailure(
      message: 'Something went wrong. Please try again.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static bool _isConnectivityError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.unknown:
        return error.error is SocketException;
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.transformTimeout:
        return false;
    }
  }

  static String _messageFromDio(DioException error) {
    if (_isConnectivityError(error)) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => 'The connection timed out.',
        _ => 'No internet connection.',
      };
    }

    final responseMessage = error.response?.data;
    if (responseMessage is Map && responseMessage['message'] is String) {
      return responseMessage['message'] as String;
    }

    return switch (error.type) {
      DioExceptionType.badCertificate => 'Unable to verify the server.',
      DioExceptionType.badResponse => 'The server returned an error.',
      DioExceptionType.cancel => 'Request was cancelled.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
