if exists('g:langtool_cmd') && !empty(exepath(fnamemodify(g:langtool_cmd, ':p')))
  let s:langtool_cmd = shellescape(exepath(fnamemodify(g:langtool_cmd, ':p')))
elseif exists('g:langtool_jar') && filereadable(fnamemodify(g:langtool_jar, ':p'))
  let s:langtool_cmd = 'java -jar ' . shellescape(fnamemodify(g:langtool_jar, ':p'))
else
  echoerr "To use the LanguageTool compiler, please set either g:langtool_cmd to the path of an executable that starts LanguageTool in command-line, or set g:langtool_jar to the path of languagetool-commandline.jar!"
  finish
endif

silent let s:list = split(system(s:langtool_cmd . ' --list'), '[[:space:]]')

function! s:lang(lang) abort
  " guess language
  let lang = substitute(a:lang, '_', '-', 'g')
  if match(s:list, '\c^' . lang . '$') >= 0
    return lang
  endif
  let lang = matchstr(lang, '\v^[^-]+')
  if match(s:list, '\c^' . lang . '$') == -1
    echoerr "Language '" . lang . "' not listed in output of " . s:langtool_cmd . " --list; trying anyway!"
  endif
  return lang
endfunction

function! langtool#langtool(bang) abort
  if !(empty(&l:buftype) && filereadable(bufname('%')))
    if input('This is not a file buffer. LangTool can only check files. Save to a temporary text file, y(es) or n(o)? ', 'y') =~? '^y'
      exe 'saveas ' . tempname() . '.txt' | filetype detect
      redraw!
    else
      return
    endif
  endif

  if exists('b:current_compiler') && !empty(b:current_compiler)
    let b:old_compiler = b:current_compiler
  else
    let errorformat = &l:errorformat
    let makeprg = &l:makeprg
  endif

  " use spelllang to set lang of langtool
  if !empty(&l:spelllang)
    let lang = s:lang(&l:spelllang)
    if !empty(lang)
      let b:langtool_parameters = '--language ' . lang
    endif
  else
    echohl WarningMsg | echomsg "Please set spellllang for more accurate check by LanguageTool. Using autodetection instead." | echohl None
    let b:langtool_parameters = '--autoDetect'
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
