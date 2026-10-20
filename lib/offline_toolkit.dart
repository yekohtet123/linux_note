import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'main.dart';

// All tools on this screen run locally. No shell commands are executed on the device.
const offlineSkills = <String>['Linux foundations','Users & permissions','Services & systemd','Networking & DNS','Bash scripting','Git & CI/CD','Docker','Kubernetes','Terraform','Monitoring & incident response'];
const incidents = <List<String>>[
  ['Disk is full','A service cannot write its logs.','df -h','Find the full filesystem, then inspect large directories with du -sh.','df -h; du -sh /var/log/*'],
  ['DNS resolution fails','IP connectivity works but names do not resolve.','getent hosts example.com','Check resolv.conf, DNS servers and routes.','cat /etc/resolv.conf; resolvectl status'],
  ['Web server stopped','HTTP connection is refused.','systemctl status nginx','Check service state and logs before restarting.','systemctl status nginx; journalctl -u nginx -n 30'],
  ['SSH login denied','User cannot authenticate to a test server.','journalctl -u sshd -n 30','Check sshd status, keys, file permissions and firewall.','systemctl status sshd; ls -ld ~/.ssh'],
  ['Pod CrashLoopBackOff','A Kubernetes Pod repeatedly restarts.','kubectl describe pod demo','Read pod events, logs and container exit status.','kubectl describe pod demo; kubectl logs demo --previous'],
  ['Container exits immediately','A Docker service does not stay running.','docker ps -a','Inspect logs, entrypoint and exit code.','docker logs demo; docker inspect demo'],
];

// These challenges run entirely inside the virtual filesystem. No host commands execute.
const virtualChallenges = <List<String>>[
  ['Create a directory', 'Create /home/student/projects', 'directory', '/home/student/projects'],
  ['Create a file', 'Create /home/student/todo.txt', 'file', '/home/student/todo.txt'],
  ['Navigate directories', 'Change your working directory to /tmp', 'cwd', '/tmp'],
  ['Create a nested folder', 'Create /tmp/lab', 'directory', '/tmp/lab'],
  ['Create a log file', 'Create /tmp/session.log', 'file', '/tmp/session.log'],
  ['Remove a file', 'Create then remove /tmp/remove-me.txt', 'removed', '/tmp/remove-me.txt'],
  ['Create a backup directory', 'Create /home/student/backup', 'directory', '/home/student/backup'],
  ['Return home', 'Change directory to /home/student', 'cwd', '/home/student'],
  ['Write a note', 'Use echo Hello > /tmp/hello.txt', 'content', '/tmp/hello.txt|Hello'],
  ['Copy a file', 'Copy /home/student/readme.txt to /tmp/readme-copy.txt', 'copy', '/tmp/readme-copy.txt|/home/student/readme.txt'],
  ['Rename a file', 'Create /tmp/old.txt then move it to /tmp/new.txt', 'moved', '/tmp/old.txt|/tmp/new.txt'],
  ['Create nested parents', 'Use mkdir -p /tmp/a/b/c', 'directory', '/tmp/a/b/c'],
  ['Change file mode', 'Use chmod 600 /home/student/readme.txt', 'mode', '/home/student/readme.txt|600'],
  ['Append to a file', 'Use echo world >> /tmp/hello.txt after lab 9', 'contains', '/tmp/hello.txt|world'],
  ['Remove a directory', 'Create and remove an empty /tmp/empty folder with rmdir', 'removedDir', '/tmp/empty'],
  ['Make a workspace', 'Create /home/student/workspace/scripts', 'directory', '/home/student/workspace/scripts'],
  ['Write a shell script', 'Write echo ready > /home/student/workspace/scripts/start.sh', 'content', '/home/student/workspace/scripts/start.sh|ready'],
  ['Copy a script', 'Copy /home/student/workspace/scripts/start.sh to /tmp/start.sh', 'copy', '/tmp/start.sh|/home/student/workspace/scripts/start.sh'],
  ['Secure a script', 'Set chmod 700 /tmp/start.sh', 'mode', '/tmp/start.sh|700'],
  ['Practice navigation', 'Navigate to /home/student/workspace/scripts', 'cwd', '/home/student/workspace/scripts'],
];

class OfflineToolkit extends StatefulWidget {
  const OfflineToolkit({super.key});
  @override State<OfflineToolkit> createState() => _OfflineToolkitState();
}
class _OfflineToolkitState extends State<OfflineToolkit> {
  int tab = 0;
  final command = TextEditingController();
  static const int maxEditorChars = 32768;
  static const String defaultEditorText = '#!/usr/bin/env bash\nset -euo pipefail\necho "Hello Linux"';
  final editor = TextEditingController(text: defaultEditorText);
  String editorLanguage = 'Bash';
  final log = <String>['Offline terminal simulator V3. Try: help'];
  final commandHistory = <String>[];
  int historyPosition = 0;
  String historyDraft = '';
  static const int maxTerminalLogLines = 250;
  static const int maxCommandHistory = 80;
  final directories = <String>{'/', '/home', '/home/student', '/tmp'};
  final files = <String,String>{'/home/student/readme.txt':'Welcome to the offline Linux lab!'};
  String cwd = '/home/student';
  final modes = <String,String>{};
  final removedPaths = <String>{};
  int incident = 0;
  bool reveal = false;
  String validation = '';
  String search = '';
  int challenge = 0;
  Set<int> verifiedChallenges = {};
  final backupInput = TextEditingController();
  String backupMessage = '';
  final infraCommand = TextEditingController();
  final infraLog = <String>['Offline infrastructure simulator. Type help.'];
  final dockerImages = <String>{'nginx:alpine', 'alpine:latest'};
  final dockerContainers = <String,String>{};
  final kubeDeployments = <String,int>{};
  final terraformResources = <String>{};
  bool terraformInitialized = false;
  final importedPacks = <Map<String,dynamic>>[];
  final packInput = TextEditingController();
  String packStatus = '';
  int infraTab = 0;
  bool useBurmese = true;
  String tr(String mm, String en) => useBurmese ? mm : en;


  Set<String> skills = {};
  Set<int> days = {};
  Set<String> badges = {};

