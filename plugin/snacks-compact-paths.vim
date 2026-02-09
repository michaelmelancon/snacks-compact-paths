" Snacks Compact Paths Plugin
" Author: Michael Melancon
" Description: Collapses empty folder paths into single character acronyms

if exists("g:loaded_snacks_compact_paths")
  finish
endif
let g:loaded_snacks_compact_paths = 1

" Default configuration
if !exists("g:snacks_compact_paths_config")
  let g:snacks_compact_paths_config = {
    \ 'min_path_length': 3,
    \ 'preserve_dirs': ['src', 'lib', 'include', 'test', 'tests', 'docs', 'assets', 'public'],
    \ 'acronym_style': 'first',
    \ 'enabled': 1
    \ }
endif

" Initialize the plugin
augroup SnacksCompactPaths
  autocmd!
  autocmd VimEnter * lua require('snacks-compact-paths').setup()
augroup END
