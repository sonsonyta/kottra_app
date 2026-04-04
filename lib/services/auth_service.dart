import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthServiceBase {
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> signInWithEmployeeToken(String loginToken);

  Future<void> signOut();
}

class AuthService implements AuthServiceBase {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFunctions? firebaseFunctions,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firebaseFunctions = firebaseFunctions ?? FirebaseFunctions.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFunctions _firebaseFunctions;
  final GoogleSignIn _googleSignIn;

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    await _googleSignIn.initialize();
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signInWithEmployeeToken(String loginToken) async {
    final HttpsCallable callable = _firebaseFunctions.httpsCallable(
      'consumeEmployeeLoginToken',
    );
    final HttpsCallableResult<dynamic> result = await callable.call(
      <String, dynamic>{'token': loginToken},
    );

    final dynamic data = result.data;
    if (data is! Map) {
      throw const FormatException(
        'The consumeEmployeeLoginToken response is invalid.',
      );
    }

    final dynamic customTokenValue = data['customToken'];
    if (customTokenValue is! String || customTokenValue.isEmpty) {
      throw const FormatException(
        'The consumeEmployeeLoginToken response did not include a customToken.',
      );
    }

    await _firebaseAuth.signInWithCustomToken(customTokenValue);
  }

  @override
  Future<void> signOut() async {
    await Future.wait<void>([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }
}
