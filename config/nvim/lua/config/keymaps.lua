local util = require("util")

util.cowboy()

-- Move to window using the movement keys
vim.keymap.set("n", "<left>", "<C-w>h")
vim.keymap.set("n", "<down>", "<C-w>j")
vim.keymap.set("n", "<up>", "<C-w>k")
vim.keymap.set("n", "<right>", "<C-w>l")

-- change word with <c-c>
vim.keymap.set("n", "<C-c>", "<cmd>normal! ciw<cr>a")

-- makes * and # work on visual mode too.
vim.cmd([[
  function! g:VSetSearch(cmdtype)
    let temp = @s
    norm! gv"sy
    let @/ = '\V' . substitute(escape(@s, a:cmdtype.'\'), '\n', '\\n', 'g')
    let @s = temp
  endfunction

  xnoremap * :<C-u>call g:VSetSearch('/')<cr>/<C-R>=@/<cr><cr>
  xnoremap # :<C-u>call g:VSetSearch('?')<cr>?<C-R>=@/<cr><cr>
]])

-- plenary testing
vim.keymap.set("n", "<leader>tt", function()
	util.test(true)
end, { desc = "Test File" })
vim.keymap.set("n", "<leader>td", function()
	util.test()
end, { desc = "Test Directory" })
