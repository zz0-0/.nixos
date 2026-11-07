# Emacs

> 对应：`home-manager/shared/programs/editor.nix`

`home-manager/shared/programs/editor.nix` installs vanilla Emacs 31 (pgtk)
with `envrc` and the built-in Eglot LSP client. `envrc-global-mode` loads the
nearest `.envrc` per buffer, so Eglot finds the language servers provided by
the devshell flake instead of requiring system-wide installs. No generated
Emacs files are needed: `envrc` reads the project `.envrc` directly.

Environment selection is per buffer: `envrc` walks up from the buffer's
`default-directory` to the nearest `.envrc`. Starting Emacs from a project
directory (or opening a file or directory there) loads that devshell
automatically. The initial `*scratch*` buffer uses the directory Emacs was
launched from; launched from the desktop it is usually `$HOME`, so the project
environment is loaded when you open a project file. The modeline shows
`envrc[on]`; run `direnv allow` once per project if it shows `denied`.

Language modes/servers wired up: Nix (`nixd`), Python
(`basedpyright-langserver`), Rust/Bevy (`rust-analyzer`), Dart/Flutter
(`dart language-server`), Java (`jdtls`), LaTeX (`texlab`), and Markdown
(`markdown-oxide`). TypeScript, YAML and TOML get modes only. Format-on-save
uses Apheleia (`nixfmt`, `ruff`, `rustfmt`, `dart format`, `latexindent`);
Java is formatted through Eglot/jdtls.

Eglot connects on the next command after the devshell environment finishes
loading; if it does not, `M-x eglot` starts it manually. PostgreSQL keeps the
built-in `sql-mode` (`M-x sql-postgres`); the video devshell has no TypeScript
language server, so `.ts` files get `typescript-mode` syntax only. The
devshell flake itself lives in `~/.devshell`; it supplies language toolchains,
not Emacs-specific files.

