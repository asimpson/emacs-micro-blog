;;; emacs-micro-blog.el --- A function to post the current buffer contents to micro.blog
;; -*- lexical-binding: t; -*-

;; Adam Simpson <adam@adamsimpson.net>
;; Version: 0.0.1
;; Keywords: micro.blog

;;; Commentary:
;; This uses my personal server endpoint to publish a blog post which micro.blog syndicates via RSS.

;;; Code:
(require 'url)
(require 'json)
(require 'ox-html)

(defun post-to-micro()
  "Take current org buffer or a buffer filled with HTML and post to micro.blog.
This converts to HTML first if necessary.
I assume a authinfo.gpg entry like this:

machine micro.blog login username password API-TOKEN port API-URL"
  (interactive)
  (let* ((org-export-show-temporary-export-buffer nil)
         (auth-info (auth-source-user-and-password "micro.blog"))
         (url (plist-get (car (last auth-info)) :port))
         (token (encode-coding-string (cadr auth-info) 'utf-8))
         (post (progn
                 (if (y-or-n-p "Export org mode or use HTML in current buffer? ")
                     (progn
                       (org-html-export-as-html nil nil nil t)
                       (with-current-buffer "*Org HTML Export*"
                         (buffer-substring-no-properties (point-min) (point-max))))
                   (with-current-buffer (current-buffer)
                     (buffer-substring-no-properties (point-min) (point-max))))))
         (json (json-encode `(("network" . "micro")
                              ("post" . ,post))))
         (url-request-method "POST")
         (url-request-extra-headers `(("Content-Type" . "application/json")
                                      ("X-API-KEY" . ,token)))
         (url-request-data (encode-coding-string json 'utf-8)))
    (url-retrieve url (lambda(_)) nil t)
    (kill-buffer)
    (delete-window)))

(provide 'emacs-micro-blog)

;;; emacs-micro-blog.el ends here
