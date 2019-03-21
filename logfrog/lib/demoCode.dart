import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logfrog/noteClassDemo.dart';


// Access a Cloud Firestore instance from your Activity
Firestore db = Firestore.instance;

// Reference to a Collection
CollectionReference notesCollectionRef = db.collection('notes');

// Reference to a Document in a Collection
DocumentReference jsaDocumentRef = db.collection('notes').document('gkz');
// or
DocumentReference jsaDocumentRef2 = db.document('notes/gkz');

// Hierarchical Data with Subcollection-Document in a Document
DocumentReference androidTutRef = db
    .collection('notes').document('gkz')
    .collection('tutorials').document('flutterTutRef');


final CollectionReference noteCollection = Firestore.instance.collection('notes');

class FirebaseFirestoreService {

  static final FirebaseFirestoreService _instance = new FirebaseFirestoreService.internal();

  factory FirebaseFirestoreService() => _instance;

  FirebaseFirestoreService.internal();

  Future<Note> createNote(String title, String description) async {
    final TransactionHandler createTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(noteCollection.document());

      final Note note = new Note(ds.documentID, title, description);
      final Map<String, dynamic> data = note.toMap();

      await tx.set(ds.reference, data);

      return data;
    };

    return Firestore.instance.runTransaction(createTransaction).then((mapData) {
      return Note.fromMap(mapData);
    }).catchError((error) {
      print('error: $error');
      return null;
    });
  }

  Stream<QuerySnapshot> getNoteList({int offset, int limit}) {
    Stream<QuerySnapshot> snapshots = noteCollection.snapshots();

    if (offset != null) {
      snapshots = snapshots.skip(offset);
    }

    if (limit != null) {
      snapshots = snapshots.take(limit);
    }

    return snapshots;
  }

  Future<dynamic> updateNote(Note note) async {
    final TransactionHandler updateTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(noteCollection.document(note.id));
      await tx.update(ds.reference, note.toMap());
      return {'updated': true};
    };

    return Firestore.instance
        .runTransaction(updateTransaction)
        .then((result) => result['updated'])
        .catchError((error) {
      print('error: $error');
      return false;
    });
  }

  Future<dynamic> deleteNote(String id) async {
    final TransactionHandler deleteTransaction = (Transaction tx) async {
      final DocumentSnapshot ds = await tx.get(noteCollection.document(id));

      await tx.delete(ds.reference);
      return {'deleted': true};
    };

    return Firestore.instance
        .runTransaction(deleteTransaction)
        .then((result) => result['deleted'])
        .catchError((error) {
      print('error: $error');
      return false;
    });
  }
}
