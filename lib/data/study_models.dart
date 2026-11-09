typedef JsonMap = Map<String, dynamic>;

JsonMap _extras(JsonMap source, Set<String> knownKeys) {
  final result = Map<String, dynamic>.from(source);
  for (final key in knownKeys) {
    result.remove(key);
  }
  return result;
}

String _stringValue(JsonMap json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('O campo "$key" precisa ser um texto.');
  }
  return value;
}

class Subject {
  const Subject({
    required this.slug,
    required this.name,
    required this.icon,
    required this.tone,
    required this.progress,
    required this.favorite,
    required this.updated,
    this.extra = const {},
  });

  final String slug;
  final String name;
  final String icon;
  final String tone;
  final int progress;
  final bool favorite;
  final int updated;
  final JsonMap extra;

  factory Subject.fromJson(JsonMap json) {
    final progress = json['progress'];
    final updated = json['updated'];
    final favorite = json['favorite'];
    if (progress is! num || updated is! num || favorite is! bool) {
      throw const FormatException('Uma matéria contém campos inválidos.');
    }
    return Subject(
      slug: _stringValue(json, 'slug'),
      name: _stringValue(json, 'name'),
      icon: _stringValue(json, 'icon'),
      tone: _stringValue(json, 'tone'),
      progress: progress.toInt(),
      favorite: favorite,
      updated: updated.toInt(),
      extra: _extras(json, {
        'slug',
        'name',
        'icon',
        'tone',
        'progress',
        'favorite',
        'updated',
      }),
    );
  }

  Subject copyWith({bool? favorite, int? updated}) => Subject(
    slug: slug,
    name: name,
    icon: icon,
    tone: tone,
    progress: progress,
    favorite: favorite ?? this.favorite,
    updated: updated ?? this.updated,
    extra: extra,
  );

  JsonMap toJson() => {
    ...extra,
    'slug': slug,
    'name': name,
    'icon': icon,
    'tone': tone,
    'progress': progress,
    'favorite': favorite,
    'updated': updated,
  };
}

class Aula {
  const Aula({
    required this.slug,
    required this.subject,
    required this.num,
    required this.title,
    required this.date,
    this.extra = const {},
  });

  final String slug;
  final String subject;
  final String num;
  final String title;
  final String date;
  final JsonMap extra;

  factory Aula.fromJson(JsonMap json) => Aula(
    slug: _stringValue(json, 'slug'),
    subject: _stringValue(json, 'subject'),
    num: _stringValue(json, 'num'),
    title: _stringValue(json, 'title'),
    date: _stringValue(json, 'date'),
    extra: _extras(json, {'slug', 'subject', 'num', 'title', 'date'}),
  );

  JsonMap toJson() => {
    ...extra,
    'slug': slug,
    'subject': subject,
    'num': num,
    'title': title,
    'date': date,
  };
}

class Note {
  const Note({
    required this.slug,
    required this.subject,
    required this.aula,
    required this.title,
    required this.date,
    required this.time,
    required this.preview,
    required this.content,
    required this.concepts,
    this.code,
    this.extra = const {},
  });

  final String slug;
  final String subject;
  final String aula;
  final String title;
  final String date;
  final String time;
  final String preview;
  final String content;
  final List<String> concepts;
  final List<String>? code;
  final JsonMap extra;

  factory Note.fromJson(JsonMap json) {
    final concepts = json['concepts'];
    final code = json['code'];
    if (concepts is! List || concepts.any((value) => value is! String)) {
      throw const FormatException('Uma anotação contém conceitos inválidos.');
    }
    if (code != null &&
        (code is! List || code.any((value) => value is! String))) {
      throw const FormatException('Uma anotação contém um exemplo inválido.');
    }
    return Note(
      slug: _stringValue(json, 'slug'),
      subject: _stringValue(json, 'subject'),
      aula: _stringValue(json, 'aula'),
      title: _stringValue(json, 'title'),
      date: _stringValue(json, 'date'),
      time: _stringValue(json, 'time'),
      preview: _stringValue(json, 'preview'),
      content: _stringValue(json, 'content'),
      concepts: List<String>.unmodifiable(concepts.cast<String>()),
      code: code == null
          ? null
          : List<String>.unmodifiable(code.cast<String>()),
      extra: _extras(json, {
        'slug',
        'subject',
        'aula',
        'title',
        'date',
        'time',
        'preview',
        'content',
        'concepts',
        'code',
      }),
    );
  }

