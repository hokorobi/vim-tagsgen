scriptencoding utf-8
if exists('g:loaded_tagsgen')
  finish
endif
let g:loaded_tagsgen = 1

command! -bang -nargs=0 Tagsgen :call tagsgen#tagsgen(<bang>0)
command! -bang -nargs=0 TagsgenSetDir :call tagsgen#tagsgen_setdir(<bang>0)

