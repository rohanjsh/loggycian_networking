import 'package:http/http.dart' as http;
import 'package:loggycian_networking/src/core/core.dart';
import 'package:loggycian_networking/src/domain/domain.dart';

final class HttpInterceptor extends http.BaseClient {
  HttpInterceptor(this._inner);
  final http.Client _inner;

  static const _idKey = 'http_interceptor';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final requestId = IdProvider.generateId();
    final requestTime = DateTime.now();

    NetworkLoggingRepository.log(
      id: requestId,
      log: NetworkRequestDetailsModel(
        requestTime: requestTime,
        uri: request.url.toString(),
        method: NetworkRequestMethodEnum.values
            .byName(request.method.toLowerCase()),
        requestHeaders: request.headers.map(MapEntry.new),
        statusType: NetworkRequestStatusEnum.started,
        requestBody: request is http.Request ? request.body : null,
        queryParameters: request.url.queryParameters,
      ),
    );

    request.headers[_idKey] = requestId;

    late final http.StreamedResponse response;
    late final List<int> bytes;
    late final String responseBody;

    try {
      response = await _inner.send(request);
      bytes = await response.stream.toBytes();
      responseBody = String.fromCharCodes(bytes);
    } catch (e) {
      final responseTime = DateTime.now();
      NetworkLoggingRepository.log(
        id: requestId,
        log: NetworkLoggingRepository.logs[requestId]!.copyWith(
          responseTime: responseTime,
          statusType: NetworkRequestStatusEnum.error,
          duration: responseTime.difference(requestTime),
          error: e.toString(),
        ),
      );
      rethrow;
    }

    final urlAndQueryParMapEntry = _extractUrl(request);
    final url = urlAndQueryParMapEntry.key;
    final queryParameters = urlAndQueryParMapEntry.value;
    final responseTime = DateTime.now();

    NetworkLoggingRepository.log(
      id: requestId,
      log: NetworkLoggingRepository.logs[requestId]!.copyWith(
        uri: url,
        responseTime: responseTime,
        duration: responseTime.difference(requestTime),
        statusType: response.statusCode >= 200 && response.statusCode < 300
            ? NetworkRequestStatusEnum.success
            : NetworkRequestStatusEnum.error,
        statusCode: response.statusCode,
        responseBody: JsonHelper.prettifyJson(responseBody),
        responseHeaders: response.headers.map(MapEntry.new),
        queryParameters: queryParameters,
      ),
    );

    return http.StreamedResponse(
      Stream.value(bytes),
      response.statusCode,
      headers: response.headers,
      contentLength: response.contentLength,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  MapEntry<String, Map<String, dynamic>> _extractUrl(http.BaseRequest request) {
    final splitUri = request.url.toString().split('?');
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
      ...request.url.queryParameters,
    };

    return MapEntry(baseUrl, queryParameters);
  }
}
