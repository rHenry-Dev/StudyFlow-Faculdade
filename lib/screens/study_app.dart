import 'dart:io';

import 'package:flutter/material.dart';

import '../data/study_models.dart';
import '../data/study_store.dart';
import '../notifications/reminder_service.dart';

const _violet = Color(0xFF9B7BFF);
const _electric = Color(0xFF54A8FF);
const _lime = Color(0xFF86D96B);
const _amber = Color(0xFFFFC45C);
const _cyan = Color(0xFF55D4D4);
const _magenta = Color(0xFFE880D5);

Color _toneColor(String tone) => switch (tone) {
  'electric' => _electric,
  'lime' => _lime,
  'amber' => _amber,
  'cyan' => _cyan,
  'magenta' => _magenta,
  _ => _violet,
};

IconData _subjectIcon(String icon) => switch (icon) {
  'CodeXml' => Icons.code,
  'Database' => Icons.storage_outlined,
  'Settings' => Icons.settings_outlined,
  'Command' => Icons.terminal,
  'Cpu' => Icons.memory,
  'BookOpenText' || 'BookOpen' => Icons.menu_book_outlined,
  'FileText' => Icons.description_outlined,
  'NotebookPen' => Icons.edit_note,
  'GraduationCap' => Icons.school_outlined,
  'Sparkles' => Icons.auto_awesome_outlined,
  _ => Icons.menu_book_outlined,
};

String _slugify(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[áàãâä]'), 'a')
    .replaceAll(RegExp(r'[éèêë]'), 'e')
    .replaceAll(RegExp(r'[íìîï]'), 'i')
    .replaceAll(RegExp(r'[óòõôö]'), 'o')
    .replaceAll(RegExp(r'[úùûü]'), 'u')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

String _dateLabel(DateTime date) {
  const months = [
    'jan.',
    'fev.',
    'mar.',
    'abr.',
    'mai.',
    'jun.',
    'jul.',
    'ago.',
    'set.',
    'out.',
    'nov.',
    'dez.',
  ];
  return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String _plural(int count, String singular, String plural) =>
    '$count ${count == 1 ? singular : plural}';

void _showPersistenceError(
  BuildContext context,
  String action,
  FileSystemException error,
) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text('Não foi possível $action: ${error.message}')),
    );
}

class StudyApp extends StatefulWidget {
  const StudyApp({super.key, required this.store, required this.reminders});

  final StudyStore store;
  final ReminderService reminders;

  @override
  State<StudyApp> createState() => _StudyAppState();
}

class _StudyAppState extends State<StudyApp> {
  int _tab = 0;

