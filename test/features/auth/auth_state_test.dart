import 'package:fitness_planner/features/auth/domain/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SignedIn сравнивается по uid и email', () {
    expect(
      const SignedIn(uid: 'u1', email: 'a@b.kz'),
      const SignedIn(uid: 'u1', email: 'a@b.kz'),
    );
    expect(
      const SignedIn(uid: 'u1').hashCode,
      const SignedIn(uid: 'u1').hashCode,
    );
    expect(const SignedIn(uid: 'u1'), isNot(const SignedIn(uid: 'u2')));
    expect(
      const SignedIn(uid: 'u1', email: 'a'),
      isNot(const SignedIn(uid: 'u1', email: 'b')),
    );
  });
}
