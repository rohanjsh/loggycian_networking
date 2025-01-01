import 'package:dio/dio.dart';
import 'package:loggycian_networking/src/core/core.dart';
import 'package:loggycian_networking/src/domain/domain.dart';

final class DioInterceptor extends Interceptor {
  const DioInterceptor();
  static const _idKey = 'rest_interceptor';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requestId = IdProvider.generateId();

    NetworkLoggingRepository.log(
      id: requestId,
      log: NetworkRequestDetailsModel(
        requestTime: DateTime.now(),
        uri: options.uri.toString(),
        method: NetworkRequestMethodEnum.values
            .byName(options.method.toLowerCase()),
        requestHeaders: options.headers.map(
          (key, value) => MapEntry(
            key,
            value.toString(),
          ),
        ),
        statusType: NetworkRequestStatusEnum.started,
        requestBody: options.data,
        queryParameters: options.queryParameters,
      ),
    );

    final extra = {_idKey: requestId};
    options.extra.addAll(extra);

    // handler.next(options);
    super.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final requestId = response.requestOptions.extra[_idKey];
    final request = NetworkLoggingRepository.logs[requestId];
    final urlAndQueryParMapEntry = _extractUrl(response.requestOptions);
    final url = urlAndQueryParMapEntry.key;
    final queryParameters = urlAndQueryParMapEntry.value;
    if (request != null) {
      final responseTime = DateTime.now();
      NetworkLoggingRepository.log(
        id: requestId is String ? requestId : '',
        log: request.copyWith(
          uri: url,
          responseTime: responseTime,
          duration: responseTime.difference(request.requestTime),
          statusType: NetworkRequestStatusEnum.success,
          statusCode: response.statusCode,
          responseBody: JsonHelper.prettifyJson(
            response.data,
          ),
          responseHeaders: response.headers.map.map(
            (key, value) => MapEntry(
              key,
              value.toString(),
            ),
          ),
          queryParameters: queryParameters,
        ),
      );
    }

    // handler.next(response);
    super.onResponse(response, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestId = err.requestOptions.extra[_idKey];
    final request = NetworkLoggingRepository.logs[requestId];
    final urlAndQueryParMapEntry = _extractUrl(err.requestOptions);
    final url = urlAndQueryParMapEntry.key;
    final queryParameters = urlAndQueryParMapEntry.value;
    if (request != null) {
      final responseTime = DateTime.now();
      NetworkLoggingRepository.log(
        id: requestId is String ? requestId : '',
        log: request.copyWith(
          uri: url,
          responseTime: responseTime,
          duration: responseTime.difference(request.requestTime),
          statusType: NetworkRequestStatusEnum.error,
          statusCode: err.response?.statusCode,
          responseBody: JsonHelper.prettifyJson(
            err.response?.data,
          ),
          requestBody: err.response?.requestOptions.data,
          responseHeaders: err.response?.headers.map.map(
            (key, value) => MapEntry(
              key,
              value.toString(),
            ),
          ),
          queryParameters: queryParameters,
          error: err.message,
        ),
      );
    }

    // handler.next(err);
    super.onError(err, handler);
  }

  MapEntry<String, Map<String, dynamic>> _extractUrl(
    RequestOptions requestOptions,
  ) {
    final splitUri = requestOptions.uri.toString().split('?');
    final baseUrl = splitUri.first;
    final builtInQuery = splitUri.length > 1 ? splitUri.last : null;
    final buildInQueryParamsList = builtInQuery?.split('&').map((e) {
      final split = e.split('=');
      return MapEntry(split.first, split.last);
    }).toList();
    final builtInQueryParams = buildInQueryParamsList == null
        ? null
        : Map.fromEntries(buildInQueryParamsList);
    final queryParameters = {
      ...?builtInQueryParams,
      ...requestOptions.queryParameters,
    };

    return MapEntry(baseUrl, queryParameters);
  }
}
