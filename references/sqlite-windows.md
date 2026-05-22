# SQLite On Windows

Use this when local tests, dev servers, or agents hit repeat SQLite lock loops on Windows.

## Symptoms

- `database is locked`
- `SQLITE_BUSY`
- `.wal` and `.shm` files remain after a crash
- test retries keep failing until the agent or editor is restarted

## Diagnosis

Run:

```powershell
.\scripts\check-sqlite-locks.ps1 -Database .\app.db
```

Check:

- Does the DB exist?
- Are `app.db-wal`, `app.db-shm`, or `app.db-journal` present?
- Is any likely process still running: app server, test watcher, node, python, sqlite tool, editor?
- What is `PRAGMA journal_mode`?

## Local Mitigation

WAL is usually good for concurrency, but Windows agent workflows can leave sidecar files and held handles after interrupted runs. For local test databases, `DELETE` journal mode can be a pragmatic mitigation:

```sql
PRAGMA journal_mode=DELETE;
```

Keep this scoped to local/dev/test configuration unless production has been evaluated separately.
