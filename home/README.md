# Home configuration

This directory is reserved for per-user configuration and dotfiles.

Candidate areas include:

- PowerShell profiles;
- Git configuration;
- Windows Terminal settings;
- Explorer preferences; and
- application-specific user settings.

No user setting is enforced yet. A setting should only be added after its desired value, merge behavior, and backup or recovery path are known. In particular, automation must not overwrite an existing profile or application configuration without an explicit migration strategy.

Machine-wide features, services, and registry state belong under `system/` instead.
