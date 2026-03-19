" cc-kokkai: Vim/Neovim compatibility layer
" Maintainer: kis9a
" License: MIT

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" --------------------------------------------------------------------------
" Environment detection
" --------------------------------------------------------------------------

function! cc_kokkai#compat#has_nvim() abort
  return has('nvim')
endfunction

function! cc_kokkai#compat#has_timers() abort
  return has('timers')
endfunction

" --------------------------------------------------------------------------
" Notification (Vim: echohl/echomsg, Neovim: nvim_notify if available)
" --------------------------------------------------------------------------

function! cc_kokkai#compat#notify(msg, level) abort
  if exists('*nvim_notify')
    let l:lv = a:level ==# 'error' ? 4 : a:level ==# 'warn' ? 3 : 2
    call nvim_notify(a:msg, l:lv, {})
  else
    if a:level ==# 'error'
      echohl ErrorMsg | echomsg a:msg | echohl None
    elseif a:level ==# 'warn'
      echohl WarningMsg | echomsg a:msg | echohl None
    else
      echo a:msg
    endif
  endif
endfunction

" --------------------------------------------------------------------------
" Timers (Vim 8.0+ / Neovim: native, fallback: immediate execution)
" --------------------------------------------------------------------------

function! cc_kokkai#compat#timer_start(ms, callback, ...) abort
  let l:opts = a:0 > 0 ? a:1 : {}
  if has('timers')
    return timer_start(a:ms, a:callback, l:opts)
  endif
  " Fallback: execute immediately (no async)
  call call(a:callback, [-1])
  return -1
endfunction

function! cc_kokkai#compat#timer_stop(id) abort
  if a:id != -1 && has('timers')
    call timer_stop(a:id)
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
