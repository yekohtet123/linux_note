import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'extra.dart';
import 'learning.dart';
import 'offline_toolkit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  try {
    await Store.load();
  } catch (error, trace) {
    debugPrint('Linux Notes startup error: $error');
    debugPrintStack(stackTrace: trace);
    startupError = error.toString();
  }
  runApp(startupError == null ? const App() : StartupErrorApp(message: startupError));
}

class StartupErrorApp extends StatelessWidget {
  final String message;
  const StartupErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Linux Notes - Startup error')),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: SelectableText('App စတင်ရာမှာ ပြဿနာရှိနေပါတယ်။\n\n$message\n\nflutter run နဲ့ log စစ်ပါ။'),
          ),
        ),
      );
}

class Store {
  static List<dynamic> data = [];
  static Set<String> fav = {};
  static late SharedPreferences p;
  static List<Map<String, String>> myNotes = [];
  static List<String> history = [];
  static Map<String, String> folders = {};
  static List<String> wrong = [];
  static Set<String> read = {};
  static Set<String> completedLabs = {};
  static Map<String, int> quizScores = {};
  static List<String> recent = [];
  static Map<String, List<int>> stats = {};
  static final theme = ValueNotifier<ThemeMode>(ThemeMode.system);
  static final scale = ValueNotifier<double>(1.0);

