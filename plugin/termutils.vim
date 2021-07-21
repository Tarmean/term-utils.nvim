if !exists("g:open_terms")
    let g:open_terms = {}
    let g:current_tag = v:false
endif




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

function! termutils#guess_term_tag()
    if s:get_term_for(g:current_tag)
        return g:current_tag
    endif
    return "temp"
endfunc
function s:get_term_for(tag)
    if !exists("g:open_terms[a:tag]") || !bufexists(g:open_terms[a:tag])
        return v:false
    endif
    let g:current_tag = a:tag
    return g:open_terms[a:tag]
endfunc
function s:set_term_for(tag, buf)
    let g:current_tag = a:tag
    let g:open_terms[a:tag] = a:buf
endfunc
command! -nargs=? -bang Autoreload call Autoreload("<bang>", "<args>")
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
    call feedkeys(":call termutils#term_toggle('insert', 'repl')\<cr>" . l:arg . "\<cr>\<C-\>\<C-n>:call termutils#goto_old_win(v:false)\<cr>", 'n')
endfunc

command! -bang -nargs=? RTerm call s:root_term("<bang>", <q-args>)
func! s:root_term(bang, arg)
    vsplit
    exec "InRoot Term! " . a:arg
endfunc


command! -bang -nargs=? -complete=customlist,s:open_term_tags Term call s:open_term_with_tag("<bang>", <q-args>)
function s:open_term_tags(a, b, c)
    for k in keys(g:open_terms)
        if !bufexists(g:open_terms[l:k])
            unlet g:open_terms[l:k]
        endif
    endfor
    return keys(g:open_terms)
endfunc
func! s:open_term_with_tag(bang, argss)
    if len(a:argss) == 0
        let a:argss = "temp"
    endif
    let exploded = split(a:argss, " ")
    let first = l:exploded[0]
    let rest = a:argss[len(l:first):]
    call s:open_term(a:bang, l:rest, l:first)
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
func! s:open_term(bang, args, tag)
    if s:switch_to(a:tag)
        norm i
        return
    endif
    let g:old_win = win_getid()
    vsplit
    let l:oldcd = getcwd()
    if a:bang == ""
        exec "cd " . expand("%:p:h")
    end
    if (has('unix'))
        exec "term zsh " 
    else
        exec "term powershell"
    endif
    if (type(a:args) == type("") && a:args != "")
        call feedkeys("i" . a:args . "Ö")
    endif
    exec "cd " . l:oldcd
    call s:set_term_for(a:tag, bufnr("%"))
endfunction
func! termutils#goto_old_win(close_cur)
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
func! termutils#term_toggle(arg, tag)
    let cur = s:get_term_for(a:tag)
    if cur != v:false
        if(l:cur == bufnr("%"))
            call termutils#goto_old_win(v:false)
            return
        endif
        call s:jump_to_buf(l:cur)
    else
        let g:old_win = win_getid()
        call s:open_term("", 0, a:tag)
        call s:set_term_for(a:tag, bufnr("%"))
    endif
    if a:arg == 'insert' 
        norm! i 
    endif
endfunc

