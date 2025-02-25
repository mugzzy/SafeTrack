import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'audit_log_service.dart'; // Import the AuditLogService

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditLogService =
      AuditLogService(); // Initialize AuditLogService

  // Check if email is already used
  Future<bool> isEmailTaken(String email) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  // Check if student ID is already used
  Future<bool> isStudentIDTaken(String studentID) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('studentID', isEqualTo: studentID)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  // Check if username is already taken
  Future<bool> isUsernameTaken(String username) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  // Register a new user without logging them in
  Future<Map<String, dynamic>> registerOrUpdate(
    String email,
    String password,
    String role, {
    required String username,
    required String firstname,
    required String lastname,
    required String address,
    required String birthday,
    String? teacherKey,
    String? studentID,
  }) async {
    try {
      // Check if email, username, and student ID are already taken
      if (await isEmailTaken(email)) {
        return {'success': false, 'message': 'Email is already in use.'};
      }

      if (await isUsernameTaken(username)) {
        return {'success': false, 'message': 'Username is already in use.'};
      }

      if (role == 'Student' &&
          studentID != null &&
          await isStudentIDTaken(studentID)) {
        return {'success': false, 'message': 'Student ID is already in use.'};
      }

      if (role == 'Teacher' && teacherKey != '1234') {
        return {'success': false, 'message': 'Invalid teacher key.'};
      }

      // Create a new user in Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Create a new UserModel object
        UserModel newUser = UserModel(
          uid: user.uid,
          username: username,
          firstname: firstname,
          lastname: lastname,
          address: address,
          birthday: birthday,
          email: email,
          role: role,
          studentID: studentID,
        );

        // Store the new user's data in Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

        // Log the account creation event
        await _auditLogService.logActivity(
            username, email, role, 'created', 'Account created');

        return {'success': true, 'message': 'Registration successful!'};
      } else {
        return {'success': false, 'message': 'Registration failed.'};
      }
    } catch (e) {
      print(e.toString());
      return {
        'success': false,
        'message': 'An error occurred during registration.'
      };
    }
  }

  // Delete user by UID
  Future<void> deleteUser(String uid) async {
    try {
      // Delete user from Firebase Auth
      User? user = await _auth.currentUser;
      if (user != null && user.uid == uid) {
        await user.delete();
        print('User deleted from FirebaseAuth.');
      }

      // Delete user from Firestore
      await _firestore.collection('users').doc(uid).delete();
      print('User document deleted from Firestore.');
    } catch (e) {
      print('Error deleting user: ${e.toString()}');
    }
  }

  // Login an existing user
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        // Log the login event
        await _auditLogService.logActivity(
          doc['username'], // Username from Firestore
          user.email ?? 'N/A',
          doc['role'], // Role from Firestore
          'logged in',
          'User logged in',
        );

        return UserModel.fromMap(doc.data() as Map<String, dynamic>, user.uid);
      } else {
        return null;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign out the currently authenticated user
  Future<bool> signOut() async {
    try {
      // Get the current user
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // Log the logout event
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        await _auditLogService.logActivity(
          doc['username'], // Username from Firestore
          currentUser.email ?? 'N/A',
          doc['role'], // Role from Firestore
          'logged out',
          'User logged out',
        );
      }

      // Check if the user is signed in with Google
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
        print("Google Sign-In session terminated.");
      }

      // Firebase sign-out
      await _auth.signOut();
      return true;
    } catch (e) {
      print("Error during sign-out: ${e.toString()}");
      return false;
    }
  }

  // Retrieve user details from Firestore using the user's UID
  // Get user details by UID
  Future<UserModel?> getUserDetails(String uid) async {
    try {
      // Try to fetch the document from Firestore
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      // If the document doesn't exist, create temporary data
      if (!doc.exists || doc.data() == null) {
        print("No document found for UID: $uid. Creating temporary data...");

        // Temporary data
        Map<String, dynamic> tempData = {
          'username': 'temp_user_$uid',
          'email': null,
          'role': 'Student',
          'firstname': 'Temporary',
          'lastname': 'User',
          'address': 'N/A',
          'birthday': 'N/A',
          'studentID': null,
        };

        // Add the temporary data to Firestore
        await _firestore.collection('users').doc(uid).set(tempData);

        // Return the temporary data as a UserModel
        return UserModel.fromMap(tempData, uid);
      }

      // If document exists, convert it to UserModel
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return UserModel.fromMap(data, uid);
    } catch (e) {
      print("GetUserDetails Error: ${e.toString()}");
      return null;
    }
  }
}
