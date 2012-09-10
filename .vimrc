map <leader>r :source %<CR>

" http://robots.thoughtbot.com/post/17450269990/convert-ruby-1-8-to-1-9-hash-syntax
map <leader>h :%s/:\([^ ]*\)\(\s*\)=>/\1:/g

" Edit routes
command! Rroutes :R config/routes.rb
command! RTroutes :RTedit config/routes.rb

"" vim-rails autocommands
autocmd User Rails/app/assets/javascripts/*.coffee let b:rails_alternate = substitute(substitute(rails#buffer().path(), 'app/assets', 'spec', ''), 'coffee', 'spec.coffee', '')
autocmd User Rails/spec/javascripts/*.coffee let b:rails_alternate = substitute(substitute(rails#buffer().path(), 'spec/javascripts', 'app/assets/javascripts', ''), 'spec\.coffee', 'coffee', '')
autocmd User BufEnterRails :Rnavcommand domain app/domain -glob=**/* -suffix=.rb
:echo "sourced file ok"
