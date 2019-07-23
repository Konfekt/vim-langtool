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

populates the location-list with all grammar mistakes found by [LanguageTool](https://languagetool.org/);
these can then be jumped to by the normal mode mappings `[g` and `]g` (where `g` stands for `G`rammar mistake).
The location-list window that lists them can then be opened by `:lwindow`.

To automatically open the location-list window after `LangTool`, add

```vim
autocmd QuickFixCmdPost lmake lwindow
```

to your `vimrc`

Under the hood, `LangTool` passes to `LanguageTool` the spellcheck language used by Vim for the current file, and calls

```vim
compiler langtool
lmake
```

To run `LanguageTool` the in the background by Vim's job feature, instead of `lmake`,

- use `LmakeJob` with [vim-makejob](https://git.danielmoch.com/vim-makejob/about/) installed, and
- use `AsyncRun -auto=make -program=make` with [AsyncRun](https://github.com/skywind3000/asyncrun.vim/) installed.

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

For example, mother tongue can be set and (categories of) rules enabled and disabled by

```vim
let s:enablecategories = 'CREATIVE_WRITING,WIKIPEDIA' .
let s:enable = 'PASSIVE_VOICE,TIRED_INTENSIFIERS'
let s:disable = 'REPEATED_WORDS,REPEATED_WORDS_3X'

let g:langtool_parameters = ' --mothertongue de' .
      \ ' --enablecategories ' . s:enablecategories .
      \ ' --enable ' . s:enable .
      \ ' --disable ' . s:disable
```

to your `vimrc`.
To set the language that LanguageTool will use to that used by Vim to spellcheck, enter

```vim
    let b:langtool_parameters = '--language ' . &l:spelllang
```

in the command line.

# Related Plug-ins

This Vim plug-in is simpler than [vim-LanguageTool](https://github.com/dpelle/vim-LanguageTool) and [vim-grammarous](https://github.com/rhysd/vim-grammarous).
In particular, it lets Vim parse the `LanguageTool` output to stdout via an appropriate value of `&errorformat`;
see `:help errorformat`.
(Whereas both plug-ins implement their proper parser for the deprecated `XML` output format of `LanguageTool`.)

