import 'study_storage.dart';
import 'study_storage_stub.dart'
    if (dart.library.io) 'study_storage_io.dart'
    if (dart.library.html) 'study_storage_web.dart'
    as platform;

Future<StudyStorage> createStudyStorage() => platform.createStudyStorage();
