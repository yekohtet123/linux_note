import 'package:flutter/material.dart';
import 'main.dart';

String labDifficulty(Map n) {
  final t = '${n['title']} ${n['difficulty'] ?? ''}'.toLowerCase();
  if (t.contains('advanced')) return 'Advanced';
  if (t.contains('intermediate')) return 'Intermediate';
  if (t.contains('beginner')) return 'Beginner';
  // Older notes have no authored difficulty; use a visible fallback.
  return 'Unrated';
}

Widget learningSummaryCard({required VoidCallback onOpen}) {
  final labs = Store.allNotes().where(Store.isLab).toList();
  final done = labs.where((n) => Store.completedLabs.contains(Store.labId(n))).length;
  final progress = labs.isEmpty ? 0.0 : done / labs.length;
  return Card(child: InkWell(onTap: onOpen, borderRadius: BorderRadius.circular(12), child: Padding(
    padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('MY LAB PROGRESS', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('$done / ${labs.length} labs completed • ${((progress) * 100).toStringAsFixed(1)}%'),
      const SizedBox(height: 8), LinearProgressIndicator(value: progress),
      const SizedBox(height: 8), const Text('Dashboard ကြည့်ရန် နှိပ်ပါ →'),
    ]),
  )));
}

class LearningDashboard extends StatefulWidget {
  const LearningDashboard({super.key});
  @override State<LearningDashboard> createState() => _LearningDashboardState();
}
class _LearningDashboardState extends State<LearningDashboard> {
  @override Widget build(BuildContext context) {
    final all = Store.allNotes();
    final labs = all.where(Store.isLab).toList();
    final done = labs.where((n) => Store.completedLabs.contains(Store.labId(n))).length;
    final remaining = labs.length - done;
    final categories = <String, List<Map>>{};
    for (final n in labs) {
      final category = (n['cat'] ?? 'Other').toString();
      categories.putIfAbsent(category, () => []).add(n);
    }
    return Scaffold(appBar: AppBar(title: const Text('Learning Dashboard')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        learningSummaryCard(onOpen: () {}),
        Wrap(spacing: 12, runSpacing: 12, children: [
          Chip(label: Text('Completed: $done')),
          Chip(label: Text('Remaining: $remaining')),
          Chip(label: Text('Bookmarks: ${Store.fav.length}')),
          Chip(label: Text('Notes read: ${Store.read.length}')),
        ]),
        const SizedBox(height: 12),
        const Text('Lab categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        for (final entry in categories.entries) Builder(builder: (context) {
          final completed = entry.value.where((n) => Store.completedLabs.contains(Store.labId(n))).length;
          return ListTile(title: Text(entry.key), subtitle: LinearProgressIndicator(value: completed / entry.value.length), trailing: Text('$completed/${entry.value.length}'));
        }),
        const SizedBox(height: 12),
        const Text('Quiz best scores', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (Store.quizScores.isEmpty) const Text('Quiz မဖြေရသေးပါ။'),
        for (final entry in Store.quizScores.entries) ListTile(title: Text(entry.key), trailing: Text('${entry.value}%')),
      ]));
  }
}

