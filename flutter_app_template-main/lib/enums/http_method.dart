/// HTTP verbs supported by the API layer.
///
/// Using an enum instead of raw strings keeps typos out of request
/// definitions and lets the client switch on the verb exhaustively.
enum HttpMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE');

  const HttpMethod(this.value);

  final String value;
}
