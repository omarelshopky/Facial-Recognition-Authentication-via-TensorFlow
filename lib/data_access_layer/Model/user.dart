

class User {
  String user, password;

  User({required this.user, required this.password});


  static User fromDB(String dbrecord) {
    return User(user: dbrecord.split(':')[0], password: dbrecord.split(':')[1]);
  }
}
