import 'package:dio/dio.dart';
import 'package:nabad/core/Error/error_model.dart';

class ServerExceptions implements Exception {
  final ErrorModel errModel;

  ServerExceptions({required this.errModel});
}

String _extractErrorMessage(dynamic data) {
  if (data == null) return "An error occurred";

  if (data is String) return data;

  if (data is Map<String, dynamic>) {
    if (data.containsKey('errors') && data['errors'] is Map) {
      final errorsMap = data['errors'] as Map<String, dynamic>;
      return errorsMap.values
          .expand((e) => e as List<dynamic>)
          .map((e) => e.toString())
          .join("\n");  
    }

    if (data.containsKey('message')) {
      return data['message'].toString();
    }

    if (data.containsKey('errorMessage')) {
      return data['errorMessage'].toString();
    }
  }

  return "An unknown error occurred";
}

void handleDioException(DioException e) {
  String errorMessage = "An unexpected error occurred";

  if (e.response == null) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = "Connection timeout. Please try again.";
        break;
      case DioExceptionType.connectionError:
        errorMessage = "No internet connection or server unreachable.";
        break;
      case DioExceptionType.cancel:
        errorMessage = "Request was cancelled.";
        break;
      default:
        errorMessage = "Please check your internet connection.";
    }

    throw ServerExceptions(
      errModel: ErrorModel(errorMessage: errorMessage),
    );
  }

  final data = e.response!.data;
  final statusCode = e.response!.statusCode;

  switch (statusCode) {
    case 400:
      errorMessage = _extractErrorMessage(data);
      break;
    case 401:
      errorMessage = "Unauthorized. Please login again.";
      break;
    case 403:
      errorMessage = _extractErrorMessage(data);
      break;
    case 404:
      errorMessage = "Resource not found.";
      break;
    case 422: 
      errorMessage = _extractErrorMessage(data);
      break;
    case 429:
      errorMessage = "Too many requests. Please try again later.";
      break;
    case 500:
      errorMessage = "Server error. Please try again later.";
      break;
    case 503:
      errorMessage = "Service unavailable. Please try again later.";
      break;
    case 504:
      errorMessage = "Gateway timeout. Please try again.";
      break;
    default:
      errorMessage = _extractErrorMessage(data);
      if (errorMessage == "An error occurred") {
        errorMessage = "An unknown error occurred (Code: $statusCode)";
      }
  }

  throw ServerExceptions(
    errModel: ErrorModel(errorMessage: errorMessage),
  );
}