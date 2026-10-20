import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

// ---------- My Notes ----------
class MyNotes extends StatefulWidget {
  const MyNotes({super.key});
  @override
  State<MyNotes> createState() => _MyNotesState();
}

class _MyNotesState extends State<MyNotes> {
  Future<void> edit([int? i]) async {
    final t = TextEditingController(text: i == null ? '' : Store.myNotes[i]['title']);
    final b = TextEditingController(text: i == null ? '' : Store.myNotes[i]['body']);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(i == null ? 'မှတ်စုအသစ်' : 'ပြင်မည်'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: t, decoration: const InputDecoration(labelText: 'ခေါင်းစဉ်')),
            TextField(
                controller: b,
                maxLines: 8,
                decoration: const InputDecoration(labelText: 'အကြောင်းအရာ / command')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('မလုပ်တော့')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('သိမ်းမည်')),
        ],
      ),
    );
    if (ok != true || t.text.trim().isEmpty) return;
    final m = <String, String>{'title': t.text.trim(), 'body': b.text};
    setState(() {
      if (i == null) {
        Store.myNotes.insert(0, m);
      } else {
        Store.myNotes[i] = m;
      }
    });
    Store.saveNotes();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('ကိုယ်ပိုင်မှတ်စု')),
        floatingActionButton: FloatingActionButton(onPressed: () => edit(), child: const Icon(Icons.add)),
        body: Store.myNotes.isEmpty
            ? const Center(child: Text('မှတ်စုမရှိသေးပါ။ + နှိပ်ပြီး ထည့်ပါ'))
            : ListView.builder(
                itemCount: Store.myNotes.length,
                itemBuilder: (_, i) {
                  final m = Store.myNotes[i];
                  return ListTile(
                    title: Text(m['title']!),
                    subtitle: Text(m['body']!, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => edit(i),
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: m['body']!));
                      ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Copy ကူးပြီး')));
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() => Store.myNotes.removeAt(i));
                        Store.saveNotes();
                      },
                    ),
                  );
                },
              ),
      );
}

// ---------- Copy history ----------
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Copy history'), actions: [
          IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                setState(() => Store.history.clear());
                Store.p.setStringList('hist', Store.history);
              })
        ]),
        body: Store.history.isEmpty
            ? const Center(child: Text('Copy ကူးထားတာ မရှိသေးပါ'))
            : ListView(children: [
                for (final h in Store.history)
                  ListTile(
                    title: Text(h, style: const TextStyle(fontFamily: 'monospace')),
                    trailing: const Icon(Icons.copy, size: 18),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: h));
                      ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Copy ကူးပြီး')));
                    },
                  )
              ]),
      );
}

// ---------- Quiz ----------
List<Map> quizCmds(String? cat) => [
      for (final ct in Store.data)
        if (cat == null || ct['category'] == cat)
          for (final n in ct['notes'])
            if (n['theory'] != true)
              for (final cm in n['cmds'])
                if (!cm['c'].toString().contains('\n') && cm['c'].toString().length <= 45) Map.from(cm)
    ];

class Quiz extends StatefulWidget {
  const Quiz({super.key});
  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> {
  String stat(String k) {
    final v = Store.stats[k];
    return v == null ? 'မစမ်းရသေးပါ' : 'မှန် ${v[0]} / ${v[1]}';
  }

  Future<void> go(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    setState(() {});
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: ListView(children: [
          ListTile(
              leading: const Icon(Icons.shuffle),
              title: const Text('ခန်းအားလုံး'),
              subtitle: Text(stat('all')),
              onTap: () => go(const QuizPlay())),
          if (Store.wrong.isNotEmpty)
            ListTile(
                leading: const Icon(Icons.replay),
                title: Text('အမှားပြန်လေ့ကျင့် (${Store.wrong.length})'),
                onTap: () => go(const QuizPlay(review: true))),
          const Divider(),
          for (final ct in Store.data)
            ListTile(
                title: Text(ct['category']),
                subtitle: Text(stat(ct['category'])),
                onTap: () => go(QuizPlay(cat: ct['category']))),
        ]),
      );
}

class QuizPlay extends StatefulWidget {
  final String? cat;
  final bool review;
  const QuizPlay({super.key, this.cat, this.review = false});
  @override
  State<QuizPlay> createState() => _QuizPlayState();
}

class _QuizPlayState extends State<QuizPlay> {
  final r = Random();
  late final List<Map> all;
  late List<Map> pool;
  Map? q;
  List<String> opts = [];
  int? picked;
  int score = 0, total = 0;

  @override
  void initState() {
    super.initState();
    all = quizCmds(null);
    next();
  }

  void next() {
    if (widget.review) {
      pool = all.where((m) => Store.wrong.contains(m['c'])).toList();
    } else {
      pool = quizCmds(widget.cat);
    }
    if (pool.isEmpty) {
      q = null;
      return;
    }
    q = pool[r.nextInt(pool.length)];
    final wrong = <String>{};
    while (wrong.length < 3) {
      final w = all[r.nextInt(all.length)]['c'] as String;
      if (w != q!['c']) wrong.add(w);
    }
    opts = [...wrong, q!['c'] as String]..shuffle(r);
    picked = null;
  }

  void answer(int i) {
    final ok = opts[i] == q!['c'];
    setState(() {
      picked = i;
      total++;
      if (ok) score++;
    });
    final c = q!['c'] as String;
    if (ok) {
      Store.wrong.remove(c);
    } else if (!Store.wrong.contains(c)) {
      Store.wrong.add(c);
      if (Store.wrong.length > 100) Store.wrong.removeAt(0);
    }
    Store.saveWrong();
    if (!widget.review) {
      final k = widget.cat ?? 'all';
      final v = Store.stats[k] ?? [0, 0];
      Store.stats[k] = [v[0] + (ok ? 1 : 0), v[1] + 1];
      Store.saveStats();
    }
  }

  @override
  Widget build(BuildContext c) {
    if (q == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Quiz')),
          body: const Center(child: Text('အမှားအားလုံး ပြန်မှန်သွားပါပြီ 🎉')));
    }
    return Scaffold(
      appBar: AppBar(title: Text('${widget.review ? "ပြန်လေ့ကျင့်" : "Quiz"}  $score/$total')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('ဒီ command ဘယ်ဟာလဲ?', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(q!['d'], style: const TextStyle(fontSize: 18, height: 1.5)),
        const SizedBox(height: 16),
        for (int i = 0; i < opts.length; i++)
          Card(
            color: picked == null
                ? null
                : opts[i] == q!['c']
                    ? Colors.green.withOpacity(0.35)
                    : (picked == i ? Colors.red.withOpacity(0.35) : null),
            child: ListTile(
              title: Text(opts[i], style: const TextStyle(fontFamily: 'monospace')),
              onTap: picked != null ? null : () => answer(i),
            ),
          ),
        if (picked != null)
          FilledButton(onPressed: () => setState(next), child: const Text('နောက်တစ်ခု')),
      ]),
    );
  }
}