  static Future<void> load() async {
    data = jsonDecode(await rootBundle.loadString('assets/linux_notes.json'));
    try {
      p = await SharedPreferences.getInstance();
    } catch (error) {
      // Temporary in-memory fallback for a broken native preferences plugin.
      // Saved progress may not persist until the Android plugin is fixed.
      debugPrint('SharedPreferences plugin unavailable: $error');
      rethrow;
    }
    fav = (p.getStringList('fav') ?? []).toSet();
    // A corrupt local preference must not prevent the bundled notes from opening.
    // Keep the original saved values untouched so a user can recover them later.
    try {
      final raw = jsonDecode(p.getString('mynotes') ?? '[]');
      if (raw is! List || raw.length > 1000) throw const FormatException('Invalid personal notes');
      myNotes = raw.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (error) {
      debugPrint('Personal notes could not be read: $error');
      myNotes = [];
    }
    history = List<String>.from(p.getStringList('hist') ?? []);
    try {
      final raw = jsonDecode(p.getString('folders') ?? '{}');
      folders = Map<String, String>.from(raw as Map);
    } catch (error) {
      debugPrint('Folders could not be read: $error');
      folders = {};
    }
    wrong = List<String>.from(p.getStringList('wrong') ?? []);
    try {
      final raw = jsonDecode(p.getString('stats') ?? '{}');
      if (raw is! Map) throw const FormatException('Invalid statistics');
      stats = {
        for (final e in raw.entries)
          e.key as String: List<int>.from(e.value as List)
      };
    } catch (error) {
      debugPrint('Statistics could not be read: $error');
      stats = {};
    }
    read = (p.getStringList('read') ?? []).toSet();
    completedLabs = (p.getStringList('completed_labs_v1') ?? []).toSet();
    try {
      quizScores = Map<String, int>.from(jsonDecode(p.getString('quiz_scores_v1') ?? '{}'));
    } catch (_) { quizScores = {}; }
    recent = List<String>.from(p.getStringList('recent') ?? []);
    final themeIndex = p.getInt('theme') ?? 0;
    theme.value = (themeIndex >= 0 && themeIndex < ThemeMode.values.length)
        ? ThemeMode.values[themeIndex] : ThemeMode.system;
    final savedScale = p.getDouble('scale') ?? 1.0;
    scale.value = savedScale.isFinite && savedScale >= 0.7 && savedScale <= 2.5
        ? savedScale : 1.0;
  }

  static String labId(Map n) => '${n['cat'] ?? ''}::${n['title']}';
  static bool isLab(Map n) => n['lab'] == true || n['cat'].toString().toLowerCase().contains('lab');
  static void setLabComplete(Map n, bool done) {
    final id = labId(n);
    if (done) { completedLabs.add(id); } else { completedLabs.remove(id); }
    p.setStringList('completed_labs_v1', completedLabs.toList());
  }
  static void saveQuizScore(String category, int score) {
    quizScores[category] = score;
    p.setString('quiz_scores_v1', jsonEncode(quizScores));
  }
  static void saveNotes() => p.setString('mynotes', jsonEncode(myNotes));
  static void saveFolders() => p.setString('folders', jsonEncode(folders));
  static void saveWrong() => p.setStringList('wrong', wrong);
  static void saveStats() => p.setString('stats', jsonEncode(stats));
  static void addHistory(String c) {
    history.remove(c);
    history.insert(0, c);
    if (history.length > 50) history.removeLast();
    p.setStringList('hist', history);
  }

  static void markRead(String t) {
    read.add(t);
    recent.remove(t);
    recent.insert(0, t);
    if (recent.length > 10) recent.removeLast();
    p.setStringList('read', read.toList());
    p.setStringList('recent', recent);
  }

  static void resetProgress() {
    read.clear();
    recent.clear();
    p.setStringList('read', []);
    p.setStringList('recent', []);
  }

  static Map? noteByTitle(String t) {
    for (final n in allNotes()) {
      if (n['title'] == t) return n;
    }
    return null;
  }

  static void toggle(String t) {
    fav.contains(t) ? fav.remove(t) : fav.add(t);
    p.setStringList('fav', fav.toList());
  }

  static List<Map> allNotes() => [
        for (final c in data)
          for (final n in c['notes']) {...n, 'cat': c['category']}
      ];
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => ValueListenableBuilder<ThemeMode>(
        valueListenable: Store.theme,
        builder: (_, mode, __) => ValueListenableBuilder<double>(
          valueListenable: Store.scale,
          builder: (_, s, __) => MaterialApp(
            title: 'Linux Notes',
            debugShowCheckedModeBanner: false,
            themeMode: mode,
            theme: ThemeData(colorSchemeSeed: const Color(0xFF20745C), useMaterial3: true, scaffoldBackgroundColor: const Color(0xFFF7F8FA)),
            darkTheme: ThemeData(
                colorSchemeSeed: Colors.teal,
                brightness: Brightness.dark,
                useMaterial3: true),
            builder: (ctx, child) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(s)),
                child: child!),
            home: const Home(),
          ),
        ),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const groups = ['Linux Core', 'DevOps', 'Cloud', 'Security', 'Database', 'Platform နှင့် Career', 'လက်တွေ့ Lab'];
  static const ink = Color(0xFF18372F);
  static const green = Color(0xFF20745C);
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String selected = 'Overview';
  String query = '';
  String difficulty = 'All';
  final searchController = TextEditingController();

  @override
  void dispose() { searchController.dispose(); super.dispose(); }

  IconData groupIcon(String g) {
    switch (g) {
      case 'Linux Core': return Icons.terminal;
      case 'DevOps': return Icons.layers_outlined;
      case 'Cloud': return Icons.cloud_outlined;
      case 'Security': return Icons.shield_outlined;
      case 'Database': return Icons.storage_outlined;
      case 'လက်တွေ့ Lab': return Icons.science_outlined;
      default: return Icons.menu_book_outlined;
    }
  }

  Future<void> open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  void choose(String value) {
    setState(() { selected = value; query = ''; searchController.clear(); });
    if (scaffoldKey.currentState?.isDrawerOpen ?? false) scaffoldKey.currentState?.closeDrawer();
  }

  List<Map> filteredNotes() {
    final q = query.trim().toLowerCase();
    return Store.allNotes().where((n) {
      final cat = Store.data.cast<Map>().firstWhere((c) => c['category'] == n['cat']);
      if (groups.contains(selected) && cat['group'] != selected) return false;
      if (selected == 'Bookmarks' && !Store.fav.contains(n['title'])) return false;
      if (difficulty != 'All' && labDifficulty(n) != difficulty) return false;
      if (selected == 'Commands & code' && (n['cmds'] as List).isEmpty) return false;
      if (q.isEmpty) return true;
      final cmds = (n['cmds'] as List).map((c) => '${c['c']} ${c['d']}').join(' ');
      return '${n['title']} ${n['desc']} ${n['cat']} $cmds'.toLowerCase().contains(q);
    }).toList();
  }

