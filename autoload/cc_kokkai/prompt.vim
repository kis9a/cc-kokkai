" cc-kokkai: Prompt builders
" Maintainer: kis9a
" License: MIT

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" --------------------------------------------------------------------------
" Pro — 賛成
" --------------------------------------------------------------------------

function! cc_kokkai#prompt#pro_open(topic, persona) abort
  let l:p = s:persona(a:persona)
  if g:cc_kokkai_lang ==# 'ja'
    return printf(
          \ 'あなたは討論の賛成派です。%s'
          \ . "\n議題「%s」について、賛成の立場から主張してください。400字以内。",
          \ l:p, a:topic)
  else
    return printf(
          \ 'You are the PRO side in a debate.%s'
          \ . "\nArgue IN FAVOR of: \"%s\". Under 300 words.",
          \ l:p, a:topic)
  endif
endfunction

function! cc_kokkai#prompt#pro_rebuttal(topic, con_text, persona) abort
  let l:prev = s:truncate(a:con_text, 800)
  let l:p = s:persona(a:persona)
  if g:cc_kokkai_lang ==# 'ja'
    return printf(
          \ '反対派から以下の反論がありました。%s再反論してください。400字以内。'
          \ . "\n\n--- 反対派 ---\n%s",
          \ l:p, l:prev)
  else
    return printf(
          \ 'The opposition said the following.%s Rebut. Under 300 words.'
          \ . "\n\n--- Opposition ---\n%s",
          \ l:p, l:prev)
  endif
endfunction

" --------------------------------------------------------------------------
" Con — 反対
" --------------------------------------------------------------------------

function! cc_kokkai#prompt#con_rebuttal(topic, pro_text, persona) abort
  let l:prev = s:truncate(a:pro_text, 800)
  let l:p = s:persona(a:persona)
  if g:cc_kokkai_lang ==# 'ja'
    return printf(
          \ 'あなたは討論の反対派です。%s'
          \ . "\n議題「%s」について、以下の賛成派の主張に反論してください。400字以内。"
          \ . "\n\n--- 賛成派 ---\n%s",
          \ l:p, a:topic, l:prev)
  else
    return printf(
          \ 'You are the CON side in a debate.%s'
          \ . "\nArgue AGAINST \"%s\". Counter this. Under 300 words."
          \ . "\n\n--- PRO ---\n%s",
          \ l:p, a:topic, l:prev)
  endif
endfunction

" --------------------------------------------------------------------------
" Judge — 議長
" --------------------------------------------------------------------------

function! cc_kokkai#prompt#judge(topic, pro_text, con_text, round, persona) abort
  let l:pro = s:truncate(a:pro_text, 600)
  let l:con = s:truncate(a:con_text, 600)
  let l:p = s:persona(a:persona)
  if g:cc_kokkai_lang ==# 'ja'
    return printf(
          \ 'あなたは討論の議長です。%s'
          \ . "\n議題「%s」の第%d回を整理してください。"
          \ . "\n両者の論点をまとめ、次に深めるべき点を指摘。300字以内。"
          \ . "\n\n--- 賛成派 ---\n%s"
          \ . "\n\n--- 反対派 ---\n%s",
          \ l:p, a:topic, a:round, l:pro, l:con)
  else
    return printf(
          \ 'You are the debate judge.%s'
          \ . "\nSummarize round %d on \"%s\". Under 200 words."
          \ . "\n\n--- PRO ---\n%s"
          \ . "\n\n--- CON ---\n%s",
          \ l:p, a:round, a:topic, l:pro, l:con)
  endif
endfunction

function! cc_kokkai#prompt#verdict(topic, persona) abort
  let l:p = s:persona(a:persona)
  if g:cc_kokkai_lang ==# 'ja'
    return printf(
          \ '議題「%s」の全討論が終了しました。%s'
          \ . "\n最終判定を下してください。"
          \ . "\nどちらがより説得力があったか判定し、理由を述べてください。",
          \ a:topic, l:p)
  else
    return printf(
          \ 'All rounds on "%s" are done.%s'
          \ . "\nDeliver the final verdict. Which side was more persuasive and why?",
          \ a:topic, l:p)
  endif
endfunction

" --------------------------------------------------------------------------
" Helpers
" --------------------------------------------------------------------------

function! s:persona(text) abort
  if empty(a:text)
    return ''
  endif
  return "\n" . a:text
endfunction

function! s:truncate(text, max_len) abort
  if strchars(a:text) > a:max_len
    return strcharpart(a:text, 0, a:max_len) . '...'
  endif
  return a:text
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
