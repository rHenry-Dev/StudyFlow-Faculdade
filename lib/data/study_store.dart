import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'study_models.dart';
import 'study_storage.dart';
import 'study_storage_factory.dart';

class StudyStore extends ChangeNotifier {
  StudyStore._(this._storage, this._database);

  final StudyStorage _storage;
  StudyDatabase _database;

  StudyDatabase get database => _database;
  List<Subject> get subjects => _database.subjects;
  List<Aula> get aulas => _database.aulas;
  List<Note> get notes => _database.notes;
  List<CalendarEvent> get events => _database.events;
  List<StudyMindMap> get mindMaps => _database.mindMaps;
  String get userName => _database.userName;
  int get nextEventId =>
      events.fold<int>(
        0,
        (current, event) => event.id > current ? event.id : current,
      ) +
      1;

  Future<void> setUserName(String value) async {
    final name = value.trim();
    if (name.isEmpty) {
      throw const FormatException('Informe seu nome para continuar.');
    }
    await _save(_database.copyWith(userName: name));
  }

  static Future<StudyStore> open(
    String seedJson, {
    StudyStorage? storage,
  }) async {
    final persistence = storage ?? await createStudyStorage();
    StudyDatabase database;
    final savedContents = await persistence.read();
    if (savedContents != null) {
      database = _decode(savedContents);
      if (database.userName.isEmpty) {
        final cleanedDatabase = database.withoutExampleContent();
        if (!identical(cleanedDatabase, database)) {
          await persistence.write(jsonEncode(cleanedDatabase.toJson()));
        }
        database = cleanedDatabase;
      }
    } else {
      database = _decode(seedJson);
      await persistence.write(jsonEncode(database.toJson()));
    }
    return StudyStore._(persistence, database);
  }

  static StudyDatabase _decode(String source) {
    final value = jsonDecode(source);
    if (value is! Map) {
      throw const FormatException('O banco local não contém um objeto JSON.');
    }
    return StudyDatabase.fromJson(Map<String, dynamic>.from(value));
  }

  Subject? subjectBySlug(String slug) {
    for (final subject in subjects) {
      if (subject.slug == slug) return subject;
    }
    return null;
  }

  Aula? aulaBySlug(String subjectSlug, String aulaSlug) {
    for (final aula in aulas) {
      if (aula.subject == subjectSlug && aula.slug == aulaSlug) return aula;
    }
    return null;
  }

  Note? noteBySlug(String subjectSlug, String aulaSlug, String noteSlug) {
    for (final note in notes) {
      if (note.subject == subjectSlug &&
          note.aula == aulaSlug &&
          note.slug == noteSlug) {
        return note;
      }
    }
    return null;
  }

  List<Aula> aulasForSubject(String subjectSlug) =>
      aulas.where((aula) => aula.subject == subjectSlug).toList();

  List<Note> notesForSubject(String subjectSlug) =>
      notes.where((note) => note.subject == subjectSlug).toList();

  List<Note> notesForAula(String subjectSlug, String aulaSlug) => notes
      .where((note) => note.subject == subjectSlug && note.aula == aulaSlug)
      .toList();

  Future<void> addEvent(CalendarEvent event) async {
    final updated = [...events.where((value) => value.id != event.id), event]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    await _save(
      _database.copyWith(events: List<CalendarEvent>.unmodifiable(updated)),
    );
  }

  Future<void> deleteEvent(int id) async {
    await _save(
      _database.copyWith(
        events: List<CalendarEvent>.unmodifiable(
          events.where((event) => event.id != id),
        ),
      ),
    );
  }

  Future<void> addMindMap(StudyMindMap mindMap) async {
    final updated = [
      ...mindMaps.where((value) => value.id != mindMap.id),
      mindMap,
    ];
    await _save(
      _database.copyWith(mindMaps: List<StudyMindMap>.unmodifiable(updated)),
    );
  }

  Future<void> deleteMindMap(String id) async {
    await _save(
      _database.copyWith(
        mindMaps: List<StudyMindMap>.unmodifiable(
          mindMaps.where((mindMap) => mindMap.id != id),
        ),
      ),
    );
  }

  Future<void> addSubject(Subject subject, {Aula? initialAula}) async {
    final updated = [
      subject,
      ...subjects.where((value) => value.slug != subject.slug),
    ];
    final updatedAulas = initialAula == null
        ? aulas
        : [
            ...aulas.where(
              (value) =>
                  !(value.subject == initialAula.subject &&
                      value.slug == initialAula.slug),
            ),
            initialAula,
          ];
    await _save(
      StudyDatabase(
        subjects: List.unmodifiable(updated),
        aulas: List.unmodifiable(updatedAulas),
        notes: notes,
        events: events,
        mindMaps: mindMaps,
        userName: _database.userName,
        extra: _database.extra,
      ),
    );
  }

  Future<void> addAula(Aula aula) async {
    final updated = [
      ...aulas.where(
        (value) => !(value.subject == aula.subject && value.slug == aula.slug),
      ),
      aula,
    ];
    await _save(
      StudyDatabase(
        subjects: subjects,
        aulas: List.unmodifiable(updated),
        notes: notes,
        events: events,
        mindMaps: mindMaps,
        userName: _database.userName,
        extra: _database.extra,
      ),
    );
  }

  Future<void> addNote(Note note, {Aula? initialAula}) async {
    final updated = [
      note,
      ...notes.where(
        (value) =>
            !(value.subject == note.subject &&
                value.aula == note.aula &&
                value.slug == note.slug),
      ),
    ];
    final updatedAulas = initialAula == null
        ? aulas
        : [
            ...aulas.where(
              (value) =>
                  !(value.subject == initialAula.subject &&
                      value.slug == initialAula.slug),
            ),
            initialAula,
          ];
    await _save(
      StudyDatabase(
        subjects: subjects,
        aulas: List.unmodifiable(updatedAulas),
        notes: List.unmodifiable(updated),
        events: events,
        mindMaps: mindMaps,
        userName: _database.userName,
        extra: _database.extra,
      ),
    );
  }

  Future<void> deleteNote(String subject, String aula, String note) async {
    await _save(
      StudyDatabase(
        subjects: subjects,
        aulas: aulas,
        notes: List.unmodifiable(
          notes.where(
            (value) =>
                !(value.subject == subject &&
                    value.aula == aula &&
                    value.slug == note),
          ),
        ),
        events: events,
        mindMaps: mindMaps,
        userName: _database.userName,
        extra: _database.extra,
      ),
    );
  }

  Future<void> toggleFavorite(String slug) async {
    final updated = subjects
        .map(
          (value) => value.slug == slug
              ? value.copyWith(
                  favorite: !value.favorite,
                  updated: DateTime.now().millisecondsSinceEpoch,
                )
              : value,
        )
        .toList();
    await _save(
      StudyDatabase(
        subjects: List.unmodifiable(updated),
        aulas: aulas,
        notes: notes,
        events: events,
        mindMaps: mindMaps,
        userName: _database.userName,
        extra: _database.extra,
      ),
    );
  }

  Future<void> _save(StudyDatabase database) async {
    await _storage.write(jsonEncode(database.toJson()));
    _database = database;
    notifyListeners();
  }
}
