import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data' show Uint8List;

import 'package:http/http.dart';

enum RequestMethod { get, post, put, patch, delete }

Map<String, dynamic> decodeJson(String jsonString) {
  try {
    return (jsonDecode(jsonString) as Map<String, dynamic>);
  } catch (error) {
    log('Error decodeJson: $error\n');
    log('JSON string >>> $jsonString');
    return {};
  }
}

final Response timeoutResponse = Response(
  '{"status":408,"message":"Request timeout"}',
  408,
);

/// Sends HTTP requests for JSON content that can be formatted into a Dart Map object
Future<Map<String, dynamic>> requestJson(
    Uri uri, {
      Map<String, String>? headers,
      Object? body,
      RequestMethod method = RequestMethod.get,
      Duration timeLimit = const Duration(minutes: 1),
    }) async {
  final Response response;

  if (headers != null) {
    headers['Access-Control-Allow-Origin'] = '*';
    headers['Access-Control-Allow-Credentials'] = 'true';
    headers['Access-Control-Allow-Headers'] =
    'Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale';
    headers['Access-Control-Allow-Methods'] = 'POST, HEAD';
    headers['Content-Type'] = 'application/json';
    headers['Accept'] = 'application/json';
  } else {
    headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
  }

  switch (method) {
    case RequestMethod.get:
      response = await get(uri, headers: headers)
          .catchError((error) => Response(error.toString(), 500))
          .timeout(timeLimit)
          .catchError((error) => timeoutResponse);
      break;
    case RequestMethod.post:
      response = await post(uri, headers: headers, body: jsonEncode(body))
          .catchError((error) => Response(error.toString(), 500))
          .timeout(timeLimit)
          .catchError((error) => timeoutResponse);
      break;
    case RequestMethod.put:
      response = await put(uri, headers: headers).timeout(timeLimit);
      break;
    case RequestMethod.patch:
      response = await patch(uri, headers: headers).timeout(timeLimit);
      break;
    case RequestMethod.delete:
      response = await delete(uri, headers: headers).timeout(timeLimit);
      break;
  }

  if (response.statusCode != 200) {
    log(response.body);
    return jsonDecode(response.body);
  }

  return json.decode(response.body);
}

Future<Response> _onTimeout(Object error) async {
  log(error.toString());
  return Response('{"status":408,"message":"Request timeout."}', 408);
}

Future<Uint8List?> requestFile(
    Uri url, {
      Map<String, String>? headers,
      Object? body,
      RequestMethod method = RequestMethod.get,
      Duration timeLimit = const Duration(seconds: 30),
    }) async {
  final Response response;

  if (headers != null) {
    headers['Access-Control-Allow-Origin'] = '*';
    headers['Access-Control-Allow-Credentials'] = 'true';
    headers['Access-Control-Allow-Headers'] =
    'Origin,Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,locale';
    headers['Access-Control-Allow-Methods'] = 'POST, HEAD';
    headers['Accept'] = 'application/json';
  } else {
    headers = {'Accept': 'image/*'};
  }

  switch (method) {
    case RequestMethod.get:
      response = await get(url, headers: headers)
          .timeout(timeLimit)
          .catchError(_onTimeout);
      break;
    case RequestMethod.post:
      response = await post(url, headers: headers, body: body)
          .timeout(timeLimit)
          .catchError(_onTimeout);
      break;
    default:
      throw Exception('requestFile Error(1): Unknown request method, $method');
  }

  if (response.statusCode != 200) {
    return null;
  }

  try {
    return response.bodyBytes;
  } catch (e) {
    throw Exception("Error opening url file");
  }
}
