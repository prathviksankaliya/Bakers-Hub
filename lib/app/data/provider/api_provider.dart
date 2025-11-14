import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiProvider{

  final Map<String, String> _headers = <String, String>{'Content-Type': 'application/json'};

  final String unauthorizedError = "Unauthorized access!";
  final String noInternetFoundError = "No Internet Found!";
  final String reqTimeOutError = "Request time out!";

  Future<Map<String, dynamic>> postRequest({required String endPoint, Object? body}) async {
    try {
      final response = await http
          .post(Uri.parse(dotenv.get("BASE_URL", fallback: "") + endPoint),
          headers: _headers,
          body: jsonEncode(body))
          .timeout(const Duration(seconds: 35));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }

      throw response.statusCode == 401 ? unauthorizedError : jsonDecode(response.body)['message'];
    } on SocketException {
      throw noInternetFoundError;
    } on TimeoutException {
      throw reqTimeOutError;
    } catch (e) {
      rethrow;
    }
  }
}
