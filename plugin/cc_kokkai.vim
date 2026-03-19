" cc-kokkai: AI Debate Simulator with 3 Persistent Sessions
" Maintainer: kis9a
" License: MIT

scriptencoding utf-8

if exists('g:loaded_cc_kokkai')
  finish
endif
let g:loaded_cc_kokkai = 1

let s:save_cpo = &cpo
set cpo&vim

" --------------------------------------------------------------------------
" Default options
" --------------------------------------------------------------------------

if !exists('g:cc_kokkai_max_rounds')
  let g:cc_kokkai_max_rounds = 3
endif
if !exists('g:cc_kokkai_model')
  let g:cc_kokkai_model = ''
endif
if !exists('g:cc_kokkai_max_turns')
  let g:cc_kokkai_max_turns = 1
endif
if !exists('g:cc_kokkai_poll_ms')
  let g:cc_kokkai_poll_ms = 500
endif
if !exists('g:cc_kokkai_poll_timeout_ms')
  let g:cc_kokkai_poll_timeout_ms = 120000
endif
if !exists('g:cc_kokkai_lang')
  let g:cc_kokkai_lang = 'ja'
endif

" Custom persona prompts (prepended to system prompt for each role)
" Example: let g:cc_kokkai_persona_pro = '関西弁の熱血議員'
if !exists('g:cc_kokkai_persona_pro')
  let g:cc_kokkai_persona_pro = ''
endif
if !exists('g:cc_kokkai_persona_con')
  let g:cc_kokkai_persona_con = ''
endif
if !exists('g:cc_kokkai_persona_judge')
  let g:cc_kokkai_persona_judge = ''
endif

" --------------------------------------------------------------------------
" Commands
" --------------------------------------------------------------------------

" :Kokkai [-r N] [-pro PERSONA] [-con PERSONA] [-judge PERSONA] TOPIC
command! -nargs=+ Kokkai call cc_kokkai#command#start(<q-args>)
command! -nargs=0 KokkaiStop call cc_kokkai#command#stop()
command! -nargs=0 KokkaiStatus call cc_kokkai#command#status()

let &cpo = s:save_cpo
unlet s:save_cpo