  @override void initState() {
    super.initState();
    skills = (Store.p.getStringList('offline_skills_v1') ?? []).toSet();
    days = (Store.p.getStringList('offline_days_v1') ?? []).map(int.tryParse).whereType<int>().toSet();
    badges = (Store.p.getStringList('offline_badges_v1') ?? []).toSet();
    verifiedChallenges = (Store.p.getStringList('offline_verified_challenges_v2') ?? []).map(int.tryParse).whereType<int>().toSet();
    useBurmese = Store.p.getBool('offline_language_mm_v1') ?? true;
    final savedLanguage = Store.p.getString('offline_editor_language_v1');
    if (const ['Bash', 'YAML', 'Terraform HCL'].contains(savedLanguage)) {
      editorLanguage = savedLanguage!;
    }
    final savedDraft = Store.p.getString('offline_editor_draft_v1');
    if (savedDraft != null && savedDraft.length <= maxEditorChars &&
        !savedDraft.contains('\u0000')) {
      editor.text = savedDraft;
    }
    editor.addListener(saveEditorDraft);
    // Command history is local-only and bounded. Malformed saved entries are ignored.
    final savedHistory = Store.p.getStringList('offline_terminal_history_v1');
    if (savedHistory != null && savedHistory.length <= maxCommandHistory &&
        savedHistory.every((entry) => entry.isNotEmpty &&
          entry.length <= 4096 && !entry.contains('\u0000'))) {
      commandHistory.addAll(savedHistory);
      historyPosition = commandHistory.length;
    }

    // Restore only well-formed, bounded virtual filesystem state. Never access host files.
    final savedTerminal = Store.p.getString('offline_terminal_state_v1');
    if (savedTerminal != null && savedTerminal.length <= 150000) {
      try {
        final state = jsonDecode(savedTerminal);
        if (state is Map && state['directories'] is List && state['files'] is Map &&
            state['modes'] is Map && state['removed'] is List && state['cwd'] is String) {
          final dirs = (state['directories'] as List).cast<String>();
          final savedFiles = (state['files'] as Map).cast<String, dynamic>();
          final savedModes = (state['modes'] as Map).cast<String, dynamic>();
          final removed = (state['removed'] as List).cast<String>();
          final current = state['cwd'] as String;
          bool validPath(String p) => p.startsWith('/') && path(p) == p &&
              p.length <= 256 && p.split('/').every((segment) => segment.length <= 128) && !p.contains('\\') && !p.contains('\u0000');
          if (dirs.length <= 1500 && dirs.toSet().length == dirs.length &&
              savedFiles.length <= 1500 && savedModes.length <= 1500 &&
              removed.length <= 400 && removed.toSet().length == removed.length &&
              dirs.length + savedFiles.length <= 1500 && ['/', '/home', '/home/student', '/tmp'].every(dirs.contains) &&
              dirs.every(validPath) && savedFiles.keys.every(validPath) &&
              savedFiles.values.every((v) => v is String && v.length <= 4096) &&
              dirs.every((d) => d == '/' || dirs.contains(parentOf(d))) &&
              savedModes.keys.every((f) => savedFiles.containsKey(f)) &&
              removed.every((p) => !dirs.contains(p) && !savedFiles.containsKey(p)) &&
              savedModes.keys.every(validPath) &&
              savedModes.values.every((v) => v is String && RegExp(r'^[0-7]{3,4}$').hasMatch(v)) &&
              removed.every(validPath) && dirs.contains(current) &&
              savedFiles.keys.every((f) => dirs.contains(parentOf(f))) &&
              savedFiles.keys.every((f) => !dirs.contains(f))) {
            directories..clear()..addAll(dirs);
            files..clear()..addAll(savedFiles.map((k, v) => MapEntry(k, v as String)));
            modes..clear()..addAll(savedModes.map((k, v) => MapEntry(k, v as String)));
            removedPaths..clear()..addAll(removed);
            cwd = current;
            log.add('Restored saved virtual filesystem.');
          }
        }
      } catch (_) { debugPrint('Ignored invalid virtual filesystem save'); }
    }

    final savedPacks = Store.p.getString('offline_imported_packs_v1');
    if (savedPacks != null) {
      try {
        final decoded = jsonDecode(savedPacks);
        if (decoded is List) {
          for (final item in decoded) {
            try {
              if (importedPacks.length >= 20) break;
              importedPacks.add(validatedPack(item));
            } on FormatException {
              debugPrint('Skipped invalid saved offline lab pack');
            }
          }
        }
      } catch (e) { debugPrint('Invalid saved offline lab packs: $e'); }
    }
  }
  void save() {
    Store.p.setStringList('offline_skills_v1', skills.toList());
    Store.p.setStringList('offline_days_v1', days.map((e)=>'$e').toList());
    Store.p.setStringList('offline_badges_v1', badges.toList());
    Store.p.setStringList('offline_verified_challenges_v2', verifiedChallenges.map((e)=>'$e').toList());
    Store.p.setBool('offline_language_mm_v1', useBurmese);
    Store.p.setString('offline_imported_packs_v1', jsonEncode(importedPacks));
  }
  // Tombstones are needed for virtual challenge verification, but must not grow
  // indefinitely after repeated create/delete operations.
  void rememberRemovedPath(String target) {
    removedPaths.remove(target);
    removedPaths.add(target);
    while (removedPaths.length > 400) {
      removedPaths.remove(removedPaths.first);
    }
  }
  void saveTerminal() {
    final state = jsonEncode({'directories': directories.toList(), 'files': files,
      'modes': modes, 'removed': removedPaths.toList(), 'cwd': cwd});
    if (state.length <= 150000) {
      Store.p.setString('offline_terminal_state_v1', state);
    } else {
      // Do not silently leave an older snapshot that looks like the latest state.
      Store.p.remove('offline_terminal_state_v1');
      log.add('Virtual terminal state exceeded the offline save limit. Reset to restore persistence.');
    }
  }
  void resetTerminal() {
    setState(() {
      directories..clear()..addAll(['/', '/home', '/home/student', '/tmp']);
      files..clear()..addAll({'/home/student/readme.txt':'Welcome to the offline Linux lab!'});
      modes.clear();
      removedPaths.clear();
      cwd = '/home/student';
      verifiedChallenges.clear();
      log..clear()..add('Virtual filesystem reset. All verified virtual challenges cleared.');
      commandHistory.clear();
      Store.p.remove('offline_terminal_history_v1');
      historyPosition = 0;
      historyDraft = '';
      command.clear();
      saveTerminal();
      save();
    });
  }
  Future<void> confirmResetTerminal() async {
    final accepted = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Reset virtual terminal?'),
      content: const Text('This removes simulated files and clears verified virtual lab progress. Other notes and learning progress are kept.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Reset'))],
    ));
    if (accepted == true && mounted) resetTerminal();
  }
  String path(String input) {
    final raw = input.startsWith('/') ? input : '$cwd/$input';
    final parts = <String>[];
    for (final p in raw.split('/')) {
      if (p.isEmpty || p == '.') continue;
      if (p == '..') { if (parts.isNotEmpty) parts.removeLast(); } else { parts.add(p); }
    }
    return '/${parts.join('/')}';
  }
  String run(String input) {
    final cmd = input.trim();
    if (cmd.isEmpty) return '';
    if (cmd.length > 4096) return 'terminal: command too long';
    // Existing files can still be inspected or removed at the capacity limit.
    // Creation commands enforce the limit individually.
    // This is a deliberately limited, non-executing command interpreter.
    // No device filesystem, subprocess, network or shell is accessed.
    final redirect = RegExp(r'^echo\s+(.+?)\s*(>>|>)\s*(\S+)$').firstMatch(cmd);
    if (redirect != null) {
      final dest = path(redirect.group(3)!);
      final parent = parentOf(dest);
      if (!directories.contains(parent)) return 'echo: parent directory missing';
      if (directories.contains(dest)) return 'echo: destination is a directory';
      final content = redirect.group(1)!;
      final addedLength = content.length + 1; // echo writes a trailing newline.
      final existingLength = redirect.group(2) == '>>' ? (files[dest]?.length ?? 0) : 0;
      if (existingLength + addedLength > 4096) return 'echo: virtual file size limit exceeded';
      if (dest.length > 256 || dest.split('/').any((segment) => segment.length > 128) || dest.contains('\\') || dest.contains('\u0000')) return 'echo: invalid virtual path';
      if (!files.containsKey(dest) && directories.length + files.length >= 1500) return 'echo: virtual filesystem limit reached';
      files[dest] = redirect.group(2) == '>>' ? '${files[dest] ?? ''}$content\n' : '$content\n';
      removedPaths.remove(dest);
      return '';
    }
    final parts = cmd.split(RegExp(r'\s+'));
    final op = parts.first;
    final args = parts.skip(1).where((v) => !v.startsWith('-')).toList();
    // Reject unsupported options instead of silently ignoring them.
    final flags = parts.skip(1).where((v) => v.startsWith('-')).toList();
    if (flags.isNotEmpty && !(op == 'mkdir' && flags.length == 1 && flags.single == '-p')) {
      return '$op: unsupported option ${flags.first}';
    }
    final target = path(args.isEmpty ? '.' : args.first);
    bool invalidVirtualPath(String value) => value.length > 256 || value.contains('\\') ||
        value.contains('\u0000') || value.split('/').any((part) => part.length > 128);
    if (args.any((a) => invalidVirtualPath(path(a)))) return '$op: invalid or overlong virtual path';
    switch (op) {
      case 'help': return 'pwd whoami ls cd mkdir [-p] touch cat echo [> | >>] rm rmdir cp mv chmod grep wc head clear help. Virtual files only.';
      case 'pwd': if (args.isNotEmpty) return 'pwd: unexpected operand'; return cwd;
      case 'whoami': if (args.isNotEmpty) return 'whoami: unexpected operand'; return 'student';
      case 'ls':
        if (args.length > 1) return 'ls: expected at most one path';
        if (files.containsKey(target)) return target.split('/').last;
        if (!directories.contains(target)) return 'ls: no such directory';
        final names = <String>{};
        for (final p in [...directories, ...files.keys]) {
          if (p != target && p.startsWith('${target == '/' ? '' : target}/')) {
            final rest = p.substring(target.length).replaceFirst(RegExp(r'^/'), '');
            if (rest.isNotEmpty) names.add(rest.split('/').first);
          }
        }
        return names.isEmpty ? '(empty)' : (names.toList()..sort()).join('  ');
      case 'cd':
        if (args.length > 1) return 'cd: expected at most one path';
        final dest = args.isEmpty ? '/home/student' : target;
        if (!directories.contains(dest)) return 'cd: no such directory';
        cwd = dest; return '';
      case 'mkdir':
        if (args.length != 1) return 'mkdir: expected one directory';
        if (args.isEmpty) return 'mkdir: missing operand';
        if (parts.contains('-p')) {
          // Validate the complete operation before changing any directory state.
          // An error must not leave a partially created directory tree.
          var current = '';
          final toCreate = <String>[];
          for (final segment in target.split('/').where((v) => v.isNotEmpty)) {
            current += '/$segment';
            if (files.containsKey(current)) return 'mkdir: path is a file';
            if (!directories.contains(current)) toCreate.add(current);
          }
          if (directories.length + files.length + toCreate.length > 1500) {
            return 'mkdir: virtual filesystem limit reached';
          }
          directories.addAll(toCreate);
          // Recreated ancestors must not remain marked as removed.
          removedPaths.removeAll(toCreate);
        } else {
          if (!directories.contains(parentOf(target))) return 'mkdir: parent directory missing';
          if (files.containsKey(target)) return 'mkdir: file already exists';
          if (directories.contains(target)) return 'mkdir: directory already exists';
          if (directories.length + files.length >= 1500) return 'mkdir: virtual filesystem limit reached';
          directories.add(target);
        }
        removedPaths.remove(target); return '';
      case 'touch':
        if (args.length != 1) return 'touch: expected one file';
        if (args.isEmpty) return 'touch: missing operand';
        if (!directories.contains(parentOf(target))) return 'touch: parent directory missing';
        if (directories.contains(target)) return 'touch: destination is a directory';
        if (!files.containsKey(target) && directories.length + files.length >= 1500) return 'touch: virtual filesystem limit reached';
        files.putIfAbsent(target, () => ''); removedPaths.remove(target); return '';
      case 'cat': if (args.length != 1) return 'cat: expected one file'; return files[target] ?? 'cat: file not found';
      case 'echo': return cmd.length > 4 ? cmd.substring(4).trim() : '';
      case 'rm':
        if (args.length != 1) return 'rm: expected one file';
        if (!files.containsKey(target)) return 'rm: file not found (directories are protected)';
        files.remove(target); modes.remove(target); rememberRemovedPath(target); return '';
      case 'rmdir':
        if (args.length != 1) return 'rmdir: expected one directory';
        if (!directories.contains(target) || target == '/' || target == '/home' || target == '/home/student' || target == cwd || cwd.startsWith('$target/')) return 'rmdir: invalid directory';
        if ([...files.keys, ...directories].any((v) => v.startsWith('$target/'))) return 'rmdir: directory not empty';
        directories.remove(target); rememberRemovedPath(target); return '';
      case 'cp':
        if (args.length != 2) return 'cp: expected source and destination';
        final dest = path(args[1]);
        if (!files.containsKey(target)) return 'cp: source file missing';
        if (!directories.contains(parentOf(dest))) return 'cp: destination parent missing';
        if (directories.contains(dest)) return 'cp: destination is a directory';
        if (!files.containsKey(dest) && directories.length + files.length >= 1500) return 'cp: virtual filesystem limit reached';
        files[dest] = files[target]!; modes[dest] = modes[target] ?? '644'; removedPaths.remove(dest); return '';
      case 'mv':
        if (args.length != 2) return 'mv: expected source and destination';
        final dest = path(args[1]);
        if (!files.containsKey(target)) return 'mv: source file missing';
        if (!directories.contains(parentOf(dest))) return 'mv: destination parent missing';
        if (directories.contains(dest)) return 'mv: destination is a directory';
        if (dest == target) return '';
        files[dest] = files.remove(target)!;
        modes[dest] = modes.remove(target) ?? '644';
        rememberRemovedPath(target); removedPaths.remove(dest); return '';
      case 'chmod':
        if (args.length != 2) return 'chmod: expected octal mode and file';
        if (!RegExp(r'^[0-7]{3,4}$').hasMatch(args[0])) return 'chmod: use octal mode (e.g. 600)';
        final dest = path(args[1]);
        if (!files.containsKey(dest)) return 'chmod: file missing';
        modes[dest] = args[0]; return '';
      case 'grep':
        if (args.length != 2) return 'grep: expected literal pattern and file';
        final dest = path(args[1]);
        if (!files.containsKey(dest)) return 'grep: file missing';
        return files[dest]!.split('\n').where((line) => line.contains(args[0])).join('\n');
      case 'wc':
        if (args.length != 1) return 'wc: expected file';
        if (!files.containsKey(target)) return 'wc: file missing';
        final content = files[target]!;
        return '${'\n'.allMatches(content).length} ${content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length} ${content.length} $target';
      case 'head':
        if (args.length != 1) return 'head: expected file';
        if (!files.containsKey(target)) return 'head: file missing';
        return files[target]!.split('\n').take(10).join('\n');
      case 'clear': if (args.isNotEmpty) return 'clear: unexpected operand'; log.clear(); return '';
      default: return '$op: not supported by offline simulator';
    }
  }
  String parentOf(String p) {
    final index = p.lastIndexOf('/');
    return index <= 0 ? '/' : p.substring(0, index);
  }

  void recallCommand(int direction) {
    if (commandHistory.isEmpty) return;
    setState(() {
      // Preserve an unfinished command while browsing older commands.
      if (historyPosition == commandHistory.length && direction < 0) {
        historyDraft = command.text;
      }
      historyPosition = (historyPosition + direction).clamp(0, commandHistory.length).toInt();
      command.text = historyPosition == commandHistory.length
          ? historyDraft : commandHistory[historyPosition];
      command.selection = TextSelection.collapsed(offset: command.text.length);
    });
  }
  void execute() {
    final s = command.text.trim();
    if (s.isEmpty) return;
    setState(() {
      // Never persist commands that would fail the history restore bounds.
      if (s.length <= 4096 && !s.contains('\u0000') &&
          (commandHistory.isEmpty || commandHistory.last != s)) {
        commandHistory.add(s);
        if (commandHistory.length > maxCommandHistory) commandHistory.removeAt(0);
      }
      historyPosition = commandHistory.length;
      historyDraft = '';
      log.add('$cwd \$ $s');
      // Preserve the previous valid filesystem if a mutation would make the
      // serialized snapshot too large to restore on the next launch.
      final beforeDirs = Set<String>.of(directories);
      final beforeFiles = Map<String, String>.of(files);
      final beforeModes = Map<String, String>.of(modes);
      final beforeRemoved = Set<String>.of(removedPaths);
      final beforeCwd = cwd;
      var output = run(s);
      final encodedState = jsonEncode({'directories': directories.toList(),
        'files': files, 'modes': modes, 'removed': removedPaths.toList(), 'cwd': cwd});
      if (encodedState.length > 150000) {
        directories..clear()..addAll(beforeDirs);
        files..clear()..addAll(beforeFiles);
        modes..clear()..addAll(beforeModes);
        removedPaths..clear()..addAll(beforeRemoved);
        cwd = beforeCwd;
        output = 'terminal: command rejected; offline save capacity exceeded';
      }
      if (output.isNotEmpty) log.add(output);
      if (log.length > maxTerminalLogLines) {
        log.removeRange(0, log.length - maxTerminalLogLines);
      }
    });
    saveTerminal();
    // Only the bounded simulator command history is persisted, never the output log.
    Store.p.setStringList('offline_terminal_history_v1', commandHistory);
    command.clear();
  }
  void saveEditorDraft() {
    final draft = editor.text;
    if (draft.length <= maxEditorChars && !draft.contains('\u0000')) {
      Store.p.setString('offline_editor_draft_v1', draft);
    }
  }
  Future<void> resetEditorDraft() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Editor စာသားကို ရှင်းမလား?', 'Reset editor draft?')),
        content: Text(tr('သိမ်းထားသော Editor စာသားကို ဖျက်ပြီး နမူနာ Code ပြန်ထည့်ပါမယ်။',
            'Your saved draft will be replaced with the default example.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(tr('မလုပ်တော့ပါ', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(tr('ပြန်စရန်', 'Reset'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    editor.text = defaultEditorText;
    setState(() => validation = '');
  }
  void validate() {
    final source = editor.text;
    final errors = <String>[];
    if (source.trim().isEmpty) errors.add('Editor is empty');
    if (source.length > maxEditorChars) errors.add('Editor exceeds the offline storage limit');
    if (source.contains('\u0000')) errors.add('NUL characters are not allowed');
    if (editorLanguage == 'YAML') {
      for (final line in source.split('\n')) {
        if (line.trim().isEmpty || line.trimLeft().startsWith('#')) continue;
        final indentation = line.length - line.trimLeft().length;
        if (line.substring(0, indentation).contains('\t')) {
          errors.add('YAML indentation must use spaces, not tabs');
          break;
        }
      }
      if (!source.split('\n').any((line) => line.trimLeft().startsWith('- ') || line.contains(':'))) {
        errors.add('No YAML mapping or list marker found');
      }
    } else if (editorLanguage == 'Terraform HCL') {
      final open = '{'.allMatches(source).length;
      final close = '}'.allMatches(source).length;
      if (open != close) errors.add('Unbalanced HCL curly braces');
    } else if (editorLanguage == 'Bash') {
      if (source.startsWith('#!') && !source.split('\n').first.contains('bash') &&
          !source.split('\n').first.contains('/sh')) {
        errors.add('Unknown shell interpreter in shebang');
      }
    }
    setState(() => validation = errors.isEmpty
        ? 'Basic $editorLanguage checks passed. This is NOT a complete parser or executable environment.'
        : errors.join('\n'));
  }
  bool challengePassed(int i) {
    final c = virtualChallenges[i];
    final value = c[3].split('|');
    switch (c[2]) {
      case 'directory': return directories.contains(c[3]);
      case 'file': return files.containsKey(c[3]);
      case 'cwd': return cwd == c[3];
      case 'removed': return removedPaths.contains(c[3]) && !files.containsKey(c[3]);
      case 'removedDir': return removedPaths.contains(c[3]) && !directories.contains(c[3]);
      case 'content': return files[value[0]]?.trim() == value[1];
      case 'contains': return files[value[0]]?.contains(value[1]) ?? false;
      case 'copy': return files.containsKey(value[0]) && files[value[0]] == files[value[1]];
      case 'moved': return removedPaths.contains(value[0]) && files.containsKey(value[1]);
      case 'mode': return modes[value[0]] == value[1];
      default: return false;
    }
  }

  // All commands below are parsed into an in-memory model. They never invoke
  // Docker, Kubernetes, Terraform, a subprocess, or any network endpoint.
  String simulateInfra(String line) {
    final args = line.trim().split(RegExp(r'\s+')).where((x)=>x.isNotEmpty).toList();
    if (args.isEmpty) return '';
    if (args[0] == 'help') return 'docker images | docker ps | docker run --name NAME IMAGE | docker stop NAME | kubectl get deployments | kubectl create deployment NAME --image=nginx | kubectl scale deployment NAME --replicas=N | terraform init | terraform plan | terraform apply | terraform state list | terraform destroy';
    if (args[0] == 'docker') {
      if (args.length == 2 && args[1] == 'images') return dockerImages.join('\n');
      if (args.length == 2 && args[1] == 'ps') return dockerContainers.entries.map((e)=>'${e.key}  ${e.value}').join('\n');
      if (args.length == 5 && args[1] == 'run' && args[2] == '--name' && args[3].isNotEmpty && args[4].isNotEmpty) {
        final name=args[3], image=args[4];
        if(dockerContainers.containsKey(name)) return 'Error: container name already exists';
        dockerImages.add(image); dockerContainers[name]=image; return 'Started simulated container $name';
      }
      if (args.length == 3 && args[1] == 'stop') return dockerContainers.remove(args[2]) == null ? 'No such running container' : 'Stopped ${args[2]}';
      return 'Unsupported Docker simulation command. Type help.';
    }
    if (args[0] == 'kubectl') {
      if(args.length == 3 && args[1]=='get' && args[2]=='deployments') return kubeDeployments.entries.map((e)=>'${e.key}  ${e.value}/${e.value}').join('\n');
      if(args.length == 5 && args[1]=='create' && args[2]=='deployment' && args[4].startsWith('--image=') && args[4].length > 8) {
        if(kubeDeployments.containsKey(args[3])) return 'Deployment already exists';
        kubeDeployments[args[3]]=1; return 'deployment.apps/${args[3]} created (simulation)';
      }
      if(args.length == 5 && args[1]=='scale' && args[2]=='deployment' && args[4].startsWith('--replicas=')) {
        final count=int.tryParse(args[4].substring(11));
        if(count == null || count < 0 || count > 50) return 'Replicas must be 0..50';
        if(!kubeDeployments.containsKey(args[3])) return 'Deployment not found';
        kubeDeployments[args[3]]=count; return 'deployment.apps/${args[3]} scaled';
      }
      return 'Unsupported Kubernetes simulation command. Type help.';
    }
    if(args[0]=='terraform' && args.length==2) {
      switch(args[1]) {
        case 'init': terraformInitialized = true; return 'Terraform initialized (simulation only)';
        case 'plan': if (!terraformInitialized) return 'Run terraform init first (simulation)'; return 'Plan: ${terraformResources.contains('local_file.lab') ? '0 to add' : '1 to add'}, 0 to change, 0 to destroy (simulation)';
        case 'apply': if (!terraformInitialized) return 'Run terraform init first (simulation)'; final created=terraformResources.add('local_file.lab'); return created ? 'Apply complete! Resources: 1 added (simulation)' : 'Apply complete! Resources: 0 added (already present, simulation)';
        case 'state': return 'Use terraform state list';
        case 'destroy': if (!terraformInitialized) return 'Run terraform init first (simulation)'; terraformResources.clear(); return 'Destroy complete (simulation)';
      }
    }
    if(args.length==3 && args[0]=='terraform' && args[1]=='state' && args[2]=='list') return terraformInitialized ? terraformResources.join('\n') : 'Run terraform init first (simulation)';
    return 'Unknown simulation command. Type help.';
  }

  Widget infrastructureSimulator() => Column(children:[
    const ListTile(title:Text('Docker / Kubernetes / Terraform sandbox'),subtitle:Text('Virtual state only. No real containers, clusters, cloud resources, or network calls.')),
    Expanded(child:Container(width:double.infinity,color:const Color(0xff121a17),padding:const EdgeInsets.all(12),child:ListView(children:[for(final line in infraLog) SelectableText(line,style:const TextStyle(fontFamily:'monospace',color:Color(0xffb9f6ca)))]))),
    Padding(padding:const EdgeInsets.all(8),child:Row(children:[Expanded(child:TextField(controller:infraCommand,decoration:const InputDecoration(labelText:'Simulated command',border:OutlineInputBorder()),onSubmitted:(_)=>runInfra())),const SizedBox(width:8),FilledButton(onPressed:runInfra,child:const Text('Run'))])),
    Wrap(spacing:6,children:[
      ActionChip(label:const Text('Docker lab'),onPressed:()=>setState(()=>infraCommand.text='docker run --name web nginx:alpine')),
      ActionChip(label:const Text('K8s lab'),onPressed:()=>setState(()=>infraCommand.text='kubectl create deployment web --image=nginx')),
      ActionChip(label:const Text('Terraform lab'),onPressed:()=>setState(()=>infraCommand.text='terraform plan')),
    ]),
    Padding(padding:const EdgeInsets.all(8),child:Text('Verified: Docker web running ${dockerContainers.containsKey('web') ? '✓' : '○'}   K8s web deployed ${kubeDeployments.containsKey('web') ? '✓' : '○'}   Terraform applied ${terraformResources.isNotEmpty ? '✓' : '○'}')),
  ]);
  void runInfra() {
    final value=infraCommand.text.trim();
    if(value.isEmpty) return;
    setState(() { infraLog.add('\$ $value'); infraLog.add(simulateInfra(value)); });
    infraCommand.clear();
  }

  // Validate imported, restored and previously saved packs through one path.
  // Packs contain display-only strings, never executable commands.
  Map<String, dynamic> validatedPack(dynamic raw) {
    if (raw is! Map<String, dynamic> || raw['title'] is! String || raw['labs'] is! List) {
      throw const FormatException('Expected a lab pack with title and labs');
    }
    final title = (raw['title'] as String).trim();
    final labs = raw['labs'] as List;
    if (title.isEmpty || title.length > 120 || labs.isEmpty || labs.length > 200) {
      throw const FormatException('Pack title or lab count is invalid');
    }
    final checked = <Map<String, String>>[];
    for (final lab in labs) {
      if (lab is! Map || lab['title'] is! String || lab['task'] is! String) {
        throw const FormatException('Each lab needs title and task');
      }
      final labTitle = (lab['title'] as String).trim();
      final task = (lab['task'] as String).trim();
      if (labTitle.isEmpty || labTitle.length > 180 || task.isEmpty || task.length > 4000) {
        throw const FormatException('Invalid lab title or task length');
      }
      checked.add({'title': labTitle, 'task': task});
    }
    return {'title': title, 'labs': checked};
  }

  // User-authored lab packs are data only. Never evaluate code from JSON.
  void importPack() {
    try {
      if (packInput.text.length > 250000) throw const FormatException('Pack JSON exceeds 250 KB');
      final pack = validatedPack(jsonDecode(packInput.text));
      final labs = pack['labs'] as List;
      if(importedPacks.any((p)=>p['title']==pack['title'])) throw const FormatException('A pack with this title already exists');
      if(importedPacks.length>=20) throw const FormatException('Maximum 20 saved packs');
      setState(() { importedPacks.add(pack); packStatus='Saved ${labs.length} read-only lab tasks locally.'; save(); });
    } catch(e) {setState(()=>packStatus='Import failed: $e');}
  }
  Widget packsPage() => ListView(padding:const EdgeInsets.all(16),children:[
    Text('Offline lab packs',style:Theme.of(context).textTheme.titleLarge),
    const Text('Paste a local JSON pack. Imported packs are read-only tasks and never execute scripts. Packs persist on this device.'),
    const SizedBox(height:12),
    OutlinedButton(onPressed:()=>Clipboard.setData(const ClipboardData(text:'{"title":"My offline labs","labs":[{"title":"Check filesystem","task":"Practice pwd and ls in the virtual terminal"}]}')),child:const Text('Copy example JSON format')),
    TextField(controller:packInput,maxLines:7,decoration:const InputDecoration(labelText:'Paste lab pack JSON',border:OutlineInputBorder())),
    FilledButton(onPressed:importPack,child:const Text('Import local pack')),
    Text(packStatus),
    for(final pack in importedPacks) ExpansionTile(
      title:Text('${pack['title']}'),
      trailing:IconButton(tooltip:'Remove saved pack',icon:const Icon(Icons.delete_outline),onPressed:(){setState(() {importedPacks.remove(pack);save();});}),
      children:[for(final lab in pack['labs'] as List) ListTile(title:Text('${lab['title']}'),subtitle:Text('${lab['task']}'))]),
  ]);

  Widget challengePage() => ListView(padding: const EdgeInsets.all(16), children: [
    Text('Verified virtual labs: ${verifiedChallenges.length}/${virtualChallenges.length}', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    LinearProgressIndicator(value: verifiedChallenges.length/virtualChallenges.length),
    const SizedBox(height: 12),
    DropdownButtonFormField<int>(value: challenge, decoration: const InputDecoration(labelText:'Choose a virtual lab'),
      items: [for(int i=0;i<virtualChallenges.length;i++) DropdownMenuItem(value:i, child: Text('${i+1}. ${virtualChallenges[i][0]}'))],
      onChanged: (v)=>setState(()=>challenge=v ?? 0)),
    const SizedBox(height: 18),
    Text(virtualChallenges[challenge][1], style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 12),
    const Text('Open the Terminal tab, execute commands, then return and tap Verify. Only virtual state is checked.'),
    const SizedBox(height: 16),
    FilledButton.icon(icon: const Icon(Icons.fact_check_outlined), label: const Text('Verify lab'), onPressed: () {
      final ok = challengePassed(challenge);
      if(ok) { verifiedChallenges.add(challenge); save(); }
      setState((){});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Passed! Virtual system state verified.' : 'Not yet passed. Try the terminal commands.')));
    }),
    if(verifiedChallenges.contains(challenge)) const ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Completed and saved offline')),
    const Divider(),
    for(int i=0;i<virtualChallenges.length;i++) ListTile(
      leading: Icon(verifiedChallenges.contains(i) ? Icons.check_circle : Icons.radio_button_unchecked),
      title: Text(virtualChallenges[i][0]),
      onTap: ()=>setState(()=>challenge=i),
    ),
  ]);
  void restoreBackup() {
    try {
      if (backupInput.text.length > 2000000) throw const FormatException('Backup exceeds 2 MB');
      final data = jsonDecode(backupInput.text);
      if(data is! Map<String,dynamic>) throw const FormatException('Expected JSON object');
      Set<String> strings(String key) {
        final v = data[key];
        if(v == null) return {};
        if(v is! List || v.length > 5000 || v.any((x)=>x is! String || (x as String).length > 300)) {
          throw FormatException('Invalid $key');
        }
        return v.cast<String>().toSet();
      }
      Set<int> numbers(String key) {
        final v = data[key];
        if(v == null) return {};
        if(v is! List || v.length > 5000 || v.any((e)=>e is! int)) {
          throw FormatException('Invalid $key');
        }
        final n = v.cast<int>();
        return n.toSet();
      }
      final restoredLabs = strings('completedLabs');
      final restoredRead = strings('read');
      final restoredFav = strings('bookmarks');
      final restoredSkills = strings('skills');
      final restoredDays = numbers('days').where((e)=>e>=1&&e<=100).toSet();
      final restoredBadges = strings('badges');
      final restoredChallenges = numbers('verifiedChallenges').where((e)=>e>=0&&e<virtualChallenges.length).toSet();
      final rawScores = data['quizScores'];
      final restoredScores = <String,int>{};
      if (rawScores != null) {
        if (rawScores is! Map || rawScores.length > 500) throw const FormatException('Invalid quizScores');
        for (final entry in rawScores.entries) {
          if (entry.key is! String || (entry.key as String).length > 150 || entry.value is! int || (entry.value as int) < 0 || (entry.value as int) > 100000) throw const FormatException('Invalid quiz score');
          restoredScores[entry.key as String] = entry.value as int;
        }
      }
      final restoredWrong = strings('wrongAnswers');
      final rawPacks = data['importedPacks'];
      final restoredPacks = <Map<String,dynamic>>[];
      if (rawPacks != null) {
        if (rawPacks is! List || rawPacks.length>20) throw const FormatException('Invalid importedPacks');
        for (final item in rawPacks) {
          restoredPacks.add(validatedPack(item));
        }
      }
      setState(() {
        Store.completedLabs.addAll(restoredLabs);
        Store.read.addAll(restoredRead);
        Store.fav.addAll(restoredFav);
        skills.addAll(restoredSkills.where(offlineSkills.contains));
        days.addAll(restoredDays);
        badges.addAll(restoredBadges);
        Store.quizScores.addAll(restoredScores);
        Store.wrong = {...Store.wrong, ...restoredWrong}.toList();
        verifiedChallenges.addAll(restoredChallenges);
        for (final pack in restoredPacks) {
          if (importedPacks.length>=20) break;
          if (!importedPacks.any((p)=>p['title']==pack['title'])) importedPacks.add(pack);
        }
        backupMessage = 'Backup merged. Existing progress was kept.';
      });
      Store.p.setStringList('completed_labs_v1', Store.completedLabs.toList());
      Store.p.setStringList('read', Store.read.toList());
      Store.p.setStringList('fav', Store.fav.toList());
      Store.p.setString('quiz_scores_v1', jsonEncode(Store.quizScores));
      Store.p.setStringList('wrong', Store.wrong);
      save();
    } catch (e) { setState(()=>backupMessage='Could not import: $e'); }
  }
  Widget backupPage() => ListView(padding: const EdgeInsets.all(16), children: [
    Text('Offline progress backup', style: Theme.of(context).textTheme.titleLarge),
    const Text('Copy a JSON backup and store it privately. Import merges saved toolkit progress. No network is used.'),
    const SizedBox(height: 12),
    FilledButton(onPressed: () {
      final payload=jsonEncode({'version':2,'completedLabs':Store.completedLabs.toList(),'read':Store.read.toList(),'bookmarks':Store.fav.toList(),'skills':skills.toList(),'days':days.toList(),'badges':badges.toList(),'verifiedChallenges':verifiedChallenges.toList(),'importedPacks':importedPacks,'quizScores':Store.quizScores,'wrongAnswers':Store.wrong});
      Clipboard.setData(ClipboardData(text:payload));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON copied to clipboard')));
    }, child: const Text('Copy backup JSON')),
    const SizedBox(height: 16),
    TextField(controller:backupInput, maxLines:8, decoration:const InputDecoration(labelText:'Paste backup JSON', border:OutlineInputBorder())),
    const SizedBox(height: 12),
    OutlinedButton(onPressed:restoreBackup, child:const Text('Import and merge backup')),
    if(backupMessage.isNotEmpty) Text(backupMessage),
    const Text('Backup includes completed labs, read notes, bookmarks, quiz scores, wrong answers, toolkit progress and imported packs. Other app preferences are not included.'),
  ]);
  Widget terminal() => Column(children: [
    ListTile(title: const Text('Safe virtual terminal'), subtitle: const Text('Commands are simulated and saved locally; no real shell or device files are accessed.'), trailing: IconButton(tooltip: 'Reset virtual filesystem', icon: const Icon(Icons.restart_alt), onPressed: confirmResetTerminal)),
    Expanded(child: Container(width: double.infinity, color: const Color(0xff121a17), padding: const EdgeInsets.all(12), child: ListView(children: [for (final line in log) SelectableText(line, style: const TextStyle(fontFamily: 'monospace', color: Color(0xffb9f6ca)))]))),
    Padding(padding: const EdgeInsets.all(10), child: Row(children: [IconButton(tooltip: 'Previous command', onPressed: commandHistory.isEmpty ? null : () => recallCommand(-1), icon: const Icon(Icons.keyboard_arrow_up)), IconButton(tooltip: 'Next command', onPressed: commandHistory.isEmpty ? null : () => recallCommand(1), icon: const Icon(Icons.keyboard_arrow_down)), Expanded(child: TextField(controller: command, decoration: const InputDecoration(labelText: 'Command', border: OutlineInputBorder()), onSubmitted: (_)=>execute())), const SizedBox(width: 8), FilledButton(onPressed: execute, child: const Text('Run'))])),
  ]);
  Widget roadmap() => ListView(padding: const EdgeInsets.all(12), children: [
    Text('${skills.length}/${offlineSkills.length} skills completed', style: Theme.of(context).textTheme.titleLarge),
    LinearProgressIndicator(value: skills.length/offlineSkills.length),
    for (final s in offlineSkills) CheckboxListTile(title: Text(s), value: skills.contains(s), onChanged: (v) {setState(() {if(v == true) {skills.add(s);} else {skills.remove(s);} save();});}),
    const Divider(),
    Text(tr('ရက် ၁၀၀ လေ့လာရေး စိန်ခေါ်မှု','100 Days Challenge'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
    Text('${days.length} days marked completed. Complete one lesson, lab or quiz each day.'),
    Wrap(spacing: 4, runSpacing: 4, children: [for (int i=1; i<=100; i++) FilterChip(label: Text('$i'), selected: days.contains(i), onSelected: (v) {setState(() {if(v){days.add(i);}else{days.remove(i);} save();});})]),
  ]);
  Widget incidentPage() => ListView(padding: const EdgeInsets.all(16), children: [
    DropdownButtonFormField<int>(value: incident, decoration: InputDecoration(labelText: tr('ပြဿနာအခြေအနေ','Incident scenario')), items: [for (int i=0;i<incidents.length;i++) DropdownMenuItem(value:i,child: Text(incidents[i][0]))], onChanged: (v)=>setState(() {incident=v ?? 0; reveal=false;})),
    const SizedBox(height: 18), Text(incidents[incident][1], style: Theme.of(context).textTheme.titleMedium),
    const SizedBox(height: 12), Text(tr('ပြဿနာကို ရှာဖွေပြီး စစ်ဆေးရန် Command များကို စဉ်းစားပါ။','Task: Identify the problem and propose diagnostic commands.')),
    const SizedBox(height: 16), OutlinedButton(onPressed: ()=>setState(()=>reveal=!reveal), child: Text(reveal ? tr('အရိပ်အမြွက် ဖျောက်ရန်','Hide hints') : tr('အရိပ်အမြွက်နှင့် နမူနာ Command ကြည့်ရန်','Reveal hints & example commands'))),
    if (reveal) ...[Text('First check: ${incidents[incident][2]}'), const SizedBox(height: 8), Text(incidents[incident][3]), const SizedBox(height: 8), SelectableText(incidents[incident][4])],
    const SizedBox(height: 12), FilledButton(onPressed: () {setState(() {badges.add('Incident ${incident+1}');save();});}, child: Text(tr('လေ့ကျင့်ပြီးကြောင်း မှတ်သားရန်','Mark scenario practiced'))),
  ]);
  Widget editorPage() => ListView(padding: const EdgeInsets.all(12), children: [
    Text(tr('Offline Code Editor — Bash, YAML, Terraform HCL (အခြေခံစစ်ဆေးမှုသာ)','Local scratchpad: Bash, YAML, Terraform HCL (basic checks only).')),
    DropdownButton<String>(
      value: editorLanguage,
      isExpanded: true,
      items: const ['Bash', 'YAML', 'Terraform HCL']
          .map((name) => DropdownMenuItem<String>(value: name, child: Text(name))).toList(),
      onChanged: (language) {
        if (language == null) return;
        setState(() { editorLanguage = language; validation = ''; });
        Store.p.setString('offline_editor_language_v1', language);
      },
    ),
    TextField(controller: editor, maxLines: 16, minLines: 10, maxLength: maxEditorChars,
      style: const TextStyle(fontFamily:'monospace'),
      decoration: const InputDecoration(border: OutlineInputBorder(),
        helperText: 'Saved locally on this device; no code is executed.')),
    const SizedBox(height: 8), Wrap(spacing: 8, children: [FilledButton(onPressed: validate, child: Text(tr('Syntax အခြေခံ စစ်ဆေးရန်','Check syntax basics'))), OutlinedButton(onPressed: ()=>Clipboard.setData(ClipboardData(text: editor.text)), child: Text(tr('Code ကူးရန်','Copy code'))), OutlinedButton(onPressed: resetEditorDraft, child: Text(tr('Editor ပြန်စရန်','Reset editor')))]),
    if(validation.isNotEmpty) SelectableText(validation),
  ]);
  Widget topology() => ListView(padding: const EdgeInsets.all(16), children: [
    Text(tr('Offline Infrastructure ပုံစံ','Offline infrastructure topology'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    Text(tr('အစိတ်အပိုင်းတစ်ခုချင်းစီ၏ လုပ်ဆောင်ချက်ကို လေ့လာပါ။ Cluster အစစ် မဟုတ်ပါ။','Tap each component to learn its role. This is a diagram, not a running cluster.')),
    const SizedBox(height: 18),
    for (final item in <List<String>>[['Client','Browser / CLI user'],['Router & Firewall','Routes and filters traffic'],['Load Balancer','Distributes requests'],['Web Service','Runs application code'],['Database','Stores persistent data'],['Observability','Metrics, logs and alerts']]) ...[
      Card(child: ListTile(leading: const Icon(Icons.dns_outlined), title: Text(item[0]), subtitle: Text(item[1]))),
      const Center(child: Icon(Icons.arrow_downward)),
    ],
  ]);
  // Creates a self-reported course progress certificate locally, without any API.
  // The platform print/share dialog can save the PDF on Android or desktop.
  Future<void> printCertificate() async {
    final total = Store.allNotes().where(Store.isLab).length;
    final completed = Store.completedLabs.length;
    final document = pw.Document();
    final issued = DateTime.now();
    final date = '${issued.year}-${issued.month.toString().padLeft(2, '0')}-${issued.day.toString().padLeft(2, '0')}';
    document.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(42),
      build: (context) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('LINUX NOTES', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 24),
          pw.Text('Personal Learning Progress Certificate', style: pw.TextStyle(fontSize: 25, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 20),
          pw.Text('Self-reported offline learning record', style: const pw.TextStyle(fontSize: 13)),
          pw.SizedBox(height: 32),
          pw.Text('$completed of $total labs marked completed', style: const pw.TextStyle(fontSize: 17)),
          pw.SizedBox(height: 8),
          pw.Text('${verifiedChallenges.length} simulator challenges verified', style: const pw.TextStyle(fontSize: 14)),
          pw.Text('${skills.length} roadmap skills marked completed', style: const pw.TextStyle(fontSize: 14)),
          pw.Text('${days.length} study days recorded', style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 32),
          pw.Text('Issued locally on $date', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 24),
          pw.Text('Not an accredited certification. Completion of content labs is self-reported; simulator verification is limited.', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    ));
    try {
      await Printing.layoutPdf(onLayout: (_) async => document.save(), name: 'linux_notes_progress_$date.pdf');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open PDF print/share: $error')));
    }
  }

  Widget achievements() {
    final labs = Store.allNotes().where(Store.isLab).length;
    final completed = Store.completedLabs.length;
    final earned = <String>[if(completed>=1) 'First lab', if(completed>=25) '25 labs', if(completed>=100) '100 labs', if(skills.length==offlineSkills.length) 'Roadmap master', ...badges];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(tr('Offline အောင်မြင်မှုမှတ်တမ်း','Local achievements'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text('$completed/$labs labs marked completed'),
      if(earned.isEmpty) const Text('Complete a lab or incident scenario to earn your first badge.'),
      for(final b in earned.toSet()) ListTile(leading: const Icon(Icons.emoji_events_outlined), title: Text(b)),
      const Divider(),
      Text(tr('တိုးတက်မှုမှတ်တမ်း ထုတ်ယူရန်','Progress export (manual backup)')),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: printCertificate, icon: const Icon(Icons.picture_as_pdf_outlined), label: Text(tr('Progress Certificate PDF ထုတ်ရန်','Print / save progress certificate PDF'))),
      Text(tr('ဤ Certificate သည် ကိုယ်ပိုင်လေ့လာမှုမှတ်တမ်းသာဖြစ်ပြီး တရားဝင် အသိအမှတ်ပြုလက်မှတ် မဟုတ်ပါ။','Certificate records personal progress only; it is not an accredited qualification.')),
      FilledButton(onPressed: () {
        final payload = jsonEncode({'version':1,'completedLabs':Store.completedLabs.toList(),'read':Store.read.toList(),'bookmarks':Store.fav.toList(),'skills':skills.toList(),'days':days.toList(),'badges':badges.toList()});
        Clipboard.setData(ClipboardData(text:payload));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Progress JSON copied to clipboard. Keep it private.')));
      }, child: Text(tr('Progress Backup JSON ကူးရန်','Copy progress backup JSON'))),
      Text(tr('Notes နှင့် Labs များကို App ထဲမှာ တစ်ပါတည်း ထည့်ထားသည်။ Account နှင့် Cloud Sync မလိုပါ။','Offline notes and labs are already bundled with the app. No account or cloud sync.')),
    ]);
  }
  Widget searchPage() {
    final found = Store.allNotes().where((n) => search.isNotEmpty && '${n['title']} ${n['cat']} ${n['body'] ?? ''}'.toLowerCase().contains(search.toLowerCase())).take(80).toList();
    return Column(children: [Padding(padding: const EdgeInsets.all(12),child: TextField(decoration: InputDecoration(prefixIcon:const Icon(Icons.search),labelText:tr('Notes နှင့် Labs ရှာရန်','Search bundled notes & labs')),onChanged:(v)=>setState(()=>search=v))), Expanded(child: ListView(children:[for(final n in found) ListTile(title:Text('${n['title']}'),subtitle:Text('${n['cat']}'),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>Detail(note:n))))]))]);
  }
  @override Widget build(BuildContext context) {
    final pages = <Widget>[terminal(),challengePage(),infrastructureSimulator(),roadmap(),incidentPage(),editorPage(),topology(),achievements(),searchPage(),packsPage(),backupPage()];
    final labels = useBurmese ? ['Terminal','Lab စစ်ဆေး','Infra Sim','လမ်းပြမြေပုံ','ပြဿနာများ','Editor','Topology','ဆုတံဆိပ်','ရှာဖွေ','Lab Packs','Backup'] : ['Terminal','Verify Labs','Infra Sim','Roadmap','Incidents','Editor','Topology','Badges','Search','Lab Packs','Backup'];
    return Scaffold(appBar: AppBar(title: Text(tr('အော့ဖ်လိုင်း လေ့ကျင့်ရေး','Offline Learning Toolkit')),actions:[
      TextButton(onPressed:()=>setState(() {useBurmese=!useBurmese;save();}),child:Text(useBurmese?'EN':'မြန်မာ',style:const TextStyle(fontWeight:FontWeight.bold))),
    ]),
      body: Column(children: [
        SizedBox(height: 54, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), children: [
          for (int i=0; i<labels.length; i++) Padding(padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6), child: ChoiceChip(label: Text(labels[i]), selected: tab==i, onSelected: (_)=>setState(()=>tab=i))),
        ])),
        Expanded(child: pages[tab]),
      ]));
  }
  @override void dispose() {command.dispose();editor.dispose();backupInput.dispose();infraCommand.dispose();packInput.dispose();super.dispose();}
}
