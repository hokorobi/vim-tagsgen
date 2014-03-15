let g:taggen_config = {
      \ '_' : '-R --sort=yes',
      \ 'vim': '-R --sort=yes --languages=Vim',
      \ }

let g:taggen_tags_command = {
      \ '_': 'ctags',
      \ 'go': 'gotags'
      \ }

function! s:get_value(dic, key)
  if has_key(a:dic, a:key)
    return a:dic[a:key]
  else
    return a:dic['_']
  endif
endfunction

function! s:exec_tags()
  let tags_command = s:get_value(g:taggen_tags_command, &filetype)
  let tags_config = s:get_value(g:taggen_config, &filetype)
  let tags_dir = fnamemodify('%', ':p:h')

  let command = tags_command . tags_config . ' -f ' . tags_dir . '/tags ' . target_dir
  echo command
endfunction

call s:exec_tags()
" echo tags_command
" echo tags_config
