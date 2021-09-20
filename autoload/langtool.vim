if exists('g:langtool_cmd') && !empty(exepath(g:langtool_cmd))
  let s:langtool_cmd = shellescape(exepath(g:langtool_cmd))
elseif exists('g:langtool_jar') && filereadable(fnamemodify(g:langtool_jar, ':p'))
  let s:langtool_cmd = 'java -jar ' . shellescape(fnamemodify(g:langtool_jar, ':p'))
else
  echoerr 'To use the LanguageTool compiler, please set either g:langtool_cmd to the path of an executable that starts LanguageTool in command-line, or set g:langtool_jar to the path of languagetool-commandline.jar!'
  finish
endif

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
    let old_compiler = b:current_compiler
  else
    let old_errorformat = &l:errorformat
    let old_makeprg = &l:makeprg
  endif
  " set language in compiler/langtool.vim by unsetting b:langtool_parameters
  if exists('b:langtool_parameters')
    let old_langtool_parameters = b:langtool_parameters
    let b:langtool_parameters = substitute(b:langtool_parameters, '\v\c%(\s|^)%(--language|-l)\s+%(\a+-)*\a+%(\s|$)', ' ', 'g')
  endif

  try
    compiler langtool
    if exists('g:langtool_save') && g:langtool_save == 1 | update | endif
    exe 'silent ' . (exists(':LMake') == 2 ? 'LMake' :
          \ exists(':Make') == 2 ? 'Make'
          \ : 'lmake') . a:bang . ' ' . shellescape(expand('%'))
  finally
    if exists('old_langtool_parameters')
      let b:langtool_parameters = old_langtool_parameters
    endif
    if exists('old_compiler')
      exe 'silent compiler ' . old_compiler
      unlet old_compiler
    else
      unlet b:current_compiler
      silent let &l:errorformat = old_errorformat
      silent let &l:makeprg = old_makeprg
    endif
  endtry
endfunction
