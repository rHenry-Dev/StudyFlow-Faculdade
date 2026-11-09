import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'study_storage.dart';

Future<StudyStorage> createStudyStorage() async {
  final documents = await getApplicationDocumentsDirectory();
  return FileStudyStorage(
    File('${documents.path}${Platform.pathSeparator}studyflow_db.json'),
  );
}

class FileStudyStorage implements StudyStorage {
  FileStudyStorage(this._file);

  final File _file;

  @override
  Future<String?> read() async {
    if (!await _file.exists()) return null;
    return _file.readAsString();
  }

  @override
  Future<void> write(String contents) async {
    await _file.parent.create(recursive: true);
    final temporaryFile = File('${_file.path}.tmp');
    await temporaryFile.writeAsString(contents, flush: true);
    await temporaryFile.rename(_file.path);
  }
}
