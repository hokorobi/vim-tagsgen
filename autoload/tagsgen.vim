scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:tagsgen_option')
  let g:tagsgen_option = {
        \ '_' : '-R',
        \ 'vim': '-R --languages=Vim',
        \ 'python': '-R --languages=Python',
        \ 'go': '{CURFILES} > tags'
        \ }
endif

if !exists('g:tagsgen_tags_command')
  let g:tagsgen_tags_command = {
        \ '_': 'ctags',
        \ 'go': 'gotags'
        \ }
endif

let g:tagsgen_data_dir = get(g:, "tagsgen_data_dir", expand('~/.tagsgen'))
if !isdirectory(g:tagsgen_data_dir)
  call mkdir(g:tagsgen_data_dir)
endif
let s:data_file = g:tagsgen_data_dir . '/tagsgen'

" ファイルごとの tags ディレクトリをキャッシュ
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

function! s:write(key, val)
  " FIXME 最初の出力時に改行が入る
  execute "redir >> " . s:data_file
  silent echo a:key . "\t" . a:val
  redir END
endfunction

function! tagsgen#tagsgen_setdir(bang)
  " bang でキャッシュした tags_dir を再指定
  let tags_dir = a:bang ? '' : s:get_value(s:dirs, expand('%'))
  if tags_dir == ''
    let tags_dir = input('tags dir?: ', fnamemodify(expand('%'), ':p:h'))
    redraw
    if tags_dir == ''
      return ''
    elseif !isdirectory(tags_dir)
      echom 'tagsgen: Not exists directory: ' . tags_dir
      return ''
    endif
  endif

  cd `=tags_dir`
  let s:dirs[expand('%')] = tags_dir

  call s:write(expand('%'), tags_dir)

  return tags_dir
endfunction

function! s:get_tags_option()
  let val = substitute(s:get_value(g:tagsgen_option, &filetype), '{CURFILE}', expand('%:t'), '')
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

  let tags_command = s:get_value(g:tagsgen_tags_command, &filetype)
  if !executable(tags_command)
    echom "tagsgen: Not available " . tags_command
    return
  endif

  let tags_option = s:get_tags_option()

  let cmd = tags_command . ' ' . tags_option
  " tags ファイル生成コマンドが標準出力へ出力される場合は > でファイルへ書き出
  " す。> を使う場合は :! でコマンドを実行する。
  let vimcmd = match(cmd, ">") == -1 && exists(':VimProcBang') == 2 ? 'VimProcBang' : ':!'
  silent! exe vimcmd cmd
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

