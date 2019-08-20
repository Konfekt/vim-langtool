if !(exists('g:langtool_jar') && filereadable(g:langtool_jar))
  echoerr "Please set g:langtool_jar to the path of languagetool-commandline.jar to use the LanguageTool compiler!"
  finish
endif

silent let s:list = split(system('java -jar ' . g:langtool_jar . ' --list'), '[[:space:]]')

function! s:lang(lang) abort
  " guess language
  let lang = substitute(a:lang, '_', '-', 'g')
  if match(s:list, '\c^' . lang . '$') >= 0
    return lang
  endif
  let lang = matchstr(lang, '\v^[^-]+')
  if match(s:list, '\c^' . lang . '$') >= 0
    return lang
  endif
  echomsg "Language '" . lang . "' not supported by LanguageTool!"
  return ''
endfunction

function! langtool#langtool(bang) abort
  if exists('b:current_compiler') && !empty(b:current_compiler)
    let b:old_compiler = b:current_compiler
  else
    let errorformat = &l:errorformat
    let makeprg = &l:makeprg
  endif

  " use spelllang to set lang of langtool
  if &l:spell && !empty(&l:spelllang)
    let lang = s:lang(&l:spelllang)
    if !empty(lang)
      let b:langtool_parameters = '--language ' . lang
    endif
  endif

  compiler langtool
  if exists(':Make') == 2
    exe 'silent Make' . a:bang
  else
    exe 'silent lmake' . a:bang
  endif

  if exists('b:old_compiler')
    exe 'silent compiler ' . b:old_compiler
    unlet b:old_compiler
  else
    unlet b:current_compiler
    silent let &l:errorformat = errorformat
    silent let &l:makeprg = makeprg
  endif
endfunction
