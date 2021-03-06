scriptencoding utf8

let s:last_completion = []
function! neomake#cmd#complete_makers(ArgLead, CmdLine, ...) abort
    if a:CmdLine !~# '\s'
        " Just 'Neomake!' without following space.
        return [' ']
    endif

    " Filter only by name before non-breaking space.
    let filter_name = split(a:ArgLead, ' ', 1)[0]

    let file_mode = a:CmdLine =~# '\v^(Neomake|NeomakeFile)\s'

    let compl_info = [bufnr('%'), &filetype, a:CmdLine]
    if empty(&filetype)
        let maker_names = neomake#GetProjectMakers()
    else
        let maker_names = neomake#GetMakers(&filetype)

        " Prefer (only) makers for the current filetype.
        if file_mode
            if !empty(filter_name)
                call filter(maker_names, 'v:val[:len(filter_name)-1] ==# filter_name')
            endif
            if empty(maker_names) || s:last_completion == compl_info
                call extend(maker_names, neomake#GetProjectMakers())
            endif
        else
            call extend(maker_names, neomake#GetProjectMakers())
        endif
    endif

    " Only display executable makers.
    let makers = []
    for maker_name in maker_names
        let maker = neomake#GetMaker(maker_name)
        if type(get(maker, 'exe', 0)) != type('') || executable(maker.exe)
            let makers += [[maker_name, maker]]
        endif
    endfor

    " Append maker.name if it differs, uses non-breaking-space.
    let r = []
    for [maker_name, maker] in makers
        if maker.name !=# maker_name
                    \ && (empty(a:ArgLead) || stridx(maker_name, a:ArgLead) != 0)
            let r += [printf('%s (%s)', maker_name, maker.name)]
        else
            let r += [maker_name]
        endif
    endfor

    let s:last_completion = compl_info
    if !empty(filter_name)
        call filter(r, 'v:val[:len(filter_name)-1] ==# filter_name')
    endif
    return r
endfunction

function! neomake#cmd#complete_jobs(...) abort
    return join(map(neomake#GetJobs(), "v:val.id.': '.v:val.maker.name"), "\n")
endfunction
