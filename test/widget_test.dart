import 'package:flutter_test/flutter_test.dart';
import 'package:myteams/core/di/injection_container.dart';

import 'package:myteams/features/auth/domain/entities/app_user.dart';
import 'package:myteams/features/auth/domain/repositories/auth_repository.dart';
import 'package:myteams/main.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(null);

  @override
  Future<AppUser> signInWithEmail({required String email, required String password}) async {
    return const AppUser(id: '1', email: 'test@example.com');
  }

  @override
  Future<AppUser> signUpWithEmail({required String email, required String password}) async {
    return const AppUser(id: '1', email: 'test@example.com');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> verifyOTP({required String email, required String token}) async {}

  @override
  Future<void> resetPassword({required String newPassword}) async {}

  @override
  Future<AppUser> signInWithGoogle() async {
    return const AppUser(id: '1', email: 'google@example.com');
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {}
}


void main() {
  setUp(() {
    if (!sl.isRegistered<AuthRepository>()) {
      sl.registerLazySingleton<AuthRepository>(() => FakeAuthRepository());
    }
  });

  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SynergyApp());
    expect(find.text('SYNERGY'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}



