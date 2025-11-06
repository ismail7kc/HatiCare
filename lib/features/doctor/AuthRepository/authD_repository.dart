import 'package:haticare/core/config/app_config.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';

class AuthDRepository {
  final ApiClient _apiClient;

  AuthDRepository(this._apiClient);

  Future<Map<String, dynamic>> logout(String deviceId, String? refresh) async {
    final url = '${AppConfig.baseUrl}/users/logout/';
    return await _apiClient.postRequest(
      url,
      body: {'device_id': deviceId, 'refresh': refresh},
    );
  }
  
}
