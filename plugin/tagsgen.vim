scriptencoding utf-8

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

" ファイルごとの tag_sdir をキャッシュ
" TODO ファイルへの書き出し、読み込み
if !exists('g:tagsgen_tags_dir')
  let g:tagsgen_tags_dir = {
        \ '_': ''
        \ }
endif

let s:save_cpo = &cpo
set cpo&vim

function! s:get_value(dic, key)
  return has_key(a:dic, a:key) ? a:dic[a:key] : a:dic['_']
endfunction

function! s:tagsgen_setdir(bang)
  " bang でキャッシュした tags_dir を再指定
  let tags_dir = a:bang ? '' : s:get_value(g:tagsgen_tags_dir, expand('%'))
  if tags_dir == ''
    let tags_dir = input('tags dir?: ', fnamemodify(expand('%'), ':p:h'))
    if !isdirectory(tags_dir)
      redraw
      echom 'tagsgen: Not exists directory: ' . tags_dir
      return ''
    endif
  endif

  cd `=tags_dir`
  return tags_dir
endfunction

function! s:tagsgen(bang)
  let tags_command = s:get_value(g:tagsgen_tags_command, &filetype)
  if !executable(tags_command)
    redraw
    echom "tagsgen: not available " . tags_command
    return
  endif
  let tags_option = s:get_value(g:tagsgen_option, &filetype)
  let tags_dir = s:tagsgen_setdir(a:bang)
  if tags_dir == ''
    return
  endif

  let tags_option = substitute(tags_option, '{CURFILE}', expand('%:t'), '')
  if match(tags_option, '{CURFILES}') != -1
    let curfiles = glob('*.' . expand('%:e'))
    let files = substitute(curfiles, '\n', ' ', 'g')
    let tags_option = substitute(tags_option, '{CURFILES}',files , '')
  endif
  let cmd = tags_command . ' ' . tags_option
  " tags ファイル生成コマンドが標準出力へ出力される場合は > でファイルへ書き出
  " す。> を使う場合は :! でコマンドを実行する。
  let vimcmd = match(cmd, ">") == -1 && exists(':VimProcBang') == 2 ? 'VimProcBang' : ':!'
  silent! exe vimcmd cmd

  let g:tagsgen_tags_dir[expand('%')] = tags_dir
endfunction

command! -bang -nargs=0 Tagsgen :call s:tagsgen(<bang>0)
command! -bang -nargs=0 TagsgenSetDir :call s:tagsgen_setdir(<bang>0)

let &cpo = s:save_cpo
unlet s:save_cpo
