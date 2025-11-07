
import 'package:snow_trading_cool/services/user_api.dart';

class DevUtils {
  static Future<void> createDemoAdmin() async {
    final userApi = UserApi();
    try {
      final response = await userApi.createUser(
        username: 'admin',
        password: 'password',
        role: 'Admin',
        active: true,
        canCreateCustomer: true,
        canManageGoods: true,
        canManageChallans: true,
        canManageProfiles: true,
        canManageSettings: true,
      );
      if (response.success) {
        print('Demo admin created successfully');
      } else {
        print('Failed to create demo admin: ${response.message}');
      }
    } catch (e) {
      print('Error creating demo admin: $e');
    }
  }
}
