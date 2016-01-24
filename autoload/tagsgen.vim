scriptencoding utf-8

let s:Vital = vital#of('tagsgen')
let s:Prelude = s:Vital.import('Prelude')
unlet s:Vital

function! s:deepcopy_nooverwrite(fromdic, todic)
  " return not dictionary
  if type(a:fromdic) != 4
    return
  endif
  for key in keys(a:fromdic)
    if !has_key(a:todic, key)
      let a:todic[key] = a:fromdic[key]
      continue
    endif
    call s:deepcopy_nooverwrite(a:fromdic[key], a:todic[key])
  endfor
endfunction

function! s:set_tagsgen_config()
  let default = {
        \   '_': {
        \     'cmd': 'ctags',
        \     'option': '-R',
        \     'redirect': 0,
        \   },
        \   'vim': {
        \     'option': '-R --languages=Vim',
        \   },
        \   'python': {
        \     'option': '-R --languages=Python',
        \   },
        \   'go': {
        \     'cmd': 'gotags',
        \     'option': '{CURFILES}',
        \     'redirect': 1,
        \   },
        \ }
  if !exists('g:tagsgen_config')
    let g:tagsgen_config = default
    return
  endif
  call s:deepcopy_nooverwrite(default, g:tagsgen_config)
endfunction
call s:set_tagsgen_config()

let g:tagsgen_data_dir = get(g:, "tagsgen_data_dir", expand('~/.tagsgen'))
if !isdirectory(g:tagsgen_data_dir)
  call mkdir(g:tagsgen_data_dir)
endif
let s:data_file = g:tagsgen_data_dir . '/tagsgen'

" 開いているファイルのディレクトリごとの tags ディレクトリをキャッシュ
function! s:load_dirs()
  let s:dirs = {'_': ''}
  if !filereadable(s:data_file)
    return
  endif

  for v in readfile(s:data_file)
    " TODO 無駄な改行が入らなくなったらいらなくなるはず
    if v == ''
      continue
    endif
    let vl = split(v, "\t")
    let s:dirs[vl[0]] = vl[1]
  endfor
endfunction
call s:load_dirs()

" キャッシュファイルの重複などを削除
" s:dirs は辞書型なので s:load_dirs() の後には、重複などがなくなるのでそれを
" 書き込み
function! s:save_dirs()
  let list = items(s:dirs)
  let vs = []
  for v in list
    if v[1] == ''
      continue
    endif
    call add(vs, v[0] . "\t" . v[1])
  endfor
  call writefile(vs, s:data_file)
endfunction
call s:save_dirs()

function! s:get_value(dic, key)
  return has_key(a:dic, a:key) ? a:dic[a:key] : a:dic['_']
endfunction

function! s:get_config(dic, filetype, key)
  if !has_key(a:dic, a:filetype)
    return a:dic['_'][a:key]
  endif
  if !has_key(a:dic[a:filetype], a:key)
    return a:dic['_'][a:key]
  endif
  return a:dic[a:filetype][a:key]
endfunction

function! s:write(key, val)
  " FIXME 最初の出力時に改行が入る
  execute "redir >> " . s:data_file
  silent echo a:key . "\t" . a:val
  redir END
endfunction

function! tagsgen#tagsgen_setdir(bang)
  let file_dir = expand('%:p:h')
  " bang でキャッシュした tags_dir を再指定
  let tags_dir = a:bang ? '' : s:get_value(s:dirs, file_dir)
  if tags_dir == ''
    let tags_dir = s:Prelude.path2project_directory(file_dir)
    redraw
    if tags_dir == ''
      return ''
    elseif !isdirectory(tags_dir)
      echom 'tagsgen: Not exists directory: ' . tags_dir
      return ''
    endif
    call s:write(file_dir, tags_dir)
  endif

  cd `=tags_dir`
  let s:dirs[file_dir] = tags_dir

  return tags_dir
endfunction

function! s:get_cmd_option()
  let val = substitute(s:get_config(g:tagsgen_config, &filetype, 'option'), '{CURFILE}', expand('%:t'), '')
  if match(val, '{CURFILES}') == -1
    return val
  endif
  let curfiles = glob('*.' . expand('%:e'))
  let files = substitute(curfiles, '\n', ' ', 'g')
  return substitute(val, '{CURFILES}',files , '')
endfunction

function! tagsgen#tagsgen(bang)
  let tags_dir = tagsgen#tagsgen_setdir(a:bang)
  if tags_dir == ''
    return
  endif

  let tags_cmd = s:get_config(g:tagsgen_config, &filetype, 'cmd')
  if !executable(tags_cmd)
    echom "tagsgen: Not available " . tags_cmd
    return
  endif
  let cmd_option = s:get_cmd_option()
  let cmd = tags_cmd . ' ' . cmd_option

  let vimcmd = exists(':VimProcBang') == 2 ? 'VimProcBang' : ':!'
  let redirect = s:get_config(g:tagsgen_config, &filetype, 'redirect')
  if redirect == 0
    silent! exe vimcmd cmd
    return
  endif
  execute "redir! > " . tags_dir . '/tags'
  silent! execute vimcmd cmd
  redir END
endfunction