  Widget sectionTitle(String title, {String? subtitle}) => Padding(
    padding: const EdgeInsets.only(bottom: 14, top: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink)),
      if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: const TextStyle(color: Color(0xFF81908C), fontSize: 12))),
    ]),
  );

  Widget stat(String label, String value, IconData icon) => Container(
  padding: const EdgeInsets.all(15),
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xFFE5EAE8)),
    borderRadius: BorderRadius.circular(13),
  ),
  child: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5F2),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: green, size: 19),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: ink,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF81908C),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
  Widget subjectCard(String g) {
    final cats = Store.data.where((c) => c['group'] == g).toList();
    final count = cats.fold<int>(0, (sum, c) => sum + (c['notes'] as List).length);
    return InkWell(
      onTap: () => choose(g),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE5EAE8)), borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFEAF4EF), borderRadius: BorderRadius.circular(11)), child: Icon(groupIcon(g), color: green)),
            const Spacer(), Text('$count notes', style: const TextStyle(color: Color(0xFF81908C), fontSize: 11)),
          ]),
          const SizedBox(height: 20),
          Text(g, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: ink)),
          const SizedBox(height: 5),
          Text('${cats.length} chapters · Beginner → Advanced', style: const TextStyle(color: Color(0xFF82918D), fontSize: 11)),
          const Divider(height: 25),
          const Row(children: [Text('Explore notes', style: TextStyle(color: green, fontSize: 12)), Spacer(), Icon(Icons.arrow_forward, color: green, size: 17)]),
        ]),
      ),
    );
  }

  Widget overview() {
    final notes = Store.allNotes();
    final commands = notes.fold<int>(0, (sum, n) => sum + (n['cmds'] as List).length);
    final last = Store.recent.isEmpty ? null : Store.noteByTitle(Store.recent.first);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('A LITTLE PROGRESS, EVERY DAY', style: TextStyle(fontSize: 10, letterSpacing: 2, color: green, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      const Text('မင်္ဂလာပါ။ စာဖတ်လေ့လာကြမယ်။', style: TextStyle(fontSize: 23, color: ink, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      const Text('Linux နှင့် နည်းပညာမှတ်စုများကို မြန်မာလို လေ့လာနိုင်ပါတယ်။', style: TextStyle(color: Color(0xFF81908C), fontSize: 12)),
      const SizedBox(height: 22),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFFEAF2EA), borderRadius: BorderRadius.circular(17)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('✧ YOUR PERSONAL KNOWLEDGE BASE', style: TextStyle(color: green, fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
          const SizedBox(height: 15),
          const Text('Build your knowledge.\nOne note at a time.', style: TextStyle(color: ink, fontSize: 25, height: 1.3, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text('ဖတ်ပါ။ လေ့ကျင့်ပါ။ မှတ်သားပါ။', style: TextStyle(color: Color(0xFF6F857B), fontSize: 12)),
          const SizedBox(height: 19),
          FilledButton.icon(onPressed: () => last != null ? open(Detail(note: last)) : choose('All notes'), icon: Icon(last != null ? Icons.play_arrow : Icons.menu_book), label: Text(last != null ? 'ဆက်ဖတ်ရန်' : 'စတင်လေ့လာရန်'), style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white)),
          if (last != null) Padding(padding: const EdgeInsets.only(top: 9), child: Text('Last read: ${last['title']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: green))),
        ]),
      ),
      const SizedBox(height: 18),
      learningSummaryCard(onOpen: () => open(const LearningDashboard())),
      const SizedBox(height: 14),
      LayoutBuilder(builder: (context, c) => GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: c.maxWidth > 700 ? 4 : 2, childAspectRatio: c.maxWidth > 700 ? 2.8 : 1.7,
        mainAxisSpacing: 10, crossAxisSpacing: 10,
        children: [stat('Learning notes', '${notes.length}', Icons.menu_book_outlined), stat('Code examples', '$commands', Icons.terminal), stat('Subjects', '${groups.length}', Icons.layers_outlined), stat('Notes completed', '${Store.read.length}', Icons.check_circle_outline)],
      )),
      sectionTitle('Explore your subjects', subtitle: 'လေ့လာချင်တဲ့ အကြောင်းအရာကို ရွေးချယ်ပါ။'),
      LayoutBuilder(builder: (context, c) => GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: c.maxWidth > 850 ? 3 : c.maxWidth > 480 ? 2 : 1,
        childAspectRatio: c.maxWidth > 850 ? 1.8 : c.maxWidth > 480 ? 1.5 : 2.1,
        mainAxisSpacing: 12, crossAxisSpacing: 12,
        children: [for (final g in groups) subjectCard(g)],
      )),
    ]);
  }

  Widget notesView() {
    final notes = filteredNotes();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('READ. UNDERSTAND. MAKE IT YOURS.', style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: green, fontWeight: FontWeight.w800)),
      sectionTitle(selected == 'All notes' ? 'All learning notes' : selected, subtitle: 'မြန်မာလို ရှင်းပြချက်များ၊ Commands နှင့် လက်တွေ့ Examples'),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChoiceChip(label: const Text('All notes'), selected: selected == 'All notes', onSelected: (_) => choose('All notes')),
        for (final g in groups) ChoiceChip(label: Text(g), selected: selected == g, onSelected: (_) => choose(g)),
      ]),
      const SizedBox(height: 14),
      Wrap(spacing: 7, runSpacing: 7, children: [
        for (final d in ['All', 'Beginner', 'Intermediate', 'Advanced'])
          ChoiceChip(label: Text(d), selected: difficulty == d, onSelected: (_) => setState(() => difficulty = d)),
      ]),
      const SizedBox(height: 12),
      Text('${notes.length} notes', style: const TextStyle(fontSize: 12, color: Color(0xFF81908C))),
      const SizedBox(height: 12),
      if (notes.isEmpty) const Padding(padding: EdgeInsets.all(25), child: Text('ကိုက်ညီတဲ့ Note မတွေ့ပါ။')),
      LayoutBuilder(builder: (context, c) => GridView.builder(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        itemCount: notes.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: c.maxWidth > 850 ? 3 : c.maxWidth > 480 ? 2 : 1,
          mainAxisSpacing: 12, crossAxisSpacing: 12,
          childAspectRatio: c.maxWidth > 850 ? 1.65 : c.maxWidth > 480 ? 1.3 : 1.85),
        itemBuilder: (_, i) {
          final n = notes[i];
          return InkWell(onTap: () => open(Detail(note: n)), borderRadius: BorderRadius.circular(13), child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE5EAE8))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('●  ${n['cat']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: green, fontSize: 10)),
              const SizedBox(height: 12),
              Text('${n['title']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: ink)),
              const SizedBox(height: 7),
              Expanded(child: Text('${n['desc']}', maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.6, color: Color(0xFF71827D)))),
              const Divider(),
              Row(children: [
                Text('${(n['cmds'] as List).length} examples', style: const TextStyle(fontSize: 10, color: Color(0xFF81908C))),
                const Spacer(),
                if (Store.isLab(n)) Text(labDifficulty(n), style: const TextStyle(fontSize: 10, color: green)),
                if (Store.completedLabs.contains(Store.labId(n))) const Icon(Icons.verified, size: 16, color: green),
                if (Store.read.contains(n['title'])) const Icon(Icons.check_circle, size: 16, color: green),
                IconButton(visualDensity: VisualDensity.compact, icon: Icon(Store.fav.contains(n['title']) ? Icons.bookmark : Icons.bookmark_border, size: 19, color: green), onPressed: () => setState(() => Store.toggle(n['title']))),
              ]),
            ]),
          ));
        },
      )),
    ]);
  }

  Widget navItem(String label, IconData icon) => ListTile(
    dense: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    tileColor: selected == label ? const Color(0xFFEAF3ED) : null,
    leading: Icon(icon, size: 19, color: selected == label ? green : const Color(0xFF87958F)),
    title: Text(label, style: TextStyle(fontSize: 13, fontWeight: selected == label ? FontWeight.w700 : FontWeight.normal, color: selected == label ? green : const Color(0xFF6F817B))),
    onTap: () => choose(label),
  );

  Widget sidebar() => Container(
    width: 235, color: Colors.white,
    child: SafeArea(child: ListView(padding: const EdgeInsets.all(17), children: [
      const SizedBox(height: 10),
      const Row(children: [CircleAvatar(backgroundColor: green, child: Text('tn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))), SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('TechNotes', style: TextStyle(fontSize: 19, color: ink, fontWeight: FontWeight.w900)), Text('YOUR LEARNING SPACE', style: TextStyle(fontSize: 8, letterSpacing: 1.3, color: Color(0xFF88958F)))]),]),
      const SizedBox(height: 33),
      const Text('MY WORKSPACE', style: TextStyle(fontSize: 10, letterSpacing: 1.6, color: Color(0xFF9AA7A2), fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      navItem('Overview', Icons.home_outlined),
      navItem('All notes', Icons.menu_book_outlined),
      navItem('Commands & code', Icons.terminal),
      navItem('Bookmarks', Icons.bookmark_outline),
      ListTile(leading: const Icon(Icons.track_changes), title: const Text('Learning Dashboard'), onTap: () => open(const LearningDashboard())),
      ListTile(leading: const Icon(Icons.quiz_outlined), title: const Text('Interactive Quiz'), onTap: () => open(const LearningQuiz())),
      ListTile(leading: const Icon(Icons.offline_bolt_outlined), title: const Text('Offline Learning Toolkit'), onTap: () => open(const OfflineToolkit())),
      const SizedBox(height: 20),
      const Text('SUBJECTS', style: TextStyle(fontSize: 10, letterSpacing: 1.6, color: Color(0xFF9AA7A2), fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      for (final g in groups) navItem(g, groupIcon(g)),
      const Divider(height: 28),
      ListTile(leading: const Icon(Icons.edit_note), title: const Text('My notes'), onTap: () => open(const MyNotes())),
      ListTile(leading: const Icon(Icons.quiz_outlined), title: const Text('Review cards / Quiz'), onTap: () => open(const Quiz())),
      ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Settings'), onTap: () => open(const Settings())),
    ])),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, size) {
    final wide = size.maxWidth >= 850;
    final page = selected == 'Overview' && query.isEmpty ? overview() : notesView();
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: wide ? null : Drawer(child: sidebar()),
      body: Row(children: [
        if (wide) sidebar(),
        Expanded(child: Column(children: [
          Container(height: 66, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Color(0xFFE5EAE8)))), child: Row(children: [
            if (!wide) Builder(builder: (ctx) => IconButton(onPressed: () => Scaffold.of(ctx).openDrawer(), icon: const Icon(Icons.menu))),
            if (wide) Text(selected, style: const TextStyle(color: Color(0xFF81908C), fontSize: 12)),
            const Spacer(),
            SizedBox(width: wide ? 360 : 180, height: 40, child: TextField(
              controller: searchController,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search, size: 19), hintText: 'Search notes, commands...', hintStyle: const TextStyle(fontSize: 11), filled: true, fillColor: const Color(0xFFF7F8FA), contentPadding: const EdgeInsets.symmetric(vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5EAE8)))),
              onChanged: (v) => setState(() => query = v),
            )),
          ])),
          Expanded(child: ListView(padding: EdgeInsets.symmetric(horizontal: wide ? 36 : 16, vertical: 26), children: [Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: page))])),
        ])),
      ]),
    );
  });
}

