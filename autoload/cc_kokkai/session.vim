" cc-kokkai: Session orchestration
" Maintainer: kis9a
" License: MIT

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" --------------------------------------------------------------------------
" State
" --------------------------------------------------------------------------

let s:db = {}

function! s:reset() abort
  if has_key(s:db, 'poll_timer') && s:db.poll_timer != -1
    call cc_kokkai#compat#timer_stop(s:db.poll_timer)
  endif
  let s:db = {
        \ 'active': 0,
        \ 'topic': '',
        \ 'rounds': 3,
        \ 'round': 0,
        \ 'persona_pro': '',
        \ 'persona_con': '',
        \ 'persona_judge': '',
        \ 'buf_pro': -1,
        \ 'buf_con': -1,
        \ 'buf_judge': -1,
        \ 'last_pro': '',
        \ 'last_con': '',
        \ 'poll_timer': -1,
        \ 'init_step': 0,
        \ }
endfunction

call s:reset()

" --------------------------------------------------------------------------
" Public API
" --------------------------------------------------------------------------

" parsed: {topic, rounds, persona_pro, persona_con, persona_judge}
function! cc_kokkai#session#start(parsed) abort
  if s:db.active
    call cc_kokkai#compat#notify('[kokkai] already running. :KokkaiStop first.', 'warn')
    return
  endif

  call s:reset()
  let s:db.active = 1
  let s:db.topic = a:parsed.topic
  let s:db.rounds = a:parsed.rounds
  let s:db.persona_pro = a:parsed.persona_pro
  let s:db.persona_con = a:parsed.persona_con
  let s:db.persona_judge = a:parsed.persona_judge
  let s:db.round = 1
  let s:db.init_step = 1

  " Create layout first, then start AI into pre-created buffers
  let l:layout = cc_kokkai#buffer#setup_layout(a:parsed.topic)
  let s:db.buf_pro = l:layout.buf_pro
  let s:db.buf_con = l:layout.buf_con
  let s:db.buf_judge = l:layout.buf_judge

  " Step 1: pro opening
  let l:prompt = cc_kokkai#prompt#pro_open(s:db.topic, s:db.persona_pro)
  call cc_kokkai#deps#plugin#aistream_run(s:opts_with_buf(l:prompt, s:db.buf_pro))
  call s:wait_then('s:on_init_done')
endfunction

function! cc_kokkai#session#stop() abort
  if !s:db.active
    call cc_kokkai#compat#notify('[kokkai] no active debate.', 'info')
    return
  endif
  if cc_kokkai#deps#plugin#aistream_is_active()
    call cc_kokkai#deps#plugin#aistream_stop()
  endif
  if s:db.poll_timer != -1
    call cc_kokkai#compat#timer_stop(s:db.poll_timer)
  endif
  let s:db.active = 0
  call cc_kokkai#compat#notify('[kokkai] stopped.', 'info')
endfunction

function! cc_kokkai#session#status() abort
  if !s:db.active
    call cc_kokkai#compat#notify('[kokkai] no active debate.', 'info')
    return
  endif
  call cc_kokkai#compat#notify(
        \ printf('[kokkai] round %d/%d | %s', s:db.round, s:db.rounds, s:db.topic),
        \ 'info')
endfunction

" --------------------------------------------------------------------------
" Init sequence: pro -> con -> judge (layout already created)
" --------------------------------------------------------------------------

function! s:on_init_done(_timer) abort
  if !s:db.active | return | endif

  if s:db.init_step == 1
    let s:db.last_pro = cc_kokkai#buffer#capture(s:db.buf_pro)
    let s:db.init_step = 2

    let l:prompt = cc_kokkai#prompt#con_rebuttal(s:db.topic, s:db.last_pro, s:db.persona_con)
    call cc_kokkai#deps#plugin#aistream_run(s:opts_with_buf(l:prompt, s:db.buf_con))
    call s:wait_then('s:on_init_done')

  elseif s:db.init_step == 2
    let s:db.last_con = cc_kokkai#buffer#capture(s:db.buf_con)
    let s:db.init_step = 3

    let l:prompt = cc_kokkai#prompt#judge(
          \ s:db.topic, s:db.last_pro, s:db.last_con, 1, s:db.persona_judge)
    call cc_kokkai#deps#plugin#aistream_run(s:opts_with_buf(l:prompt, s:db.buf_judge))
    call s:wait_then('s:on_init_done')

  elseif s:db.init_step == 3
    let s:db.init_step = 0

    let s:db.round = 2
    if s:db.round > s:db.rounds
      call s:conclude()
    else
      call cc_kokkai#compat#timer_start(500, function('s:round_pro'))
    endif
  endif
