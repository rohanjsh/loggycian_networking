abstract final class CurlReserved {
  const CurlReserved._();

  static const String curl = 'curl';
  static const String methodFlag = '-X';
  static const String headerFlag = '-H';
  static const String dataFlag = '-d';
  static const String formFlag = '-F';
  static const String followRedirectFlag = '-L';
  static const String insecureFlag = '-k';

  static const String contentTypeHeader = 'content-type';
  static const String contentLengthHeader = 'content-length';

  static const String formUrlEncoded = 'application/x-www-form-urlencoded';
  static const String multipartFormData = 'multipart/form-data';
}