class Settings extends StatefulWidget {
  const Settings({super.key});
  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext c) {
    const names = ['စက်အတိုင်း', 'အလင်း', 'အမှောင်'];
    return Scaffold(
      appBar: AppBar(title: const Text('ဆက်တင်')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
        for (int i = 0; i < 3; i++)
          ListTile(
            title: Text(names[i]),
            leading: Icon(Store.theme.value.index == i
                ? Icons.radio_button_checked
                : Icons.radio_button_off),
            onTap: () {
              Store.theme.value = ThemeMode.values[i];
              Store.p.setInt('theme', i);
              setState(() {});
            },
          ),
        const SizedBox(height: 16),
        Text('စာလုံးအရွယ်အစား (${Store.scale.value.toStringAsFixed(1)}x)',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          min: 0.8,
          max: 1.6,
          divisions: 8,
          value: Store.scale.value,
          onChanged: (v) {
            Store.scale.value = v;
            setState(() {});
          },
          onChangeEnd: (v) => Store.p.setDouble('scale', v),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.restart_alt),
          title: const Text('ဖတ်ပြီးမှတ်တမ်းကို ရှင်းမည်'),
          subtitle: Text('${Store.read.length} မှတ်စု ဖတ်ပြီး'),
          onTap: () {
            Store.resetProgress();
            setState(() {});
          },
        ),
      ]),
    );
  }
}

