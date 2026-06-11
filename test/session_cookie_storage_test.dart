import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pb_iot/services/session_cookie_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('saveRememberedLogin stores token in secure storage only', () async {
    await SessionCookieStorage.saveRememberedLogin(
      token: 'secret-token',
      displayName: 'Prince',
      rememberMe: true,
    );

    final preferences = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    expect(preferences.getBool('remember_me'), isTrue);
    expect(preferences.getString('remembered_display_name'), 'Prince');
    expect(preferences.getString('remembered_token'), isNull);
    expect(await secureStorage.read(key: 'remembered_token'), 'secret-token');
  });

  test('loadRememberedLogin migrates legacy plaintext token', () async {
    SharedPreferences.setMockInitialValues({
      'remember_me': true,
      'remembered_token': 'legacy-token',
      'remembered_display_name': 'Legacy',
    });

    final remembered = await SessionCookieStorage.loadRememberedLogin();
    final preferences = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    expect(remembered?.rememberMe, isTrue);
    expect(remembered?.token, 'legacy-token');
    expect(remembered?.displayName, 'Legacy');
    expect(preferences.getString('remembered_token'), isNull);
    expect(await secureStorage.read(key: 'remembered_token'), 'legacy-token');
  });
}
