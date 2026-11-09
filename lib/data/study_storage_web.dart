import 'dart:js_interop';

import 'study_storage.dart';

@JS()
extension type _BrowserStorage(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
}

@JS('window.localStorage')
external _BrowserStorage get _localStorage;

Future<StudyStorage> createStudyStorage() async => BrowserStudyStorage();

class BrowserStudyStorage implements StudyStorage {
  static const _databaseKey = 'studyflow_db.json';

  @override
  Future<String?> read() async =>
      _localStorage.getItem(_databaseKey.toJS)?.toDart;

  @override
  Future<void> write(String contents) async {
    _localStorage.setItem(_databaseKey.toJS, contents.toJS);
  }
}
