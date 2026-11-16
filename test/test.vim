" Headless tests for vim-langtool.
" Run with test/run.sh, or:
"   vim -N -u NONE -i NONE --not-a-term -S test/test.vim
"   nvim --headless -u NONE -i NONE -S test/test.vim
" A stand-in for LanguageTool (test/fake-languagetool) is used unless
" $LANGTOOL_JAR points to a real languagetool-commandline.jar, in which case
" one extra test runs it. Results are written to the file in
" $LANGTOOL_TEST_OUT (default: test/result.txt); the editor exits with status
" 1 if any test fails.

let s:root = fnamemodify(expand('<sfile>:p'), ':h:h')
let s:out = empty($LANGTOOL_TEST_OUT) ? s:root . '/test/result.txt' : $LANGTOOL_TEST_OUT
let s:fake = s:root . '/test/fake-languagetool'
let s:tmp = tempname()
call mkdir(s:tmp . '/bin', 'p')
let s:log = s:tmp . '/args.log'
let $LANGTOOL_FAKE_LOG = s:log
let s:path = $PATH

" A $PATH without java, but with the tools the shell commands need.
let s:nojava = s:tmp . '/nojava'
call mkdir(s:nojava)
for s:tool in ['sh', 'cat', 'head', 'tee', 'rm']
  if executable(s:tool)
    call system('ln -s ' . shellescape(exepath(s:tool)) . ' ' . shellescape(s:nojava . '/' . s:tool))
  endif
endfor

" A `java` on $PATH that runs the stand-in instead of the jar.
call writefile(['#!/bin/sh', 'while [ "$1" != -jar ]; do shift; done; shift 2', 'exec ' . shellescape(s:fake) . ' "$@"'], s:tmp . '/bin/java')
call setfperm(s:tmp . '/bin/java', 'rwxr-xr-x')
let s:jar = s:tmp . '/languagetool-commandline.jar'
call writefile([], s:jar)

let &runtimepath = s:root . ',' . &runtimepath
execute 'source' fnameescape(s:root . '/plugin/langtool.vim')
set noswapfile hidden nomore shortmess+=F

let s:results = []
let s:failed = 0

function! s:Check(name, got, want) abort
  if a:got ==# a:want
    call add(s:results, 'ok   ' . a:name)
  else
    let s:failed += 1
    call add(s:results, 'FAIL ' . a:name . ': got ' . string(a:got) . ', want ' . string(a:want))
  endif
  call writefile(s:results, s:out)
endfunction

" Open a fresh file buffer {name} in the temporary directory.
function! s:Reset(name) abort
  silent! %bwipeout!
  unlet! g:langtool_cmd g:langtool_jar g:langtool_parameters
  let $PATH = s:path
  call writefile(['This is a example sentence.'], s:tmp . '/' . a:name)
  execute 'edit' fnameescape(s:tmp . '/' . a:name)
  call setloclist(0, [])
  call delete(s:log)
  messages clear
  let g:langtool_cmd = s:fake
  setlocal spelllang=en
endfunction

" Run :LangTool and return the exception it threw, if any.
function! s:LangTool() abort
  try
    LangTool
  catch
    return v:exception
  endtry
  return ''
endfunction

" Arguments of the last call of the stand-in.
function! s:Args() abort
  return filereadable(s:log) ? get(readfile(s:log), -1, '') : ''
endfunction

function! s:Texts() abort
  return map(getloclist(0), '[v:val.lnum, v:val.col, v:val.text]')
endfunction

let s:want_texts = [[1, 1, "FAKE_RULE premium: false prio=0\n: Fake mistake.\n: fake\n: https://example.invalid/"]]

