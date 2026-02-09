" Snacks Compact Paths Plugin
" Author: Michael Melancon
" Description: Collapses empty folder paths into single character acronyms

if exists("g:loaded_snacks_compact_paths")
  finish
endif
let g:loaded_snacks_compact_paths = 1

" Initialize the plugin with defaults if user hasn't called setup() explicitly
augroup SnacksCompactPaths
  autocmd!
  autocmd VimEnter * ++once lua if not require('snacks-compact-paths')._configured then require('snacks-compact-paths').setup() end
augroup END
