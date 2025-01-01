import 'dart:async';

import 'package:gql/language.dart';
import 'package:graphql/client.dart';
import 'package:loggycian_networking/src/core/core.dart';
import 'package:loggycian_networking/src/domain/domain.dart';

final class GqlInterceptor extends Link {
  const GqlInterceptor(
    this._link, {
    this.timeout = const Duration(seconds: 30),
  });

  final Link _link;
  final Duration timeout;

  @override
  Stream<Response> request(
    Request request, [
    NextLink? forward,
  ]) {
    final link = _link;
    try {
      if (link is HttpLink) {
        return _handleHttpRequest(link, request, forward).timeout(
          timeout,
          onTimeout: (EventSink<Response> sink) {
            sink
              ..addError(TimeoutException('Request timed out'))
              ..close();
          },
        );
      } else if (link is WebSocketLink) {
        return _handleWebSocketRequest(link, request, forward).timeout(
          timeout,
          onTimeout: (EventSink<Response> sink) {
            sink
              ..addError(TimeoutException('Request timed out'))
              ..close();
          },
        );
      } else {
        return link.request(request, forward);
      }
    } catch (e) {
      return Stream.error(e);
    }
  }

  Stream<Response> _handleHttpRequest(
    HttpLink link,
    Request request,
    NextLink? forward,
  ) async* {
    final requestId = IdProvider.generateId();
    final startTime = DateTime.now();

    try {
      await for (final response in link.request(request, forward)) {
        final endTime = DateTime.now();
        final responseContext =
            response.context.entry<HttpLinkResponseContext>();

        final headers = Map<String, String>.from(link.defaultHeaders);
        headers['Content-Type'] = 'application/json';

        final requestBody = {
          'query': _sanitizeQuery(printNode(request.operation.document)),
          'variables': request.variables,
          'operationName': request.operation.operationName ?? '',
        };

        NetworkLoggingRepository.log(
          id: requestId,
          log: NetworkRequestDetailsModel(
            requestTime: startTime,
            responseTime: endTime,
            duration: endTime.difference(startTime),
            uri: link.uri.toString(),
            method: NetworkRequestMethodEnum.post,
            requestHeaders: headers,
            responseHeaders: responseContext?.headers ?? {},
            requestBody:
                requestBody, // Don't pre-format, let curl command handle it
            responseBody: response.response
                .toString(), // Raw response, let curl command handle it
            queryParameters: request.variables,
            statusCode: responseContext?.statusCode ?? 0,
            statusType: _determineStatusType(response),
            error: response.errors?.isNotEmpty ?? false
                ? response.errors?.first.message
                : null,
          ),
        );
        yield response;
      }
    } catch (e) {
      final endTime = DateTime.now();
      NetworkLoggingRepository.log(
        id: requestId,
        log: NetworkRequestDetailsModel(
          requestTime: startTime,
          responseTime: endTime,
          duration: endTime.difference(startTime),
          uri: link.uri.toString(),
          method: NetworkRequestMethodEnum.post,
          statusType: NetworkRequestStatusEnum.error,
          error: e.toString(),
          requestHeaders: link.defaultHeaders,
          queryParameters: request.variables,
          responseHeaders: const {},
          requestBody: JsonHelper.prettifyJson({
            'query': _sanitizeQuery(printNode(request.operation.document)),
            'variables': request.variables,
            'operationName': request.operation.operationName ?? '',
          }),
        ),
      );
      rethrow;
    }
  }

  Stream<Response> _handleWebSocketRequest(
    WebSocketLink link,
    Request request,
    NextLink? forward,
  ) async* {
    final requestId = IdProvider.generateId();
    final startTime = DateTime.now();

    try {
      await for (final response in link.request(request, forward)) {
        final endTime = DateTime.now();

        NetworkLoggingRepository.log(
          id: requestId,
          log: NetworkRequestDetailsModel(
            requestTime: startTime,
            responseTime: endTime,
            duration: endTime.difference(startTime),
            uri: link.url,
            method: NetworkRequestMethodEnum.websocket,
            requestHeaders: const {},
            responseHeaders: const {},
            requestBody: JsonHelper.prettifyJson({
              'query': _sanitizeQuery(printNode(request.operation.document)),
              'variables': request.variables,
            }),
            responseBody: JsonHelper.prettifyJson(response.response),
            queryParameters: request.variables,
            statusType: _determineStatusType(response),
            statusCode: 0,
            error: response.errors?.isNotEmpty ?? false
                ? response.errors?.first.message
                : null,
          ),
        );
        yield response;
      }
    } catch (e) {
      final endTime = DateTime.now();
      NetworkLoggingRepository.log(
        id: requestId,
        log: NetworkRequestDetailsModel(
          requestTime: startTime,
          responseTime: endTime,
          duration: endTime.difference(startTime),
          uri: link.url,
          method: NetworkRequestMethodEnum.websocket,
          statusType: NetworkRequestStatusEnum.error,
          error: e.toString(),
          requestHeaders: const {},
          responseHeaders: const {},
          queryParameters: request.variables, // Added missing query parameters
          statusCode: 0, // Added missing status code
          requestBody: _sanitizeQuery(
            printNode(
              request.operation.document,
            ),
          ), // Added missing request body
        ),
      );
      rethrow;
    }
  }

  String _sanitizeQuery(String query) {
    return query.replaceAll('\n', '').replaceAll('__typename', '');
  }

  NetworkRequestStatusEnum _determineStatusType(Response response) {
    if (response.errors?.isNotEmpty ?? false) {
      return NetworkRequestStatusEnum.error;
    }
    if (response.data == null) {
      return NetworkRequestStatusEnum.started;
    }
    return NetworkRequestStatusEnum.success;
  }
}
