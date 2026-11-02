{ pkgs, ... }:

{
  # pgtk = pure GTK, native Wayland (no XWayland) and still works in a terminal.
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;

    # Language modes + direnv integration. Eglot itself is built into Emacs 31.
    extraPackages = epkgs: [
      epkgs.doom-themes
      epkgs.envrc
      epkgs.nix-mode
      epkgs.dart-mode
      epkgs.rust-mode
      epkgs.markdown-mode
      epkgs.typescript-mode
      epkgs.yaml-mode
      epkgs.toml-mode
      epkgs.apheleia
    ];

    extraConfig = ''
      ;;; -*- lexical-binding: t; -*-
      ;; --- Theme ---------------------------------------------------------
      (require 'doom-themes)
      (load-theme 'doom-acario-dark t)

      ;; emacsWithPackages does not load package autoloads for us; require the
      ;; modes so their auto-mode-alist entries and hooks are active.
      (require 'nix-mode)
      (require 'dart-mode)
      (require 'rust-mode)
      (require 'markdown-mode)
      (require 'typescript-mode)
      (require 'yaml-mode)
      (require 'toml-mode)

      ;; --- direnv / Nix devshells ----------------------------------------
      ;; Each buffer gets the environment from the nearest .envrc.  This is
      ;; the Emacs equivalent of the .zed/lsp wrappers in the devshell flake:
      ;; language servers are found through the project's devshell PATH.
      (require 'envrc)
      (envrc-global-mode 1)

      ;; --- Eglot (built-in LSP client) -----------------------------------
      (require 'eglot)

      (defun my/jdtls-contact (_interactive)
        "Start jdtls with a per-project data directory under the cache."
        (let* ((project (project-current nil))
               (root (if project (project-root project) default-directory))
               (data (expand-file-name (secure-hash 'sha1 root)
                                       "~/.cache/eglot/jdtls/")))
          (list "jdtls" "-data" data)))

      (dolist (mode '(nix-mode nix-ts-mode))
        (add-to-list 'eglot-server-programs (cons mode '("nixd"))))
      (dolist (mode '(python-mode python-ts-mode))
        (add-to-list 'eglot-server-programs
                     (cons mode '("basedpyright-langserver" "--stdio"))))
      (dolist (mode '(rust-mode rust-ts-mode))
        (add-to-list 'eglot-server-programs (cons mode '("rust-analyzer"))))
      (dolist (mode '(dart-mode dart-ts-mode))
        (add-to-list 'eglot-server-programs
                     (cons mode '("dart" "language-server"))))
      (dolist (mode '(java-mode java-ts-mode))
        (add-to-list 'eglot-server-programs (cons mode 'my/jdtls-contact)))
      (dolist (mode '(latex-mode LaTeX-mode))
        (add-to-list 'eglot-server-programs (cons mode '("texlab"))))
      (dolist (mode '(markdown-mode markdown-ts-mode))
        (add-to-list 'eglot-server-programs (cons mode '("markdown-oxide"))))

      (defun my/eglot-server-for-mode ()
        (pcase major-mode
          ((or 'nix-mode 'nix-ts-mode) "nixd")
          ((or 'python-mode 'python-ts-mode) "basedpyright-langserver")
          ((or 'rust-mode 'rust-ts-mode) "rust-analyzer")
          ((or 'dart-mode 'dart-ts-mode) "dart")
          ((or 'java-mode 'java-ts-mode) "jdtls")
          ((or 'latex-mode 'LaTeX-mode) "texlab")
          ((or 'markdown-mode 'markdown-ts-mode) "markdown-oxide")
          (_ nil)))

      (defun my/eglot-ensure ()
        (when-let* ((server (my/eglot-server-for-mode))
                    ((executable-find server))
                    ((not (eglot-current-server))))
          (eglot-ensure)))

      ;; --- Format on save -------------------------------------------------
      (require 'apheleia)
      ;; nixfmt 1.5 deprecates bare stdin; pass "-" explicitly.
      (setf (alist-get 'nixfmt apheleia-formatters) '("nixfmt" "-"))
      ;; The devshells ship ruff, not black.
      (setf (alist-get 'python-mode apheleia-mode-alist) 'ruff)
      (setf (alist-get 'python-ts-mode apheleia-mode-alist) 'ruff)

      (defun my/apheleia-formatter ()
        (pcase major-mode
          ('nix-mode "nixfmt")
          ('rust-mode "rustfmt")
          ('python-mode "ruff")
          ('dart-mode "dart")
          ('latex-mode "latexindent")
          (_ nil)))

      (defun my/apheleia-ensure ()
        (when-let* ((exe (my/apheleia-formatter))
                    ((executable-find exe)))
          (apheleia-mode 1)))

      (defun my/eglot-format-on-save ()
        "Use the LSP formatter when Apheleia is not handling this buffer."
        (when (and (eglot-current-server)
                   (not (bound-and-true-p apheleia-mode)))
          (ignore-errors (eglot-format-buffer))))
      (add-hook 'before-save-hook #'my/eglot-format-on-save)

      ;; --- Start language support after direnv has applied the env --------
      (defun my/language-setup ()
        (my/eglot-ensure)
        (my/apheleia-ensure))

      (dolist (hook '(nix-mode-hook
                      python-mode-hook python-ts-mode-hook
                      rust-mode-hook rust-ts-mode-hook
                      dart-mode-hook
                      java-mode-hook java-ts-mode-hook
                      latex-mode-hook
                      markdown-mode-hook))
        (add-hook hook #'my/language-setup))

      ;; envrc loads direnv asynchronously.  Start Eglot only after the
      ;; devshell environment (and therefore the server executable) is set.
      (defun my/envrc-after-apply (buf &rest _)
        (when (buffer-live-p buf)
          (with-current-buffer buf
            (when (eq envrc--status 'on)
              (my/language-setup)))))
      (advice-add 'envrc--apply :after #'my/envrc-after-apply)

      ;; --- Small built-in quality-of-life ---------------------------------
      (which-key-mode 1)
      (completion-preview-mode 1)
      (savehist-mode 1)
      (recentf-mode 1)
      (save-place-mode 1)
      (global-auto-revert-mode 1)
      (show-paren-mode 1)
      (electric-pair-mode 1)
      (column-number-mode 1)
      (add-hook 'prog-mode-hook #'display-line-numbers-mode)
      (setq-default indent-tabs-mode nil)
      (setq custom-file (expand-file-name "custom.el" user-emacs-directory))
      (when (file-exists-p custom-file)
        (load custom-file))
    '';
  };

  # Headless daemon: every emacsclient frame shares the same buffers.
  services.emacs = {
    enable = true;
  };

  programs.zed-editor = {
    enable = true;
  };
}