  JsonMap toJson() => {
    ...extra,
    'slug': slug,
    'subject': subject,
    'aula': aula,
    'title': title,
    'date': date,
    'time': time,
    'preview': preview,
    'content': content,
    'concepts': concepts,
    if (code != null) 'code': code,
  };
}

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.title,
    required this.kind,
    required this.dateTime,
    this.description = '',
    this.reminderMinutes,
    this.reminderScheduled = false,
  });

  final int id;
  final String title;
  final String kind;
  final DateTime dateTime;
  final String description;
  final int? reminderMinutes;
  final bool reminderScheduled;

  factory CalendarEvent.fromJson(JsonMap json) {
    final id = json['id'];
    final dateTime = json['dateTime'];
    final reminderMinutes = json['reminderMinutes'];
    final reminderScheduled = json['reminderScheduled'] ?? false;
    if (id is! int ||
        dateTime is! String ||
        reminderScheduled is! bool ||
        (reminderMinutes != null && reminderMinutes is! int)) {
      throw const FormatException(
        'Um evento do calendário contém campos inválidos.',
      );
    }
    return CalendarEvent(
      id: id,
      title: _stringValue(json, 'title'),
      kind: _stringValue(json, 'kind'),
      dateTime: DateTime.parse(dateTime),
      description: json['description'] == null
          ? ''
          : _stringValue(json, 'description'),
      reminderMinutes: reminderMinutes as int?,
      reminderScheduled: reminderScheduled,
    );
  }

  CalendarEvent copyWith({bool? reminderScheduled}) => CalendarEvent(
    id: id,
    title: title,
    kind: kind,
    dateTime: dateTime,
    description: description,
    reminderMinutes: reminderMinutes,
    reminderScheduled: reminderScheduled ?? this.reminderScheduled,
  );

  JsonMap toJson() => {
    'id': id,
    'title': title,
    'kind': kind,
    'dateTime': dateTime.toIso8601String(),
    'description': description,
    'reminderMinutes': reminderMinutes,
    'reminderScheduled': reminderScheduled,
  };
}

class MindMapBranch {
  const MindMapBranch({required this.title, required this.topics});

  final String title;
  final List<String> topics;

  factory MindMapBranch.fromJson(JsonMap json) {
    final topics = json['topics'];
    if (topics is! List || topics.any((topic) => topic is! String)) {
      throw const FormatException('Um ramo do mapa contém tópicos inválidos.');
    }
    return MindMapBranch(
      title: _stringValue(json, 'title'),
      topics: List<String>.unmodifiable(topics.cast<String>()),
    );
  }

  JsonMap toJson() => {'title': title, 'topics': topics};
}

class StudyMindMap {
  const StudyMindMap({
    required this.id,
    required this.title,
    required this.root,
    required this.branches,
    this.subject = '',
  });

  final String id;
  final String title;
  final String root;
  final String subject;
  final List<MindMapBranch> branches;

  factory StudyMindMap.fromJson(JsonMap json) {
    final branches = json['branches'];
    if (branches is! List || branches.any((branch) => branch is! Map)) {
      throw const FormatException('Um mapa contém ramos inválidos.');
    }
    return StudyMindMap(
      id: _stringValue(json, 'id'),
      title: _stringValue(json, 'title'),
      root: _stringValue(json, 'root'),
      subject: json['subject'] == null ? '' : _stringValue(json, 'subject'),
      branches: List<MindMapBranch>.unmodifiable(
        branches.map(
          (branch) => MindMapBranch.fromJson(Map<String, dynamic>.from(branch)),
        ),
      ),
    );
  }

  JsonMap toJson() => {
    'id': id,
    'title': title,
    'root': root,
    'subject': subject,
    'branches': branches.map((branch) => branch.toJson()).toList(),
  };
}

class StudyDatabase {
  const StudyDatabase({
    required this.subjects,
    required this.aulas,
    required this.notes,
    this.events = const [],
    this.mindMaps = const [],
    this.userName = '',
    this.extra = const {},
  });

  final List<Subject> subjects;
  final List<Aula> aulas;
  final List<Note> notes;
  final List<CalendarEvent> events;
  final List<StudyMindMap> mindMaps;
  final String userName;
  final JsonMap extra;

  factory StudyDatabase.fromJson(JsonMap json) {
    List<T> decodeList<T>(String key, T Function(JsonMap) decoder) {
      final values = json[key];
      if (values is! List) {
        throw FormatException('A lista "$key" está ausente ou inválida.');
      }
      return List<T>.unmodifiable(
        values.map((value) {
          if (value is! Map) {
            throw FormatException(
              'A lista "$key" contém um registro inválido.',
            );
          }
          return decoder(Map<String, dynamic>.from(value));
        }),
      );
    }

    final userName = json['userName'] ?? '';
    if (userName is! String) {
      throw const FormatException('O nome do usuário precisa ser um texto.');
    }
    List<T> decodeOptionalList<T>(String key, T Function(JsonMap) decoder) {
      if (!json.containsKey(key)) return const [];
      return decodeList(key, decoder);
    }

    return StudyDatabase(
      subjects: decodeList('subjects', Subject.fromJson),
      aulas: decodeList('aulas', Aula.fromJson),
      notes: decodeList('notes', Note.fromJson),
      events: decodeOptionalList('events', CalendarEvent.fromJson),
      mindMaps: decodeOptionalList('mindMaps', StudyMindMap.fromJson),
      userName: userName,
      extra: _extras(json, {
        'subjects',
        'aulas',
        'notes',
        'events',
        'mindMaps',
        'userName',
      }),
    );
  }

