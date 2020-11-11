if exists("g:loaded_select")
    func! s:get_bufdefs(buf) abort
        let result = getbufline(a:buf.bufnr, 1, '$')
                    \ ->map({i, ln -> printf("%*d: %s", len(line('$', a:buf.winid)), i+1, trim(ln))})
                    \ ->filter({_, val -> val =~ '^\s*\d\+:\s#\+\s\S'})

        return result
    endfunc
    let b:select_info = {}
    let b:select_info.bufdef = {}
    let b:select_info.bufdef.data = {_, v -> s:get_bufdefs(v)}
    let b:select_info.bufdef.sink = {
                \ "transform": {_, v -> matchstr(v, '^\s*\zs\d\+')},
                \ "action": "normal! %sG"
                \ }
    let b:select_info.bufdef.highlight = {"PrependLineNr": ['^\(\s*\d\+:\)', 'LineNr']}
endif
