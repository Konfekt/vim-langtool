if exists('g:langtool_cmd')
  let s:langtool_cmd = g:langtool_cmd
elseif !(exists('g:langtool_jar') && filereadable(g:langtool_jar))
  echoerr "To use the LanguageTool compiler, please set either g:langtool_cmd to the path of an executable that starts LanguageTool in command-line, or set g:langtool_jar to the path of languagetool-commandline.jar!"
  finish
else
  let s:langtool_cmd = 'java -jar ' . g:langtool_jar
endif

silent let s:list = split(system(s:langtool_cmd . ' --list'), '[[:space:]]')

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
   if !(empty(&l:buftype) && filereadable(bufname('%')))
     echoerr "This is not a file buffer. Please save the buffer to a file before calling LangTool, because it can only check files."
     return
   endif

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
  if exists('g:langtool_save') && g:langtool_save == 1 | update | endif
  exe 'silent ' . (exists(':Make') == 2 ? 'Make' : 'lmake') . a:bang . ' ' . shellescape(expand('%'))

  if exists('b:old_compiler')
    exe 'silent compiler ' . b:old_compiler
    unlet b:old_compiler
  else
    unlet b:current_compiler
    silent let &l:errorformat = errorformat
    silent let &l:makeprg = makeprg
  endif
endfunction
