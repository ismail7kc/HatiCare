import 'package:haticare/core/config/app_config.dart';
import 'package:haticare/features/doctor/ApiClient/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LabRepositoryLayer {
  final ApiClient _apiClient;

  LabRepositoryLayer(this._apiClient);

  Future<Map<String, dynamic>> laboratoryPrescriptionList() async {
    final url = '${AppConfig.baseUrl}prescriptions/laboratory/';

    final pref = await SharedPreferences.getInstance();
    final accessToken = pref.getString('access_token');

    print('Here is access token got from Login laboratory $accessToken');

    return await _apiClient.getRequest(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );
  }
}
