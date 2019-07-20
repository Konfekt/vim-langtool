let langtool = 'java -jar ' . g:langtool_jar
silent let s:list = split(system(langtool . ' --list'), '[[:space:]]')

function! s:lang(lang) abort
  " guess language
  let lang = substitute(a:lang, '_', '-', 'g')
  if match(s:list, '\c' . lang) >= 0
    return lang
  endif
  let lang = matchstr(lang, '\v^[^-]+')
  if match(s:list, '\c' . lang) >= 0
    return lang
  endif
  echomsg "Language '" . lang . "' not supported by LanguageTool!"
  return ''
endfunction

function! langtool#langtool(bang) abort
  let errorformat = &l:errorformat
  let makeprg = &l:makeprg

  " use spelllang to set lang of langtool
  if &l:spell && !empty(&l:spelllang)
    let lang = s:lang(&l:spelllang)
    if !empty(lang)
      let b:langtool_parameters = '--language ' . lang
    endif
  endif
  compiler langtool

  if a:bang
    lmake!
  else
    lmake
  endif

  silent let &l:errorformat = errorformat
  silent let &l:makeprg = makeprg
endfunction
