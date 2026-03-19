" cc-kokkai: Command implementation (arg parsing / validation)
" Maintainer: kis9a
" License: MIT

scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpoptions&vim

" --------------------------------------------------------------------------
" Command entry points (called from plugin/)
" --------------------------------------------------------------------------

function! cc_kokkai#command#start(args_str) abort
  let l:parsed = cc_kokkai#command#parse_args(a:args_str)
  if empty(l:parsed.topic)
    call cc_kokkai#compat#notify('[kokkai] topic required.', 'error')
    return
  endif
  call cc_kokkai#session#start(l:parsed)
endfunction

function! cc_kokkai#command#stop() abort
  call cc_kokkai#session#stop()
endfunction

function! cc_kokkai#command#status() abort
  call cc_kokkai#session#status()
endfunction

" --------------------------------------------------------------------------
" Argument parser
"
" :Kokkai [-r N] [-pro PERSONA] [-con PERSONA] [-judge PERSONA] TOPIC
"
" Returns: {topic, rounds, persona_pro, persona_con, persona_judge}
" --------------------------------------------------------------------------

function! cc_kokkai#command#parse_args(args_str) abort
  let l:tokens = s:tokenize(a:args_str)
  let l:result = {
        \ 'topic': '',
        \ 'rounds': g:cc_kokkai_max_rounds,
        \ 'persona_pro': g:cc_kokkai_persona_pro,
        \ 'persona_con': g:cc_kokkai_persona_con,
        \ 'persona_judge': g:cc_kokkai_persona_judge,
        \ }
  let l:rest = []
  let l:i = 0

  while l:i < len(l:tokens)
    let l:tok = l:tokens[l:i]

    if l:tok ==# '-r' && l:i + 1 < len(l:tokens)
      let l:i += 1
      let l:result.rounds = max([1, str2nr(l:tokens[l:i])])
    elseif l:tok ==# '-pro' && l:i + 1 < len(l:tokens)
      let l:i += 1
      let l:result.persona_pro = l:tokens[l:i]
    elseif l:tok ==# '-con' && l:i + 1 < len(l:tokens)
      let l:i += 1
      let l:result.persona_con = l:tokens[l:i]
    elseif l:tok ==# '-judge' && l:i + 1 < len(l:tokens)
      let l:i += 1
      let l:result.persona_judge = l:tokens[l:i]
    elseif l:tok ==# '--'
      let l:rest += l:tokens[l:i + 1 :]
      break
    else
      call add(l:rest, l:tok)
    endif

    let l:i += 1
  endwhile

  let l:result.topic = join(l:rest, ' ')
  return l:result
endfunction

" --------------------------------------------------------------------------
" Tokenizer (respects single/double quotes)
" --------------------------------------------------------------------------

function! s:tokenize(str) abort
  let l:tokens = []
  let l:current = ''
  let l:i = 0
  let l:len = len(a:str)

  while l:i < l:len
    let l:c = a:str[l:i]
    if l:c ==# '"' || l:c ==# "'"
      let l:quote = l:c
      let l:i += 1
      while l:i < l:len && a:str[l:i] !=# l:quote
        let l:current .= a:str[l:i]
        let l:i += 1
      endwhile
    elseif l:c ==# ' ' || l:c ==# "\t"
      if !empty(l:current)
        call add(l:tokens, l:current)
        let l:current = ''
      endif
    else
      let l:current .= l:c
    endif
    let l:i += 1
  endwhile

  if !empty(l:current)
    call add(l:tokens, l:current)
  endif
  return l:tokens
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
