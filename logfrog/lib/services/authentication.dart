import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logfrog/users.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
abstract class BaseAuth {

  Future<String> signIn(String email, String password);

  Future<String> signUp(String email, String password);

  Future<FirebaseUser> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();

  Future<bool> reauthenticate(String password);
}

class Auth implements BaseAuth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String _email;



  String getEmail(){return _email;}


  Future<String> signIn(String email, String password) async {
    FirebaseUser user = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    _email = email;
    return user.uid;
  }

  Future<String> signUp(String email, String password) async {
    FirebaseUser user = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    final CollectionReference usersCollection =
    Firestore.instance.collection('Users');
    final CollectionReference equipmentCollection =
    Firestore.instance.collection('Objects');


    Future<Users> createNewUser(
        { String id,
          String emailAddress,
          List<String> databases,}) async {
      final TransactionHandler createTransaction = (Transaction tx) async {
        DocumentSnapshot ds;
        DocumentSnapshot objectsDs;
        ds = await tx.get(usersCollection.document(id));
        objectsDs = await tx.get(equipmentCollection.document());
        databases.add(objectsDs.documentID.toString());
        var dataMap = new Map<String, dynamic>();
        dataMap['emailAddress'] = emailAddress;
        dataMap['databases'] = databases;
        await tx.set(ds.reference, dataMap);
        await tx.set(objectsDs.reference, new Map<String, dynamic>());
        return dataMap;
      };
      return usersCollection.document(id).get().then((doc) {
        if (doc.exists){
          //throw ("error: Item ID already exists");
        } else {
          return Firestore.instance.runTransaction(createTransaction).then((mapData) {
            return Users.fromMap(mapData);
          }).catchError((error) {
            throw ('error: unable to communicate with server');
          });
        }
      }).catchError((e){
        throw (e);
      });
    }
    createNewUser(id: user.uid, emailAddress: email, databases: []);
    return user.uid;
  }

  Future<FirebaseUser> getCurrentUser() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    if (user != null)
      {_email = user.email;}
    return user;
  }

  Future<void> signOut() async {
    return _firebaseAuth.signOut();
  }

  Future<void> sendEmailVerification() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    user.sendEmailVerification();
  }
  
  Future<void> updatePassword(String newPass) async{
    FirebaseUser user = await _firebaseAuth.currentUser();
    user.updatePassword(newPass);
  }

  Future<bool> reauthenticate(String password) async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    _email = user.email;
    try {
      user = await _firebaseAuth.signInWithEmailAndPassword(
          email: _email, password: password);
      if (user.uid != null) {
        return true;
      }
      else {
        return false;
      }
    }
    catch(e){}
    return false;
  }

  Future<bool> isEmailVerified() async {
    FirebaseUser user = await _firebaseAuth.currentUser();
    return user.isEmailVerified;
  }

}