// Curated multiple-choice questions. Scores are saved locally, not validated by a server.
const quizBank = <List<String>>[
  ['Linux', 'လက်ရှိ directory ကို ပြမယ့် command?', 'pwd', 'ls', 'cd', 'cat'],
  ['Linux', 'Disk filesystem usage ကြည့်ရန်?', 'df -h', 'free -h', 'top', 'whoami'],
  ['Linux', 'RAM usage ကြည့်ရန်?', 'free -h', 'df -h', 'lsblk', 'ip route'],
  ['Linux', 'systemd service status ကြည့်ရန်?', 'systemctl status nginx', 'systemctl delete nginx', 'killall systemd', 'ls nginx'],
  ['Linux', 'Linux IP address ကြည့်ရန်?', 'ip addr', 'lsmod', 'pwd', 'chmod'],
  ['Linux', 'File permission ပြောင်းရန်?', 'chmod', 'chown-only', 'grep', 'curl'],
  ['Docker', 'Running containers စာရင်းကြည့်ရန်?', 'docker ps', 'docker images', 'docker build', 'docker pull'],
  ['Docker', 'Image build လုပ်ရန်?', 'docker build -t myapp .', 'docker ps', 'docker logs', 'docker stop'],
  ['Docker', 'Container logs ကြည့်ရန်?', 'docker logs web', 'docker inspect --rm', 'docker pull web', 'docker rm -f all'],
  ['Docker', 'Image list ကြည့်ရန်?', 'docker images', 'docker ps', 'docker volume rm', 'docker exec'],
  ['Kubernetes', 'Pods စာရင်းကြည့်ရန်?', 'kubectl get pods', 'kubectl get nodes --delete', 'docker ps', 'helm repo add'],
  ['Kubernetes', 'Pod logs ကြည့်ရန်?', 'kubectl logs mypod', 'kubectl describe service', 'docker images', 'terraform show'],
  ['Kubernetes', 'Deployment replicas ပြောင်းရန်?', 'kubectl scale deployment web --replicas=3', 'kubectl logs web', 'kubectl version', 'docker pull web'],
  ['Kubernetes', 'Namespace စာရင်းကြည့်ရန်?', 'kubectl get namespaces', 'kubectl get images', 'docker namespace ls', 'terraform init'],
  ['Terraform', 'Provider/module initialize လုပ်ရန်?', 'terraform init', 'terraform destroy', 'terraform output', 'terraform fmt'],
  ['Terraform', 'Changes ကြိုတင်ကြည့်ရန်?', 'terraform plan', 'terraform destroy', 'terraform import', 'terraform state rm'],
  ['Terraform', 'Configuration format လုပ်ရန်?', 'terraform fmt', 'terraform output', 'terraform apply', 'terraform graph'],
  ['DevOps', 'Git working tree status ကြည့်ရန်?', 'git status', 'git clone --delete', 'git push --all', 'git tag -d'],
  ['DevOps', 'Git commit history အကျဉ်းချုပ်?', 'git log --oneline', 'git reset --hard', 'git init', 'git clean -fd'],
  ['Bash', 'နောက်ဆုံး command exit status?', 'echo \$?', 'echo \$\$', 'echo \$HOME', 'echo \$PATH'],
  ['Bash', 'Script shebang အဖြစ် Bash သတ်မှတ်ရန်?', '#!/usr/bin/env bash', '#!/usr/bin/env python', 'echo bash', 'set -x'],
];

class LearningQuiz extends StatefulWidget {
  const LearningQuiz({super.key});
  @override State<LearningQuiz> createState() => _LearningQuizState();
}
class _LearningQuizState extends State<LearningQuiz> {
  String category = 'Linux';
  int index = 0;
  int score = 0;
  int? selected;
  bool finished = false;
  List<List<String>> get questions => quizBank.where((q) => q[0] == category).toList();
  void reset(String c) => setState(() { category = c; index = 0; score = 0; selected = null; finished = false; });
  @override Widget build(BuildContext context) {
    final qs = questions;
    final q = qs[index];
    // Rotate the correct option deterministically to avoid always being option A.
    final options = [q[2], q[3], q[4], q[5]];
    final shift = (index * 3 + category.length) % options.length;
    final rotated = [...options.skip(shift), ...options.take(shift)];
    return Scaffold(appBar: AppBar(title: const Text('Interactive Quiz')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Subject'),
          items: quizBank.map((e) => e[0]).toSet().map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) { if (v != null) reset(v); }),
        const SizedBox(height: 20),
        if (finished) ...[
          Text('Result: $score / ${qs.length}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          Text('${(score * 100 / qs.length).round()}% — ရလဒ်ကို Device ထဲမှာ သိမ်းထားပါတယ်။'),
          const SizedBox(height: 15), FilledButton(onPressed: () => reset(category), child: const Text('Try again')),
        ] else ...[
          LinearProgressIndicator(value: (index + 1) / qs.length),
          const SizedBox(height: 16), Text('Question ${index + 1} / ${qs.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12), Text(q[1], style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 14),
          for (var i = 0; i < rotated.length; i++) RadioListTile<int>(title: Text(rotated[i]), value: i, groupValue: selected, onChanged: (v) => setState(() => selected = v)),
          const SizedBox(height: 14),
          FilledButton(onPressed: selected == null ? null : () {
            if (rotated[selected!] == q[2]) score++;
            if (index == qs.length - 1) {
              Store.saveQuizScore(category, (score * 100 / qs.length).round());
              setState(() => finished = true);
            } else { setState(() { index++; selected = null; }); }
          }, child: Text(index == qs.length - 1 ? 'Finish quiz' : 'Next question')),
        ],
      ]));
  }
}
