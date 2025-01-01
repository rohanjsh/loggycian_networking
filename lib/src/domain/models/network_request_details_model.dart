// ignore_for_file: lines_longer_than_80_chars

import 'package:loggycian_networking/src/domain/models/network_request_status_enum.dart';
import 'package:loggycian_networking/src/domain/models/network_request_type_enum.dart';

final class NetworkRequestDetailsModel {
  const NetworkRequestDetailsModel({
    required this.uri,
    required this.method,
    required this.requestTime,
    required this.requestHeaders,
    this.statusType,
    this.requestBody,
    this.queryParameters,
    this.statusCode,
    this.responseTime,
    this.responseHeaders,
    this.responseBody,
    this.duration,
    this.error,
  });
  final String uri;
  final NetworkRequestMethodEnum method;
  final NetworkRequestStatusEnum? statusType;
  final DateTime requestTime;
  final DateTime? responseTime;
  final Map<String, String> requestHeaders;
  final Map<String, String>? responseHeaders;
  final int? statusCode;
  final dynamic requestBody;
  final dynamic queryParameters;
  final String? responseBody;
  final Duration? duration;
  final String? error;

  NetworkRequestDetailsModel copyWith({
    String? uri,
    NetworkRequestMethodEnum? method,
    NetworkRequestStatusEnum? statusType,
    DateTime? requestTime,
    DateTime? responseTime,
    Map<String, String>? requestHeaders,
    Map<String, String>? responseHeaders,
    int? statusCode,
    dynamic requestBody,
    dynamic queryParameters,
    String? responseBody,
    Duration? duration,
    String? error,
  }) =>
      NetworkRequestDetailsModel(
        uri: uri ?? this.uri,
        method: method ?? this.method,
        statusType: statusType ?? this.statusType,
        requestTime: requestTime ?? this.requestTime,
        responseTime: responseTime ?? this.responseTime,
        requestHeaders: requestHeaders ?? this.requestHeaders,
        responseHeaders: responseHeaders ?? this.responseHeaders,
        statusCode: statusCode ?? this.statusCode,
        requestBody: requestBody ?? this.requestBody,
        queryParameters: queryParameters ?? this.queryParameters,
        responseBody: responseBody ?? this.responseBody,
        duration: duration ?? this.duration,
        error: error ?? this.error,
      );
}