  JsonMap toJson() => {
    ...extra,
    'userName': userName,
    'subjects': subjects.map((value) => value.toJson()).toList(),
    'aulas': aulas.map((value) => value.toJson()).toList(),
    'notes': notes.map((value) => value.toJson()).toList(),
    'events': events.map((value) => value.toJson()).toList(),
    'mindMaps': mindMaps.map((value) => value.toJson()).toList(),
  };

  StudyDatabase copyWith({
    String? userName,
    List<CalendarEvent>? events,
    List<StudyMindMap>? mindMaps,
  }) => StudyDatabase(
    subjects: subjects,
    aulas: aulas,
    notes: notes,
    events: events ?? this.events,
    mindMaps: mindMaps ?? this.mindMaps,
    userName: userName ?? this.userName,
    extra: extra,
  );

  StudyDatabase withoutExampleContent() {
    const exampleSubjects = {
      'programacao': 'Programação',
      'banco-de-dados': 'Banco de dados',
      'engenharia-de-software': 'Engenharia de software',
      'redes-de-computadores': 'Redes de computadores',
      'sistemas-operacionais': 'Sistemas operacionais',
    };
    const exampleAulas = {
      'programacao|aula-01': 'Introdução à lógica',
      'programacao|aula-02': 'Estruturas de dados',
      'programacao|aula-03': 'Orientação a objetos',
      'programacao|aula-04': 'Tratamento de erros',
      'programacao|aula-05': 'Projeto prático',
      'banco-de-dados|aula-01': 'Modelagem e DER',
      'banco-de-dados|aula-02': 'SQL e JOINs',
      'engenharia-de-software|aula-01': 'Requisitos e análise',
    };
    const exampleNotes = {
      'programacao|aula-01|o-que-e-logica': 'O que é lógica de programação?',
      'programacao|aula-01|estruturas-condicionais': 'Estruturas condicionais',
      'programacao|aula-01|lacos-de-repeticao': 'Laços de repetição',
      'programacao|aula-02|vetores-e-listas': 'Vetores e listas',
      'programacao|aula-02|pilhas-e-filas': 'Pilhas e filas',
      'programacao|aula-03|classes-e-objetos': 'Classes e objetos',
      'banco-de-dados|aula-01|entidades-e-relacionamentos':
          'Entidades e relacionamentos',
      'banco-de-dados|aula-02|inner-join': 'INNER JOIN na prática',
      'banco-de-dados|aula-02|left-e-right-join': 'LEFT e RIGHT JOIN',
      'engenharia-de-software|aula-01|funcionais-vs-nao-funcionais':
          'Requisitos funcionais e não funcionais',
      'engenharia-de-software|aula-01|levantamento': 'Técnicas de levantamento',
    };

    final examples = exampleSubjects.entries
        .where(
          (entry) => subjects.any(
            (subject) =>
                subject.slug == entry.key && subject.name == entry.value,
          ),
        )
        .map((entry) => entry.key)
        .toSet();
    if (examples.isEmpty) return this;

    final remainingNotes = notes.where((note) {
      final key = '${note.subject}|${note.aula}|${note.slug}';
      return !examples.contains(note.subject) ||
          exampleNotes[key] != note.title;
    }).toList();
    final remainingAulas = aulas.where((aula) {
      final key = '${aula.subject}|${aula.slug}';
      final isExample =
          examples.contains(aula.subject) && exampleAulas[key] == aula.title;
      final hasCustomNote = remainingNotes.any(
        (note) => note.subject == aula.subject && note.aula == aula.slug,
      );
      return !isExample || hasCustomNote;
    }).toList();
    final subjectsToKeep = subjects.where((subject) {
      if (!examples.contains(subject.slug)) return true;
      return remainingAulas.any((aula) => aula.subject == subject.slug) ||
          remainingNotes.any((note) => note.subject == subject.slug);
    }).toList();

    return StudyDatabase(
      subjects: List.unmodifiable(subjectsToKeep),
      aulas: List.unmodifiable(remainingAulas),
      notes: List.unmodifiable(remainingNotes),
      events: events,
      mindMaps: mindMaps,
      userName: userName,
      extra: extra,
    );
  }
}
