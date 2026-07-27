nnoremap <F5> <Cmd>OverseerRunCmd zig build run -Dtarget=x86_64-windows<CR>
nnoremap <F7> <Cmd>below new \| execute "term runic build-web.rn && cd zig-out/web && vite . --open" \| normal a<CR>
nnoremap <F10> <Cmd>below new \| execute "term runic pack-web.rn" \| normal a<CR>
