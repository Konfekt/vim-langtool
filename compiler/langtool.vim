if exists('current_compiler') | finish | endif
let current_compiler = 'langtool'

let s:cpo_save = &cpo
set cpo&vim

let s:langtool_cmd = langtool#cmd()
if empty(s:langtool_cmd)
  echoerr langtool#cmd_error()
  let &cpo = s:cpo_save
  unlet s:cpo_save
  finish
endif

if !exists('g:langtool_parameters')
  let g:langtool_parameters = ''
endif
let s:parameters = get(b:, 'langtool_parameters', g:langtool_parameters)
if match(s:parameters, langtool#language_pattern()) == -1
  " guess language from 'spelllang' (skipping 'cjk', which names no language)
  let s:spelllangs = filter(split(&l:spelllang, ','), 'v:val !=? "cjk"')
  if len(s:spelllangs) > 1
    echohl WarningMsg | echo 'Please select one of the &spelllang language codes numbered 0,1,...' | echohl None
    let s:spelllang = get(s:spelllangs, inputlist(map(copy(s:spelllangs), 'v:key . ". " . v:val')), '')
  else
    let s:spelllang = get(s:spelllangs, 0, '')
  endif
  let b:langtool_lang = substitute(s:spelllang, '_', '-', 'g')
  if empty(b:langtool_lang)
    echohl WarningMsg | echomsg 'Please set &spelllang for more accurate check by LanguageTool; using autodetection instead.' | echohl None
    if match(s:parameters, '\v\c%(\s|^)%(--autodetect|-adl)%(\s|$)') == -1
      let s:parameters .= ' --autoDetect'
    endif
  else
    " LanguageTool is slow to start, so list its languages only once.
    if !exists('s:list')
      silent let s:output = system(s:langtool_cmd . ' --list')
      if v:shell_error == 0
        let s:list = split(s:output, '[[:space:]]')
      endif
      unlet s:output
    endif
    let s:languages = get(s:, 'list', [])
    if index(s:languages, b:langtool_lang, 0, 1) == -1
      let b:langtool_lang = matchstr(b:langtool_lang, '\v^[^-]+')
      if index(s:languages, b:langtool_lang, 0, 1) == -1
        echohl WarningMsg | echomsg "Language '" . b:langtool_lang . "' not listed in output of " . s:langtool_cmd . ' --list; trying anyway!' | echohl None
      endif
    endif
    let s:parameters .= ' --language ' . b:langtool_lang
    unlet s:languages
  endif
  unlet s:spelllangs s:spelllang
endif

execute 'CompilerSet makeprg=' . escape(s:langtool_cmd . ' ' . s:parameters, ' \|"')
execute 'CompilerSet errorformat=' . escape(
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
      \ '%-GTime: %.%#', ' \|"')
unlet s:parameters

let &cpo = s:cpo_save
unlet s:cpo_save
