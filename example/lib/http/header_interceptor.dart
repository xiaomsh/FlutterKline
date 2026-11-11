import 'package:dio/dio.dart';

class HeadersInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // GET has no body; sending Content-Type adds a CORS preflight to every request on web.
    final json = (options.extra["json"] ?? true) && options.method != 'GET';
    options.headers = {
      if (json) "Content-Type": "application/json",
      ...options.headers,
    };
    handler.next(options);
  }
}
