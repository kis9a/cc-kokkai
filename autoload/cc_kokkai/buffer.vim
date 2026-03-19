" cc-kokkai: Buffer management
" Maintainer: kis9a
" License: MIT

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

" --------------------------------------------------------------------------
" Capture last response from an AIStream buffer
" --------------------------------------------------------------------------

function! cc_kokkai#buffer#capture(bufnr) abort
  if a:bufnr <= 0 || !bufexists(a:bufnr)
    return ''
  endif

  let l:lines = getbufline(a:bufnr, 1, '$')

  " Find the last prompt line "> ..." — response starts after it.
  " Prompt continuation lines are indented with two spaces; skip those too.
  let l:start = 0
  for l:i in range(len(l:lines) - 1, 0, -1)
    if l:lines[l:i] =~# '^> '
      let l:start = l:i + 1
      break
    endif
  endfor
  while l:start < len(l:lines) && l:lines[l:start] =~# '^  '
    let l:start += 1
  endwhile

  let l:out = l:lines[l:start :]
  while !empty(l:out) && l:out[0] =~# '^\s*$'
    call remove(l:out, 0)
  endwhile
  while !empty(l:out) && l:out[-1] =~# '^\s*$'
    call remove(l:out, -1)
  endwhile

  return join(l:out, "\n")
endfunction

" --------------------------------------------------------------------------
" Arrange 3 buffers in split layout
"
"   +--------+--------+
"   |  pro   |  con   |
"   +--------+--------+
"   |     judge       |
"   +-----------------+
" --------------------------------------------------------------------------

" Create the 3-pane layout in a new tab with empty buffers.
" Returns {buf_pro, buf_con, buf_judge}.
function! cc_kokkai#buffer#setup_layout(topic) abort
  tabnew

  " Pro (top-left) — current buffer after tabnew
  enew
  setlocal buftype=nofile bufhidden=hide noswapfile
  let l:buf_pro = bufnr('%')

  " Con (top-right)
  vsplit
  enew
  setlocal buftype=nofile bufhidden=hide noswapfile
  let l:buf_con = bufnr('%')

  " Judge (bottom)
  botright split
  enew
  setlocal buftype=nofile bufhidden=hide noswapfile
  let l:buf_judge = bufnr('%')
  resize 12

  " Focus pro pane
  wincmd t

  return {'buf_pro': l:buf_pro, 'buf_con': l:buf_con, 'buf_judge': l:buf_judge}
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
