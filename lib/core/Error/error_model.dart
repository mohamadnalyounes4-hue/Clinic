
import 'package:nabad/core/Api/end_points.dart';

class ErrorModel {
  final String errorMessage;

  ErrorModel({
    required this.errorMessage,
  });

  factory ErrorModel.fromJson(Map<String, dynamic> jsonData) {
    String message = "An unknown error occurred";

    if (jsonData.containsKey(ApiKey.errorMessage) && jsonData[ApiKey.errorMessage] != null) {
      message = jsonData[ApiKey.errorMessage].toString();
    }
    else if (jsonData.containsKey('message') && jsonData['message'] != null) {
      message = jsonData['message'].toString();
    }
    else if (jsonData.containsKey('errors') && jsonData['errors'] is Map) {
      final errorsMap = jsonData['errors'] as Map<String, dynamic>;
      message = errorsMap.entries
          .map((entry) {
            final msgs = entry.value as List<dynamic>;
            return msgs.map((m) => m.toString()).join(", ");
          })
          .join("\n");
    }
    else if (jsonData.isNotEmpty) {
      message = jsonData.toString();
    }

    return ErrorModel(
      errorMessage: message,
    );
  }
}