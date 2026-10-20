# Learning Features Edition

Built on the previous 600 Labs Fixed Edition. Preserves original assets/linux_notes.json and existing Flutter UI.

1. Lab Progress Tracking: Mark a lab complete from its Detail page. Local SharedPreferences storage key `completed_labs_v1`.
2. Difficulty Filter: Beginner / Intermediate / Advanced / All chips on the notes page. Existing labs without an explicit level display `Unrated` and appear only in All. Some 600 labs include levels in their titles.
3. Interactive Quiz: Curated MCQs for Linux, Docker, Kubernetes, Terraform, DevOps and Bash. Per-subject latest percentage saved locally. Quiz does not evaluate terminal commands.
4. Challenge Mode: Lab detail toggle hides commands until Reveal. It does not automatically verify external Linux environments.
5. Dashboard & Bookmarks: Progress overview, per-category completion, saved quiz results, bookmarks count, notes read count. Existing bookmark feature preserved.

To integrate into an existing project, copy lib/main.dart, lib/learning.dart, and (if needed) assets/linux_notes.json; preserve lib/extra.dart. Rebuild Android and Web.

Note: no Flutter SDK was available in the authoring environment, so compile/runtime tests must be done locally. Existing SharedPreferences fallback may use in-memory storage if the native plugin is broken, in which case saved progress may not persist.
