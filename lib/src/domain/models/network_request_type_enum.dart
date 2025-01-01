enum NetworkRequestMethodEnum {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH'),
  head('HEAD'),
  options('OPTIONS'),
  trace('TRACE'),
  connect('CONNECT'),
  websocket('WS');

  const NetworkRequestMethodEnum(this.value);
  final String value;
}
