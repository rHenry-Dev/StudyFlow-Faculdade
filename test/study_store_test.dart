import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/data/study_models.dart';
import 'package:studyflow/data/study_store.dart';
import 'package:studyflow/data/study_storage.dart';

void main() {
  late MemoryStudyStorage storage;

  setUp(() async {
    storage = MemoryStudyStorage();
  });

  test('cria o banco local a partir do JSON inicial', () async {
    const seed =
        '{"subjects":[],"aulas":[],"notes":[],"userName":"","versao":1}';
    final store = await StudyStore.open(seed, storage: storage);
    final saved = jsonDecode(storage.contents!) as Map<String, dynamic>;

    expect(store.subjects, isEmpty);
    expect(store.userName, isEmpty);
    expect(saved['versao'], 1);
    expect(saved['subjects'], isEmpty);
    await store.setUserName('  Ana  ');
    expect(store.userName, 'Ana');
  });

  test('persiste alterações e mantém dados desconhecidos', () async {
    const seed = '{"subjects":[],"aulas":[],"notes":[],"versao":1}';
    final store = await StudyStore.open(seed, storage: storage);
    await store.addSubject(
      const Subject(
        slug: 'programacao',
        name: 'Programação',
        icon: 'CodeXml',
        tone: 'violet',
        progress: 0,
        favorite: false,
        updated: 1,
        extra: {'origem': 'importado'},
      ),
    );
    await store.addAula(
      const Aula(
        slug: 'aula-01',
        subject: 'programacao',
        num: '01',
        title: 'Introdução',
        date: '08 nov. 2026',
      ),
    );
    await store.addNote(
      const Note(
        slug: 'logica',
        subject: 'programacao',
        aula: 'aula-01',
        title: 'Lógica',
        date: '08 nov. 2026',
        time: '10:00',
        preview: 'Resumo',
        content: 'Conteúdo da nota.',
        concepts: ['Algoritmos'],
      ),
    );
    await store.toggleFavorite('programacao');

    final reopened = await StudyStore.open(seed, storage: storage);
    final saved = jsonDecode(storage.contents!) as Map<String, dynamic>;
    final subject = saved['subjects'][0] as Map<String, dynamic>;

    expect(reopened.subjects, hasLength(1));
    expect(reopened.subjects.single.favorite, isTrue);
    expect(reopened.aulas, hasLength(1));
    expect(reopened.notes.single.content, 'Conteúdo da nota.');
    expect(subject['origem'], 'importado');
    expect(saved['versao'], 1);
  });

  test('persiste compromissos, avisos e mapas mentais', () async {
    const seed = '{"subjects":[],"aulas":[],"notes":[]}';
    final store = await StudyStore.open(seed, storage: storage);
    final event = CalendarEvent(
      id: store.nextEventId,
      title: 'Prova',
      kind: 'Prova',
      dateTime: DateTime(2026, 12, 1, 10),
      reminderMinutes: 10,
      reminderScheduled: true,
    );
    await store.addEvent(event);
    await store.addMindMap(
      const StudyMindMap(
        id: 'mapa-1',
        title: 'Revisão',
        root: 'Banco de dados',
        branches: [
          MindMapBranch(title: 'SQL', topics: ['SELECT', 'JOIN']),
        ],
      ),
    );

    final reopened = await StudyStore.open(seed, storage: storage);

    expect(reopened.events.single.title, 'Prova');
    expect(reopened.events.single.reminderMinutes, 10);
    expect(reopened.events.single.reminderScheduled, isTrue);
    expect(reopened.mindMaps.single.root, 'Banco de dados');
    expect(reopened.mindMaps.single.branches.single.topics, ['SELECT', 'JOIN']);
    await reopened.deleteEvent(event.id);
    await reopened.deleteMindMap('mapa-1');
    expect(reopened.events, isEmpty);
    expect(reopened.mindMaps, isEmpty);
  });

  test('remove exemplos antigos sem apagar conteúdo próprio', () async {
    storage.contents = jsonEncode({
      'subjects': [
        {
          'slug': 'programacao',
          'name': 'Programação',
          'icon': 'CodeXml',
          'tone': 'violet',
          'progress': 75,
          'favorite': true,
          'updated': 5,
        },
        {
          'slug': 'meu-curso',
          'name': 'Meu curso',
          'icon': 'BookOpen',
          'tone': 'violet',
          'progress': 0,
          'favorite': false,
          'updated': 1,
        },
      ],
      'aulas': [
        {
          'slug': 'aula-01',
          'subject': 'programacao',
          'num': '01',
          'title': 'Introdução à lógica',
          'date': '12 set. 2026',
        },
        {
          'slug': 'aula-01',
          'subject': 'meu-curso',
          'num': '01',
          'title': 'Minha aula',
          'date': '08 nov. 2026',
        },
      ],
      'notes': [],
    });

    final store = await StudyStore.open(
      '{"subjects":[],"aulas":[],"notes":[]}',
      storage: storage,
    );

    expect(store.subjects.map((subject) => subject.slug), ['meu-curso']);
    expect(store.aulas.single.title, 'Minha aula');
  });

  test('não sobrescreve um banco existente inválido', () async {
    const invalid = '{dados inválidos';
    storage.contents = invalid;

    expect(
      () => StudyStore.open(
        '{"subjects":[],"aulas":[],"notes":[]}',
        storage: storage,
      ),
      throwsFormatException,
    );
    expect(storage.contents, invalid);
  });
}

class MemoryStudyStorage implements StudyStorage {
  String? contents;

  @override
  Future<String?> read() async => contents;

  @override
  Future<void> write(String value) async {
    contents = value;
  }
}
