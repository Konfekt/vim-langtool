This Vim plug-in lists all grammar mistakes found by [LanguageTool](https://languagetool.org/) in the quickfix (or local) list.

# Setup

Download and unpack [LanguageTool](https://languagetool.org/download/), say into the folder `~/LanguageTool`, and add to your `vimrc` the line

```vim
let g:langtool_jar = '~/LanguageTool/languagetool-commandline.jar'
```

where the right-hand side, `~/LanguageTool/languagetool-commandline.jar`, is the path of the file `languagetool-commandline.jar`.

# Usage

The command

```vim
LangTool
```

populates the location-list with all grammar mistakes found by [LanguageTool](https://languagetool.org/);
these can then be jumped to by the normal mode mappings `[g` and `]g` (where `g` stands for `G`rammar mistake).
The location-list window that lists them can then be opened by `lwindow`.

To automatically open the location-list window after `LangTool`, add

```vim
autocmd QuickFixCmdPost lmake lwindow
```

to your `vimrc`

Under the hood, `LangTool` passes to Language Tool the spellcheck language used by Vim for the current file, and calls

```vim
compiler langtool
lmake
```

Instead of `lmake`, you could use , if, for example, [AsyncRun](https://github.com/skywind3000/asyncrun.vim/) is installed,

```vim
compiler langtool
AsyncRun -auto=make -program=make
```

to run `Language Tool` the in the background.

# Configuration

Parameters, buffer-local and global, can be passed by the global variable `g:langtool_parameters` and the buffer-local variable `b:langtool_parameters`.
By default

```vim
let g:langtool_parameters = ''
```

and

```vim
let b:langtool_parameters = '--autoDetect'
```

For example, (categories of) rules can be enabled and disabled by

```vim
let s:enablecategories = 'CREATIVE_WRITING,WIKIPEDIA' .
let s:enable = 'PASSIVE_VOICE,TIRED_INTENSIFIERS'
let s:disable = 'REPEATED_WORDS,REPEATED_WORDS_3X'

let g:langtool_parameters =
      \ '--enablecategories ' . s:enablecategories . ' ' .
      \ '--enable ' . s:enable . ' ' .
      \ '--disable ' . s:disable
```

to your `vimrc`.
To set the language that LanguageTool will use to that used by Vim to spellcheck, enter

```vim
    let b:langtool_parameters = '--lang' . &l:spelllang
```

in the command line.

# Related Plug-ins

This Vim plug-in is simpler than [vim-LanguageTool](https://github.com/dpelle/vim-LanguageTool) and [vim-grammarous](https://github.com/rhysd/vim-grammarous).
In particular, it lets Vim parse the `LanguageTool` output to stdout via an appropriate value of `&errorformat`;
see `:help errorformat`.
(Instead, both plug-ins implement their proper parser for the deprecated `XML` output format of `LanguageTool`.)

