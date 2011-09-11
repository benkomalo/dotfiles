"===================
" General behaviour
"===================
set nocompatible
set encoding=utf-8

source $VIMRUNTIME/mswin.vim

" Navigate by visual line
noremap j gj
noremap k gk

" put backup files in ~/.vim/baks
"set backup
"set backupdir=~/.vim/baks

" Lexical autocomplete tabwrapper
function InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
        return "\<tab>"
    else
        return "\<c-p>"
    endif
endfunction

inoremap <tab> <c-r>=InsertTabWrapper()<cr>

" Map key to toggle option
function MapToggle(key, opt)
  let cmd = ':set '.a:opt.'! \| set '.a:opt."?\<CR>"
  exec 'nnoremap '.a:key.' '.cmd
  exec 'inoremap '.a:key." \<C-O>".cmd
endfunction
command -nargs=+ MapToggle  call MapToggle(<f-args>)

"===================
" Visuals
"===================

color torte

" show trailing spaces in yellow.
set list
set listchars=tab:\ \ ,trail:\ ,extends:»,precedes:«
highlight SpecialKey ctermbg=Yellow guibg=Yellow

hi Pmenu ctermbg=DarkBlue ctermfg=fg cterm=NONE guibg=DarkBlue guifg=fg gui=none
hi PmenuSel ctermbg=DarkCyan ctermfg=fg cterm=NONE guibg=DarkCyan guifg=fg gui=none

syn on
set nu
set visualbell
set showcmd
set ruler

" Matching characters (conditionally set angle brackets only in certain types)
set showmatch
set matchtime=1
au BufNewFile,BufRead *.html,*.xml set mps+=<:>

"===================
" Search
"===================

set smartcase incsearch ignorecase hlsearch
set incsearch
" Display-altering option toggles
MapToggle <C-n> hlsearch
MapToggle <C-p> ignorecase

"===================
" Window management
"===================

map <C-J> <C-W>j<C-W>_<C-W>k4<C-W>+<C-W>j
map <C-K> <C-W>k<C-W>_<C-W>j4<C-W>+<C-W>k
map <C-h> <C-W>h<C-W>\|<C-W>l<C-W>h
map <C-l> <C-W>l<C-W>\|<C-W>h<C-W>l

"===================
" Coding style
"===================

set shiftwidth=2 tabstop=2 softtabstop=2
set expandtab
set cindent

" 100 col limit
au BufNewFile,BufRead *.vimrc,*.c,*.cc,*.h,*.java,*.js,*.py match TooLong /\%>100v.\+/
hi link TooLong Warning

if has("gui")
  hi Warning guifg=#ffffff guibg=#6e2e2e
else
  hi Warning ctermbg=DarkRed ctermfg=Grey
endif

"===================
" Perforce
"===================

command! -nargs=* -complete=file PEdit :!p4 edit %
command! -nargs=* -complete=file PRevert :!p4 revert %
command! -nargs=* -complete=file PDiff :!p4 diff %

" Fuzzy matcher
source ~/.vim/fuf/plugin/fuf.vim
map <C-S-r> :FufFile<cr>