endfunction

" --------------------------------------------------------------------------
" Round loop: pro -> con -> judge
" --------------------------------------------------------------------------

function! s:round_pro(_timer) abort
  if !s:db.active | return | endif

  let l:prompt = cc_kokkai#prompt#pro_rebuttal(s:db.topic, s:db.last_con, s:db.persona_pro)
  call s:run_followup(s:db.buf_pro, l:prompt, 's:on_pro_done')
endfunction

function! s:on_pro_done(_timer) abort
  if !s:db.active | return | endif

  let s:db.last_pro = cc_kokkai#buffer#capture(s:db.buf_pro)
  let l:prompt = cc_kokkai#prompt#con_rebuttal(s:db.topic, s:db.last_pro, s:db.persona_con)
  call s:run_followup(s:db.buf_con, l:prompt, 's:on_con_done')
endfunction

function! s:on_con_done(_timer) abort
  if !s:db.active | return | endif

  let s:db.last_con = cc_kokkai#buffer#capture(s:db.buf_con)
  let l:prompt = cc_kokkai#prompt#judge(
        \ s:db.topic, s:db.last_pro, s:db.last_con, s:db.round, s:db.persona_judge)
  call s:run_followup(s:db.buf_judge, l:prompt, 's:on_judge_done')
endfunction

function! s:on_judge_done(_timer) abort
  if !s:db.active | return | endif

  let s:db.round += 1
  if s:db.round > s:db.rounds
    call s:conclude()
  else
    call cc_kokkai#compat#timer_start(500, function('s:round_pro'))
  endif
endfunction

" --------------------------------------------------------------------------
" Conclusion
" --------------------------------------------------------------------------

function! s:conclude() abort
  if !s:db.active | return | endif

  let l:prompt = cc_kokkai#prompt#verdict(s:db.topic, s:db.persona_judge)
  call s:run_followup(s:db.buf_judge, l:prompt, 's:on_concluded')
endfunction

function! s:on_concluded(_timer) abort
  let s:db.active = 0
  call cc_kokkai#compat#notify('[kokkai] closed.', 'info')
endfunction

" --------------------------------------------------------------------------
" Run follow-up in a specific buffer
" --------------------------------------------------------------------------

function! s:run_followup(bufnr, prompt, callback) abort
  call s:focus_buf(a:bufnr)
  call cc_kokkai#deps#plugin#aistream_run(s:opts(a:prompt, 1))
  call s:wait_then(a:callback)
endfunction

" --------------------------------------------------------------------------
" Poll: wait for idle then call callback
" --------------------------------------------------------------------------

function! s:wait_then(callback) abort
  let s:db.poll_count = 0
  let s:db.poll_timer = cc_kokkai#compat#timer_start(
        \ g:cc_kokkai_poll_ms,
        \ function('s:poll_idle', [a:callback]),
        \ {'repeat': -1})
endfunction

function! s:poll_idle(callback, timer_id) abort
  if !s:db.active
    call cc_kokkai#compat#timer_stop(a:timer_id)
    return
  endif
  let s:db.poll_count += 1
  let l:max = g:cc_kokkai_poll_timeout_ms / g:cc_kokkai_poll_ms
  if s:db.poll_count > l:max
    call cc_kokkai#compat#timer_stop(a:timer_id)
    let s:db.poll_timer = -1
    let s:db.active = 0
    call cc_kokkai#compat#notify('[kokkai] timed out waiting for response.', 'error')
    return
  endif
  if cc_kokkai#deps#plugin#aistream_get_state() !=# 'idle'
    return
  endif
  call cc_kokkai#compat#timer_stop(a:timer_id)
  let s:db.poll_timer = -1
  call cc_kokkai#compat#timer_start(300, function(a:callback))
endfunction

" --------------------------------------------------------------------------
" Helpers
" --------------------------------------------------------------------------

function! s:opts(prompt, bang) abort
  let l:o = {
        \ 'prompt': a:prompt,
        \ 'bang': a:bang,
        \ 'max_turns': g:cc_kokkai_max_turns,
        \ }
  if !empty(g:cc_kokkai_model)
    let l:o.model = g:cc_kokkai_model
  endif
  return l:o
endfunction

function! s:opts_with_buf(prompt, bufnr) abort
  let l:o = s:opts(a:prompt, 0)
  let l:o.bufnr = a:bufnr
  return l:o
endfunction

function! s:focus_buf(bufnr) abort
  let l:wins = win_findbuf(a:bufnr)
  if empty(l:wins)
    execute 'sbuffer ' . a:bufnr
  else
    call win_gotoid(l:wins[0])
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
