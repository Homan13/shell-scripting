# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal collection of standalone, unrelated utility scripts — not an
application. There is no build system, no test suite, no linter config, and no
dependency manifest. Each file is self-contained and shipped by copying it to a
target machine and running it.

Because the scripts are destructive to the host they run on (they install
packages, rewrite Apache config, reset the MariaDB root password, and `rm -rf`
themselves at the end), **do not execute `drupal.sh` or `wordpress.sh` to test a
change.** Validate by reading, and with `bash -n` / `shellcheck`.

## Commands

```bash
bash -n drupal.sh wordpress.sh      # syntax check — the only safe local validation
shellcheck drupal.sh wordpress.sh   # not installed by default; see TODO.md
python3 -m py_compile participant-report.py

# participant-report.py deps are not installed system-wide — use a venv
python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt

python3 participant-report.py <results.pdf> <export.csv> <template.xlsx> <output.xlsx> \
  [--sheet-name NAME] [--sheet-password PASS]
```

The shell scripts are intended to run as root on a freshly launched AWS EC2
instance. They prompt interactively for web directory, DB name, DB user, DB
password, and MariaDB root password.

## Architecture

### `drupal.sh` / `wordpress.sh` — parallel structure, must stay in sync

These two are near-identical by design and follow the same five-stage skeleton:

1. Interactive `read` prompts for the five variables
2. Platform detection, then a four-way `if/elif` branch
3. A shared MariaDB hardening heredoc + `/root/.my.cnf` creation
4. Application download, extract, `chown`, SELinux context (RHEL only)
5. Self-deletion and tarball cleanup

**A fix to one almost always belongs in the other.** They diverge today only in
the PHP extension sets (WordPress uses `php-mysqli`, Drupal uses `php-mysqlnd`
plus `php-dom`/`php-simplexml`/`php-opcache`), the application download step, and
the `AllowOverride` sed (Drupal's Ubuntu branch scopes the sed to the
`<Directory /var/www/>` block and runs `a2enmod rewrite`; WordPress's does not).
Any other divergence is likely a bug — several are already catalogued in
`TODO.md`.

### Platform detection — the quoting is load-bearing

```bash
platform=$(cat /etc/*release | grep -w ^NAME | sed 's/NAME=//')
version=$(cat /etc/*release | grep -w ^VERSION | sed 's/VERSION=//')
```

The `sed` strips only the key, **not** the surrounding double quotes, so every
comparison must keep the literal quotes inside the single-quoted string:

```bash
if [[ $platform == '"Amazon Linux"' ]] && [[ $version == '"2"' ]]; then
```

Dropping the inner quotes silently sends every platform to the `else` branch.
Supported branches are Amazon Linux 2, Amazon Linux 2023, RHEL 9, and Ubuntu
22.04 — in that order, with AL2 and AL2023 distinguished by `$version`. RHEL and
Ubuntu match on `$platform` alone, so point releases are not checked.

Later stages re-test `$platform` to pick the Apache user (`apache` on Amazon
Linux and RHEL, `www-data` on Ubuntu) and the service name (`httpd` vs
`apache2`). New platform support means touching all of those sites, not just the
install branch.

### `participant-report.py`

Unrelated to the LAMP scripts. Takes **two** Orbits exports and merges them into
an SCCA participation report `.xlsx`:

```
participant-report.py <results.pdf> <export.csv> <template.xlsx> <output.xlsx>
```

- the **PDF** supplies finishing order, car number, driver name, class
- the **CSV** supplies member ID, vehicle make/model, and the canonical
  first/last name split

**The two are joined on driver name, not car number.** Numbers disagree between
the exports (the PDF had Matthew Peck as No. 13 where the CSV said 70) and
collide within the CSV, so number is unusable as a key. Names are matched
through `normalize_name()`, which folds case and whitespace — the PDF writes
"Joseph Desantis" where the CSV writes "Joseph DeSantis".

Two parsing details are load-bearing and easy to regress:

- **Class is matched as a suffix against the CSV's class vocabulary**, longest
  first (`split_name_and_class`). It cannot be a fixed token count: classes run
  from "Max 2" to "Club Spec Mustang". The earlier fixed-2-token slice split
  that into name="Michael Bard Club", class="Spec Mustang".
- **First/last name comes from the CSV, never from splitting the PDF name.**
  Surnames like "Avendano Diaz" and "Caberol Prat" defeat any whitespace split.

Derived rather than read: a driver entering two cars appears twice in the PDF, so
entries are collapsed to their best finish, `POS` is renumbered contiguously from
1, and `PIC` is computed as rank within class in finishing order.

Writes only the columns the sanctioning body marks required (bold headers):
`A`/`B` name, `C` member ID, `D` POS, `E` PIC, `P` make-model, `W` class.
Passing Rules (`U`) and Satisfactory (`V`) are also required but exist in neither
input, so they are deliberately left blank — the script logs a reminder.

Sheet layout is discovered, not hardcoded: data starts at row 2, and the legend
block below it is located by its "Bold-headed columns are required" marker, with
rows inserted above it so it is never overwritten. Only the sheet *name*
(`DEFAULT_SHEET_NAME`) is a constant, and it changes with each season's template
— override with `--sheet-name`.

## Known issues

`TODO.md` tracks reviewed-but-unfixed bugs with file:line references, plus three
open design questions (Drupal 10 vs 11, whether `drupal.sh` should honor its
`web_dir` prompt, and whether to keep Amazon Linux 2 past EOL). Check it before
starting work — and when fixing something listed there, tick the box in the same
change.

## README

`README.md` is written for end users and states specific version numbers
(WordPress 6.4.x, Drupal 10.2.x, PHP 8.2.x, MariaDB 10.11/10.5). The scripts
actually download "latest", so these claims drift. Update the README alongside
any version-affecting change.
