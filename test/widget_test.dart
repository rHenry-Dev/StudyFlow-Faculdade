import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/data/study_store.dart';
import 'package:studyflow/data/study_storage.dart';
import 'package:studyflow/main.dart';
import 'package:studyflow/notifications/reminder_service.dart';
import 'package:studyflow/screens/study_app.dart';

void main() {
  testWidgets('configura usuário, exibe o painel e navega pelas seções', (
    tester,
  ) async {
    final store = await StudyStore.open(
      '{"subjects":[],"aulas":[],"notes":[]}',
      storage: MemoryStudyStorage(),
    );

    await tester.pumpWidget(StudyFlowApp(store: store));
    await tester.pump();

    expect(find.text('Como você quer ser chamado?'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Ana');
    await tester.tap(find.text('Começar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(store.userName, 'Ana');
    expect(find.text('Olá, Ana.'), findsOneWidget);
    expect(find.text('Minhas matérias'), findsOneWidget);
    expect(find.text('Você ainda não cadastrou matérias.'), findsOneWidget);
    await tester.tap(find.text('Mapas').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Mapas mentais'), findsOneWidget);
  });

  testWidgets('cadastra mapa mental próprio', (tester) async {
    final store = await StudyStore.open(
      '{"subjects":[],"aulas":[],"notes":[]}',
      storage: MemoryStudyStorage(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MapsPage(store: store)),
      ),
    );
    await tester.ensureVisible(find.text('Novo mapa'));
    await tester.tap(find.text('Novo mapa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Meu mapa');
    await tester.enterText(find.byType(TextFormField).at(1), 'Tema central');
    await tester.enterText(find.byType(TextFormField).at(2), 'Primeiro ramo');
    await tester.enterText(find.byType(TextFormField).at(3), 'Subtópico');
    await tester.ensureVisible(find.text('Salvar mapa'));
    await tester.tap(find.text('Salvar mapa'));
    await tester.pumpAndSettle();

    expect(store.mindMaps.single.title, 'Meu mapa');
    expect(store.mindMaps.single.branches.single.topics, ['Subtópico']);
  });

  testWidgets('cadastra compromisso sem dados de demonstração', (tester) async {
    final store = await StudyStore.open(
      '{"subjects":[],"aulas":[],"notes":[]}',
      storage: MemoryStudyStorage(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarPage(store: store, reminders: ReminderService()),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Novo compromisso'));
    await tester.tap(find.text('Novo compromisso'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Minha prova');
    await tester.ensureVisible(find.text('Salvar compromisso'));
    await tester.tap(find.text('Salvar compromisso'));
    await tester.pumpAndSettle();

    expect(store.events.single.title, 'Minha prova');
    expect(store.events.single.reminderMinutes, 10);
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
