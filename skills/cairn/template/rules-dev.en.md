## Extra rules for code projects

- **The documents are the source of truth.** When the spec and the implementation disagree, the spec wins. If you find a defect in the spec while implementing, don't work around it in code — fix the document and record the problem first.
- Commit in work-sized units (one journal). Put `P-NNN` in the body of a fix commit. Push only when the user asks.
- Experiments and measurements run through a script so they stay reproducible. If you ran something by hand, paste the exact command into the journal.
- If the project touches external APIs, protocols or format conversion, **the golden set is the definition of "done"**: record real responses through a sanitizer into `fixtures/` → tests replay fixtures only (no network) → compare against snapshots. Build the capture harness alongside the converter, or before it.
- Keep build, test and run instructions in `wiki/howto/`.
