import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  // To build Singleton
  static final DatabaseService _cameraServiceService = DatabaseService._internal();

  late File _dbFile;
  Map<String, dynamic> _db = <String, dynamic>{};


  factory DatabaseService() {


    return _cameraServiceService;
  }
  // To build Singleton
  DatabaseService._internal();


  // Getter for the attribute
  get db => _db;


  /// Loads the database from local file
  Future load() async {
    var appDir = await getApplicationDocumentsDirectory();
    String _dbPath = appDir.path + '/db.json';

    _dbFile = File(_dbPath);

    if (_dbFile.existsSync()) {
      _db = json.decode(_dbFile.readAsStringSync());
    }
  }


  /// Saves a user data in the db file
  ///
  /// A user identify by his [name], [password] and Face representation for Machine Learning model [modelData]
  Future saveData(String name, String password, List modelData) async {
    _db[name+':'+password] = modelData;
    _dbFile.writeAsStringSync(json.encode(_db));
  }


  /// Deletes all users from the database
  clear() {
    _db = <String, dynamic>{};
    _dbFile.writeAsStringSync(json.encode({}));
  }
}
