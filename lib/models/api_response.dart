// API Response Model for Flutter Pharmacy App
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    required this.statusCode,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(
      isSuccess: true,
      data: data,
      statusCode: 200,
    );
  }

  factory ApiResponse.error(String error, int statusCode) {
    return ApiResponse._(
      isSuccess: false,
      error: error,
      statusCode: statusCode,
    );
  }

  @override
  String toString() {
    return 'ApiResponse(isSuccess: $isSuccess, data: $data, error: $error, statusCode: $statusCode)';
  }
}
