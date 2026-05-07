class ApiError implements Exception {
  const ApiError({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => 'ApiError(code: $code, message: $message)';
}
