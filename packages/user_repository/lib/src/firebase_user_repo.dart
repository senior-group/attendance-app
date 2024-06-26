import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:user_repository/user_repository.dart';

class FirebaseUserRepo implements UserRepository{
  final FirebaseAuth _firebaseAuth;
  final usersCollection = FirebaseFirestore.instance.collection('users');

  FirebaseUserRepo({FirebaseAuth? firebaseAuth}) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Stream<MyUser?> get user {
    return _firebaseAuth.authStateChanges().switchMap((firebaseUser) {
      if(firebaseUser == null) {
        return Stream.value(MyUser.empty);
      } else {
        return usersCollection
          .doc(firebaseUser.uid)
          .snapshots()
          .map((snapshot) => MyUser.fromEntity(MyUserEntity.fromJson(snapshot.data()!)));
      }
    });
  }

  Future<MyUser> getUser(String userId) {
    try {
      return usersCollection
      .doc(userId)
      .get()
      .then((snapshot) { 
        if(snapshot.exists) {
          return MyUser.fromEntity(MyUserEntity.fromJson(snapshot.data()!));
        } else {
          throw Exception('User not found');
        }
      });
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    try{
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } catch(e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<MyUser> signUp(MyUser myUser, String password) async {
    try{
      // Check if the email already exists
      bool emailExists = await checkEmailExists(myUser.email);
      if(emailExists) {
        throw Exception('Email already exists');
      }

      UserCredential user = await _firebaseAuth.createUserWithEmailAndPassword(
        email: myUser.email,
        password: password
      );

      myUser.userId = user.user!.uid;
      return myUser;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> logOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> setUserData(MyUser myUser) async {
    try{
      await usersCollection
        .doc(myUser.userId)
        .set(myUser.toEntity().toJson());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
  // HELPER FUNCTIONS
  Future<bool> checkEmailExists(String email) async {
    QuerySnapshot <Map<String, dynamic>> query = await usersCollection
      .where('email', isEqualTo: email)
      .limit(1)
      .get();

    return query.docs.isNotEmpty;
  }
}