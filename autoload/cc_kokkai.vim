" cc-kokkai: Public API
" Maintainer: kis9a
" License: MIT

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" --------------------------------------------------------------------------
" Public API (programmatic entry points)
" --------------------------------------------------------------------------

function! cc_kokkai#start(args_str) abort
  call cc_kokkai#command#start(a:args_str)
endfunction

function! cc_kokkai#stop() abort
  call cc_kokkai#command#stop()
endfunction

function! cc_kokkai#status() abort
  call cc_kokkai#command#status()
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
