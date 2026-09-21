import 'package:shared_preferences/shared_preferences.dart';
import 'local_data_dispatcher.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  String? get message => error;

  ApiResponse.success(this.data) : success = true, error = null;
  ApiResponse.error(this.error) : success = false, data = null;
}

/// 100% database-free, offline-first client.
/// Routes requests directly to local storage repositories with zero network latency.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _token;
  final LocalDataDispatcher _dispatcher = LocalDataDispatcher();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("auth_token");
  }

  void setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString("auth_token", token);
    } else {
      await prefs.remove("auth_token");
    }
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<ApiResponse<dynamic>> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    return _dispatcher.handleGet(endpoint, queryParams: queryParams);
  }

  Future<ApiResponse<dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    return _dispatcher.handlePost(endpoint, body: body);
  }

  Future<ApiResponse<dynamic>> put(String endpoint, {Map<String, dynamic>? body}) async {
    return _dispatcher.handlePut(endpoint, body: body);
  }

  Future<ApiResponse<dynamic>> delete(String endpoint) async {
    return _dispatcher.handleDelete(endpoint);
  }
}