  void _openQuickAction() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Criar rapidamente',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              _QuickAction(
                icon: Icons.edit_note,
                label: 'Nova anotação',
                color: _violet,
                onTap: () {
                  Navigator.pop(context);
                  _push(NewNotePage(store: widget.store));
                },
              ),
              _QuickAction(
                icon: Icons.menu_book_outlined,
                label: 'Nova matéria',
                color: _electric,
                onTap: () {
                  Navigator.pop(context);
                  _push(NewSubjectPage(store: widget.store));
                },
              ),
              _QuickAction(
                icon: Icons.account_tree_outlined,
                label: 'Novo mapa mental',
                color: _cyan,
                onTap: () {
                  Navigator.pop(context);
                  _push(NewMindMapPage(store: widget.store));
                },
              ),
              _QuickAction(
                icon: Icons.calendar_month_outlined,
                label: 'Novo evento',
                color: _amber,
                onTap: () {
                  Navigator.pop(context);
                  _push(
                    NewCalendarEventPage(
                      store: widget.store,
                      reminders: widget.reminders,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(store: widget.store, onOpenSubject: _openSubject),
      SubjectsPage(store: widget.store, onOpenSubject: _openSubject),
      CalendarPage(store: widget.store, reminders: widget.reminders),
      MapsPage(store: widget.store),
      NotificationsPage(store: widget.store, reminders: widget.reminders),
    ];
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) => Scaffold(
        body: IndexedStack(index: _tab, children: pages),
        floatingActionButton: _tab == 0
            ? FloatingActionButton(
                onPressed: _openQuickAction,
                backgroundColor: _violet,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.edit_note),
              label: 'Anotações',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Calendário',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_tree_outlined),
              label: 'Mapas',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none),
              label: 'Avisos',
            ),
          ],
        ),
      ),
    );
  }

  void _openSubject(Subject subject) {
    _push(SubjectPage(store: widget.store, subjectSlug: subject.slug));
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(label),
    onTap: onTap,
  );
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.child, this.eyebrow});

  final String title;
  final String? eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (eyebrow != null) ...[
                const SizedBox(height: 5),
                Text(
                  eyebrow!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              child,
            ]),
          ),
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF30303A)),
    ),
    child: child,
  );
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({
    required this.subject,
    required this.store,
    required this.onTap,
  });

  final Subject subject;
  final StudyStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(subject.tone);
    final noteCount = store.notesForSubject(subject.slug).length;
    final aulaCount = store.aulasForSubject(subject.slug).length;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          foregroundColor: color,
          child: Icon(_subjectIcon(subject.icon)),
        ),
        title: Text(subject.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_plural(noteCount, 'anotação', 'anotações')} · ${_plural(aulaCount, 'aula', 'aulas')}',
              ),
              if (subject.progress > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: subject.progress.clamp(0, 100) / 100,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ],
          ),
        ),
        trailing: subject.favorite
            ? const Icon(Icons.star, color: _amber)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.store, required this.onOpenSubject});

  final StudyStore store;
  final ValueChanged<Subject> onOpenSubject;

  @override
  Widget build(BuildContext context) {
    final progress = store.subjects.isEmpty
        ? 0
        : (store.subjects.fold<int>(
                    0,
                    (total, subject) => total + subject.progress,
                  ) /
                  store.subjects.length)
              .round();
    return _Page(
      title: 'Olá, ${store.userName}.',
      eyebrow: 'Seu conhecimento, em um só lugar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seu progresso geral',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            store.subjects.isEmpty
                                ? 'Adicione suas matérias para acompanhar seu progresso.'
                                : 'Seu progresso nas matérias cadastradas.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress / 100,
                            strokeWidth: 6,
                            backgroundColor: const Color(0xFF30303A),
                            color: _violet,
                          ),
                          Center(
                            child: Text(
                              '$progress%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _Statistic(
                      icon: Icons.menu_book_outlined,
                      count: store.subjects.length,
                      label: 'matérias',
                    ),
                    const SizedBox(width: 10),
                    _Statistic(
                      icon: Icons.edit_note,
                      count: store.notes.length,
                      label: 'anotações',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _SectionHeading(
            title: 'Minhas matérias',
            action: 'Ver todas',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _StandaloneSubjectsPage(
                  store: store,
                  onOpenSubject: onOpenSubject,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (store.subjects.isEmpty)
            _EmptyMessage(
              message: 'Você ainda não cadastrou matérias.',
              action: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NewSubjectPage(store: store),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Cadastrar primeira matéria'),
              ),
            )
          else
            ...store.subjects
                .take(4)
                .map(
                  (subject) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _SubjectTile(
                      subject: subject,
                      store: store,
                      onTap: () => onOpenSubject(subject),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _Statistic extends StatelessWidget {
  const _Statistic({
    required this.icon,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF22222D),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: Colors.white70),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );
}

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({
    super.key,
    required this.store,
    required this.onOpenSubject,
  });

  final StudyStore store;
  final ValueChanged<Subject> onOpenSubject;

  @override
  Widget build(BuildContext context) => _StandaloneSubjectsPage(
    store: store,
    onOpenSubject: onOpenSubject,
    embedded: true,
  );
}

class _StandaloneSubjectsPage extends StatefulWidget {
  const _StandaloneSubjectsPage({
    required this.store,
    required this.onOpenSubject,
    this.embedded = false,
  });

  final StudyStore store;
  final ValueChanged<Subject> onOpenSubject;
  final bool embedded;

  @override
  State<_StandaloneSubjectsPage> createState() =>
      _StandaloneSubjectsPageState();
}

class _StandaloneSubjectsPageState extends State<_StandaloneSubjectsPage> {
  String _query = '';
  String _filter = 'Todas';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    var subjects = widget.store.subjects
        .where((subject) => subject.name.toLowerCase().contains(query))
        .toList();
    if (_filter == 'Favoritas') {
      subjects = subjects.where((subject) => subject.favorite).toList();
    } else if (_filter == 'Recentes') {
      subjects.sort((a, b) => b.updated.compareTo(a.updated));
    } else if (_filter == 'A-Z') {
      subjects.sort((a, b) => a.name.compareTo(b.name));
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Buscar matéria...',
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Todas', 'Favoritas', 'Recentes', 'A-Z']
                .map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (subjects.isEmpty)
          const _EmptyMessage(message: 'Nenhuma matéria encontrada.')
        else
          ...subjects.map(
            (subject) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Dismissible(
                key: ValueKey(subject.slug),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  try {
                    await widget.store.toggleFavorite(subject.slug);
                  } on FileSystemException catch (error) {
                    if (context.mounted) {
                      _showPersistenceError(
                        context,
                        'atualizar o favorito',
                        error,
                      );
                    }
                  }
                  return false;
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: _amber.withValues(alpha: 0.15),
                  child: Icon(
                    subject.favorite ? Icons.star_border : Icons.star,
                    color: _amber,
                  ),
                ),
                child: _SubjectTile(
                  subject: subject,
                  store: widget.store,
                  onTap: () => widget.onOpenSubject(subject),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => NewSubjectPage(store: widget.store),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nova matéria'),
        ),
      ],
    );

    if (!widget.embedded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Minhas matérias')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [content],
          ),
        ),
      );
    }

    return _Page(
      title: 'Minhas matérias',
      eyebrow: 'Organize seus estudos por disciplina.',
      child: content,
    );
  }
}

class SubjectPage extends StatefulWidget {
  const SubjectPage({
    super.key,
    required this.store,
    required this.subjectSlug,
  });

  final StudyStore store;
  final String subjectSlug;

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  int _view = 0;

