class UserModel {
  final String uid;
  final String username;
  final String firstname;
  final String lastname;
  final String address;
  final String birthday;
  final String profileImage;
  final String email;
  final String role;
  final String? studentID; // Nullable field for student ID

  UserModel({
    required this.uid,
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.address,
    required this.birthday,
    this.profileImage = 'assets/images/default_profile.png',
    required this.email,
    required this.role,
    this.studentID, // Add studentID to the constructor
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      username: data['username'] ?? '',
      firstname: data['firstname'] ?? '',
      lastname: data['lastname'] ?? '',
      address: data['address'] ?? '',
      birthday: data['birthday'] ?? '',
      profileImage: data['profileImage'] ?? 'assets/images/default_profile.png',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      studentID: data['studentID'], // Retrieve studentID from map
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'firstname': firstname,
      'lastname': lastname,
      'address': address,
      'birthday': birthday,
      'profileImage': profileImage,
      'email': email,
      'role': role,
      'studentID': studentID, // Include studentID in map
    };
  }
}
