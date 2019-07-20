scriptencoding utf-8

" LICENCE PUBLIQUE RIEN À BRANLER
" Version 1, Mars 2009
"
" Copyright (C) 2009 Sam Hocevar
" 14 rue de Plaisance, 75014 Paris, France
"
" La copie et la distribution de copies exactes de cette licence sont
" autorisées, et toute modification est permise à condition de changer
" le nom de la licence.
"
" CONDITIONS DE COPIE, DISTRIBUTON ET MODIFICATION
" DE LA LICENCE PUBLIQUE RIEN À BRANLER
"
" 0. Faites ce que vous voulez, j’en ai RIEN À BRANLER.

if exists('g:loaded_langtool') || &cp
  finish
endif
let g:loaded_langtool = 1

let s:keepcpo         = &cpo
set cpo&vim
" ------------------------------------------------------------------------------

" Grammar
silent! nnoremap <silent><unique> ]g :<C-U>lnext<CR>
silent! nnoremap <silent><unique> [g :<C-U>lprevious<CR>

command! -bar -bang LangTool silent call langtool#langtool(<bang>0)

" ------------------------------------------------------------------------------
let &cpo= s:keepcpo
unlet s:keepcpo
