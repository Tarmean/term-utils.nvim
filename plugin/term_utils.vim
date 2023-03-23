" if exists("g:open_terms")
"     finish
" endif

let g:open_terms = {}
let g:current_tag = v:false



command! -bang -nargs=1 TermTag call s:set_tag_for_buf("<bang>", <q-args>)
function! s:set_tag_for_buf(bang, tag)
    if &buftype != "terminal"
        throw "set_tag_for_buf only makes sense for terminal buffers"
    endif
    let old_tag = v:false
    let buf_nr = bufnr('')
    if a:bang != "!"
        for k in keys(g:open_terms)
            if g:open_terms[k] == l:buf_nr
                unlet g:open_terms[k]
            endif
        endfor
    endif
    let g:open_terms[a:tag] = l:buf_nr
endfunc

function! term_utils#guess_term_tag()
    if s:get_term_for(g:current_tag)
        return g:current_tag
    endif
    return "temp"
endfunc
function s:get_term_for(tag)
    if !exists("g:open_terms[a:tag]") || !buflisted(g:open_terms[a:tag])
        return v:false
    endif
    let g:current_tag = a:tag
    return g:open_terms[a:tag]
endfunc
function s:set_term_for(tag, buf)
    let g:current_tag = a:tag
    let g:open_terms[a:tag] = a:buf
endfunc
command! -nargs=? -bang TermAutoreload call Autoreload("<bang>", "<args>")
function! Autoreload(disabled, command)
    augroup AutoReloadTerm
        au!
        if (""==a:disabled)
           exec "au BufWritePost <buffer> call s:Reload('" . a:command . "')"
        endif
    augroup END
endfunc
function! s:Reload(arg)
     let l:arg = a:arg == "" ? ":r" : a:arg
    call feedkeys(":call term_utils#term_toggle('insert', 'repl', v:false)\<cr>" . l:arg . "\<cr>\<C-\>\<C-n>:call term_utils#goto_old_win(v:false)\<cr>", 'n')
endfu nc

command! -nargs=? -complete=customlist,s:open_term_tags Term call s:open_term_with_tag('root', <q-args>)

command! -nargs=? -complete=customlist,s:open_term_tags TermCWD call s:open_term_with_tag('current', <q-args>)

command! -nargs=? -complete=customlist,s:open_term_tags TermLocal call s:open_term_with_tag('local', <q-args>)
function s:open_term_tags(a, b, c)
    for k in keys(g:open_terms)
        if !bufexists(g:open_terms[l:k])
            unlet g:open_terms[l:k]
        endif
    endfor
    return keys(g:open_terms)
endfunc
func! s:open_term_with_tag(where, argss)
    let argss = a:argss == "" ? "temp" : a:argss
    let exploded = split(l:argss, " ")
    let first = l:exploded[0]
    let rest = l:argss[len(l:first):]
    call s:open_term(a:where, l:rest, l:first)
endfunc
func! s:switch_to(tag)
    let target = s:get_term_for(a:tag)
    if l:target != v:false
        let g:old_win = win_getid()
        call s:jump_to_buf(l:target)
        return v:true
    endif
    return v:false
endfunc
func! s:open_term(where, args, tag)
    if s:switch_to(a:tag)
        norm i
        return
    endif
    let g:old_win = win_getid()
    let l:oldcd = getcwd()
    if a:where == 'root'
        call s:in_root()
    elseif a:where == 'local'
        call s:in_local()
    endif

    if has('nvim')
        vsplit
        let prefix = ""
    else
        let prefix = "vert "
    endif
    if (has('unix'))
        exec prefix."term" 
    else
        exec prefix."term powershell"
    endif
    if (type(a:args) == type("") && a:args != "")
        call feedkeys("i" . a:args . "Ö")
    endif
    exec "cd " . l:oldcd
    call s:set_term_for(a:tag, bufnr("%"))
endfunc
func! term_utils#goto_old_win(close_cur)
    let [tab, win] = win_id2tabwin(g:old_win)
    let close = a:close_cur && (tabpagenr() == l:tab)
    if close
        let cur_term_buf = s:get_term_for(g:current_tag)
        let term_wins = l:cur_term_buf ? win_findbuf(l:cur_term_buf) : []
        for i in term_wins
            call win_gotoid(i)
            wincmd c
        endfor
    endif
    if l:tab != 0
        exec "norm! " . l:tab . "gt"
        exec l:win . "wincmd w"
    endif
endfunc

func! s:cur_term(tag)
    vs
    call s:switch_to(a:tag)
endfunc
func! s:jump_to_buf(buf)
        let g:old_win = win_getid()
        let wins = win_findbuf(a:buf)
        if (len(l:wins) > 0)
            call win_gotoid(l:wins[0])
        else
            vsplit
            exec "b ". a:buf
        endif
endfunc
func! term_utils#term_toggle(arg, tag, close, where="root")
    let cur = s:get_term_for(a:tag)
    if cur != v:false
        if(l:cur == bufnr("%"))
            call term_utils#goto_old_win(a:close)
            return
        endif
        call s:jump_to_buf(l:cur)
    else
        let g:old_win = win_getid()
        call s:open_term(a:where, 0, a:tag)
        call s:set_term_for(a:tag, bufnr("%"))
    endif
    if has('nvim') && a:arg == 'insert' 
        norm! i 
    endif
endfunc

" command! -nargs=* InRoot call s:in_root(<q-args>)
function! s:in_root()
  let old = getcwd()
  let root = FugitiveExtractGitDir(expand('%:p'))
  if root != ""
      exec "lcd " . root . "/.."
  endif
  " exec a:e
  " exec "cd " . l:old
endfunc
function! s:in_local()
  exec "lcd " . expand('%:h')
endfunc
