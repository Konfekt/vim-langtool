if exists("current_compiler") | finish | endif
let current_compiler = "langtool"

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo&vim

if !(exists('g:langtool_jar') && filereadable(g:langtool_jar))
  echoerr "Please set g:langtool_jar to the path of languagetool-commandline.jar to use the LanguageTool compiler!"
  finish
endif
if !exists('g:langtool_parameters')
  let g:langtool_parameters = ''
endif
if !exists('b:langtool_parameters')
  let b:langtool_parameters = '--autoDetect'
endif

let &l:makeprg = 'java -jar ' . g:langtool_jar . ' ' . g:langtool_parameters . ' ' . b:langtool_parameters . ' ' . '%'
let &l:errorformat =
      \ '%-GPicked up _JAVA_OPTIONS: %.%#,' .
      \ '%-GExpected text language: %.%#,' .
      \ '%-PWorking on %f...,' .
      \ '%-G%.%# [main] DEBUG %.%#,' .
      \ '%-GUsing %.%# for file %.%#,' .
      \ '%I%\d%\+.) Line %l\, column %c\, Rule ID: %m,' .
      \ '%+CMessage: %m,' .
      \ '%-CSuggestion: %.%#,' .
      \ '%-C%.%#,' .
      \ '%-C%.%#,' .
      \ '%-CMore info: %.%#,' .
      \ '%-Z\s%#,' .
      \ '%-Q,' .
      \ '%-GTime: %.%#'
silent CompilerSet makeprg
silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save
