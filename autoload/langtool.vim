" Matches a --language (or -l) option and its value in LanguageTool parameters.
let s:language_pattern = '\v\c%(^|\s)\zs%(--language|-l)\s+%(\a+-)*\a+\ze%(\s|$)'

function! langtool#language_pattern() abort
  return s:language_pattern
endfunction

" Shell command that starts LanguageTool on the command line, or '' if neither
" g:langtool_cmd nor g:langtool_jar (with Java) is usable.
function! langtool#cmd() abort
  if exists('g:langtool_cmd') && !empty(exepath(g:langtool_cmd))
    return shellescape(exepath(g:langtool_cmd))
  endif
  if exists('g:langtool_jar') && filereadable(fnamemodify(g:langtool_jar, ':p')) && executable('java')
    return 'java -Dfile.encoding=' . &encoding . ' -jar ' . shellescape(fnamemodify(g:langtool_jar, ':p'))
  endif
  return ''
endfunction

" Why langtool#cmd() returned ''.
function! langtool#cmd_error() abort
  if exists('g:langtool_jar') && filereadable(fnamemodify(g:langtool_jar, ':p')) && !executable('java')
    return 'To use the LanguageTool compiler, Java must be installed and available in your PATH!'
  endif
  return 'To use the LanguageTool compiler, please set either g:langtool_cmd to the path of an executable that starts LanguageTool in command-line, or set g:langtool_jar to the path of languagetool-commandline.jar!'
endfunction

function! langtool#langtool(bang) abort
  if empty(langtool#cmd())
    echoerr langtool#cmd_error()
    return
  endif

  if !(empty(&l:buftype) && filereadable(bufname('%')))
    if input('This is not a file buffer. LangTool can only check files. Save to a temporary text file, y(es) or n(o)? ', 'y') =~? '^y'
      silent execute 'saveas' fnameescape(tempname() . '.txt') | filetype detect
      redraw!
    else
      return
    endif
  endif

  let old_compiler = get(b:, 'current_compiler', v:null)
  let old_makeprg = &l:makeprg
  let old_errorformat = &l:errorformat
  " Let compiler/langtool.vim guess the language from 'spelllang'.
  let old_parameters = get(b:, 'langtool_parameters', v:null)
  if old_parameters isnot v:null
    let b:langtool_parameters = substitute(old_parameters, s:language_pattern, '', 'g')
  endif

  try
    compiler langtool
    if get(g:, 'langtool_save', 1) | silent update | endif
    execute 'silent' (exists(':LMake') == 2 ? 'LMake' : exists(':Make') == 2 ? 'Make' : 'lmake') . a:bang
          \ escape(shellescape(expand('%')), '%#')
  finally
    if old_parameters isnot v:null
      let b:langtool_parameters = old_parameters
    endif
    if old_compiler is v:null
      unlet! b:current_compiler
    else
      let b:current_compiler = old_compiler
    endif
    let &l:makeprg = old_makeprg
    let &l:errorformat = old_errorformat
  endtry
endfunction
