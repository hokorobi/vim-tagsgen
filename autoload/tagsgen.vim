scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#tagsgen#new()
let s:Prelude = vital#tagsgen#import('Prelude')

function! s:deepcopy_nooverwrite(fromdic, todic) abort
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

function! s:set_tagsgen_config() abort
  let default = {
        \   '_': {
        \     'cmd': 'ctags',
        \     'option': ['-R'],
        \   },
        \   'vim': {
        \     'option': ['-R', '--languages=Vim'],
        \   },
        \   'python': {
        \     'option': ['-R', '--languages=Python'],
        \   },
        \   'go': {
        \     'cmd': 'gotags',
        \     'option': ['-R', '-f', 'tags', '.'],
        \   },
        \ }
  if !exists('g:tagsgen_config')
    let g:tagsgen_config = default
    return
  endif
  call s:deepcopy_nooverwrite(default, g:tagsgen_config)
endfunction
call s:set_tagsgen_config()

function! s:get_config(dic, filetype, key) abort
  if !has_key(a:dic, a:filetype)
    return a:dic['_'][a:key]
  endif
  if !has_key(a:dic[a:filetype], a:key)
    return a:dic['_'][a:key]
  endif
  return a:dic[a:filetype][a:key]
endfunction

function! tagsgen#tagsgen(bang) abort
  let tags_dir = s:Prelude.path2project_directory(expand('%:p:h'))
  if tags_dir !=# ''
    execute 'cd '.tags_dir
  endif

  let tags_cmd = s:get_config(g:tagsgen_config, &filetype, 'cmd')
  if !executable(tags_cmd)
    echomsg 'tagsgen: Not available ' . tags_cmd
    return
  endif
  let cmd_option = s:get_config(g:tagsgen_config, &filetype, 'option')
  let cmd = [tags_cmd] + cmd_option
  echo system_job#system(cmd)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

