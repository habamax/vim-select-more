if exists('g:loaded_select_more') || !exists('g:loaded_select')
    finish
endif
let g:loaded_select_more = 1

nnoremap <silent> <Plug>(SelectHighlight) :Select highlight<CR>
nnoremap <silent> <Plug>(SelectCmdHistory) :Select cmdhistory<CR>
nnoremap <silent> <Plug>(SelectBufDef) :Select bufdef<CR>


let g:select_info = get(g:, "select_info", {})

"""
""" Select highlight
"""
let g:select_info.highlight = {}
let g:select_info.highlight.data = {-> s:get_highlights()}
let g:select_info.highlight.sink = {
            \ "transform": {_, v -> matchstr(v, '^\S*')},
            \ "action": {v -> s:highlight_sink(v)}
            \ }
let g:select_info.highlight.highlight = {->
            \ s:get_highlights()
            \ ->reduce(
            \   {acc, val ->
            \       extend(acc, {matchstr(val, '^\S*'): [matchstr(val, '^\S*')..'\s*\zsxxx\ze\s*', matchstr(val, '^\S*')]}
            \  )}, {})}


"""
""" Select cmdhistory
"""
let g:select_info.cmdhistory = {}
let g:select_info.cmdhistory.data = {-> range(1, histnr("cmd"))
            \ ->map({i -> printf("%*d: %s", len(histnr("cmd")), i, histget("cmd", i))})
            \ ->filter({_, v -> v !~ '^\s*\d\+:\s*$'})
            \ ->reverse()
            \ }
let g:select_info.cmdhistory.sink = {
            \ "transform": {_, v -> matchstr(v, '^\s*\d\+:\s*\zs.*$')},
            \ "action": {v -> feedkeys(':'..v, "nt")}
            \ }
let g:select_info.cmdhistory.highlight = {"PrependLineNr": ['^\(\s*\d\+:\)', 'LineNr']}


"""
""" Helpers
"""
func! s:get_highlights()
    redir => l:hl
    silent highlight
    redir END
    return filter(split(l:hl, '\n'), {i, v -> v !~ 'Select.*'})
endfunc


func! s:highlight_sink(val)
    redir => l:hl
    exe "silent highlight "..a:val
    redir END
    let @" = trim(substitute(l:hl, '\s*xxx\s*', ' ', ''))
    echo @" 'is copied to unnamed register'
endfunc
