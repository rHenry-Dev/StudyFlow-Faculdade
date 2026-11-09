import 'package:flutter/material.dart';

import 'data/study_store.dart';
import 'notifications/reminder_service.dart';
import 'screens/study_app.dart';

const _emptyDatabase = '{"subjects":[],"aulas":[],"notes":[]}';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  StudyStore? store;
  Object? startupError;
  final reminders = ReminderService();
  try {
    await reminders.initialize();
  } catch (error) {
    reminders.initializationError = error.toString();
  }
  try {
    store = await StudyStore.open(_emptyDatabase);
  } catch (error) {
    startupError = error;
  }
  runApp(
    StudyFlowApp(
      store: store,
      startupError: startupError,
      reminders: reminders,
    ),
  );
}

class StudyFlowApp extends StatelessWidget {
  StudyFlowApp({
    super.key,
    this.store,
    this.startupError,
    ReminderService? reminders,
  }) : reminders = reminders ?? ReminderService();

  final StudyStore? store;
  final Object? startupError;
  final ReminderService reminders;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF9B7BFF);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: const Color(0xFF171720),
    );
    return MaterialApp(
      title: 'StudyFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF0D0D13),
        cardColor: const Color(0xFF171720),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0D13),
          surfaceTintColor: Colors.transparent,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF171720),
          indicatorColor: accent.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF171720),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF30303A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF30303A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accent),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF272733),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: store == null
          ? StartupErrorPage(error: startupError)
          : AnimatedBuilder(
              animation: store!,
              builder: (context, _) => store!.userName.isEmpty
                  ? UserSetupPage(store: store!)
                  : StudyApp(store: store!, reminders: reminders),
            ),
    );
  }
}

class UserSetupPage extends StatefulWidget {
  const UserSetupPage({super.key, required this.store});

  final StudyStore store;

  @override
  State<UserSetupPage> createState() => _UserSetupPageState();
}

class _UserSetupPageState extends State<UserSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.store.setUserName(_nameController.text);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível salvar seu nome: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 56,
                    color: Color(0xFF9B7BFF),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bem-vindo ao StudyFlow',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Como você quer ser chamado?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: 'Seu nome',
                      hintText: 'Digite seu nome',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe seu nome para continuar.'
                        : null,
                    onFieldSubmitted: (_) => _continue(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isSaving ? null : _continue,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Começar'),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Seu nome e seus estudos ficam salvos somente neste aparelho.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class StartupErrorPage extends StatelessWidget {
  const StartupErrorPage({super.key, required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Não foi possível abrir seus dados.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
