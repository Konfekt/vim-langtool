This Vim plug-in collects all grammar mistakes (of the currently open file) found by [LanguageTool](https://languagetool.org/) into the quickfix (or local) list from which they can be jumped to.

# Setup

Download and unpack [LanguageTool](https://languagetool.org/download/), say into the folder `~/LanguageTool`, and add to your `vimrc` the line

```vim
let g:langtool_jar = '~/LanguageTool/languagetool-commandline.jar'
```

where the right-hand side, `~/LanguageTool/languagetool-commandline.jar`, is the path of the file `languagetool-commandline.jar`.

# Usage

The command

```vim
:LangTool
```

populates the location-list with all grammar mistakes found by [LanguageTool](https://languagetool.org/).
The (location-list) window that lists them can then be opened by `:lwindow` and they can be jumped to by `:lN` respectively `:lp`.
(Have a look at [vim-unimpaired](https://github.com/tpope/vim-unimpaired) to use convenient mappings instead).

`LanguageTool` runs in the background by Vim's job feature, provided a custom `:Make` command exists, such as

- that of [vim-dispatch](https://github.com/tpope/vim-dispatch) or,
- with [AsyncRun.vim](https://github.com/skywind3000/asyncrun.vim/) installed (see also [Hints](#hints) below), that defined by

    ```vim
    command! -bang -nargs=* -complete=file -bar Make AsyncRun<bang> -auto=make -program=make
    ```

The (quickfix) window that lists the grammar mistakes can then be opened by `:cwindow` and they can be jumped to by `:cN` respectively `:cp`.

To automatically open the location-list window after `LangTool`, add
`autocmd QuickFixCmdPost lmake lwindow` to your `vimrc`, respectively `autocmd QuickFixCmdPost make cwindow` if the `:Make` command exists.
To automatically run `LangTool` after saving the modifications to a text, mail or markdown file, add to your `vimrc`:

```vim
    autocmd FileType text,mail,markdown autocmd BufWrite <buffer=abuf> LangTool
```

# Configuration

Command-line parameters can be passed to `LanguageTool` by the global variable `g:langtool_parameters` and the buffer-local variable `b:langtool_parameters`.
By default

```vim
let g:langtool_parameters = ''
```

and

```vim
let b:langtool_parameters = '--autoDetect'
```

For example, the mother tongue can be set and (categories of) rules enabled and disabled by adding to your `vimrc`

```vim
let s:enablecategories = 'CREATIVE_WRITING,WIKIPEDIA' .
let s:enable = 'PASSIVE_VOICE,TIRED_INTENSIFIERS'
let s:disable = 'REPEATED_WORDS,REPEATED_WORDS_3X'

let g:langtool_parameters = ' --mothertongue de' .
      \ ' --enablecategories ' . s:enablecategories .
      \ ' --enable ' . s:enable .
      \ ' --disable ' . s:disable
```

`:LangTool` sets the language that LanguageTool will use to that used by Vim to spellcheck by

```vim
    let b:langtool_parameters = '--language ' . &l:spelllang
```

# Hints

If you use [AsyncRun.vim](https://github.com/skywind3000/asyncrun.vim/), add `let g:asyncrun_trim = 1` to your `vimrc` to avoid empty lines in the quickfix list.
Other [options](https://github.com/skywind3000/asyncrun.vim/wiki/Options), such as `g:asyncrun_save` might be of interest.

# Related Plug-ins

This Vim plug-in is simpler than [vim-LanguageTool](https://github.com/dpelle/vim-LanguageTool) and [vim-grammarous](https://github.com/rhysd/vim-grammarous).
In particular, it lets Vim parse the `LanguageTool` output to stdout via an appropriate value of `&errorformat`;
see `:help errorformat`.
(Whereas both cited plug-ins implement their proper parser for the deprecated `XML` output format of `LanguageTool`.)

