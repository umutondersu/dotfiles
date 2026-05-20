# Agent Instructions

## Library, Framework, and API Queries

For every query related to libraries, frameworks, or APIs, use the `context7` tool to fetch up-to-date documentation.

## When Unsure How to Implement Something

If you are unsure how to do something, use the `gh_grep` tool to search for real-world code examples from GitHub repositories.

## Running Commands That Require sudo

Never use `sudo` directly. Instead, use `pkexec` with `SHELL=/bin/bash` prefix. Example: `sudo pacman -Syu` must be run as `SHELL=/bin/bash pkexec pacman -Syu`.

## Mandatory Result Verification

You must actively verify your work before declaring a task complete. Do not assume your code or changes work perfectly on the first try.

**Examples:**

- **Web Apps:** Use `browsermcp` to visually inspect changes, check for console errors, and verify DOM updates.
- **Test Suites:** Execute existing unit tests. If no tests exist for your changes, you must write and run them.
- **Scripts:** Execute the scripts you generate (e.g., checking shell script exit codes or testing output) to prove they match expectations.
