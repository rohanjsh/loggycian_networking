import 'package:dio/dio.dart';
import 'package:loggycian_networking/loggycian_networking.dart';

class CurlCommandException implements Exception {
  CurlCommandException(this.message);
  final String message;
}

enum ContentType {
  formUrlEncoded(CurlReserved.formUrlEncoded),
  multipartFormData(CurlReserved.multipartFormData),
  json('application/json');

  const ContentType(this.value);
  final String value;
}

final class Curl {
  const Curl({required this.request});
  final NetworkRequestDetailsModel request;

  /// Generates a curl command from the request
  String generate() {
    _validateRequest();
    return _buildCommand();
  }

  void _validateRequest() {
    if (request.uri.isEmpty) {
      throw CurlCommandException('URL cannot be empty');
    }
  }

  String _buildCommand() {
    final command =
        StringBuffer('${CurlReserved.curl} ${CurlReserved.methodFlag} ');

    _appendMethodType(command);
    _appendSanitizedURL(command);
    _appendQueryParameters(command);
    _appendSanitizedHeaders(command);
    _appendRequestBody(command);
    _appendDefaultOptions(command);

    return command.toString();
  }

  void _appendMethodType(StringBuffer command) {
    switch (request.method) {
      case NetworkRequestMethodEnum.get:
        command.write('GET ');
      case NetworkRequestMethodEnum.post:
        command.write('POST ');
      case NetworkRequestMethodEnum.patch:
        command.write('PATCH ');
      case NetworkRequestMethodEnum.put:
        command.write('PUT ');
      case NetworkRequestMethodEnum.delete:
        command.write('DELETE ');
      // ignore: no_default_cases
      default:
        throw Exception('Invalid Request Method');
    }
  }

  void _appendSanitizedURL(StringBuffer command) {
    final sanitizedUrl = _sanitizeShellInput(request.uri);
    command.write('"$sanitizedUrl');
  }

  void _appendSanitizedHeaders(StringBuffer command) {
    if (request.requestHeaders.isEmpty) return;

    for (final header in request.requestHeaders.entries) {
      if (_isValidHeader(header)) {
        final sanitizedKey = _sanitizeShellInput(header.key);
        final sanitizedValue = _sanitizeShellInput(header.value);
        command.write(
          '${CurlReserved.headerFlag} "$sanitizedKey: $sanitizedValue" ',
        );
      }
    }
  }

  bool _isValidHeader(MapEntry<String, String> header) {
    return header.key.isNotEmpty &&
        header.value.isNotEmpty &&
        header.key != CurlReserved.contentLengthHeader;
  }

  String _sanitizeShellInput(String input) {
    return input
        .replaceAll('"', r'\"')
        .replaceAll(r'$', r'\$')
        .replaceAll('`', r'\`');
  }

  void _appendQueryParameters(StringBuffer command) {
    if (request.queryParameters == null ||
        request.queryParameters is! Map ||
        (request.queryParameters as Map).isEmpty) {
      command.write('" ');
      return;
    }

    final paramString = StringBuffer('?');
    (request.queryParameters as Map).forEach((dynamic key, dynamic value) {
      paramString.write(
        '${Uri.encodeQueryComponent(key.toString())}=${Uri.encodeQueryComponent(value.toString())}&',
      );
    });
    var paramStringFinal = paramString.toString();
    paramStringFinal = paramStringFinal.substring(
      0,
      paramStringFinal.length - 1,
    ); // remove last &
    command
      ..write(paramStringFinal)
      ..write('" ');

    // command.write('" ');
  }

  void _appendRequestBody(StringBuffer command) {
    if (request.requestBody == null) return;

    final contentType = _getContentType();
    switch (contentType) {
      case ContentType.formUrlEncoded:
        _appendFormUrlEncodedBody(command);
      case ContentType.multipartFormData:
        _appendMultipartFormData(command);
      case ContentType.json:
        _appendJsonBody(command);
    }
  }

  ContentType _getContentType() {
    final contentTypeHeader =
        request.requestHeaders[CurlReserved.contentTypeHeader] ??
            request.requestHeaders['Content-Type'] ??
            '';

    if (contentTypeHeader.contains(ContentType.formUrlEncoded.value)) {
      return ContentType.formUrlEncoded;
    } else if (contentTypeHeader
        .contains(ContentType.multipartFormData.value)) {
      return ContentType.multipartFormData;
    }
    return ContentType.json;
  }

  void _appendFormUrlEncodedBody(StringBuffer command) {
    if (request.requestBody is! Map) return;
    final bodyBuffer = StringBuffer();
    (request.requestBody as Map).forEach((key, value) {
      bodyBuffer.write(
        '${Uri.encodeQueryComponent(key.toString())}=${Uri.encodeQueryComponent(value.toString())}&',
      );
    });
    var bodyString = bodyBuffer.toString();
    bodyString = bodyString.substring(0, bodyString.length - 1);
    command.write("${CurlReserved.dataFlag} '$bodyString' ");
  }

  void _appendMultipartFormData(StringBuffer command) {
    if (request.requestBody is! FormData) return;
    final formData = request.requestBody as FormData;
    for (final mapEntry in formData.fields) {
      command.write(
        "${CurlReserved.formFlag} '${mapEntry.key}=${mapEntry.value}' ",
      );
    }

    for (final file in formData.files) {
      final fileName = file.value.filename ?? 'file';
      command.write("${CurlReserved.formFlag} '${file.key}=@$fileName' ");
    }
  }

  void _appendJsonBody(StringBuffer command) {
    var jsonBody = '';
    try {
      if (request.requestBody is String) {
        final body = request.requestBody as String;
        if (body.trim().startsWith('{') || body.trim().startsWith('[')) {
          jsonBody = JsonHelper.prettifyJson(body);
        } else {
          jsonBody = body;
        }
      } else {
        jsonBody = JsonHelper.prettifyJson(request.requestBody);
      }

      jsonBody = jsonBody
          .replaceAll("'", r"'\''")
          .replaceAll('\n', ' ')
          .replaceAll('\r', '');
    } catch (e) {
      jsonBody = request.requestBody.toString();
    }
    command.write("${CurlReserved.dataFlag} '$jsonBody' ");
  }

  void _appendDefaultOptions(StringBuffer command) {
    command
      ..write('${CurlReserved.followRedirectFlag} ') // Follow Redirects
      ..write('${CurlReserved.insecureFlag} '); // Insecure SSL
  }
}
