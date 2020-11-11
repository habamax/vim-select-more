if exists('g:loaded_select_more') || !exists('g:loaded_select')
    finish
endif
let g:loaded_select_more = 1

nnoremap <silent> <Plug>(SelectHighlight) :Select highlight<CR>
nnoremap <silent> <Plug>(SelectCmdHistory) :Select cmdhistory<CR>
nnoremap <silent> <Plug>(SelectBufDef) :Select bufdef<CR>
nnoremap <silent> <Plug>(SelectCmd) :Select command<CR>
nnoremap <silent> <Plug>(SelectColors) :Select colors<CR>
nnoremap <silent> <Plug>(SelectHelp) :Select help<CR>
nnoremap <silent> <Plug>(SelectBufLine) :Select bufline<CR>


let g:select_info = get(g:, "select_info", {})


"""
""" Select colors
"""
let g:select_info.colors = {}
let g:select_info.colors.data = {-> s:get_colorscheme_list()}
let g:select_info.colors.sink = "colorscheme %s"


"""
""" Select help
"""
let g:select_info.help = {}
let g:select_info.help.data = {"cmd": {-> s:get_helptags()}}
let g:select_info.help.sink = "help %s"


"""
""" Select bufline
"""
let g:select_info.bufline = {}
let g:select_info.bufline.data = {_, v ->
            \ getbufline(v.bufnr, 1, "$")->map({i, ln -> printf("%*d: %s", len(line('$', v.winid)), i+1, ln)})
            \ }
let g:select_info.bufline.sink = {
            \ "transform": {_, v -> matchstr(v, '^\s*\zs\d\+')},
            \ "action": "normal! %sG"
            \ }
let g:select_info.bufline.highlight = {"PrependLineNr": ['^\(\s*\d\+:\)', 'LineNr']}



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
""" Select command
"""
let g:select_info.command = {}
let g:select_info.command.data = {-> getcompletion('', 'command')}
let g:select_info.command.sink = {"action": {v -> feedkeys(':'..v, 'n')}}


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

"" Colorscheme list.
"" * remove current colorscheme name  from the list of all sorted colorschemes.
"" * put current colorscheme name on top of the colorscheme list.
"" Thus current colorscheme is initially preselected.
func! s:get_colorscheme_list() abort
    let colors_name = get(g:, "colors_name", "default")
    return [colors_name] + filter(getcompletion('', 'color'), {_, v -> v != colors_name})
endfunc


"" List of all help tags/topics.
"" Uses ripgrep.
func! s:get_helptags() abort
    let l:help = split(globpath(&runtimepath, 'doc/tags', 1), '\n')
    return 'rg ^[^[:space:]]+ -No --no-heading --no-filename '..join(map(l:help, {_,v -> fnameescape(v)}))
endfunc


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
