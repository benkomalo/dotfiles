"===================
" General behaviour
"===================
set nocompatible
set encoding=utf-8
set autoread
set modelines=0

set wildignore+=*.jpg,*.bmp,*.gif,*.png,*.jpeg
set wildignore+=*.o,*.obj,*.exe,*.dll,*.so
set wildignore+=*.sw?
set wildignore+=*.DS_Store
set wildignore+=*.pyc
set wildignore+=*.apk,*.class,*.jar,*.zip,*.tar,*.gz
set wildmenu

" Disable useless manual lookup
nnoremap K <nop>

" Navigate by visual line (is there a proper way to do this?)
noremap j gj
noremap k gk

" put backup files in ~/.vim/baks
"set backup
"set backupdir=~/.vim/baks

let mapleader = ","
let maplocalleader = "\\"
nnoremap ; :

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

" Install plugins!
call pathogen#infect()

"===================
" Visuals
"===================

syntax enable
if !has('gui_running')
    let g:solarized_termcolors=256
endif
set background=dark
colorscheme solarized
set nu
set visualbell
set showcmd
set showmode
set ruler

let g:syntastic_javascript_checkers=['jsxhint']
let g:syntastic_python_checkers=['pyflakes']

" show trailing spaces in yellow.
set list
set listchars=tab:\ \ ,trail:\ ,extends:»,precedes:«
hi ExtraWhitespace ctermbg=yellow guibg=yellow
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

if has("gui")
  set cursorline
  hi CursorLine ctermbg=DarkBlue ctermfg=NONE cterm=NONE guibg=DarkBlue guifg=NONE gui=none
  autocmd WinEnter * setlocal cursorline
  autocmd WinLeave * setlocal nocursorline
endif

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

" Clean whitespace
map <leader>w  :s/\s\+$//<cr>:let @/=''<CR>

" file regex search
map <leader>s  :%s/

" Easier bracket match
nnoremap <tab> %
vnoremap <tab> %

"===================
" Window management
"===================

map <C-J> <C-W>j<C-W>_<C-W>k4<C-W>+<C-W>j
map <C-K> <C-W>k<C-W>_<C-W>j4<C-W>+<C-W>k
map <C-h> <C-W>h<C-W>\|<C-W>l<C-W>h
map <C-l> <C-W>l<C-W>\|<C-W>h<C-W>l

nnoremap <leader>t :NERDTreeToggle<CR>

"===================
" Coding style
"===================

set shiftwidth=4 tabstop=4 softtabstop=4

let g:indent = '4'
function ToggleTab()
    if g:indent == '4'
        set shiftwidth=2 tabstop=2 softtabstop=2
        echo "Using 2 space indent"
        let g:indent = '2'
    else
        set shiftwidth=4 tabstop=4 softtabstop=4
        echo "Using 4 space indent"
        let g:indent = '4'
    endif
endfunction
map <leader>e :exec ToggleTab()<cr><cr>
set expandtab
set cindent

filetype plugin on

" Hive pseudo-support
au BufRead,BufNewFile *.q set filetype=sql

" 80 col limit
au BufNewFile,BufRead *.vimrc,*.c,*.cc,*.h,*.java,*.js,*.py,*.q match TooLong /\%>80v.\+/
hi link TooLong Warning
set colorcolumn=80

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
let g:fuf_file_exclude = '\v\~$|\.(o|exe|dll|bak|orig|rej|handlebars\.js|sw[po])$|(^|[/\\])\.(hg|git|bzr)($|[/\\])'
map <leader>r :FufFile<cr>

" From Steve Losh (https://bitbucket.org/sjl/dotfiles/src/tip/vim/.vimrc):
" Split/Join {{{
"
" Basically this splits the current line into two new ones at the cursor position,
" then joins the second one with whatever comes next.
"
" Example:                      Cursor Here
"                                    |
"                                    V
" foo = ('hello', 'world', 'a', 'b', 'c',
"        'd', 'e')
"
"            becomes
"
" foo = ('hello', 'world', 'a', 'b',
"        'c', 'd', 'e')
"
" Especially useful for adding items in the middle of long lists/tuples in Python
" while maintaining a sane text width.
nnoremap K h/[^ ]<cr>"zd$jyyP^v$h"zpJk:s/\v +$//<cr>:noh<cr>j^
" }}}

function! s:HgBlame()
    let fn = expand('%:p')

    wincmd v
    wincmd h
    edit __hgblame__
    vertical resize 28

    setlocal scrollbind winfixwidth nolist nowrap nonumber buftype=nofile ft=none

    normal ggdG
    execute "silent r!hg blame -undq " . fn
    normal ggdd
    execute ':%s/\v:.*$//'

    wincmd l
    setlocal scrollbind
    syncbind
endf
command! -nargs=0 HgBlame call s:HgBlame()
nnoremap <leader>hb :HgBlame<cr>

function! s:HgDiff()
    diffthis

    let fn = expand('%:p')
    let ft = &ft

    wincmd v
    edit __hgdiff_orig__

    setlocal buftype=nofile

    normal ggdG
    execute "silent r!hg cat --rev . " . fn
    normal ggdd

    execute "setlocal ft=" . ft

    diffthis
    diffupdate
endf
command! -nargs=0 HgDiff call s:HgDiff()
nnoremap <leader>hd :HgDiff<cr>
