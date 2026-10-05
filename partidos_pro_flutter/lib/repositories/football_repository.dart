import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fb_firestore;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart' as fb_storage;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as image_lib;

import '../models/familia.dart';
import '../models/jugador.dart';
import '../models/partido.dart';

class FootballRepository {
  FootballRepository();

  final _db = fb_firestore.FirebaseFirestore.instance;
  final _storage = fb_storage.FirebaseStorage.instance;
  final _auth = fb_auth.FirebaseAuth.instance;

  // ✅ CORRECCIÓN: Constructor compatible con la mayoría de versiones
  final _googleSignIn = GoogleSignIn(
    serverClientId:
        '561211790247-ln56lmo3vc0a0ko0rcit7nq9kft3gpq5.apps.googleusercontent.com',
  );

  String? _uid;
  bool _authUnavailable = false;
  bool _googleInitialized = false;

  fb_auth.User? get currentUser => _auth.currentUser;
  bool get authUnavailable => _authUnavailable;

  Future<String> _ensureUser() async {
    if (_authUnavailable) return 'legacy-unsecured';
    var user = _auth.currentUser;
    try {
      user ??= (await _auth.signInAnonymously()).user;
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'configuration-not-found' ||
          e.code == 'operation-not-allowed') {
        _authUnavailable = true;
        _uid = 'legacy-unsecured';
        return _uid!;
      }
      rethrow;
    }
    final uid = user?.uid;
    if (uid == null) {
      throw StateError('No se pudo iniciar sesión en Firebase.');
    }
    _uid = uid;
    return uid;
  }

  Future<void> connect() async {
    await _ensureUser();
    if (!_authUnavailable) {
      await _claimLegacyDocsIfNeeded();
    }
  }

  Future<void> linkOrSignInWithEmail(String email, String password) async {
    final credential = fb_auth.EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    try {
      final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
      if (user != null && user.isAnonymous) {
        await user.linkWithCredential(credential);
      } else {
        await _auth.signInWithCredential(credential);
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use' ||
          e.code == 'credential-already-in-use' ||
          e.code == 'provider-already-linked') {
        await _auth.signInWithCredential(credential);
      } else if (e.code == 'user-not-found') {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        rethrow;
      }
    }

    _authUnavailable = false;
    _uid = _auth.currentUser?.uid;
    await _claimLegacyDocsIfNeeded();
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    _googleInitialized = true;
  }

  Future<void> linkOrSignInWithGoogle() async {
    await _ensureGoogleInitialized();

    if (!kIsWeb) {
      // En móvil, verificar que Google Play Services esté disponible
      try {
        await _googleSignIn.signInSilently();
      } catch (_) {
        // Si falla, el usuario tendrá que iniciar manualmente
      }
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // Usuario canceló
      return;
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null || idToken.isEmpty) {
      throw StateError(
        'Firebase no recibió el token de Google. Revisá la configuración SHA y google-services.json.',
      );
    }

    final credential = fb_auth.GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );

    try {
      final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
      if (user != null && user.isAnonymous) {
        await user.linkWithCredential(credential);
      } else {
        await _auth.signInWithCredential(credential);
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'provider-already-linked' ||
          e.code == 'account-exists-with-different-credential') {
        await _auth.signInWithCredential(credential);
      } else {
        rethrow;
      }
    }

    _authUnavailable = false;
    _uid = _auth.currentUser?.uid;
    await _claimLegacyDocsIfNeeded();
  }

  Future<void> _claimLegacyDocsIfNeeded() async {
    final uid = _uid ?? await _ensureUser();
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('legacy_claimed_uid') == uid) return;

    final snapshot = await _db.collection('historial').get();
    final batch = _db.batch();
    var pending = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['ownerUid'] == null || data['ownerUid'] == '') {
        batch.update(doc.reference, {
          'ownerUid': uid,
          'migrado_a_sdk_en': fb_firestore.FieldValue.serverTimestamp(),
        });
        pending++;
      }
    }
    if (pending > 0) await batch.commit();
    await prefs.setString('legacy_claimed_uid', uid);
  }

  // ==========================================
  // GESTIÓN DE GRUPO FAMILIAR (FAMILY SHARING)
  // ==========================================

  static const String _prefActiveFamilyId = 'active_family_id';
  static const String _prefActiveFamilyCode = 'active_family_code';
  static const String _prefActiveFamilyOwnerUid = 'active_family_owner_uid';
  static const String _prefActiveFamilyNombre = 'active_family_nombre';
  static const String _prefIsFamilyAdmin = 'is_family_admin';

  Future<String> _getEffectiveOwnerUid() async {
    final uid = _uid ?? await _ensureUser();
    final prefs = await SharedPreferences.getInstance();
    final familyOwnerUid = prefs.getString(_prefActiveFamilyOwnerUid);
    if (familyOwnerUid != null && familyOwnerUid.isNotEmpty) {
      return familyOwnerUid;
    }
    return uid;
  }

  Future<String?> getActiveFamilyCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefActiveFamilyCode);
  }

  Future<String?> getActiveFamilyNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefActiveFamilyNombre);
  }

  Future<bool> isFamilyAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefIsFamilyAdmin) ?? false;
  }

  Future<bool> isInFamily() async {
    final prefs = await SharedPreferences.getInstance();
    final familyId = prefs.getString(_prefActiveFamilyId);
    return familyId != null && familyId.isNotEmpty;
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ),
    );
  }

  Future<String> getOrCreateFamilyCode({
    List<Jugador> jugadores = const [],
    String? nombreFamilia,
  }) async {
    await connect();
    final uid = _uid ?? await _ensureUser();
    final prefs = await SharedPreferences.getInstance();

    final cachedCode = prefs.getString(_prefActiveFamilyCode);
    final cachedOwnerUid = prefs.getString(_prefActiveFamilyOwnerUid);
    if (cachedCode != null && cachedOwnerUid == uid) {
      await syncJugadoresToFamily(jugadores);
      return cachedCode;
    }

    final existingFamDoc = await _db.collection('familias').doc(uid).get();
    if (existingFamDoc.exists && existingFamDoc.data() != null) {
      final data = existingFamDoc.data()!;
      final existingCode = (data['codigo'] as String? ?? '').toUpperCase();
      final name = data['nombreFamilia'] as String? ?? nombreFamilia ?? 'Mi Familia';

      await prefs.setString(_prefActiveFamilyId, uid);
      await prefs.setString(_prefActiveFamilyCode, existingCode);
      await prefs.setString(_prefActiveFamilyOwnerUid, uid);
      await prefs.setString(_prefActiveFamilyNombre, name);
      await prefs.setBool(_prefIsFamilyAdmin, true);

      await syncJugadoresToFamily(jugadores);
      return existingCode;
    }

    String newCode = '';
    var unique = false;
    var attempts = 0;
    while (!unique && attempts < 10) {
      newCode = _generateRandomCode(6);
      final check = await _db.collection('codigos_familia').doc(newCode).get();
      if (!check.exists) {
        unique = true;
      }
      attempts++;
    }
    if (!unique) {
      newCode = '${_generateRandomCode(4)}${DateTime.now().millisecond}';
    }

    final familyName = (nombreFamilia != null && nombreFamilia.trim().isNotEmpty)
        ? nombreFamilia.trim()
        : 'Familia ${jugadores.isNotEmpty ? jugadores.first.nombreDisplay : ""}';

    final familyData = {
      'codigo': newCode,
      'ownerUid': uid,
      'nombreFamilia': familyName,
      'miembros': [uid],
      'jugadores': jugadores.map((j) => j.toMap()).toList(),
      'creadoEn': fb_firestore.FieldValue.serverTimestamp(),
      'actualizadoEn': fb_firestore.FieldValue.serverTimestamp(),
    };
    await _db.collection('familias').doc(uid).set(familyData);

    await _db.collection('codigos_familia').doc(newCode).set({
      'codigo': newCode,
      'familyId': uid,
      'ownerUid': uid,
      'nombreFamilia': familyName,
      'activo': true,
      'creadoEn': fb_firestore.FieldValue.serverTimestamp(),
    });

    await prefs.setString(_prefActiveFamilyId, uid);
    await prefs.setString(_prefActiveFamilyCode, newCode);
    await prefs.setString(_prefActiveFamilyOwnerUid, uid);
    await prefs.setString(_prefActiveFamilyNombre, familyName);
    await prefs.setBool(_prefIsFamilyAdmin, true);

    return newCode;
  }

  Future<GrupoFamiliar> joinFamilyWithCode(String rawCode) async {
    await connect();
    final uid = _uid ?? await _ensureUser();
    final code = rawCode.trim().toUpperCase();

    if (code.isEmpty) {
      throw StateError('Por favor ingresá un código válido.');
    }

    final codeDoc = await _db.collection('codigos_familia').doc(code).get();
    if (!codeDoc.exists || codeDoc.data() == null) {
      throw StateError('El código familiar "$code" no existe o ya caducó.');
    }

    final codeData = codeDoc.data()!;
    final familyId = (codeData['familyId'] as String? ?? codeData['ownerUid'] as String);

    final familyDoc = await _db.collection('familias').doc(familyId).get();
    if (!familyDoc.exists || familyDoc.data() == null) {
      throw StateError('No se encontró el grupo familiar para este código.');
    }

    await _db.collection('familias').doc(familyId).update({
      'miembros': fb_firestore.FieldValue.arrayUnion([uid]),
      'actualizadoEn': fb_firestore.FieldValue.serverTimestamp(),
    });

    final grupo = GrupoFamiliar.fromSnapshot(familyDoc);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefActiveFamilyId, familyId);
    await prefs.setString(_prefActiveFamilyCode, code);
    await prefs.setString(_prefActiveFamilyOwnerUid, grupo.ownerUid);
    await prefs.setString(_prefActiveFamilyNombre, grupo.nombreFamilia);
    await prefs.setBool(_prefIsFamilyAdmin, grupo.ownerUid == uid);

    if (grupo.jugadores.isNotEmpty) {
      await prefs.setStringList(
        'jugadores_perfiles',
        grupo.jugadores.map((j) => j.toJson()).toList(),
      );
      await prefs.setStringList(
        'jugadores',
        grupo.jugadores.map((j) => j.nombre).toList(),
      );
    }

    return grupo;
  }

  Future<void> leaveFamily() async {
    await connect();
    final uid = _uid ?? await _ensureUser();
    final prefs = await SharedPreferences.getInstance();

    final familyId = prefs.getString(_prefActiveFamilyId);
    final ownerUid = prefs.getString(_prefActiveFamilyOwnerUid);

    if (familyId != null && ownerUid != uid) {
      try {
        await _db.collection('familias').doc(familyId).update({
          'miembros': fb_firestore.FieldValue.arrayRemove([uid]),
          'actualizadoEn': fb_firestore.FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    await prefs.remove(_prefActiveFamilyId);
    await prefs.remove(_prefActiveFamilyCode);
    await prefs.remove(_prefActiveFamilyOwnerUid);
    await prefs.remove(_prefActiveFamilyNombre);
    await prefs.remove(_prefIsFamilyAdmin);
  }

  Future<GrupoFamiliar?> getActiveFamily() async {
    await connect();
    final prefs = await SharedPreferences.getInstance();
    final familyId = prefs.getString(_prefActiveFamilyId);
    if (familyId == null || familyId.isEmpty) return null;

    final doc = await _db.collection('familias').doc(familyId).get();
    if (!doc.exists || doc.data() == null) return null;
    return GrupoFamiliar.fromSnapshot(doc);
  }

  Future<void> syncJugadoresToFamily(List<Jugador> jugadores) async {
    final prefs = await SharedPreferences.getInstance();
    final familyId = prefs.getString(_prefActiveFamilyId);
    final isOwner = prefs.getBool(_prefIsFamilyAdmin) ?? false;

    if (familyId != null && familyId.isNotEmpty && isOwner && jugadores.isNotEmpty) {
      try {
        await _db.collection('familias').doc(familyId).update({
          'jugadores': jugadores.map((j) => j.toMap()).toList(),
          'actualizadoEn': fb_firestore.FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  Future<List<Partido>> listPartidos() async {
    await connect();
    final effectiveUid = await _getEffectiveOwnerUid();
    final snapshot = _authUnavailable
        ? await _db.collection('historial').get()
        : await _db
              .collection('historial')
              .where('ownerUid', isEqualTo: effectiveUid)
              .get();
    final all = snapshot.docs.map(Partido.fromSnapshot).toList();

    all.sort((a, b) => b.fechaPartido.compareTo(a.fechaPartido));
    return all;
  }

  Future<void> savePartido(Partido partido) async {
    await connect();
    final effectiveUid = await _getEffectiveOwnerUid();
    final prefs = await SharedPreferences.getInstance();
    final familyId = prefs.getString(_prefActiveFamilyId);

    final isEditing = partido.documentName != null;
    final data = partido.toMap(ownerUid: effectiveUid, includeCreated: !isEditing);
    if (familyId != null && familyId.isNotEmpty) {
      data['familyId'] = familyId;
    }
    if (_authUnavailable) {
      data.remove('ownerUid');
    }
    if (isEditing) {
      await _db.doc(partido.documentName!).update(data);
    } else {
      await _db.collection('historial').add(data);
    }
  }

  Future<void> updatePartidosBatch(List<Partido> partidos) async {
    if (partidos.isEmpty) return;
    await connect();
    final effectiveUid = await _getEffectiveOwnerUid();
    final prefs = await SharedPreferences.getInstance();
    final familyId = prefs.getString(_prefActiveFamilyId);

    const chunkSize = 400;
    for (var i = 0; i < partidos.length; i += chunkSize) {
      final chunk = partidos.skip(i).take(chunkSize);
      final batch = _db.batch();
      var count = 0;
      for (final p in chunk) {
        if (p.documentName != null) {
          final data = p.toMap(ownerUid: effectiveUid, includeCreated: false);
          if (familyId != null && familyId.isNotEmpty) {
            data['familyId'] = familyId;
          }
          if (_authUnavailable) {
            data.remove('ownerUid');
          }
          batch.update(_db.doc(p.documentName!), data);
          count++;
        }
      }
      if (count > 0) {
        await batch.commit();
      }
    }
  }

  Future<void> deletePartido(Partido partido) async {
    await connect();
    if (partido.fotoPath != null && partido.fotoPath!.isNotEmpty) {
      await deletePhoto(partido.fotoPath!);
    }
    if (partido.documentName != null) {
      await _db.doc(partido.documentName!).delete();
    }
  }

  Future<String> uploadPhoto(Uint8List bytes) async {
    await connect();
    final uid = _uid ?? await _ensureUser();
    final processed = _compressImage(bytes);
    final objectName = _authUnavailable
        ? 'fotos/img_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : 'users/$uid/fotos/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref(objectName);
    await ref.putData(
      processed,
      fb_storage.SettableMetadata(contentType: 'image/jpeg'),
    );
    return await ref.getDownloadURL();
  }

  Future<void> deletePhoto(String objectName) async {
    await connect();
    try {
      await _storage.ref(objectName).delete();
    } catch (_) {
      // La foto puede haber sido borrada desde otro lugar.
    }
  }

  Uint8List _compressImage(Uint8List bytes) {
    final decoded = image_lib.decodeImage(bytes);
    if (decoded == null) return bytes;
    final longest = max(decoded.width, decoded.height);
    final resized = longest > 1920
        ? image_lib.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 1920 : null,
            height: decoded.height > decoded.width ? 1920 : null,
          )
        : decoded;
    var quality = 88;
    var jpg = image_lib.encodeJpg(resized, quality: quality);
    while (jpg.length > 2 * 1024 * 1024 && quality > 35) {
      quality -= 8;
      jpg = image_lib.encodeJpg(resized, quality: quality);
    }
    return Uint8List.fromList(jpg);
  }
}