class NoteList extends StatefulWidget {
  final Map? cat;
  final bool favOnly;
  const NoteList({super.key, this.cat, this.favOnly = false});
  @override
  State<NoteList> createState() => _NoteListState();
}

class _NoteListState extends State<NoteList> {
  Future<void> setFolder(Map n) async {
    final t = TextEditingController(text: Store.folders[n['title']] ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Folder နာမည်'),
        content: TextField(controller: t, decoration: const InputDecoration(hintText: 'ဥပမာ - Server, Daily')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('မလုပ်တော့')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('သိမ်းမည်')),
        ],
      ),
    );
    if (ok != true) return;
    final v = t.text.trim();
    if (v.isEmpty) {
      Store.folders.remove(n['title']);
    } else {
      Store.folders[n['title']] = v;
    }
    Store.saveFolders();
    setState(() {});
  }

  @override
  Widget build(BuildContext c) {
    final List notes = widget.favOnly
        ? Store.allNotes().where((n) => Store.fav.contains(n['title'])).toList()
        : widget.cat!['notes'];
    if (widget.favOnly) {
      notes.sort((a, b) => (Store.folders[a['title']] ?? '').compareTo(Store.folders[b['title']] ?? ''));
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.favOnly ? 'သိမ်းထားသည်များ' : widget.cat!['category'])),
      body: notes.isEmpty
          ? const Center(child: Text('မရှိသေးပါ'))
          : ListView(children: [
              for (final n in notes)
                ListTile(
                  leading: Icon(
                      Store.read.contains(n['title']) ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 20),
                  title: Text(n['title']),
                  subtitle: Text((widget.favOnly && Store.folders[n['title']] != null ? '📁 ${Store.folders[n['title']]}  ' : '') + n['desc'], maxLines: 2, overflow: TextOverflow.ellipsis),
                  onLongPress: widget.favOnly ? () => setFolder(n) : null,
                  onTap: () async {
                    await Navigator.push(c,
                        MaterialPageRoute(builder: (_) => Detail(note: n)));
                    setState(() {});
                  },
                )
            ]),
    );
  }
}

