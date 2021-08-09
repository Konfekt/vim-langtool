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
  echoerr 'To use the LanguageTool compiler, please set either g:langtool_cmd to the path of an executable that starts LanguageTool in command-line, or set g:langtool_jar to the path of languagetool-commandline.jar!'
  finish
endif

if !exists('g:langtool_parameters')
  let g:langtool_parameters = ''
endif
if !exists('b:langtool_parameters')
  let b:langtool_parameters = g:langtool_parameters
endif
if match(b:langtool_parameters, '\v\c%(\s|^)%(--language|-l)\s+%(\a+-)*\a+%(\s|$)') == -1
  if !exists('s:list')
    silent let s:list = split(system(s:langtool_cmd . ' --list'), '[[:space:]]')
  endif
  " guess language
  let b:langtool_lang = substitute(&spelllang, '_', '-', 'g')
  if match(s:list, '\c^' . b:langtool_lang . '$') == -1
    let b:langtool_lang = matchstr(b:langtool_lang, '\v^[^-]+')
    if match(s:list, '\c^' . b:langtool_lang . '$') == -1
      echoerr "Language '" . b:langtool_lang . "' not listed in output of " . s:langtool_cmd . " --list; trying anyway!"
    endif
  endif
  if !empty(b:langtool_lang)
    let b:langtool_parameters .= ' --language ' . b:langtool_lang
  else
    echohl WarningMsg | echomsg 'Please set &spellllang for more accurate check by LanguageTool; using autodetection instead.' | echohl None
    if match(b:langtool_parameters, '\v\c%(\s|^)%(--autodetect|-adl)%(\s|$)') == -1
      let b:langtool_parameters .= ' --autoDetect'
    endif
  endif
endif

let &l:makeprg = 
      \ s:langtool_cmd . ' ' . b:langtool_parameters
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

