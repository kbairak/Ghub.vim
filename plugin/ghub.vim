if exists("g:loaded_ghub")
    finish
endif
let g:loaded_ghub = 1

function s:strip(input_string)
    return substitute(a:input_string, '^\n*\(.\{-}\)\n*$', '\1', '')
endfunction

function s:get_git_dir()
    let l:gitdir = expand('%:h')
    while 1
        let l:paths = readdir(l:gitdir)
        if index(l:paths, '.git') != -1
            return l:gitdir
        endif
        let l:gitdir = fnamemodify(l:gitdir, ':h')
    endwhile
endfunction

function s:get_remote_url()
    let l:startdir = getcwd()
    let l:gitdir = s:get_git_dir()

    execute 'cd ' . l:gitdir

    let l:url = system('git config --get remote.origin.url')

    " get rid of the '(https|ssh|git)://'
    let l:url = split(l:url, '://')[-1]

    " get rid of (potential) 'git@'
    let l:url = split(l:url, '@')[-1]

    execute 'cd ' . l:startdir

    return s:strip('https://' . l:url)
endfunction

function s:get_branch_name()
    let l:startdir = getcwd()
    let l:gitdir = s:get_git_dir()
    execute 'cd ' . l:gitdir

    let l:branch_name = system('git symbolic-ref HEAD 2> /dev/null')
    if l:branch_name == ''
        let l:branch_name = system('git rev-parse --short HEAD 2> /dev/null')
    else
        let l:branch_name = split(l:branch_name, '/')[-1]
    endif

    execute 'cd ' . l:startdir

    return s:strip(l:branch_name)

    "let l:branch_name = system('git branch --contains HEAD | head -1')

    "" remove the '* '
    "return s:strip(split(l:branch_name, '* ')[-1])
endfunction

function s:get_path()
    let l:gitdir = s:get_git_dir()

    let l:return_value = s:strip(expand('%'))
    if stridx(l:return_value, l:gitdir) != -1
        return l:return_value[strlen(l:gitdir) + 1:]
    else
        return l:return_value
    endif
endfunction

function s:get_line()
    return s:strip(line('.'))
endfunction

function s:get_github_url()
    let l:result = s:strip(s:get_remote_url() . '/blob/' . s:get_branch_name() . '/' . s:get_path())
    let l:line = s:get_line()
    if l:line != 1
        let l:result = l:result . '#L' . l:line
    endif
    return s:strip(l:result)
endfunction

function s:copy_github_url()
    call setreg('+', s:get_github_url())
endfunction

function s:open_github_url()
    call system('xdg-open ' . s:get_github_url())
endfunction

command Ghub call s:copy_github_url()
command GhubOpen call s:open_github_url()