  @override
  Widget build(BuildContext context) {
    final subject = widget.store.subjectBySlug(widget.subjectSlug);
    if (subject == null) {
      return const Scaffold(
        body: _EmptyMessage(message: 'Matéria não encontrada.'),
      );
    }
    final aulas = widget.store.aulasForSubject(subject.slug);
    final notes = widget.store.notesForSubject(subject.slug);
    final color = _toneColor(subject.tone);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(subject.name),
        actions: [
          IconButton(
            tooltip: subject.favorite ? 'Remover dos favoritos' : 'Favoritar',
            onPressed: () async {
              try {
                await widget.store.toggleFavorite(subject.slug);
              } on FileSystemException catch (error) {
                if (context.mounted) {
                  _showPersistenceError(context, 'atualizar o favorito', error);
                }
              }
            },
            icon: Icon(
              subject.favorite ? Icons.star : Icons.star_border,
              color: subject.favorite ? _amber : null,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: color.withValues(alpha: 0.15),
                  foregroundColor: color,
                  child: Icon(_subjectIcon(subject.icon)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_plural(notes.length, 'anotação', 'anotações')} · ${_plural(aulas.length, 'aula', 'aulas')}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Aulas')),
                ButtonSegment(value: 1, label: Text('Anotações')),
                ButtonSegment(value: 2, label: Text('Mapa')),
              ],
              selected: {_view},
              onSelectionChanged: (value) =>
                  setState(() => _view = value.first),
            ),
            const SizedBox(height: 16),
            if (_view == 0) ...[
              const Text(
                'Suas aulas',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              const SizedBox(height: 10),
              if (aulas.isEmpty)
                const _EmptyMessage(message: 'Nenhuma aula cadastrada ainda.')
              else
                ...aulas.map(
                  (aula) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.class_outlined),
                        ),
                        title: Text('Aula ${aula.num} — ${aula.title}'),
                        subtitle: Text(
                          '${aula.date} · ${_plural(widget.store.notesForAula(subject.slug, aula.slug).length, 'anotação', 'anotações')}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AulaPage(
                              store: widget.store,
                              subjectSlug: subject.slug,
                              aulaSlug: aula.slug,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        NewAulaPage(store: widget.store, subject: subject),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nova aula'),
              ),
            ] else if (_view == 1) ...[
              if (notes.isEmpty)
                const _EmptyMessage(message: 'Nenhuma anotação nesta matéria.')
              else
                ...notes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _NoteTile(
                      note: note,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NotePage(
                            store: widget.store,
                            subjectSlug: subject.slug,
                            aulaSlug: note.aula,
                            noteSlug: note.slug,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NewNotePage(
                      store: widget.store,
                      initialSubject: subject.slug,
                    ),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Nova anotação'),
              ),
            ] else
              _MindMapCard(
                title: 'Mapa mental de ${subject.name}',
                description: 'Abra os mapas mentais da matéria.',
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}

class AulaPage extends StatefulWidget {
  const AulaPage({
    super.key,
    required this.store,
    required this.subjectSlug,
    required this.aulaSlug,
  });

  final StudyStore store;
  final String subjectSlug;
  final String aulaSlug;

  @override
  State<AulaPage> createState() => _AulaPageState();
}

class _AulaPageState extends State<AulaPage> {
  int _view = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final aula = widget.store.aulaBySlug(widget.subjectSlug, widget.aulaSlug);
    if (aula == null) {
      return const Scaffold(
        body: _EmptyMessage(message: 'Aula não encontrada.'),
      );
    }
    final notes = widget.store.notesForAula(
      widget.subjectSlug,
      widget.aulaSlug,
    );
    final filtered = notes
        .where(
          (note) => note.title.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Aula ${aula.num} — ${aula.title}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              '${aula.date} · ${_plural(notes.length, 'anotação', 'anotações')}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 18),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Anotações')),
                ButtonSegment(value: 1, label: Text('Resumo')),
              ],
              selected: {_view},
              onSelectionChanged: (value) =>
                  setState(() => _view = value.first),
            ),
            const SizedBox(height: 16),
            if (_view == 0) ...[
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar anotações...',
                ),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const _EmptyMessage(
                  message: 'Nenhuma anotação nesta aula ainda.',
                )
              else
                ...filtered.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _NoteTile(
                      note: note,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => NotePage(
                            store: widget.store,
                            subjectSlug: note.subject,
                            aulaSlug: note.aula,
                            noteSlug: note.slug,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ] else if (notes.isEmpty)
              const _EmptyMessage(
                message: 'Adicione anotações para gerar o resumo desta aula.',
              )
            else
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo da aula',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ...notes.map(
                      (note) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: '${note.title}: ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: note.preview),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: const CircleAvatar(
        backgroundColor: Color(0x269B7BFF),
        child: Icon(Icons.description_outlined, color: _violet),
      ),
      title: Text(note.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('${note.date} · ${note.time}\n${note.preview}'),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class NotePage extends StatefulWidget {
  const NotePage({
    super.key,
    required this.store,
    required this.subjectSlug,
    required this.aulaSlug,
    required this.noteSlug,
  });

  final StudyStore store;
  final String subjectSlug;
  final String aulaSlug;
  final String noteSlug;

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  bool _studied = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.store.noteBySlug(
      widget.subjectSlug,
      widget.aulaSlug,
      widget.noteSlug,
    );
    final subject = widget.store.subjectBySlug(widget.subjectSlug);
    if (note == null || subject == null) {
      return const Scaffold(
        body: _EmptyMessage(message: 'Anotação não encontrada.'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anotação'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'excluir') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Excluir anotação?'),
                    content: const Text('Esta ação não pode ser desfeita.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Excluir'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  try {
                    await widget.store.deleteNote(
                      widget.subjectSlug,
                      widget.aulaSlug,
                      widget.noteSlug,
                    );
                  } on FileSystemException catch (error) {
                    if (context.mounted) {
                      _showPersistenceError(
                        context,
                        'excluir a anotação',
                        error,
                      );
                    }
                    return;
                  }
                  if (context.mounted) Navigator.pop(context);
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'excluir', child: Text('Excluir anotação')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              note.title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Text(
              '${subject.name} · ${note.date} · ${note.time}',
              style: TextStyle(color: _toneColor(subject.tone)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Conteúdo',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              note.content,
              style: const TextStyle(height: 1.65, color: Colors.white70),
            ),
            const SizedBox(height: 22),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Principais conceitos',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ...note.concepts.map(
                    (concept) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: _violet),
                          const SizedBox(width: 10),
                          Expanded(child: Text(concept)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (note.code != null) ...[
              const SizedBox(height: 22),
              const Text(
                'Exemplo prático',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var index = 0; index < note.code!.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${index + 1}  ${note.code![index]}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: Colors.white70,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => setState(() => _studied = !_studied),
              icon: Icon(
                _studied ? Icons.check_circle : Icons.check_circle_outline,
              ),
              label: Text(_studied ? 'Estudado' : 'Marcar como estudado'),
              style: _studied
                  ? FilledButton.styleFrom(
                      backgroundColor: _lime.withValues(alpha: 0.2),
                      foregroundColor: _lime,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class NewSubjectPage extends StatefulWidget {
  const NewSubjectPage({super.key, required this.store});

  final StudyStore store;

  @override
  State<NewSubjectPage> createState() => _NewSubjectPageState();
}

class _NewSubjectPageState extends State<NewSubjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _icon = 'BookOpenText';
  String _tone = 'violet';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova matéria')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const Text(
                'Adicione uma nova disciplina ao seu estudo.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome da matéria'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe um nome.'
                    : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Ícone',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children:
                    {
                          'CodeXml': Icons.code,
                          'Database': Icons.storage_outlined,
                          'Settings': Icons.settings_outlined,
                          'Command': Icons.terminal,
                          'BookOpenText': Icons.menu_book_outlined,
                        }.entries
                        .map(
                          (entry) => IconButton.filledTonal(
                            onPressed: () => setState(() => _icon = entry.key),
                            style: IconButton.styleFrom(
                              backgroundColor: _icon == entry.key
                                  ? _violet.withValues(alpha: 0.25)
                                  : null,
                              foregroundColor: _icon == entry.key
                                  ? _violet
                                  : null,
                            ),
                            icon: Icon(entry.value),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cor da matéria',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                children:
                    ['electric', 'violet', 'cyan', 'lime', 'amber', 'magenta']
                        .map(
                          (tone) => ChoiceChip(
                            label: Text(tone == _tone ? 'Selecionada' : ''),
                            avatar: CircleAvatar(
                              backgroundColor: _toneColor(tone),
                            ),
                            selected: _tone == tone,
                            onSelected: (_) => setState(() => _tone = tone),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _save(context, widget.store),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar matéria'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, StudyStore store) async {
    if (!_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    final now = DateTime.now();
    final normalizedSlug = _slugify(name);
    final slug = normalizedSlug.isEmpty
        ? 'materia-${now.millisecondsSinceEpoch}'
        : normalizedSlug;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await store.addSubject(
        Subject(
          slug: slug,
          name: name,
          icon: _icon,
          tone: _tone,
          progress: 0,
          favorite: false,
          updated: now.millisecondsSinceEpoch,
        ),
        initialAula: Aula(
          slug: 'aula-01',
          subject: slug,
          num: '01',
          title: 'Introdução',
          date: _dateLabel(now),
        ),
      );
    } on FileSystemException catch (error) {
      if (context.mounted) {
        _showPersistenceError(context, 'salvar a matéria', error);
      }
      return;
    }
    if (!context.mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Matéria criada com sucesso!')),
    );
  }
}

class NewAulaPage extends StatefulWidget {
  const NewAulaPage({super.key, required this.store, required this.subject});

  final StudyStore store;
  final Subject subject;

  @override
  State<NewAulaPage> createState() => _NewAulaPageState();
}

class _NewAulaPageState extends State<NewAulaPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nova aula')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título da aula'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe um título.'
                  : null,
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: _save, child: const Text('Salvar aula')),
          ],
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final aulas = widget.store.aulasForSubject(widget.subject.slug);
    final next =
        aulas
            .map((aula) => int.tryParse(aula.num) ?? 0)
            .fold<int>(
              0,
              (current, value) => value > current ? value : current,
            ) +
        1;
    final number = next.toString().padLeft(2, '0');
    final aula = Aula(
      slug: 'aula-$number',
      subject: widget.subject.slug,
      num: number,
      title: _title.text.trim(),
      date: _dateLabel(DateTime.now()),
    );
    try {
      await widget.store.addAula(aula);
    } on FileSystemException catch (error) {
      if (mounted) _showPersistenceError(context, 'salvar a aula', error);
      return;
    }
    if (mounted) Navigator.pop(context);
  }
}

class NewNotePage extends StatefulWidget {
  const NewNotePage({super.key, required this.store, this.initialSubject});

  final StudyStore store;
  final String? initialSubject;

  @override
  State<NewNotePage> createState() => _NewNotePageState();
}

class _NewNotePageState extends State<NewNotePage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  late String _subjectSlug;
  String? _aulaSlug;

  @override
  void initState() {
    super.initState();
    _subjectSlug =
        widget.initialSubject ??
        (widget.store.subjects.isEmpty ? '' : widget.store.subjects.first.slug);
    final aulas = widget.store.aulasForSubject(_subjectSlug);
    if (_aulaSlug == null && aulas.isNotEmpty) _aulaSlug = aulas.first.slug;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    if (store.subjects.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nova anotação')),
        body: const _EmptyMessage(
          message: 'Cadastre uma matéria antes de criar anotações.',
        ),
      );
    }
    final aulas = store.aulasForSubject(_subjectSlug);
    return Scaffold(
      appBar: AppBar(title: const Text('Nova anotação')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const Text(
                'Crie uma nova anotação para sua aula.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: store.subjectBySlug(_subjectSlug)?.slug,
                decoration: const InputDecoration(labelText: 'Matéria'),
                items: store.subjects
                    .map(
                      (subject) => DropdownMenuItem(
                        value: subject.slug,
                        child: Text(subject.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _subjectSlug = value!;
                  final available = store.aulasForSubject(value);
                  _aulaSlug = available.isEmpty ? null : available.first.slug;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: aulas.any((aula) => aula.slug == _aulaSlug)
                    ? _aulaSlug
                    : null,
                decoration: const InputDecoration(labelText: 'Aula'),
                items: [
                  ...aulas.map(
                    (aula) => DropdownMenuItem<String?>(
                      value: aula.slug,
                      child: Text('Aula ${aula.num} — ${aula.title}'),
                    ),
                  ),
                  if (aulas.isEmpty)
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Aula 01 — Introdução (nova)'),
                    ),
                ],
                onChanged: (value) => setState(() => _aulaSlug = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Título da anotação',
                  hintText: 'Ex.: Conceitos de variáveis',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe um título.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _content,
                minLines: 7,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: 'Conteúdo',
                  hintText: 'Digite sua anotação aqui...',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Digite o conteúdo.'
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _save(context, store, aulas),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar anotação'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    StudyStore store,
    List<Aula> aulas,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    var aulaSlug = _aulaSlug;
    Aula? initialAula;
    final date = DateTime.now();
    if (aulaSlug == null || aulas.isEmpty) {
      aulaSlug = 'aula-01';
      initialAula = Aula(
        slug: aulaSlug,
        subject: _subjectSlug,
        num: '01',
        title: 'Introdução',
        date: _dateLabel(date),
      );
    }
    final title = _title.text.trim();
    final content = _content.text.trim();
    final concepts = content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.length > 3 && line.length < 35)
        .take(4)
        .toList();
    if (concepts.isEmpty) concepts.add(title);
    final slug = _slugify(title);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await store.addNote(
        Note(
          slug: slug.isEmpty ? 'nota-${date.millisecondsSinceEpoch}' : slug,
          subject: _subjectSlug,
          aula: aulaSlug,
          title: title,
          date: _dateLabel(date),
          time:
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
          preview: content.length > 80
              ? '${content.substring(0, 80)}...'
              : content,
          content: content,
          concepts: concepts,
        ),
        initialAula: initialAula,
      );
    } on FileSystemException catch (error) {
      if (context.mounted) {
        _showPersistenceError(context, 'salvar a anotação', error);
      }
      return;
    }
    if (!context.mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Anotação salva com sucesso!')),
    );
  }
}

class MapsPage extends StatefulWidget {
  const MapsPage({super.key, required this.store});

  final StudyStore store;

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.store.mindMaps.where((map) {
      final subject = widget.store.subjectBySlug(map.subject)?.name ?? '';
      return '${map.title} ${map.root} $subject'.toLowerCase().contains(_query);
    }).toList();
    return _Page(
      title: 'Mapas mentais',
      eyebrow: 'Organize ideias a partir de um tema central.',
      child: Column(
        children: [
          TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar mapa...',
            ),
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            _EmptyMessage(
              message: widget.store.mindMaps.isEmpty
                  ? 'Você ainda não criou mapas mentais.'
                  : 'Nenhum mapa encontrado.',
            )
          else
            ...filtered.map(
              (map) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MindMapCard(
                  title: map.title,
                  description: [
                    if (widget.store.subjectBySlug(map.subject) != null)
                      widget.store.subjectBySlug(map.subject)!.name,
                    map.root,
                  ].join(' · '),
                  color: _toneColor(
                    widget.store.subjectBySlug(map.subject)?.tone ?? 'violet',
                  ),
                  root: map.root,
                  branches: [
                    for (final branch in map.branches)
                      (branch.title, branch.topics),
                  ],
                  onDelete: () => _deleteMap(map),
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NewMindMapPage(store: widget.store),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Novo mapa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMap(StudyMindMap map) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir mapa?'),
        content: Text('O mapa "${map.title}" será removido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.store.deleteMindMap(map.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível excluir o mapa: $error')),
        );
      }
    }
  }
}

class _MindMapBranchEditor {
  final title = TextEditingController();
  final topics = TextEditingController();

  void dispose() {
    title.dispose();
    topics.dispose();
  }
}

class NewMindMapPage extends StatefulWidget {
  const NewMindMapPage({super.key, required this.store});

  final StudyStore store;

  @override
  State<NewMindMapPage> createState() => _NewMindMapPageState();
}

class _NewMindMapPageState extends State<NewMindMapPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _root = TextEditingController();
  final List<_MindMapBranchEditor> _branches = [_MindMapBranchEditor()];
  String? _subject;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _root.dispose();
    for (final branch in _branches) {
      branch.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novo mapa mental')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título do mapa'),
              validator: _required,
            ),
            const SizedBox(height: 14),
            if (widget.store.subjects.isNotEmpty)
              DropdownButtonFormField<String?>(
                initialValue: _subject,
                decoration: const InputDecoration(
                  labelText: 'Matéria (opcional)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sem matéria'),
                  ),
                  ...widget.store.subjects.map(
                    (subject) => DropdownMenuItem<String?>(
                      value: subject.slug,
                      child: Text(subject.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _subject = value),
              ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _root,
              decoration: const InputDecoration(
                labelText: 'Tema central',
                hintText: 'Ideia principal do mapa',
              ),
              validator: _required,
            ),
            const SizedBox(height: 20),
            const Text(
              'Ramos e subtópicos',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < _branches.length; index++)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ramo ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_branches.length > 1)
                            IconButton(
                              tooltip: 'Remover ramo',
                              onPressed: () => _removeBranch(index),
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
                      TextFormField(
                        controller: _branches[index].title,
                        decoration: const InputDecoration(
                          labelText: 'Nome do ramo',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _branches[index].topics,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Subtópicos',
                          hintText: 'Digite um subtópico por linha',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addBranch,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar ramo'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Salvar mapa'),
            ),
          ],
        ),
      ),
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Preencha este campo.' : null;

  void _addBranch() => setState(() => _branches.add(_MindMapBranchEditor()));

  void _removeBranch(int index) {
    final branch = _branches.removeAt(index);
    branch.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final mindMap = StudyMindMap(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      root: _root.text.trim(),
      subject: _subject ?? '',
      branches: List.unmodifiable(
        _branches.map(
          (branch) => MindMapBranch(
            title: branch.title.text.trim(),
            topics: List.unmodifiable(
              branch.topics.text
                  .split('\n')
                  .map((topic) => topic.trim())
                  .where((topic) => topic.isNotEmpty),
            ),
          ),
        ),
      ),
    );
    try {
      await widget.store.addMindMap(mindMap);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar o mapa: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MindMapCard extends StatelessWidget {
  const _MindMapCard({
    required this.title,
    required this.description,
    required this.color,
    this.root,
    this.branches = const [],
    this.onDelete,
  });

  final String title;
  final String description;
  final Color color;
  final String? root;
  final List<(String, List<String>)> branches;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        child: const Icon(Icons.account_tree_outlined),
      ),
      title: Text(title),
      subtitle: Text(description),
      trailing: onDelete == null
          ? null
          : IconButton(
              tooltip: 'Excluir mapa',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Text(
                    root ?? title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (branches.isNotEmpty) ...[
                Container(width: 1, height: 16, color: Colors.white24),
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: branches
                      .map(
                        (branch) => SizedBox(
                          width: 132,
                          child: Column(
                            children: [
                              Container(
                                width: 1,
                                height: 12,
                                color: Colors.white24,
                              ),
                              Text(
                                branch.$1,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...branch.$2.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22222D),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.store, required this.reminders});

  final StudyStore store;
  final ReminderService reminders;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime _selected = DateTime.now();

  Color _eventColor(String kind) => switch (kind) {
    'Aula' => _electric,
    'Prova' => _amber,
    'Trabalho' => _violet,
    _ => _lime,
  };

  String _monthName(int month) => const [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ][month - 1];

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(_month.year, _month.month).weekday % 7;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final dayEvents = widget.store.events
        .where(
          (event) =>
              event.dateTime.year == _selected.year &&
              event.dateTime.month == _selected.month &&
              event.dateTime.day == _selected.day,
        )
        .toList();
    final exams =
        widget.store.events
            .where(
              (event) =>
                  event.kind == 'Prova' &&
                  !event.dateTime.isBefore(DateTime(_month.year, _month.month)),
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return _Page(
      title: 'Calendário',
      eyebrow: 'Cadastre aulas, provas, trabalhos e compromissos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _addEvent,
              icon: const Icon(Icons.add),
              label: const Text('Novo compromisso'),
            ),
          ),
          const SizedBox(height: 12),
          _Panel(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_monthName(_month.month)} ${_month.year}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month - 1),
                      ),
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Mês anterior',
                    ),
                    IconButton(
                      onPressed: () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1),
                      ),
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Próximo mês',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                for (var row = 0; row < (firstWeekday + daysInMonth) / 7; row++)
                  Row(
                    children: List.generate(7, (column) {
                      final day = row * 7 + column - firstWeekday + 1;
                      if (day < 1 || day > daysInMonth) {
                        return const Expanded(child: SizedBox(height: 44));
                      }
                      final date = DateTime(_month.year, _month.month, day);
                      final events = widget.store.events
                          .where(
                            (event) =>
                                event.dateTime.year == date.year &&
                                event.dateTime.month == date.month &&
                                event.dateTime.day == date.day,
                          )
                          .toList();
                      final selected =
                          date.year == _selected.year &&
                          date.month == _selected.month &&
                          date.day == _selected.day;
                      return Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => setState(() => _selected = date),
                          child: SizedBox(
                            height: 44,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: selected ? _violet : null,
                                  child: Text(
                                    '$day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: events.take(3).map((event) {
                                    return Container(
                                      width: 4,
                                      height: 4,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: selected
                                            ? Colors.white
                                            : _eventColor(event.kind),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                const Divider(height: 20),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: ['Aula', 'Prova', 'Trabalho', 'Pessoal', 'Outro']
                      .map(
                        (kind) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 7,
                              color: _eventColor(kind),
                            ),
                            const SizedBox(width: 5),
                            Text(kind, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _isToday(_selected)
                ? 'Hoje, ${_selected.day} de ${_monthName(_selected.month).toLowerCase()}'
                : '${_selected.day} de ${_monthName(_selected.month).toLowerCase()}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (dayEvents.isEmpty)
            const _EmptyMessage(message: 'Nada agendado para este dia.')
          else
            ...dayEvents.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _EventTile(
                  event: event,
                  color: _eventColor(event.kind),
                  onDelete: () => _deleteEvent(event),
                ),
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'Provas',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (exams.isEmpty)
            const _EmptyMessage(message: 'Nenhuma prova neste período.')
          else
            ...exams.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _EventTile(
                  event: event,
                  color: _amber,
                  onDelete: () => _deleteEvent(event),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _addEvent() async {
    final event = await Navigator.of(context).push<CalendarEvent>(
      MaterialPageRoute(
        builder: (_) => NewCalendarEventPage(
          store: widget.store,
          reminders: widget.reminders,
        ),
      ),
    );
    if (event != null && mounted) {
      setState(() {
        _month = DateTime(event.dateTime.year, event.dateTime.month);
        _selected = event.dateTime;
      });
    }
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    try {
      await widget.reminders.cancel(event.id);
      await widget.store.deleteEvent(event.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível excluir o compromisso: $error'),
          ),
        );
      }
    }
  }
}

class NewCalendarEventPage extends StatefulWidget {
  const NewCalendarEventPage({
    super.key,
    required this.store,
    required this.reminders,
  });

  final StudyStore store;
  final ReminderService reminders;

  @override
  State<NewCalendarEventPage> createState() => _NewCalendarEventPageState();
}

class _NewCalendarEventPageState extends State<NewCalendarEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime _dateTime = DateTime.now().add(const Duration(hours: 1));
  String _kind = 'Aula';
  int? _reminderMinutes = 10;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novo compromisso')),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe um título.'
                  : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const ['Aula', 'Prova', 'Trabalho', 'Pessoal', 'Outro']
                  .map(
                    (kind) => DropdownMenuItem(value: kind, child: Text(kind)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _kind = value ?? _kind),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Data'),
              subtitle: Text(_formatEventDate(_dateTime)),
              onTap: _selectDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Horário'),
              subtitle: Text(_formatEventTime(_dateTime)),
              onTap: _selectTime,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _reminderMinutes,
              decoration: const InputDecoration(labelText: 'Aviso no celular'),
              items: const [
                DropdownMenuItem<int?>(value: null, child: Text('Sem aviso')),
                DropdownMenuItem<int?>(value: 0, child: Text('No horário')),
                DropdownMenuItem<int?>(
                  value: 10,
                  child: Text('10 minutos antes'),
                ),
                DropdownMenuItem<int?>(
                  value: 30,
                  child: Text('30 minutos antes'),
                ),
              ],
              onChanged: (value) => setState(() => _reminderMinutes = value),
            ),
            if (widget.reminders.initializationError case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'O serviço de notificações não iniciou: $error',
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Salvar compromisso'),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(
      () => _dateTime = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _dateTime.hour,
        _dateTime.minute,
      ),
    );
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (selected == null || !mounted) return;
    setState(
      () => _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        selected.hour,
        selected.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final event = CalendarEvent(
      id: widget.store.nextEventId,
      title: _title.text.trim(),
      kind: _kind,
      dateTime: _dateTime,
      description: _description.text.trim(),
      reminderMinutes: _reminderMinutes,
    );
    var reminderResult = ReminderResult.noReminder;
    String? reminderFailure;
    try {
      try {
        reminderResult = await widget.reminders.schedule(event);
      } catch (error) {
        reminderFailure = error.toString();
      }
      final savedEvent = event.copyWith(
        reminderScheduled:
            reminderResult == ReminderResult.scheduledExact ||
            reminderResult == ReminderResult.scheduledApproximate,
      );
      await widget.store.addEvent(savedEvent);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, savedEvent);
      final message = switch (reminderResult) {
        ReminderResult.scheduledExact =>
          'Compromisso salvo e aviso exato agendado.',
        ReminderResult.scheduledApproximate => 'Compromisso salvo. O Android pode atrasar o aviso; permita alarmes exatos nas configurações para maior precisão.',
        ReminderResult.noPermission => 'Compromisso salvo, mas as notificações estão bloqueadas. Ative-as nas configurações do Android.',
        ReminderResult.unsupported => 'Compromisso salvo. Avisos do sistema estão disponíveis no aplicativo Android.',
        ReminderResult.tooLate =>
          'Compromisso salvo, mas o horário do aviso já passou.',
        ReminderResult.noReminder => 'Compromisso salvo.',
      };
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            reminderFailure == null
                ? message
                : '$message Falha: $reminderFailure',
          ),
        ),
      );
    } catch (error) {
      if (reminderResult == ReminderResult.scheduledExact ||
          reminderResult == ReminderResult.scheduledApproximate) {
        try {
          await widget.reminders.cancel(event.id);
        } catch (cancelError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Não foi possível cancelar o aviso após a falha ($cancelError).',
                ),
              ),
            );
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível salvar o compromisso: $error'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.color,
    required this.onDelete,
  });

  final CalendarEvent event;
  final Color color;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Container(
        width: 4,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      title: Text(event.title),
      subtitle: Text(
        '${event.kind} · ${_formatEventDate(event.dateTime)} · ${_formatEventTime(event.dateTime)}'
        '${event.reminderMinutes == null
            ? ''
            : event.reminderScheduled
            ? ' · aviso agendado'
            : ' · aviso não agendado'}'
        '${event.description.isEmpty ? '' : '\n${event.description}'}',
      ),
      isThreeLine: event.description.isNotEmpty,
      trailing: IconButton(
        tooltip: 'Excluir compromisso',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    ),
  );
}

String _formatEventDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _formatEventTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
    required this.store,
    required this.reminders,
  });

  final StudyStore store;
  final ReminderService reminders;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  Widget build(BuildContext context) {
    final events =
        widget.store.events
            .where((event) => event.reminderMinutes != null)
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final pending = events.where((event) => !event.reminderScheduled).length;
    return _Page(
      title: 'Avisos',
      eyebrow: events.isEmpty
          ? 'Os lembretes aparecem aqui quando você os cadastrar no calendário.'
          : pending == 0
          ? 'Todos os lembretes estão agendados.'
          : '$pending ${pending == 1 ? 'lembrete precisa' : 'lembretes precisam'} de atenção.',
      child: Column(
        children: [
          if (widget.reminders.initializationError case final error?)
            _EmptyMessage(message: 'Falha ao iniciar avisos: $error')
          else if (!widget.reminders.supportsScheduledReminders)
            const _EmptyMessage(
              message: 'Os avisos de tela de bloqueio funcionam no aplicativo Android. O Android também precisa permitir notificações na tela de bloqueio.',
            )
          else
            const _EmptyMessage(
              message: 'Os avisos são enviados pelo Android. Permita as notificações do StudyFlow e a exibição na tela de bloqueio nas configurações do aparelho.',
            ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const _EmptyMessage(message: 'Nenhum lembrete cadastrado.')
          else
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      event.reminderScheduled
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      color: event.reminderScheduled ? _violet : _amber,
                    ),
                    title: Text(event.title),
                    subtitle: Text(
                      '${_formatEventDate(event.dateTime)} · ${_formatEventTime(event.dateTime)} · '
                      '${switch (event.reminderMinutes) {
                        0 => 'no horário',
                        10 => '10 min antes',
                        30 => '30 min antes',
                        _ => 'horário personalizado',
                      }}'
                      '${event.reminderScheduled ? '\nAviso agendado' : '\nAviso ainda não agendado'}',
                    ),
                    isThreeLine: true,
                    trailing: event.reminderScheduled
                        ? null
                        : IconButton(
                            tooltip: 'Tentar agendar aviso',
                            onPressed: () => _retry(event),
                            icon: const Icon(Icons.refresh),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _retry(CalendarEvent event) async {
    try {
      final result = await widget.reminders.schedule(event);
      final scheduled =
          result == ReminderResult.scheduledExact ||
          result == ReminderResult.scheduledApproximate;
      await widget.store.addEvent(event.copyWith(reminderScheduled: scheduled));
      if (!mounted) return;
      final message = switch (result) {
        ReminderResult.scheduledExact => 'Aviso exato agendado.',
        ReminderResult.scheduledApproximate =>
          'Aviso agendado; o Android pode atrasar a entrega.',
        ReminderResult.noPermission =>
          'Permissão de notificações negada nas configurações do Android.',
        ReminderResult.tooLate => 'O horário do aviso já passou.',
        ReminderResult.unsupported =>
          'Agendamento do sistema disponível somente no Android.',
        ReminderResult.noReminder =>
          'Este compromisso não tem aviso configurado.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível agendar o aviso: $error')),
        );
      }
    }
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    ),
  );
}
