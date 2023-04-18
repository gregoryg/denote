;;; denote-extract.el --- Extract text from buffer into new Denote note -*- lexical-binding: t -*-

;; Copyright (C) 2023  Free Software Foundation, Inc.

;; Author: Protesilaos Stavrou <info@protesilaos.com>
;; Maintainer: Denote Development <~protesilaos/denote@lists.sr.ht>
;; URL: https://git.sr.ht/~protesilaos/denote
;; Mailing-List: https://lists.sr.ht/~protesilaos/denote

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; HIGHLY EXPERIMENTAL.
;;
;; Extract text from buffer into new Denote note.  The idea is to
;; capture some thoughts using voice input with its automatic
;; transcription and then invoke `denote-extract-text' to turn that
;; into a Denote note.  The workflow relies on the low-tech "hack" of
;; using special words to designate sections of the note as "title"
;; and "keywords", respectively.

;;; Code:

(require 'denote)

(defgroup denote-extract nil
  "Extract text from buffer into new Denote note."
  :group 'denote)

(defcustom denote-extract-special-terms "\\(taz\\|kaz\\)"
  "Regular expression of terms that correspond to the title and keywords.
Taz means Title A-Z and kaz is the same for keywords."
  :type 'string
  :group 'denote-extract)

(defun denote-extract--line-or-region ()
  "Return buffer positions of active region or current line."
  (if (region-active-p)
      (cons (region-beginning) (region-end))
    (cons (line-beginning-position) (line-end-position))))

(defun denote-extract--substring ()
  "Return string from `denote-extract--line-or-region'."
  (let ((area (denote-extract--line-or-region)))
    (buffer-substring-no-properties (car area) (cdr area))))
  
(defun denote-extract--constituents (str)
  "Extract coded note from STR."
  (split-string str denote-extract-special-terms :omit-nulls "[\s\f\t\n\r\v]+"))

(defun denote-extract--format-title (constituents)
  "Format title from list of CONSTITUENTS strings."
  (if-let ((title (nth 1 constituents)))
      (string-trim title)
    ""))

(defun denote-extract--format-keywords (constituents)
  "Format keywords from list of CONSTITUENTS strings."
  (if-let ((kw (nth 2 constituents))
           (sep "[\s\f\t\n\r\v]+"))
      (denote-keywords-sort (split-string kw sep :omit-nulls sep))
    '("")))

;;;###autoload
(defun denote-extract-text ()
  "Create a new note from the text in the active region or current line.

If the text includes a field that starts with the first match in
`denote-extract-special-terms', use is as the new note's TITLE
component.  If there is a field that starts with the second match
in the aforementioned variable, use it as the new note's KEYWORDS
component.

If there are no matches for `denote-extract-special-terms',
create a new note without a title or keywords.  The user may then
manually perform a `denote-rename-file' or modify the front
matter and then do `denote-rename-file-using-front-matter'."
  (interactive)
  (let ((constituents (denote-extract--constituents (denote-extract--substring))))
    (denote
     (denote-extract--format-title constituents)
     (denote-extract--format-keywords constituents))
    (insert (nth 0 constituents))))

(provide 'denote-extract)
;;; denote-extract.el ends here