" Without g:langtool_cmd or g:langtool_jar, :LangTool reports the setup error
" and works as soon as either is set.
function! s:TestUnconfigured() abort
  call s:Reset('unconfigured.txt')
  unlet g:langtool_cmd
  silent! LangTool
  call s:Check('unconfigured: setup error', v:errmsg =~# 'please set either g:langtool_cmd', 1)
  let g:langtool_cmd = s:fake
  call s:Check('unconfigured: then configured', s:LangTool(), '')
  call s:Check('unconfigured: then configured: list', s:Texts(), s:want_texts)
endfunction

" g:langtool_cmd alone suffices, without Java on $PATH.
function! s:TestCmd() abort
  call s:Reset('cmd.txt')
  let $PATH = s:nojava
  call s:Check('cmd: no error', s:LangTool(), '')
  call s:Check('cmd: list', s:Texts(), s:want_texts)
  call s:Check('cmd: args', s:Args(), '--language en ' . s:tmp . '/cmd.txt')
endfunction

function! s:TestJar() abort
  call s:Reset('jar.txt')
  unlet g:langtool_cmd
  let g:langtool_jar = s:jar
  let $PATH = s:tmp . '/bin:' . s:path
  call s:Check('jar: no error', s:LangTool(), '')
  call s:Check('jar: list', s:Texts(), s:want_texts)
  compiler langtool
  call s:Check('jar: makeprg', split(&l:makeprg), ['java', '-Dfile.encoding=' . &encoding, '-jar', shellescape(s:jar), '--language', 'en'])
endfunction

function! s:TestJarWithoutJava() abort
  call s:Reset('nojava.txt')
  unlet g:langtool_cmd
  let g:langtool_jar = s:jar
  let $PATH = s:nojava
  call s:Check('jar without java: error', s:LangTool() =~# 'Java must be installed', 1)
  call s:Check('jar without java: not run', filereadable(s:log), 0)
endfunction

" The compiler must not leave g:spelllang or g:spelllangs behind.
function! s:TestNoGlobals() abort
  call s:Reset('globals.txt')
  unlet! g:spelllang g:spelllangs
  call s:LangTool()
  call s:Check('no globals', [exists('g:spelllang'), exists('g:spelllangs')], [0, 0])
endfunction

" :LangTool leaves b:langtool_parameters as it found it.
function! s:TestParametersUntouched() abort
  call s:Reset('params.txt')
  call s:LangTool()
  call s:Check('parameters: not created', exists('b:langtool_parameters'), 0)
  let b:langtool_parameters = '--mothertongue de --language fr'
  call s:LangTool()
  call s:Check('parameters: kept', b:langtool_parameters, '--mothertongue de --language fr')
  call s:Check('parameters: spelllang wins', s:Args() =~# '^--mothertongue de\s\+--language en ', 1)
endfunction

" Autodetection used once, for an empty 'spelllang', does not stick.
function! s:TestAutoDetectNotSticky() abort
  call s:Reset('autodetect.txt')
  setlocal spelllang=
  call s:LangTool()
  call s:Check('autodetect: used', s:Args() =~# '--autoDetect', 1)
  setlocal spelllang=de
  call s:LangTool()
  call s:Check('autodetect: not sticky', s:Args(), '--language de ' . s:tmp . '/autodetect.txt')
endfunction

" The warning about an empty 'spelllang' reaches the message history.
function! s:TestSpelllangWarning() abort
  call s:Reset('warning.txt')
  setlocal spelllang=
  call s:LangTool()
  call s:Check('spelllang warning shown', execute('messages') =~# 'Please set &spelllang', 1)
endfunction

" An unlisted language is tried anyway, as the warning says.
function! s:TestUnlistedLanguage() abort
  call s:Reset('unlisted.txt')
  setlocal spelllang=xx
  call s:Check('unlisted: no error', s:LangTool(), '')
  call s:Check('unlisted: tried', s:Args(), '--language xx ' . s:tmp . '/unlisted.txt')
  call s:Check('unlisted: list', s:Texts(), s:want_texts)
  call s:Check('unlisted: warning', execute('messages') =~# "Language 'xx' not listed", 1)
endfunction

" en_us falls back to en-US, then en_xx to en.
function! s:TestLanguageFallback() abort
  call s:Reset('fallback.txt')
  setlocal spelllang=en_us
  call s:LangTool()
  call s:Check('fallback: region', s:Args() =~# '^--language en-us ', 1)
  setlocal spelllang=en_xx
  call s:LangTool()
  call s:Check('fallback: language', s:Args() =~# '^--language en ', 1)
endfunction

" 'cjk' in 'spelllang' names no language and is not offered.
function! s:TestCjk() abort
  call s:Reset('cjk.txt')
  setlocal spelllang=en,cjk
  call feedkeys("1\<CR>", 'nt')
  call s:LangTool()
  " Flush the keys in case no prompt consumed them.
  call feedkeys('', 'x')
  call s:Check('cjk skipped', s:Args() =~# '^--language en ', 1)
endfunction

" Several languages in 'spelllang' are offered for selection.
function! s:TestSelectLanguage() abort
  call s:Reset('select.txt')
  setlocal spelllang=en,de
  call feedkeys("1\<CR>", 'nt')
  call s:LangTool()
  call s:Check('select language', s:Args() =~# '^--language de ', 1)
endfunction

" Every --language option is replaced by the one from 'spelllang'.
function! s:TestSeveralLanguageOptions() abort
  call s:Reset('several.txt')
  let b:langtool_parameters = '-l de -l fr'
  call s:LangTool()
  call s:Check('several language options', split(s:Args()), ['--language', 'en', s:tmp . '/several.txt'])
endfunction

" A file name with % or # is passed literally.
function! s:TestSpecialFileName() abort
  call s:Reset('a%b#c.txt')
  call s:Check('special file name: no error', s:LangTool(), '')
  call s:Check('special file name: args', s:Args(), '--language en ' . s:tmp . '/a%b#c.txt')
  call s:Check('special file name: list', s:Texts(), s:want_texts)
endfunction

" The compiler settings in effect before :LangTool are restored exactly.
function! s:TestRestoreCompiler() abort
  call s:Reset('restore.txt')
  compiler gcc
  setlocal makeprg=mymake errorformat=%f:%l:%m
  call s:LangTool()
  call s:Check('restore: compiler', [get(b:, 'current_compiler', ''), &l:makeprg, &l:errorformat], ['gcc', 'mymake', '%f:%l:%m'])
  unlet b:current_compiler
  setlocal makeprg= errorformat=
  call s:LangTool()
  call s:Check('restore: no compiler', [exists('b:current_compiler'), &l:makeprg, &l:errorformat], [0, '', ''])
endfunction

" :compiler! sets the global options, :compiler the local ones.
function! s:TestCompilerBang() abort
  call s:Reset('bang.txt')
  let [g_mp, g_efm] = [&g:makeprg, &g:errorformat]
  compiler langtool
  call s:Check('compiler: local makeprg', split(&l:makeprg), [shellescape(s:fake), '--language', 'en'])
  call s:Check('compiler: global untouched', [&g:makeprg, &g:errorformat], [g_mp, g_efm])
  compiler! langtool
  call s:Check('compiler!: global makeprg', split(&g:makeprg), [shellescape(s:fake), '--language', 'en'])
  call s:Check('compiler!: global errorformat', &g:errorformat =~# 'Rule ID', 1)
  let [&g:makeprg, &g:errorformat] = [g_mp, g_efm]
endfunction

" A real LanguageTool, if $LANGTOOL_JAR is set.
function! s:TestRealLanguageTool() abort
  call s:Reset('real.txt')
  call writefile(['This is a example sentence.', 'He go to school every days.'], s:tmp . '/real.txt')
  edit!
  unlet g:langtool_cmd
  let g:langtool_jar = $LANGTOOL_JAR
  setlocal spelllang=en_us
  call s:Check('real: no error', s:LangTool(), '')
  let list = getloclist(0)
  call s:Check('real: positions', map(copy(list), '[v:val.lnum, v:val.col, v:val.valid]'), [[1, 9, 1], [2, 4, 1], [2, 23, 1]])
  call s:Check('real: first message', get(get(list, 0, {}), 'text', '') =~# '^EN_A_VS_AN .*\n: Use .an. instead of .a.', 1)
endfunction

let s:tests = ['Unconfigured', 'Cmd', 'Jar', 'JarWithoutJava', 'NoGlobals', 'ParametersUntouched',
      \ 'AutoDetectNotSticky', 'SpelllangWarning', 'UnlistedLanguage', 'LanguageFallback', 'Cjk',
      \ 'SelectLanguage', 'SeveralLanguageOptions', 'SpecialFileName', 'RestoreCompiler', 'CompilerBang']
if !empty($LANGTOOL_JAR)
  call add(s:tests, 'RealLanguageTool')
endif
for s:test in s:tests
  try
    call call('s:Test' . s:test, [])
  catch
    let s:failed += 1
    call add(s:results, 'FAIL ' . s:test . ': ' . v:exception . ' at ' . v:throwpoint)
  endtry
endfor

call add(s:results, s:failed ? s:failed . ' failed' : 'all passed')
call writefile(s:results, s:out)
call delete(s:tmp, 'rf')
execute (s:failed ? 'cquit' : 'qall!')
