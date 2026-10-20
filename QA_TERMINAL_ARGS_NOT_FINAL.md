# Terminal argument-safety checkpoint (not final)

- Reject unsupported flags rather than silently discarding them.
- Reject extra operands for commands that only simulate one path.
- Protect the virtual current working directory and its ancestors from `rmdir`.
- Account for trailing newline and overwrite semantics in `echo` size limit.
- Check filesystem entry limit when `echo` creates a new file.
- Static contract checks only; Flutter runtime unverified.
