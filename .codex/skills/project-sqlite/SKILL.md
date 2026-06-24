---
name: project-sqlite
description: SQLite and embedded local API best practices for this local Flutter billing app. Use when Codex changes local schema, SQL queries, SQLite indexes, transactions, report aggregation, Shelf endpoints backed by SQLite, persistence behavior, date filtering, or data access patterns.
---

# Project SQLite

Use this skill for all SQLite-backed changes in `app/lib/core/local_api/**` and feature datasources/repositories that call the embedded local API.

## Project Rules

- Keep the app local-only: Flutter calls the embedded Shelf API through Dio; Shelf reads/writes SQLite through `LocalDatabase`.
- Keep schema in `local_database.dart`. This project starts from zero, so direct schema changes are acceptable unless the user asks for migration compatibility.
- Use `LocalDatabase.transaction` for multi-step writes and any write sequence that must stay consistent.
- Preserve `PRAGMA foreign_keys = ON`, WAL mode, and busy timeout behavior.
- Return JSON through `jsonResponse`; throw `HttpError` for expected API failures.

## Schema And Indexes

- Add foreign keys for relationships and choose `ON DELETE` behavior deliberately.
- Add indexes for columns used in `WHERE`, `JOIN`, `ORDER BY`, and report date ranges.
- Prefer uniqueness constraints for business invariants that must be race-safe.
- Keep timestamps as text compatible with SQLite `CURRENT_TIMESTAMP` unless changing all date handling consistently.
- When adding report/date queries, define whether boundaries use local time or UTC and keep API/UI labels consistent.

## Query Practices

- Use parameterized SQL only. Never interpolate user input into SQL.
- Use SQL aggregation for reports: `COUNT`, `SUM`, `GROUP BY`, `COALESCE`.
- Return complete empty buckets from report endpoints when the UI needs stable charts.
- Cap embedded lists in report responses and expose `hasMore` or equivalent metadata.
- For list endpoints, always support bounded `limit` and `offset`.
- Avoid N+1 queries; join related user/client/item data in one query when returning lists.

## Write Practices

- Validate referenced rows before insert/update when the error should be a clean 404/400.
- Use transactions for parent/child writes such as bills and bill details.
- Recalculate derived totals in the same transaction as line-item changes.
- Keep derived fields rounded consistently with `round2`.
- Prefer database constraints for invariants, then map constraint failures to user-friendly API errors when needed.

## Date And Reporting

- Be explicit about day boundaries. For local reports, filter/group with the same local-time policy throughout the endpoint.
- Use inclusive start and exclusive end boundaries: `created_at >= start AND created_at < endExclusive`.
- For week reports, use Monday as the first day unless the user chooses otherwise.
- For year reports, group by calendar month and keep all 12 buckets.

## Validation Checklist

- Auth and privilege checks happen before data access.
- SQL uses bound parameters.
- Queries have appropriate indexes.
- Transactions wrap related writes.
- API response shape is stable for empty and non-empty data.
- `flutter analyze` and `flutter test` are run after code changes.
