if !exists('g:loaded_select')
    finish
endif

nnoremap <silent> <Plug>(SelectHighlight) :Select highlight<CR>
nnoremap <silent> <Plug>(SelectCmdHistory) :Select cmdhistory<CR>
nnoremap <silent> <Plug>(SelectBufDef) :Select bufdef<CR>
nnoremap <silent> <Plug>(SelectCmd) :Select command<CR>
nnoremap <silent> <Plug>(SelectColors) :Select colors<CR>
nnoremap <silent> <Plug>(SelectHelp) :Select help<CR>
nnoremap <silent> <Plug>(SelectBufLine) :Select bufline<CR>
nnoremap <silent> <Plug>(SelectBufTag) :Select buftag<CR>
nnoremap <silent> <Plug>(SelectGitFile) :Select gitfile<CR>
nnoremap <silent> <Plug>(SelectToDo) :Select todo<CR>



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
let g:select_info.help.data = {"job": {-> s:get_helptags()}}
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
let g:select_info.bufline.highlight = {"PrependLineNr": ['^\(\s*\d\+:\)', 'Identifier']}



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
let g:select_info.cmdhistory.highlight = {"PrependLineNr": ['^\(\s*\d\+:\)', 'Identifier']}


"""
""" Select buftag
"""
if executable("ctags")
    let g:select_info.buftag = {}
    let g:select_info.buftag.data = {
                \ "transform_output": {v -> s:transform_tag(v)},
                \ "job": {_, init_buf -> s:get_btags(bufname(init_buf.bufnr))}}
    let g:select_info.buftag.sink = {
            \ "transform": {_, v -> matchstr(v, '^\s*\zs\d\+')},
            \ "action": "normal! %sG"
            \}
    let g:select_info.buftag.highlight = {
                \ "PrependLineNr": ['^\(\s*\d\+:\)', 'Identifier'],
                \ "TagType": ['\t\a\t', 'Type'],
                \ }
endif


"""
""" Select gitfile
"""
if executable("git")
    let g:select_info.gitfile = {}
    let g:select_info.gitfile.data = {"job": "git ls-files"}
    let g:select_info.gitfile.sink = {
                \ "transform": {p, v -> fnameescape(p..v)},
                \ "action": "edit %s",
                \ "action2": "split %s",
                \ "action3": "vsplit %s",
                \ "action4": "tab split %s"
                \ }
    let g:select_info.gitfile.highlight = {"DirectoryPrefix": ['\(\s*\d\+:\)\?\zs.*[/\\]\ze.*$', 'Comment']}
    let g:select_info.gitfile.prompt = "Git File> "
endif


"""
""" Select todo
"""
if executable('rg')
    let g:select_info.todo = {}
    let g:select_info.todo.data = {"job": 'rg --vimgrep "(TODO|FIXME|XXX):" .'}
    let g:select_info.todo.sink = {
                \ "action": {v -> s:todo_sink(v, 'edit')},
                \ "action2": {v -> s:todo_sink(v, 'split')},
                \ "action3": {v -> s:todo_sink(v, 'vsplit')},
                \ "action4": {v -> s:todo_sink(v, 'tab split')}
                \ }
    let g:select_info.todo.highlight = {"GrepPrefix": ['^.\{-}:\d\+:\d\+:', 'Comment']}
    let g:select_info.todo.prompt = "TODO> "
endif


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


"" Get list of all help tags/topics.
"" Uses ripgrep.
func! s:get_helptags() abort
    let l:help = split(globpath(&runtimepath, 'doc/tags', 1), '\n')
    return 'rg ^[^[:space:]]+ -No --no-heading --no-filename '
          \ . join(map(l:help, {_,v -> has("win32") ? shellescape(v) : fnameescape(v)}))
endfunc


"" Get list of highlights without highlights used by Select plugin
func! s:get_highlights() abort
    redir => l:hl
    silent highlight
    redir END
    return filter(
          \ split(l:hl, '\n'),
          \ {i, v -> v !~ 'Select.*' && v !~ '^\s*links to' && v !~ 'cleared$'})
endfunc


"" Transform selected highlight to proper :highlight command.
"" Copy selected highlight to unnamed buffer.
"" Put selected highlight to command line.
func! s:highlight_sink(val) abort
    redir => hl
    exe "silent highlight " .. a:val
    redir END
    let hl = trim(substitute(hl, '\s*xxx\s*', ' ', ''))
    let hl = trim(substitute(hl, '\s*cleared\s*', ' ', ''))
    if hl =~ '.*links to.*'
        let hl = 'link ' .. trim(substitute(hl, '\s*links to\s*', ' ', ''))
    endif
    let hl = 'hi ' .. hl
    let @" = hl
    call feedkeys(':' .. hl, 'n')
endfunc


"" Get list of tags for a filename
func! s:get_btags(filename) abort
    return 'ctags -f - --sort=yes --excmd=number "'..a:filename..'" 2> null'
endfunc


"" Make tag info more readable
func! s:transform_tag(tag) abort
    let tag_info = split(a:tag, '\t')
    return printf("%5s:\t%s\t%s",
                \ matchstr(tag_info[2], '\d\+'),
                \ tag_info[3],
                \ tag_info[0])
endfunc


"" Goto TODO
func! s:todo_sink(value, cmd) abort
    let matches = matchlist(a:value, '^\(.\{-}\):\(\d\+\):\(\d\+\):')
    exe a:cmd.." "..matches[1]
    exe matches[2]
    let col = matches[3]
    if col > 1
        exe "normal! 0"..(col-1).."l"
    endif
endfunc

