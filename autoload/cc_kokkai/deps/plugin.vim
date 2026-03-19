" cc-kokkai: External plugin dependency adapter (aistream.vim)
" Maintainer: kis9a
" License: MIT

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" --------------------------------------------------------------------------
" aistream.vim adapter
"
" All aistream calls go through here. Provides:
"   - Existence check before calling
"   - Stub injection point for testing (g:cc_kokkai_aistream_stub)
"
" Note: exists('*autoload#func') returns 0 until the autoload file is
" sourced, so we check runtimepath for the file instead.
" --------------------------------------------------------------------------

function! s:has_aistream() abort
  return !empty(globpath(&runtimepath, 'autoload/aistream.vim'))
endfunction

function! cc_kokkai#deps#plugin#aistream_run(opts) abort
  if s:use_stub('run')
    return call(g:cc_kokkai_aistream_stub, ['run', a:opts])
  endif
  if !s:has_aistream()
    call cc_kokkai#compat#notify('[kokkai] aistream.vim is required but not found.', 'error')
    return
  endif
  call aistream#run(a:opts)
endfunction

function! cc_kokkai#deps#plugin#aistream_stop() abort
  if s:use_stub('stop')
    return call(g:cc_kokkai_aistream_stub, ['stop', {}])
  endif
  if s:has_aistream()
    call aistream#stop()
  endif
endfunction

function! cc_kokkai#deps#plugin#aistream_is_active() abort
  if s:use_stub('is_active')
    return call(g:cc_kokkai_aistream_stub, ['is_active', {}])
  endif
  if !s:has_aistream()
    return 0
  endif
  return aistream#internal#session#is_active()
endfunction

function! cc_kokkai#deps#plugin#aistream_get_state() abort
  if s:use_stub('get_state')
    return call(g:cc_kokkai_aistream_stub, ['get_state', {}])
  endif
  if !s:has_aistream()
    return 'idle'
  endif
  return aistream#internal#session#get_state()
endfunction

" --------------------------------------------------------------------------
" Stub injection (for testing without aistream.vim)
"
" Usage:
"   let g:cc_kokkai_aistream_stub = function('MyStub')
"   " MyStub(action, opts) where action is 'run'|'stop'|'is_active'|'get_state'
" --------------------------------------------------------------------------

function! s:use_stub(action) abort
  return exists('g:cc_kokkai_aistream_stub')
        \ && type(g:cc_kokkai_aistream_stub) == type(function('tr'))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
