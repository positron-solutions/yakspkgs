;;; elisp-repo-kit.el --- Github elisp repository with bells & whistles  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Positron Solutions

;; Author: Psionik K <73710933+psionic-k@users.noreply.github.com>
;; Keywords: package dependencies
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1"))
;; Homepage: http://github.com/positron-solutions/yakspkgs

;; Permission is hereby granted, free of charge, to any person obtaining a copy of
;; this software and associated documentation files (the "Software"), to deal in
;; the Software without restriction, including without limitation the rights to
;; use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
;; the Software, and to permit persons to whom the Software is furnished to do so,
;; subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
;; FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
;; COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
;; IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:

;; This package manages a Nix or Guix profile from within Emacs.  3rd party
;; dependencies of packages and user defined packages can be installed into this
;; profile and will be available to Emacs.

;;; Code:

(defgroup yakspkgs nil "Yakspkgs Nix & Guix package management.")

(defcustom yakspkgs-nix-profile-dir
  (if (featurep 'no-littering)
      (no-littering-expand-var-file-name "yakspkgs/nix-profile")
    (expand-file-name "yakspkgs/nix-profile" user-emacs-directory))
  "Where the profile manifest and profile links live."
  :group 'yakspkgs
  :type 'directory)

;; not supported yet
(defcustom yakspkgs-package-manager 'nix
  "Which package manager is in use for commands now."
  :group 'yakspks
  :type 'symbol
  :options '(nix guix))

;; not supported yet
(defcustom yakspkgs-nix-extra-args nil
  "Extra arguments to pass to to every nix program."
  :group 'yakspkgs
  :type '(repeat string))

(defcustom yakspkgs-nix-output-buffer-name " *yakspkgs-nix*"
  "Buffer for checking output of nix processes."
  :group 'yakspkgs
  :type 'string)

(defconst yakspkgs--nix-empty-profile
  (expand-file-name "profile-contents/#profile-contents"
                    (file-name-directory load-file-name))
  "This path will be used to intialize the profile.")

(defconst yakspkgs--min-nix-version "2.8.0"
  "The API since 2.8.0 contains most recent changes.")

(defun yakspkgs-installed-packages ()
  "Return a list of installed packages."
  (let* ((pkgsraw (shell-command-to-string
                   (format "nix profile list --profile %s" yakspkgs-nix-profile-dir))))
    (->> (string-lines (string-chop-newline pkgsraw))
         (--map
          (let* ((parts (split-string it))
                 (index (elt parts 0))
                 (flake-path (elt parts 1)))
            (cons flake-path index))))))

;;;###autoload
(defun yakspkgs-install (path)
  "Install PATH into profile using the package manager."
  (interactive)
  (start-process "nix profile install" yakspkgs-nix-output-buffer-name
                 "nix" "profile" "install"
                 path
                 "--profile" yakspkgs-nix-profile-dir))

;;;###autoload
(defun yakspkgs-initialize ()
  "Set up a profile and verify package manager sanity."
  (interactive)
  (make-directory yakspkgs-nix-profile-dir t)
  (let* ((raw-version-string (shell-command-to-string "nix --version"))
         (version-string (when (string-match "nix (Nix) \\([0-9.]+\\)"
                                             raw-version-string)
                           (match-string 1 raw-version-string))))
    (when (string-version-lessp version-string yakspkgs--min-nix-version)
      (delay-warning 'yakspkgs
                     "Your version of Nix is a bit behind.  Please update.")))
  (when (shell-command "nix-build --expr '{}'" (get-buffer-create
                                                yakspkgs-nix-output-buffer-name))
    (delay-warning 'yakspkgs "The nix build command returned an error."))
  (yakspkgs-install yakspkgs--nix-empty-profile)
  (let ((profile-path (expand-file-name yakspkgs-nix-profile-dir "bin")))
    (unless (string-match-p (regexp-quote profile-path) (getenv "PATH"))
      (setenv "PATH" (concat profile-path ":" (getenv "PATH")))))
  (when delayed-warnings-list
    (pop-to-buffer yakspkgs-nix-output-buffer-name)))

;;;###autoload
(defun yakspkgs-uninstall ()
  "Remove PATH from profile using the package manager."
  (interactive)
  (message "Not done yet.")
  ;; list packages
  ;; do a completion
  ;; call an uninstall command on selected result
  )

(provide 'yakspkgs)
;;; yakspkgs.el ends here.
