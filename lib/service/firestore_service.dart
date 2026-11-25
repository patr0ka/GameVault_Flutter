import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../database/model/game_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'É necessário estar autenticado para acessar a biblioteca.',
      );
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _gamesFor(String userId) {
    return _firestore.collection('users').doc(userId).collection('games');
  }

  String newDocumentId() => _gamesFor(_userId).doc().id;

  Future<void> saveAt(String documentId, Game game) async {
    final userId = _userId;
    if (documentId.trim().isEmpty) {
      throw ArgumentError('Informe o ID remoto do jogo.');
    }
    if (game.userId != userId) {
      throw StateError('O jogo pertence a outra conta.');
    }
    _validateGame(game.toFirestoreMap());

    final document = _gamesFor(userId).doc(documentId);
    final current = await document.get(const GetOptions(source: Source.server));

    final data = <String, dynamic>{
      ...game.toFirestoreMap(),
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (!current.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await document.set(data, SetOptions(merge: true));
  }

  Future<void> create(Map<String, dynamic> gameData) async {
    _validateGame(gameData);

    final userId = _userId;
    final data = Map<String, dynamic>.from(gameData)
      ..remove('userId')
      ..remove('createdAt')
      ..remove('updatedAt');

    await _gamesFor(userId).add({
      ...data,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> read() {
    final userId = _userId;
    return _gamesFor(userId).orderBy('updatedAt', descending: true).snapshots();
  }

  Future<void> update(String documentId, Map<String, dynamic> gameData) async {
    if (documentId.trim().isEmpty) {
      throw ArgumentError.value(
        documentId,
        'documentId',
        'Informe o ID do jogo.',
      );
    }

    final data = Map<String, dynamic>.from(gameData)
      ..remove('userId')
      ..remove('createdAt')
      ..remove('updatedAt');
    if (data.isEmpty) {
      throw ArgumentError('Informe ao menos um campo para atualizar.');
    }

    final userId = _userId;
    await _gamesFor(userId)
        .doc(documentId)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> delete(String documentId) async {
    if (documentId.trim().isEmpty) {
      throw ArgumentError.value(
        documentId,
        'documentId',
        'Informe o ID do jogo.',
      );
    }

    final userId = _userId;
    await _gamesFor(userId).doc(documentId).delete();
  }

  void _validateGame(Map<String, dynamic> gameData) {
    final rawgId = gameData['rawgId'];
    if (rawgId != null && (rawgId is! int || rawgId <= 0)) {
      throw ArgumentError('O ID da RAWG deve ser maior que zero.');
    }

    final name = gameData['name'];
    if (name is! String || name.trim().isEmpty) {
      throw ArgumentError('O jogo precisa ter um nome.');
    }
  }
}
