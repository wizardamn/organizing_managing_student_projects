import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final supabase = Supabase.instance.client;
  User? get user => supabase.auth.currentUser;

  Future<void> signIn(String email, String pass) async {
    await supabase.auth.signInWithPassword(email: email, password: pass);
    notifyListeners();
  }

  Future<void> signUp(String email, String pass) async {
    await supabase.auth.signUp(email: email, password: pass);
    notifyListeners();
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    notifyListeners();
  }
}
