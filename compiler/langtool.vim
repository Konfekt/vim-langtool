if exists("current_compiler") | finish | endif
let current_compiler = "langtool"

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo&vim

if exists('g:langtool_cmd') && !empty(exepath(fnamemodify(g:langtool_cmd, ':p')))
  let s:langtool_cmd = shellescape(exepath(fnamemodify(g:langtool_cmd, ':p')))
elseif exists('g:langtool_jar') && filereadable(fnamemodify(g:langtool_jar, ':p'))
  let s:langtool_cmd = 'java -jar ' . shellescape(fnamemodify(g:langtool_jar, ':p'))
else
  echoerr "To use the LanguageTool compiler, please set either g:langtool_cmd to the path of an executable that starts LanguageTool in command-line, or set g:langtool_jar to the path of languagetool-commandline.jar!"
  finish
endif

if !exists('g:langtool_parameters')
  let g:langtool_parameters = ''
endif
if !exists('b:langtool_parameters')
  let b:langtool_parameters = '--autoDetect'
endif

let &l:makeprg = 
      \ s:langtool_cmd . ' ' . g:langtool_parameters . ' ' . b:langtool_parameters
let &l:errorformat =
      \ '%-GPicked up _JAVA_OPTIONS: %.%#,' .
      \ '%-GExpected text language: %.%#,' .
      \ '%-PWorking on %f...,' .
      \ '%-I%.%# [main] DEBUG %.%#,' .
      \ '%+IUsing %.%# for file %.%#,' .
      \ '%I%\d%\+.) Line %l\, column %c\, Rule ID: %m,' .
      \ '%-CMessage%m,' .
      \ '%-CSuggestion%m,' .
      \ '%-CMore info%m,' .
      \ '%-C%\s%#^%\+%\s%#,' .
      \ '%-C%.%#,' .
      \ '%-Z%\s%#,' .
      \ '%-Q,' .
      \ '%-GTime: %.%#'
silent CompilerSet makeprg
silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save

