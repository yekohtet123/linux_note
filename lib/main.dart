import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'extra.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.load();
  runApp(const App());
}

class Store {
  static List<dynamic> data = [];
  static Set<String> fav = {};
  static late SharedPreferences p;
  static List<Map<String, String>> myNotes = [];
  static List<String> history = [];
  static Map<String, String> folders = {};
  static List<String> wrong = [];
  static Map<String, List<int>> stats = {};
  static final theme = ValueNotifier<ThemeMode>(ThemeMode.system);
  static final scale = ValueNotifier<double>(1.0);

  static Future<void> load() async {
    data = jsonDecode(await rootBundle.loadString('assets/linux_notes.json'));
    p = await SharedPreferences.getInstance();
    fav = (p.getStringList('fav') ?? []).toSet();
    myNotes = [
      for (final e in jsonDecode(p.getString('mynotes') ?? '[]')) Map<String, String>.from(e)
    ];
    history = List<String>.from(p.getStringList('hist') ?? []);
    folders = Map<String, String>.from(jsonDecode(p.getString('folders') ?? '{}'));
    wrong = List<String>.from(p.getStringList('wrong') ?? []);
    stats = {
      for (final e in (jsonDecode(p.getString('stats') ?? '{}') as Map).entries)
        e.key as String: List<int>.from(e.value)
    };
    theme.value = ThemeMode.values[p.getInt('theme') ?? 0];
    scale.value = p.getDouble('scale') ?? 1.0;
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
            theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
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

class Home extends StatelessWidget {
  const Home({super.key});

  Map tip() {
    final all = <Map>[];
    for (final n in Store.allNotes()) {
      if (n['theory'] == true) continue;
      for (final cm in n['cmds']) {
        all.add({'c': cm['c'], 'd': cm['d'], 'note': n});
      }
    }
    final day = DateTime.now().difference(DateTime(2026)).inDays.abs();
    return all[day % all.length];
  }

  @override
  Widget build(BuildContext c) {
    final t = tip();
    return Scaffold(
      appBar: AppBar(title: const Text('Linux Notes'), actions: [
        IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(context: c, delegate: Search())),
        IconButton(
            icon: const Icon(Icons.star),
            onPressed: () => Navigator.push(c,
                MaterialPageRoute(builder: (_) => const NoteList(favOnly: true)))),
        PopupMenuButton<int>(
          onSelected: (v) {
            final pages = <Widget>[const Quiz(), const MyNotes(), const HistoryPage(), const Settings()];
            Navigator.push(c, MaterialPageRoute(builder: (_) => pages[v]));
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 0, child: Text('Quiz')),
            PopupMenuItem(value: 1, child: Text('ကိုယ်ပိုင်မှတ်စု')),
            PopupMenuItem(value: 2, child: Text('Copy history')),
            PopupMenuItem(value: 3, child: Text('ဆက်တင်')),
          ],
        ),
      ]),
      body: ListView(children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: InkWell(
            onTap: () => Navigator.push(
                c, MaterialPageRoute(builder: (_) => Detail(note: t['note']))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ယနေ့ command', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(t['c'].toString().split('\n').first,
                    style: const TextStyle(fontFamily: 'monospace')),
                const SizedBox(height: 4),
                Text(t['d']),
              ]),
            ),
          ),
        ),
        for (final cat in Store.data)
          ListTile(
            leading: const Icon(Icons.terminal),
            title: Text(cat['category']),
            subtitle: Text('${cat['notes'].length} မှတ်စု'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
                c, MaterialPageRoute(builder: (_) => NoteList(cat: cat))),
          )
      ]),
    );
  }
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
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(n['desc'], style: const TextStyle(fontSize: 16, height: 1.6)),
        const SizedBox(height: 16),
        for (final cm in n['cmds'])
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
          )
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
