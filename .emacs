;; emacs conf

(require 'package)
(require 'splash-screen)

(add-to-list 'exec-path "~/.cabal/bin/")

(let ((default-directory "~/.emacs.d/load/"))
	(normal-top-level-add-subdirs-to-load-path))

(defun set-exec-path-from-shell-PATH ()
  (let ((path-from-shell (replace-regexp-in-string
                          "[ \t\n]*$"
                          ""
                          (shell-command-to-string "$SHELL --login -i -c 'echo $PATH'"))))
    (setenv "PATH" path-from-shell)
    (setq eshell-path-env path-from-shell) ; for eshell users
    (setq exec-path (split-string path-from-shell path-separator))))

(when window-system (set-exec-path-from-shell-PATH))

(load-file (let ((coding-system-for-read 'utf-8))
                (shell-command-to-string "agda-mode locate")))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Packaging
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/"))
(add-to-list 'package-archives '("gnu-devel" . "https://elpa.gnu.org/devel/"))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; My Custom Stuff
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Custom keybinds
(defun center-to-top ()
  (interactive)
  (recenter-top-bottom 15))
(global-set-key (kbd "C-t") 'center-to-top) ; recenter screen but better!
(global-set-key (kbd "M-<down>") 'scroll-up-line)
(global-set-key (kbd "M-<up>") 'scroll-down-line) 
;; Allow Clipboard
(setq x-select-enable-clipboard t)
;; Disable menu bar
(menu-bar-mode -1)
;; Parentheses
(electric-pair-mode t)
(rainbow-delimiters-mode t)
;; No more ~ files
(setq make-backup-files nil)
;; Line numbers on the side
(global-display-line-numbers-mode 1)
;; Dired sidebar
(use-package dired-sidebar
  :bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
  :ensure t
  :commands (dired-sidebar-toggle-sidebar)
  :init
  (add-hook 'dired-sidebar-mode-hook
            (lambda ()
	      (display-line-numbers-mode 0)
              (unless (file-remote-p default-directory)
                (auto-revert-mode))))
  :config
  (push 'toggle-window-split dired-sidebar-toggle-hidden-commands)
  (push 'rotate-windows dired-sidebar-toggle-hidden-commands)

  (setq dired-sidebar-use-term-integration t)
  (setq dired-sidebar-use-custom-font 0)
  (setq dired-sidebar-width 25))
;; Deduce
(add-to-list 'auto-mode-alist '("\\.pf\\'" . deduce-mode))
;; Racket schtuff
(defun my-racket-faces ()
  "Buffer-local face remapping for `racket-mode-hook`."
  (face-remap-add-relative 'font-lock-comment-delimiter-face
			   '(:foreground "#ffb75e"))
  (face-remap-add-relative 'font-lock-comment-face
			   '(:foreground "#ffb75e"))
  )

(defun racket-start ()
  (rainbow-delimiters-mode 1)
  (flymake-mode 1)
  (define-key flymake-mode-map (kbd "M-n") 'open-small-flymake))

(defun open-small-flymake ()
  "Open flymake in minimized window"
  (interactive)
  (let ((split-width-threshold nil)
        (split-height-threshold 0))
    (flymake-show-buffer-diagnostics)
    (maximize-window)))

(add-hook 'racket-mode-hook 'my-racket-faces)
(add-hook 'racket-mode-hook 'racket-start)

(with-eval-after-load 'racket-mode
  ;; Redefine `test-fun` to change its internals
  (defun racket--sexp-comment-face-spec-set (face)
    "Create or refresh a faded variant of FACE."
    (let* ((fg (if noninteractive "black" (face-foreground face nil 'default)))
           (bg (if noninteractive "white" "#1c2433"))
           (fg-rgb (color-name-to-rgb fg))
           (bg-rgb (color-name-to-rgb bg))
           (pct (- 1.0 (color-clamp (or racket-sexp-comment-fade 1.0))))
           (faded-rgb (cl-mapcar (lambda (fg bg)
                                   (color-clamp
                                    (+ (* fg pct)
                                       (* bg (- 1.0 pct)))))
				 fg-rgb bg-rgb))
           (faded (apply #'color-rgb-to-hex faded-rgb))
           (other-props (apply #'append
                               (mapcar (pcase-lambda (`(,k . ,v))
					 (unless (or (eq k :foreground)
                                                     (eq k :inherit)
                                                     (eq v 'unspecified))
                                           (list k v)))
                                       (face-all-attributes face))))
           (spec `((t (:foreground ,faded ,@other-props))))
           (doc (format "A faded variant of the face `%s'.\nSee the customization variable `racket-sexp-comment-fade'." face))
           (faded-face-name (racket--sexp-comment-face-name face)))
      (face-spec-set faded-face-name spec)
      (set-face-documentation faded-face-name doc))))


(use-package flymake-racket
  :ensure t
  :commands (flymake-racket-add-hook)
  :init 
  (add-hook 'scheme-mode-hook #'flymake-racket-add-hook)
  (add-hook 'racket-mode-hook #'flymake-racket-add-hook))
;; C schtuff
(add-hook 'c++-mode-hook 'irony-mode)
(add-hook 'c-mode-hook 'irony-mode)
(add-hook 'objc-mode-hook 'irony-mode)
(add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)

(require 'company-irony)
(eval-after-load 'company
 '(add-to-list 'company-backends 'company-irony))

(add-to-list 'company-backends 'company-irony-c-headers)

(add-hook 'c++-mode-hook 'company-mode)
(add-hook 'c-mode-hook 'company-mode)
(add-hook 'objc-mode-hook 'company-mode)

(defun c-start ()
  (rainbow-identifiers-mode 0)
  (rainbow-delimiters-mode 1)
  (hs-minor-mode 1)
  (define-key c-mode-map (kbd "C-x <down>")   'hs-hide-block)
  (define-key c-mode-map (kbd "C-x <up>")     'hs-show-block)
  (define-key c-mode-map (kbd "C-x C-<down>") 'hs-hide-all)
  (define-key c-mode-map (kbd "C-x C-<up>")   'hs-show-all)
  (define-key c-mode-map (kbd "<tab>")        'company-indent-or-complete-common))
(add-hook 'c-mode-hook 'c-start)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Themeing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/")
(load-theme 'bearded-arc t)

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:family "Source Code Pro" :foundry "adobe" :slant normal :weight normal :height 98 :width normal))))
 '(agda2-highlight-datatype-face ((t (:foreground "#83d9ec"))))
 '(agda2-highlight-field-face ((t (:foreground "#4ff87a"))))
 '(agda2-highlight-function-face ((t (:foreground "#4ff87a" :weight heavy))))
 '(agda2-highlight-inductive-constructor-face ((t (:foreground "#F92672"))))
 '(agda2-highlight-keyword-face ((t (:foreground "#ff79c6" :weight heavy))))
 '(agda2-highlight-module-face ((t (:foreground "#AE81FF"))))
 '(agda2-highlight-number-face ((t (:foreground "#AE81FF"))))
 '(agda2-highlight-postulate-face ((t (:foreground "#83d9ec"))))
 '(agda2-highlight-primitive-face ((t (:foreground "#d76aab"))))
 '(agda2-highlight-primitive-type-face ((t (:foreground "#83d9ec")))))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes '(bearded-arc))
 '(custom-safe-themes
   '("f9f539f9244168622006754ad5a8190b47615ff46a2ae7a4ef8d285d8e290267" "a18eb9558abb09a418b46e2d0a7cd5bcb08c2ac5e10258987725f25e18034820" "a22f8a4d17b916b55b4745a3035e4bc0eadf6ce54b2b118fedd0d1ee3b69638e" "4ddddcaa1a512e172e06c9b1397ddc887ea5f165b618752d9b73185b1299bf29" "8de49e355d96a07beabfc1919e961ad87d7d63d0ba8edc3da1a12d45276cbbb5" "7fd02ca5e412da32a0e7cb6881e70012122b651af0c058d7ff451976ef6d32b5" "3e7ff296392da297015f7b4095928c8e0a31173fa57e2171dd396cbb0f4063bb" "8c7e832be864674c220f9a9361c851917a93f921fedb7717b1b5ece47690c098" "f4d1b183465f2d29b7a2e9dbe87ccc20598e79738e5d29fc52ec8fb8c576fcfd" "cbc8dee011906427c45f4757d2c4c41749309d92037eb296f7d6d77fc93c7014" "8190f278193fbe359843ccbb969c722c1b9f710d11c1f593e35d1deaf7a481ac" "1a2a53c7a0517dafcb85e0196a5de451668adac22cd8b0f112bf605e87489eda" "042fe5b1f435086a27456eaec477f5154adf4b34994e433d08dac0d82877822a" "d10f3a1a3bc7cef84cd6b6812b450a8b511bec4b67a62fb7d4510fc0430d1bbf" "f44bb32804c6dc06f539c82ff978f7178eef577caa90c0b89260fa4e67ba3322" "2f6a54ad14a28dbecafc9c7f2f9089948815ccff9d9739bec8475d9cd0905716" default))
 '(package-selected-packages
   '(tagedit racket-mode company-irony-c-headers company-irony irony impatient-mode markdown-mode emmet-mode web-mode splash-screen-new splash-screen rainbow-identifiers color-identifiers-mode dired-sidebar rainbow-delimiters autothemer melancholy-theme flymake-racket deduce-mode highlight-numbers parent-mode haskell-mode ##)))
