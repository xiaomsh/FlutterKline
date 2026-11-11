enum ApiErrorType { cancelled, network, server, parse, business }

class ApiError implements Exception {
  final ApiErrorType kind;
  final String message;
  final int? code;

  ApiError({
    required this.kind,
    required this.message,
    this.code,
  });

  bool get cancelled => kind == ApiErrorType.cancelled;

  @override
  String toString() => message;
}
