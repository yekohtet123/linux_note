# Terminal capacity alignment checkpoint (not final)

- Restore accepts up to 1,500 active filesystem nodes (same as runtime), instead of rejecting valid states over 400 nodes in one category.
- Removed-path tombstones retain only the 400 most recent unique paths; avoids unlimited accumulation after repeated deletion.
- The serialized state still has a 150,000-character cap. Larger states are not persisted, and Flutter runtime behavior has not been verified here.
