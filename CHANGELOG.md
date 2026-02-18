# Changelog

## v1.1.1 - Widget Unlimited List + Journal + Black Theme

- Reworked both Android widgets to use collection list rendering (scrollable, no fixed 5-row cap).
- Removed widget edit/delete row actions and kept checkbox toggle as the primary row action.
- Updated widget completed-task behavior to keep strike-through for same-day completions.
- Added expanded native quick-add popup with task, due date, kind, and priority controls.
- Added support for routing to advanced add flow from widget popup.
- Improved widget sync performance by throttling rapid refresh calls and increasing snapshot limits.
- Added `completedAt` to `TaskItem` for day-based completed visibility logic.
- Upgraded Daily Notes to support:
  - audio recording/playback
  - image + audio persistence
  - reverse-chronological history list
- Restored Journal tab in app navigation.
- Updated dark theme to pure black app surfaces and darker widget palettes.
- Bumped version to `1.1.1+4`.

## v1.2 - ToDo + Day Plan Split, Dual Widgets, and Migration

- Added `TaskKind` (`todo` / `dayPlan`) with backward-compatible Hive migration.
- Added separate app tabs: `ToDo`, `Day Plan`, `Calendar`, `Settings`.
- Added one-time v1.2 migration wizard with options:
  - Move all tasks to ToDo
  - Auto-split by due date
  - Skip for now
- Merged Daily Notes data into Day Plan items during migration.
- Added full edit flow from widget (opens full Add/Edit task screen).
- Added second Android widget for Day Plan (`DayPlanWidgetProvider`).
- Updated ToDo widget and Day Plan widget to support:
  - Toggle complete
  - Edit
  - Delete
  - Quick add (`+`)
  - Open app target routing
- Improved widget sync payloads:
  - `todo_task_count` / `todo_tasks_json`
  - `dayplan_task_count` / `dayplan_tasks_json`
  - `widget_is_dark`
- Improved reliability of checkbox persistence via repository upsert flow.
- Bumped version to `1.2.0+4`.

## v1.1.1 - Widget Behavior, Theme, Quick Edit/Add, and Settings Control

- Reworked widget rendering with launcher-safe dual layouts (`light` and `dark`).
- Widget theme now follows app theme setting via `widget_is_dark` snapshot state.
- Fixed widget interactivity reliability with explicit PendingIntents for:
  - Toggle complete
  - Edit title
  - Delete task
- Added quick title editing flow from widget tap.
- Added top-right `+` quick add popup flow for fast task creation from widget.
- Added settings switch to control widget scope:
  - `ON`: all unfinished tasks
  - `OFF`: today-only tasks
- Improved widget UI spacing, row styling, and readability.
- Added home_widget background receiver/service wiring for stable action handling.

## v1.1 - Widget Fix & Launch Experience Update

- Fixed Android widget task display reliability.
- Added structured widget snapshot sync (`today_tasks_json`, `today_task_count`).
- Added widget task actions:
  - Complete task
  - Edit task (opens app edit screen directly)
  - Delete task
- Added widget empty state: `No tasks for today`.
- Added bottom-right `Open App` button.
- Improved widget layout for resize and half-width use.
- Added splash branding improvements:
  - Theme-based launch backgrounds
  - Light/dark splash logos
  - In-app splash gate with theme-based logo
- Updated app version to `1.1.0+2`.
- Updated README with v1.1 docs and screenshot checklist.

## v1.0

- Initial offline release of My-Do.
- Task CRUD with local Hive database.
- Image and voice attachments in tasks.
- Daily notes and calendar task view.
- Theme toggle and initial Android widget integration.
