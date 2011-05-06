" Name:    localvimrc.vim
" Version: 0.1.0
" Author:  Markus Braun <markus.braun@krawel.de>
" Summary: Vim plugin to search local vimrc files and load them.
" Licence: This program is free software; you can redistribute it and/or
"          modify it under the terms of the GNU General Public License.
"          See http://www.gnu.org/copyleft/gpl.txt
"
" Section: Documentation {{{1
"
" Description: {{{2
"
"   This plugin searches for local vimrc files in the file system tree of the
"   currently opened file. By default it searches for all ".lvimrc" files from
"   the file's directory up to the root directory and loads them in reverse
"   order. The filename and amount of loaded files is customizable through
"   global variables.
"
" Installation: {{{2
"
"   Copy the localvimrc.vim file to the $HOME/.vim/plugin directory.
"   Refer to ':help add-plugin', ':help add-global-plugin' and ':help
"   runtimepath' for more details about Vim plugins.
"
" Variables: {{{2
"
"   g:localvimrc_name
"     Filename of local vimrc files.
"     Defaults to ".lvimrc".
"
"   g:localvimrc_count
"     On the way from root, the last localvimrc_count files are sourced.
"     Defaults to -1 (all)
"
"   g:localvimrc_sandbox
"     Source the found local vimrc files in a sandbox for security reasons.
"     Defaults to 1.
"
"   g:localvimrc_ask
"     Ask before sourcing any local vimrc file.
"     Defaults to 1.
"
" Credits: {{{2
"
" - Simon Howard for his hint about "sandbox"
"
" Section: Plugin header {{{1

" guard against multiple loads {{{2
if (exists("g:loaded_localvimrc") || &cp)
  finish
endif
let g:loaded_localvimrc = 1

" check for correct vim version {{{2
if version < 700
  finish
endif

" define default "localvimrc_name" {{{2
if (!exists("g:localvimrc_name"))
  let s:localvimrc_name = ".lvimrc"
else
  let s:localvimrc_name = g:localvimrc_name
endif

" define default "localvimrc_count" {{{2
if (!exists("g:localvimrc_count"))
  let s:localvimrc_count = -1
else
  let s:localvimrc_count = g:localvimrc_count
endif

" define default "localvimrc_sandbox" {{{2
" copy to script local variable to prevent .lvimrc disabling the sandbox
" again.
if (!exists("g:localvimrc_sandbox"))
  let s:localvimrc_sandbox = 1
else
  let s:localvimrc_sandbox = g:localvimrc_sandbox
endif

" define default "localvimrc_ask" {{{2
" copy to script local variable to prevent .lvimrc disabling the sandbox
" again.
if (!exists("g:localvimrc_ask"))
  let s:localvimrc_ask = 1
else
  let s:localvimrc_ask = g:localvimrc_ask
endif

" define default "localvimrc_debug" {{{2
if (!exists("g:localvimrc_debug"))
  let g:localvimrc_debug = 0
endif

" Section: Autocmd setup {{{1

if has("autocmd")
  augroup localvimrc
    autocmd!

    " call s:LocalVimRC() when creating ore reading any file
    autocmd VimEnter,BufNewFile,BufRead * call s:LocalVimRC()
  augroup END
endif

" Section: Functions {{{1

" Function: s:LocalVimRC() {{{2
"
" search all local vimrc files from current directory up to root directory and
" source them in reverse order.
"
function! s:LocalVimRC()
  " print version
  call s:LocalVimRCDebug(1, "localvimrc.vim " . g:loaded_localvimrc)

  " directory of current file (correctly escaped)
  let l:directory = escape(expand("%:p:h"), ' ~|!"$%&()=?{[]}+*#'."'")
  if empty(l:directory)
    let l:directory = escape(getcwd(), ' ~|!"$%&()=?{[]}+*#'."'")
  endif
  call s:LocalVimRCDebug(2, "searching directory \"" . l:directory . "\"")

  " generate a list of all local vimrc files along path to root
  let l:rcfiles = findfile(s:localvimrc_name, l:directory . ";", -1)
  call s:LocalVimRCDebug(1, "found files: " . string(l:rcfiles))

  " shrink list of found files
  if s:localvimrc_count == -1
    let l:rcfiles = l:rcfiles[0:-1]
  elseif s:localvimrc_count == 0
    let l:rcfiles = []
  else
    let l:rcfiles = l:rcfiles[0:(s:localvimrc_count-1)]
  endif
  call s:LocalVimRCDebug(1, "candidate files: " . string(l:rcfiles))

  " source all found local vimrc files along path from root (reverse order)
  let l:answer = ""
  for l:rcfile in reverse(l:rcfiles)
    call s:LocalVimRCDebug(2, "processing \"" . l:rcfile . "\"")

    if filereadable(l:rcfile)
      " ask if this rcfile should be loaded
      if (l:answer != "a")
        if (s:localvimrc_ask == 1)
          let l:message = "localvimrc: source " . l:rcfile . "? (y/n/a/q) "
          let l:answer = input(l:message)
          call s:LocalVimRCDebug(2, "answer is \"" . l:answer . "\"")
        else
          let l:answer = "a"
        endif
      endif

      " check the answer
      if (l:answer == "y" || l:answer == "a")

        " add 'sandbox' if requested
        if (s:localvimrc_sandbox != 0)
          let l:command = "sandbox "
          call s:LocalVimRCDebug(2, "using sandbox")
        else
          let l:command = ""
        endif
        let l:command .= "source " . escape(l:rcfile, ' ~|!"$%&()=?{[]}+*#'."'")

        " execute the command
        exec l:command
        call s:LocalVimRCDebug(1, "sourced " . l:rcfile)

      else
        call s:LocalVimRCDebug(1, "skipping " . l:rcfile)
        if (l:answer == "q")
          call s:LocalVimRCDebug(1, "end processing files")
          break
        endif
      endif

    endif
  endfor

  " clear command line
  redraw!
endfunction

" Function: s:LocalVimRCDebug(level, text) {{{2
"
" output debug message, if this message has high enough importance
"
function! s:LocalVimRCDebug(level, text)
  if (g:localvimrc_debug >= a:level)
    echom "localvimrc: " . a:text
  endif
endfunction

" vim600: foldmethod=marker foldlevel=0 :
