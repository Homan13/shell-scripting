# Script Review — Open Tasks

Notes from a code review on 2026-10-05, covering `drupal.sh`, `wordpress.sh`,
`participant-report.py` and `README.md`. Nothing here has been changed yet.

## Open Questions

These affect how several tasks below get resolved, so worth deciding first.

- [ ] **Drupal version direction** — pin the download to Drupal 10.x (matching the
  README), or bump PHP to 8.3+/8.4 and move to Drupal 11?
- [ ] **`web_dir` in `drupal.sh`** — honor the prompt everywhere, or drop the prompt
  and document `/var/www/html` as a fixed path?
- [ ] **Amazon Linux 2** — keep supporting it past its June 2025 end of standard
  support, or retire that branch?

## Bugs

### `drupal.sh` prompts for `web_dir` and never uses it

Lines 9–10 collect the value, but the install hardcodes `/var/www/html`
(`drupal.sh:92`, `:151`, `:153`, `:155`, `:158`). Anyone answering anything else
gets a silently wrong install. `wordpress.sh` does honor the variable, so the two
scripts behave differently from identical prompts.

- [ ] Resolve per the open question above, and make both scripts consistent.

### `drupal.sh` uses `wget` and `rsync` without installing them

Only the RHEL branch installs `wget` (`drupal.sh:70`); the AL2, AL2023 and Ubuntu
branches don't. Nothing installs `rsync` on any branch. Both are used at
`drupal.sh:147` and `:151`. On minimal AL2023 and Ubuntu cloud images this fails
*after* the database has already been created, leaving a half-built system.

- [ ] Add `wget` and `rsync` to the package list in every branch (or switch to
  `curl` + `cp -a`, which are already present).

### `wordpress.sh:147` — `else` with a stray test

```bash
else [[ $platform == '"Ubuntu"' ]]
```

This is an `else` followed by a no-op test command, not an `elif`. The exit status
is discarded, so any platform that isn't Amazon Linux or RHEL silently gets
`www-data` ownership.

- [ ] Change to `elif [[ $platform == '"Ubuntu"' ]]; then` and add a real `else`
  branch that errors out.

### `wordpress.sh` "already downloaded" guard skips too much

`wordpress.sh:139` — if `/tmp/latest.tar.gz` exists, the script skips both the
extraction and the `chown`, then proceeds to `mv $web_dir/wp-config-sample.php`
at `:155` against a directory that was never populated. Re-running after a partial
failure breaks instead of resuming.

- [ ] Guard on the extracted result (e.g. presence of `wp-config-sample.php` or
  `wp-settings.php` in `$web_dir`) rather than on the tarball, and keep the
  `chown` outside the conditional.

### Version drift between README and what actually installs

Both scripts download "latest" (`wordpress.sh:143`, `drupal.sh:147`), so today
that's WordPress 6.8-ish and Drupal 11 — but the README claims 6.4.x and 10.2.x.

The Drupal case is a hard break: Drupal 11 requires PHP 8.3+, and every branch
pins PHP 8.2. The current script likely produces a Drupal that won't install.

- [ ] Fix per the Drupal version decision above.
- [ ] Update the README version claims, or state "latest" explicitly if that's the
  intent.

### Amazon Linux 2 is past end of standard support (June 2025)

The AL2 branches still work for now — `amazon-linux-extras`, the MariaDB rhel7
repo — but this will rot.

- [ ] Decide per the open question above; if keeping, add a note in the README
  that AL2 is community/legacy support only.

## Hardening

- [ ] Add `set -euo pipefail` to both scripts. Today a typo'd package name or a
  failed `yum` just keeps going, and the failure surfaces much later as a
  confusing symptom.
- [ ] Add a root/EUID check at the top of both scripts.
- [ ] Quote `$web_dir` everywhere, and validate that the directory exists before
  writing into it.
- [ ] `read -sp` doesn't emit a newline, so password prompts run into the
  following prompt text on screen. Add `echo` after each.
- [ ] `/root/.my.cnf` is created `chmod 640` (`wordpress.sh:132`, `drupal.sh:132`).
  `600` is conventional for a file holding the DB root password.
- [ ] The DB user password is passed on the `mysql -e` command line
  (`wordpress.sh:182`, `drupal.sh:140`), making it visible in `ps` to any local
  user while the script runs. Minor on a single-tenant learning box, but the
  heredoc style already used at `:116` avoids it.
- [ ] The WordPress salt-injection block (`wordpress.sh:177-180`) is fragile —
  `grep -A50 'table_prefix'` and `sed '/**#@/,/$p/d'` depend on the exact upstream
  `wp-config-sample.php` layout and line count. Consider fetching salts into a
  temp file and splicing on an anchored marker instead.
- [ ] `drupal.sh` never writes `settings.php` or sets `trusted_host_patterns`, so
  the install still needs manual browser setup. Probably intentional — if so, note
  it in the README the way the WordPress flow is described.

## `participant-report.py`

- [x] ~~`rsplit(' ', 1)` name splitting mangles multi-word surnames~~ — resolved
  2026-10-05. The script now takes the authoritative first/last split from the
  CSV export's own columns, which fixes "Avendano Diaz" and "Caberol Prat".
- [x] ~~Add a `#!/usr/bin/env python3` shebang.~~
- [x] ~~Track the remaining ~25% of fields once Orbits report changes land.~~ —
  resolved 2026-10-05 by joining the CSV export to the PDF. See below for what
  is still manual.
- [x] ~~Add a `requirements.txt` pinning `openpyxl` and `pdfplumber`.~~ — added
  2026-10-05. Neither is installed system-wide, so the script needs a venv.
- [ ] **Passing Rules (U) and Satisfactory (V) are still manual.** Both are
  required columns, but neither value exists in the PDF or the CSV. In past
  reports they were constant (`2` and `Yes`) for every row. If that holds, add
  `--passing-rules` / `--satisfactory` flags rather than typing them in Excel.
- [ ] Make-Model (P) is written without a model year. Past reports included one
  ("2000 Mazda Miata"); the MSR export has no year field. Either accept the
  shorter form or ask for a year column in the export.
- [ ] Member ID is missing from the CSV for some drivers (2 of 32 in the
  2026 Weekend 8 data). The script warns and leaves the cell blank. Worth
  chasing why the Orbits export drops them.
- [ ] Driver dedupe keeps the best finish when someone enters two cars, then
  renumbers POS contiguously. Confirm this is what the sanctioning body wants
  before relying on it for a season.

## Repo housekeeping

- [ ] All four files are mode `644`, but the README tells people to make the
  scripts executable. Either `chmod +x` the two `.sh` files and commit the mode,
  or reword that line.
- [ ] README line 30: "Phython" → "Python".
- [ ] README has placeholder sections: Contributing, Versioning, License — all
  still "Coming Soon". Add a LICENSE file at minimum.
- [ ] Consider running `shellcheck` over both scripts (not currently installed
  here) and wiring it into a pre-commit hook or CI.
