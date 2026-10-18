# Security

Do not post credentials, private captures, or exploit details in public issues. Use GitHub's private vulnerability reporting for this repository when available: the **Security → Report a vulnerability** button.

Include the affected version, macOS version, reproduction steps and potential impact. Please allow time for investigation before public disclosure. Do not include private screen content unless it is essential and the recipient has explicitly agreed to receive it.

Ordinary capture errors and feature requests belong in [GitHub Issues](https://github.com/xiaolongnk/XGlassShot/issues).

## Before publishing

- Keep signing keys, API-key JSON, environment files, provisioning profiles and release artifacts outside source. Ignore rules prevent accidental adds; they cannot remove files already in Git history.
- Scan the complete history and pull-request refs for credentials before making a repository public. Also review author email addresses, local paths, editor conversation memory, image pixels and embedded metadata; a credential scanner does not cover all personal information.
- Use a GitHub noreply email for commits when a personal address should stay private.
- Keep GitHub secret scanning, push protection and dependency alerts enabled. Resolve release-tooling alerts as well as app dependencies, using the committed Gemfile.lock with Ruby 3.3+ and Bundler 4.
- If a secret is exposed, revoke or rotate it first. Coordinate any history rewrite and GitHub pull-request/cache cleanup; deleting a file in a new commit does not retract earlier public copies.
