

class User {
  String user, password;

  User({required this.user, required this.password});


  /// Get user data from database record [dbrecord]
  static User fromDB(String dbrecord) {
    return User(user: dbrecord.split(':')[0], password: dbrecord.split(':')[1]);
  }
}
