import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/error.dart';

/// App-wide error observer: every API failure (except cancellation) passes through it.
/// Register once in main. For handling that shouldn't be repeated at each call site:
/// 401 re-login, risk-control blocks, analytics reporting.
void Function(String path, ApiError error)? onApiError;

/// Single exit point: failures are swallowed and return null, with logging and reporting done
/// here; pass [onError] to learn the reason.
/// [fn] returning null only means "failed": unparsable data must return null, while
/// "no data" returns `[]`.
Future<T?> safeCall<T>(
  String path,
  Future<T?> Function() fn, {
  void Function(ApiError error)? onError,
}) async {
  try {
    return await fn();
  } on ApiError catch (e) {
    _report(path, e, onError);
    return null;
  } catch (e) {
    _report(path, ApiError(kind: ApiErrorType.parse, message: e.toString()), onError);
    return null;
  }
}

void _report(String path, ApiError e, void Function(ApiError)? onError) {
  // Cancellation is intentional (leaving the page / switching pairs), not an error: no log and
  // no global hook. onError still fires; callers may use `cancelled` to skip the retry prompt.
  if (!e.cancelled) {
    debugPrint("$path [${e.kind.name}${e.code == null ? '' : ' ${e.code}'}]");
    onApiError?.call(path, e);
  }
  onError?.call(e);
}
