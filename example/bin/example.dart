import 'package:dio/dio.dart';
import 'package:graphql/client.dart';
import 'package:http/http.dart' as http;
import 'package:loggycian_networking/loggycian_networking.dart';

void main() async {
  await networking();
}

Future<void> networking() async {
  // Listen to network logs
  NetworkLoggingRepository.logsStreamController.stream.listen((logs) {
    print('New network activity detected! Total logs: ${logs.length}');
  });

  // Example with Dio
  await dioExample();

  // Example with HTTP package
  await httpExample();

  // Example with GraphQL
  await graphqlExample();

  // Get all current logs
  final allLogs = NetworkLoggingRepository.logs.values.toList();
  print('Total logged requests: ${allLogs.length}');

  // Get CURL commands for all requests
  for (final request in allLogs) {
    final curlCommand = Curl(request: request).generate();
    print('CURL command for ${request.uri}:\n$curlCommand\n');
  }

  // Clean up
  NetworkLoggingRepository.clearSelectedLogs(allLogs);
  NetworkLoggingRepository.disposeListeners();
}

Future<void> dioExample() async {
  final dio = Dio();
  dio.interceptors.add(const DioInterceptor());

  try {
    await dio.get('https://api.github.com/users/flutter');
  } catch (e) {
    print('Dio request failed: $e');
  }
}

Future<void> httpExample() async {
  final client = HttpInterceptor(http.Client());

  try {
    await client.get(Uri.parse('https://api.github.com/users/dart-lang'));
  } catch (e) {
    print('HTTP request failed: $e');
  } finally {
    client.close();
  }
}

Future<void> graphqlExample() async {
  final httpLink = HttpLink('https://countries.trevorblades.com/');
  final gqlLink = GqlInterceptor(httpLink);

  final client = GraphQLClient(link: gqlLink, cache: GraphQLCache());

  const query = r'''
    query ViewerQuery {
      continents { 
        code name 
      } 
    }
  ''';

  try {
    await client.query(QueryOptions(document: gql(query)));
  } catch (e) {
    print('GraphQL request failed: $e');
  }
}
