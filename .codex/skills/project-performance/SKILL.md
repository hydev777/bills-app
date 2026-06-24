---
name: project-performance
description: Performance engineering guidance for this local Flutter billing app. Use when Codex designs, reviews, or implements changes that may affect Flutter rendering, Bloc/Cubit rebuilds, local Shelf API latency, Dio usage, SQLite query speed, startup time, memory use, large lists, charts, reports, or responsiveness.
---

# Project Performance

Use this skill together with `flutter-master` for performance-sensitive work in this app.

## Workflow

1. Identify the hot path before changing code: UI build, Bloc state flow, Dio/local API, SQLite query, or startup.
2. Prefer scoped fixes over broad refactors. Preserve the feature-first structure and existing `Result<T, Failure>` error flow.
3. Measure or inspect the likely bottleneck before optimizing. For UI, look for unnecessary rebuilds and eager widgets. For local API, inspect query shape and payload size.
4. Keep app behavior local-only. Do not add remote services, background servers, or network dependencies for performance.
5. Verify with `flutter analyze`, `flutter test`, and targeted smoke checks. If Flutter tooling hangs under sandbox, retry with approval and report the exact result.

## Flutter UI

- Use `const` widgets and immutable inputs where possible.
- Split large build methods into small `StatelessWidget` classes, not helper functions that return widgets.
- Use `ListView.builder`, `SliverList`, or paged lists for growing data. Avoid mapping large lists into widgets eagerly.
- Use stable dimensions for chart panels, KPI tiles, list rows, and toolbar controls to avoid layout shifts.
- Use `BlocSelector`, `buildWhen`, or `listenWhen` when only part of state should rebuild.
- Keep BLoC state payloads lean; avoid storing derived UI-only collections when they can be computed once in the repository/API response.
- Do not put heavy parsing, grouping, or aggregation in `build`.

## Local API And Data

- Prefer server-side aggregation for reports and summaries instead of fetching every row into Flutter.
- Keep API responses bounded: use pagination or explicit caps for lists embedded in reports.
- Avoid replaying mutating requests after local API restart attempts.
- Parse JSON once at the datasource/model boundary; domain entities should stay simple and immutable.
- Keep Dio interceptors small and async-safe. Do not do expensive work in every request interceptor.

## SQLite Performance

- Add indexes for new filters, joins, sort keys, and date ranges.
- Verify query predicates can use indexes; avoid wrapping indexed columns in functions for large-table filters unless the data size is intentionally small or an expression/index strategy is chosen.
- Use `COUNT`, `SUM`, `GROUP BY`, and bounded `LIMIT` queries for dashboards/reports.
- Run related writes inside the existing `LocalDatabase.transaction`.
- Keep read queries synchronous and short inside `database.read`; do not perform Dart-side long loops when SQL can aggregate.

## Review Checklist

- No expensive work in widget `build`.
- Large lists are lazy or capped.
- BLoC rebuilds are scoped.
- SQLite queries have clear filters and needed indexes.
- API payloads are bounded.
- Startup work is necessary and awaited intentionally.
- Tests or smoke checks cover the changed path.