class Detail extends StatefulWidget {
  final Map note;
  const Detail({super.key, required this.note});
  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  bool challenge = false;
  @override
  void initState() {
    super.initState();
    Store.markRead(widget.note['title']);
  }

  @override
  Widget build(BuildContext c) {
    final n = widget.note;
    final f = Store.fav.contains(n['title']);
    return Scaffold(
      appBar: AppBar(title: Text(n['title']), actions: [
        IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () {
              final s = StringBuffer('# ${n['title']}\n${n['desc']}\n\n');
              for (final cm in n['cmds']) {
                s.writeln('```\n${cm['c']}\n```\n${cm['d']}\n');
              }
              Clipboard.setData(ClipboardData(text: s.toString()));
              ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('မှတ်စုတစ်ခုလုံး copy ကူးပြီး')));
            }),
        IconButton(
            icon: Icon(f ? Icons.star : Icons.star_border),
            onPressed: () => setState(() => Store.toggle(n['title'])))
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('${n['cat'] ?? 'Linux Notes'}  /  LEARNING NOTE', style: const TextStyle(color: Color(0xFF20745C), fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 13),
        Text('${n['title']}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Text(n['desc'], style: const TextStyle(fontSize: 16, height: 1.8)),
        if (Store.isLab(n)) ...[
          Text('Difficulty: ${labDifficulty(n)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          SwitchListTile(title: const Text('Challenge Mode'), subtitle: const Text('Commands ကို အရင်ဖုံးပြီး ကိုယ်တိုင်ဖြေရှင်းပါ'), value: challenge, onChanged: (v) => setState(() => challenge = v)),
          CheckboxListTile(title: const Text('Mark lab as completed'), value: Store.completedLabs.contains(Store.labId(n)), onChanged: (v) => setState(() => Store.setLabComplete(n, v ?? false))),
        ],
        const SizedBox(height: 16),
        if (challenge && Store.isLab(n)) ...[
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Challenge: ရှင်းပြချက်ကိုဖတ်ပြီး Command ကို မကြည့်ဘဲ ကိုယ်တိုင်လုပ်ကြည့်ပါ။ အဖြေစစ်ရန် Reveal ကို နှိပ်ပါ။'))),
          FilledButton.icon(onPressed: () => setState(() => challenge = false), icon: const Icon(Icons.visibility), label: const Text('Reveal commands')),
        ],
        if (!challenge || !Store.isLab(n)) for (final cm in n['cmds'])
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                      child: SelectableText(cm['c'],
                          style: TextStyle(fontFamily: n['theory'] == true ? null : 'monospace', fontWeight: FontWeight.bold))),
                  IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: cm['c']));
                        Store.addHistory(cm['c']);
                        ScaffoldMessenger.of(c).showSnackBar(
                            const SnackBar(content: Text('Copy ကူးပြီး')));
                      })
                ]),
                Text(cm['d'], style: const TextStyle(height: 1.5)),
              ]),
            ),
          ),
        const SizedBox(height: 20),
        Builder(builder: (context) {
          final notes = Store.allNotes();
          final index = notes.indexWhere((x) => x['title'] == n['title']);
          return Row(children: [
            if (index > 0) Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Detail(note: notes[index - 1]))), icon: const Icon(Icons.arrow_back), label: const Text('Previous'))),
            if (index > 0 && index < notes.length - 1) const SizedBox(width: 12),
            if (index >= 0 && index < notes.length - 1) Expanded(child: FilledButton.icon(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Detail(note: notes[index + 1]))), icon: const Icon(Icons.arrow_forward), label: const Text('Next'))),
          ]);
        }),
      ]),
    );
  }
}

class Search extends SearchDelegate {
  List<Map> res() {
    final q = query.toLowerCase();
    return Store.allNotes().where((n) {
      final s = '${n['title']} ${n['desc']} ${n['cmds'].map((x) => x['c'] + x['d']).join(' ')}'.toLowerCase();
      return q.isNotEmpty && s.contains(q);
    }).toList();
  }

  @override
  List<Widget>? buildActions(BuildContext c) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget? buildLeading(BuildContext c) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(c, null));
  @override
  Widget buildResults(BuildContext c) => buildSuggestions(c);
  @override
  Widget buildSuggestions(BuildContext c) => ListView(children: [
        for (final n in res())
          ListTile(
            title: Text(n['title']),
            subtitle: Text(n['cat']),
            onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => Detail(note: n))),
          )
      ]);
}
