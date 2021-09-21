if exists("current_compiler") | finish | endif
let current_compiler = "langtool"

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo&vim

" if exists('g:langtool_cmd') && !empty(exepath(g:langtool_cmd))
"   let s:langtool_cmd = shellescape(exepath(g:langtool_cmd))
if exists('g:langtool_jar') && filereadable(fnamemodify(g:langtool_jar, ':p'))
  let s:langtool_cmd = 'java -Dfile.encoding=' . &encoding . ' -jar ' . shellescape(fnamemodify(g:langtool_jar, ':p'))
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
  let spelllangs = split(&l:spelllang, ',')
  if len(spelllangs) > 1
    echohl WarningMsg | echo 'Please select one of the &spelllang language codes numbered 0,1,...' | echohl None
    let spelllang = get(spelllangs, inputlist(spelllangs), '')
  else
    let spelllang = &l:spelllang
  endif
  let b:langtool_lang = substitute(spelllang, '_', '-', 'g')
  if empty(b:langtool_lang)
    echohl WarningMsg | echomsg 'Please set &spellllang for more accurate check by LanguageTool; using autodetection instead.' | echohl None
    if match(b:langtool_parameters, '\v\c%(\s|^)%(--autodetect|-adl)%(\s|$)') == -1
      let b:langtool_parameters .= ' --autoDetect'
    endif
  else
    if match(s:list, '\c^' . b:langtool_lang . '$') == -1
      let b:langtool_lang = matchstr(b:langtool_lang, '\v^[^-]+')
      if match(s:list, '\c^' . b:langtool_lang . '$') == -1
        echoerr "Language '" . b:langtool_lang . "' not listed in output of " . s:langtool_cmd . " --list; trying anyway!"
      endif
    endif
    let b:langtool_parameters .= ' --language ' . b:langtool_lang
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

