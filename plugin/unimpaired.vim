" unimpaired.vim - Pairs of handy bracket mappings

if exists("g:loaded_unimpaired") || &cp || v:version < 700
  finish
endif
let g:loaded_unimpaired = 1

function! s:Map(...) abort
  let [mode, head, rhs; rest] = a:000
  let flags = get(rest, 0, '') . (rhs =~# '^<Plug>' ? '' : '<script>')
  let tail = ''
  let keys = get(g:, mode.'remap', {})
  if type(keys) == type({}) && !empty(keys)
    while !empty(head) && len(keys)
      if has_key(keys, head)
        let head = keys[head]
        if empty(head)
          let head = '<skip>'
        endif
        break
      endif
      let tail = matchstr(head, '<[^<>]*>$\|.$') . tail
      let head = substitute(head, '<[^<>]*>$\|.$', '', '')
    endwhile
  endif
  if head !=# '<skip>' && empty(maparg(head.tail, mode))
    return mode.'map ' . flags . ' ' . head.tail . ' ' . rhs
  endif
  return ''
endfunction

" Section: Next and previous {{{1

function! s:MapNextFamily(map,cmd) abort
  let prefix = '<Plug>(unimpaired-' . a:cmd
  let map = '<Plug>unimpaired'.toupper(a:map)
  let cmd = '".(v:count ? v:count : "")."'.a:cmd
  let end = '"<CR>'.(a:cmd ==# 'l' || a:cmd ==# 'c' ? 'zv' : '')
  execute 'nnoremap <silent> '.prefix.'previous) :<C-U>exe "'.cmd.'previous'.end
  execute 'nnoremap <silent> '.prefix.'next)     :<C-U>exe "'.cmd.'next'.end
  execute 'nnoremap <silent> '.prefix.'first)    :<C-U>exe "'.cmd.'first'.end
  execute 'nnoremap <silent> '.prefix.'last)     :<C-U>exe "'.cmd.'last'.end
  execute 'nnoremap <silent> '.map.'Previous :<C-U>exe "'.cmd.'previous'.end
  execute 'nnoremap <silent> '.map.'Next     :<C-U>exe "'.cmd.'next'.end
  execute 'nnoremap <silent> '.map.'First    :<C-U>exe "'.cmd.'first'.end
  execute 'nnoremap <silent> '.map.'Last     :<C-U>exe "'.cmd.'last'.end
  exe s:Map('n', '['.        a:map , prefix.'previous)')
  exe s:Map('n', ']'.        a:map , prefix.'next)')
  exe s:Map('n', '['.toupper(a:map), prefix.'first)')
  exe s:Map('n', ']'.toupper(a:map), prefix.'last)')
  if a:cmd ==# 'c' || a:cmd ==# 'l'
    execute 'nnoremap <silent> '.prefix.'pfile)  :<C-U>exe "'.cmd.'pfile'.end
    execute 'nnoremap <silent> '.prefix.'nfile)  :<C-U>exe "'.cmd.'nfile'.end
    execute 'nnoremap <silent> '.map.'PFile :<C-U>exe "'.cmd.'pfile'.end
    execute 'nnoremap <silent> '.map.'NFile :<C-U>exe "'.cmd.'nfile'.end
    exe s:Map('n', '[<C-'.toupper(a:map).'>', prefix.'pfile)')
    exe s:Map('n', ']<C-'.toupper(a:map).'>', prefix.'nfile)')
  elseif a:cmd ==# 't'
    nnoremap <silent> <Plug>(unimpaired-ptprevious) :<C-U>exe v:count1 . "ptprevious"<CR>
    nnoremap <silent> <Plug>(unimpaired-ptnext) :<C-U>exe v:count1 . "ptnext"<CR>
    execute 'nnoremap <silent> '.map.'PPrevious :<C-U>exe "p'.cmd.'previous'.end
    execute 'nnoremap <silent> '.map.'PNext :<C-U>exe "p'.cmd.'next'.end
    exe s:Map('n', '[<C-T>', '<Plug>(unimpaired-ptprevious)')
    exe s:Map('n', ']<C-T>', '<Plug>(unimpaired-ptnext)')
  endif
endfunction

call s:MapNextFamily('a','')
call s:MapNextFamily('b','b')
call s:MapNextFamily('l','l')
call s:MapNextFamily('q','c')
call s:MapNextFamily('t','t')

function! s:entries(path) abort
  let path = substitute(a:path,'[\\/]$','','')
  let files = split(glob(path."/.*"),"\n")
  let files += split(glob(path."/*"),"\n")
  call map(files,'substitute(v:val,"[\\/]$","","")')
  call filter(files,'v:val !~# "[\\\\/]\\.\\.\\=$"')

  let filter_suffixes = substitute(escape(&suffixes, '~.*$^'), ',', '$\\|', 'g') .'$'
  call filter(files, 'v:val !~# filter_suffixes')

  return sort(files)
endfunction

function! s:FileByOffset(num) abort
  let file = expand('%:p')
  if empty(file)
    let file = getcwd() . '/'
  endif
  let num = a:num
  while num
    let files = s:entries(fnamemodify(file,':h'))
    if a:num < 0
      call reverse(filter(files,'v:val <# file'))
    else
      call filter(files,'v:val ># file')
    endif
    let temp = get(files,0,'')
    if empty(temp)
      let file = fnamemodify(file,':h')
    else
      let file = temp
      let found = 1
      while isdirectory(file)
        let files = s:entries(file)
        if empty(files)
          let found = 0
          break
        endif
        let file = files[num > 0 ? 0 : -1]
      endwhile
      let num += (num > 0 ? -1 : 1) * found
    endif
  endwhile
  return file
endfunction

function! s:fnameescape(file) abort
  if exists('*fnameescape')
    return fnameescape(a:file)
  else
    return escape(a:file," \t\n*?[{`$\\%#'\"|!<")
  endif
endfunction

function! s:GetWindow() abort
  if exists('*getwininfo') && exists('*win_getid')
    return get(getwininfo(win_getid()), 0, {})
  else
    return {}
  endif
endfunction

function! s:PreviousFileEntry(count) abort
  let window = s:GetWindow()

  if get(window, 'loclist')
    return 'lolder ' . a:count
  elseif get(window, 'quickfix')
    return 'colder ' . a:count
  else
    return 'edit ' . s:fnameescape(fnamemodify(s:FileByOffset(-v:count1), ':.'))
  endif
endfunction

function! s:NextFileEntry(count) abort
  let window = s:GetWindow()

  if get(window, 'loclist')
    return 'lnewer ' . a:count
  elseif get(window, 'quickfix')
    return 'cnewer ' . a:count
  else
    return 'edit ' . s:fnameescape(fnamemodify(s:FileByOffset(v:count1), ':.'))
  endif
endfunction

nnoremap <silent> <Plug>(unimpaired-directory-next)     :<C-U>execute <SID>NextFileEntry(v:count1)<CR>
nnoremap <silent> <Plug>(unimpaired-directory-previous) :<C-U>execute <SID>PreviousFileEntry(v:count1)<CR>
nnoremap <silent> <Plug>unimpairedDirectoryNext     :<C-U>execute <SID>NextFileEntry(v:count1)<CR>
nnoremap <silent> <Plug>unimpairedDirectoryPrevious :<C-U>execute <SID>PreviousFileEntry(v:count1)<CR>
exe s:Map('n', ']f', '<Plug>(unimpaired-directory-next)')
exe s:Map('n', '[f', '<Plug>(unimpaired-directory-previous)')

" Section: Diff {{{1

nnoremap <silent> <Plug>(unimpaired-context-previous) :<C-U>call <SID>Context(1)<CR>
nnoremap <silent> <Plug>(unimpaired-context-next)     :<C-U>call <SID>Context(0)<CR>
vnoremap <silent> <Plug>(unimpaired-context-previous) :<C-U>exe 'normal! gv'<Bar>call <SID>Context(1)<CR>
vnoremap <silent> <Plug>(unimpaired-context-next)     :<C-U>exe 'normal! gv'<Bar>call <SID>Context(0)<CR>
onoremap <silent> <Plug>(unimpaired-context-previous) :<C-U>call <SID>ContextMotion(1)<CR>
onoremap <silent> <Plug>(unimpaired-context-next)     :<C-U>call <SID>ContextMotion(0)<CR>

exe s:Map('n', '[n', '<Plug>(unimpaired-context-previous)')
exe s:Map('n', ']n', '<Plug>(unimpaired-context-next)')
exe s:Map('x', '[n', '<Plug>(unimpaired-context-previous)')
exe s:Map('x', ']n', '<Plug>(unimpaired-context-next)')
exe s:Map('o', '[n', '<Plug>(unimpaired-context-previous)')
exe s:Map('o', ']n', '<Plug>(unimpaired-context-next)')

nnoremap <silent> <Plug>unimpairedContextPrevious :<C-U>call <SID>Context(1)<CR>
nnoremap <silent> <Plug>unimpairedContextNext     :<C-U>call <SID>Context(0)<CR>
xnoremap <silent> <Plug>unimpairedContextPrevious :<C-U>exe 'normal! gv'<Bar>call <SID>Context(1)<CR>
xnoremap <silent> <Plug>unimpairedContextNext     :<C-U>exe 'normal! gv'<Bar>call <SID>Context(0)<CR>
onoremap <silent> <Plug>unimpairedContextPrevious :<C-U>call <SID>ContextMotion(1)<CR>
onoremap <silent> <Plug>unimpairedContextNext     :<C-U>call <SID>ContextMotion(0)<CR>

function! s:Context(reverse) abort
  call search('^\(@@ .* @@\|[<=>|]\{7}[<=>|]\@!\)', a:reverse ? 'bW' : 'W')
endfunction

function! s:ContextMotion(reverse) abort
  if a:reverse
    -
  endif
  call search('^@@ .* @@\|^diff \|^[<=>|]\{7}[<=>|]\@!', 'bWc')
  if getline('.') =~# '^diff '
    let end = search('^diff ', 'Wn') - 1
    if end < 0
      let end = line('$')
    endif
  elseif getline('.') =~# '^@@ '
    let end = search('^@@ .* @@\|^diff ', 'Wn') - 1
    if end < 0
      let end = line('$')
    endif
  elseif getline('.') =~# '^=\{7\}'
    +
    let end = search('^>\{7}>\@!', 'Wnc')
  elseif getline('.') =~# '^[<=>|]\{7\}'
    let end = search('^[<=>|]\{7}[<=>|]\@!', 'Wn') - 1
  else
    return
  endif
  if end > line('.')
    execute 'normal! V'.(end - line('.')).'j'
  elseif end == line('.')
    normal! V
  endif
endfunction

" Section: Put {{{1

function! s:putline(how, map) abort
  let [body, type] = [getreg(v:register), getregtype(v:register)]
  if type ==# 'V'
    exe 'normal! "'.v:register.a:how
  else
    call setreg(v:register, body, 'l')
    exe 'normal! "'.v:register.a:how
    call setreg(v:register, body, type)
  endif
  silent! call repeat#set("\<Plug>(unimpaired-put-".a:map.")")
endfunction

nnoremap <silent> <Plug>(unimpaired-put-above) :call <SID>putline('[p', 'above')<CR>
nnoremap <silent> <Plug>(unimpaired-put-below) :call <SID>putline(']p', 'below')<CR>
nnoremap <silent> <Plug>(unimpaired-put-above-rightward) :<C-U>call <SID>putline(v:count1 . '[p', 'Above')<CR>>']
nnoremap <silent> <Plug>(unimpaired-put-below-rightward) :<C-U>call <SID>putline(v:count1 . ']p', 'Below')<CR>>']
nnoremap <silent> <Plug>(unimpaired-put-above-leftward)  :<C-U>call <SID>putline(v:count1 . '[p', 'Above')<CR><']
nnoremap <silent> <Plug>(unimpaired-put-below-leftward)  :<C-U>call <SID>putline(v:count1 . ']p', 'Below')<CR><']
nnoremap <silent> <Plug>(unimpaired-put-above-reformat)  :<C-U>call <SID>putline(v:count1 . '[p', 'Above')<CR>=']
nnoremap <silent> <Plug>(unimpaired-put-below-reformat)  :<C-U>call <SID>putline(v:count1 . ']p', 'Below')<CR>=']
nnoremap <silent> <Plug>unimpairedPutAbove :call <SID>putline('[p', 'above')<CR>
nnoremap <silent> <Plug>unimpairedPutBelow :call <SID>putline(']p', 'below')<CR>

exe s:Map('n', '[p', '<Plug>(unimpaired-put-above)')
exe s:Map('n', ']p', '<Plug>(unimpaired-put-below)')
exe s:Map('n', '[P', '<Plug>(unimpaired-put-above)')
exe s:Map('n', ']P', '<Plug>(unimpaired-put-below)')

exe s:Map('n', '>P', "<Plug>(unimpaired-put-above-rightward)")
exe s:Map('n', '>p', "<Plug>(unimpaired-put-below-rightward)")
exe s:Map('n', '<P', "<Plug>(unimpaired-put-above-leftward)")
exe s:Map('n', '<p', "<Plug>(unimpaired-put-below-leftward)")
exe s:Map('n', '=P', "<Plug>(unimpaired-put-above-reformat)")
exe s:Map('n', '=p', "<Plug>(unimpaired-put-below-reformat)")


" vim:set sw=2 sts=2:
