import 'package:flutter_test/flutter_test.dart';
import 'package:aintreal_app/core/auth/auth_provider.dart';

/// Tests for auth state classes.
///
/// These test the sealed class hierarchy and state properties.
/// Firebase-dependent behavior is tested via integration tests.

void main() {
  group('AuthState Classes', () {
    group('AuthStateUnauthenticated', () {
      test('can be instantiated', () {
        const state = AuthStateUnauthenticated();
        expect(state, isA<AuthState>());
        expect(state, isA<AuthStateUnauthenticated>());
      });

      test('is const', () {
        const state1 = AuthStateUnauthenticated();
        const state2 = AuthStateUnauthenticated();
        expect(identical(state1, state2), isTrue);
      });
    });

    group('AuthStateLoading', () {
      test('can be instantiated', () {
        const state = AuthStateLoading();
        expect(state, isA<AuthState>());
        expect(state, isA<AuthStateLoading>());
      });

      test('is const', () {
        const state1 = AuthStateLoading();
        const state2 = AuthStateLoading();
        expect(identical(state1, state2), isTrue);
      });
    });

    group('AuthStateError', () {
      test('can be instantiated with message', () {
        const state = AuthStateError('Test error');
        expect(state, isA<AuthState>());
        expect(state, isA<AuthStateError>());
        expect(state.message, equals('Test error'));
      });

      test('different messages create different instances', () {
        const state1 = AuthStateError('Error 1');
        const state2 = AuthStateError('Error 2');
        expect(state1.message, isNot(equals(state2.message)));
      });
    });

    group('AuthState pattern matching', () {
      test('can pattern match on Unauthenticated', () {
        const AuthState state = AuthStateUnauthenticated();
        final result = switch (state) {
          AuthStateUnauthenticated() => 'unauthenticated',
          AuthStateLoading() => 'loading',
          AuthStateAuthenticated() => 'authenticated',
          AuthStateError() => 'error',
        };
        expect(result, equals('unauthenticated'));
      });

      test('can pattern match on Loading', () {
        const AuthState state = AuthStateLoading();
        final result = switch (state) {
          AuthStateUnauthenticated() => 'unauthenticated',
          AuthStateLoading() => 'loading',
          AuthStateAuthenticated() => 'authenticated',
          AuthStateError() => 'error',
        };
        expect(result, equals('loading'));
      });

      test('can pattern match on Error', () {
        const AuthState state = AuthStateError('test');
        final result = switch (state) {
          AuthStateUnauthenticated() => 'unauthenticated',
          AuthStateLoading() => 'loading',
          AuthStateAuthenticated() => 'authenticated',
          AuthStateError(message: final m) => 'error: $m',
        };
        expect(result, equals('error: test'));
      });

      test('can use is checks', () {
        const AuthState state = AuthStateUnauthenticated();
        expect(state is AuthStateUnauthenticated, isTrue);
        expect(state is AuthStateLoading, isFalse);
        expect(state is AuthStateAuthenticated, isFalse);
        expect(state is AuthStateError, isFalse);
      });
    });
  });
}
