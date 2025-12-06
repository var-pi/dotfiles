vim.g.mapleader = " "

vim.keymap.set(
  {"n", "v"},
  "<leader>oo",
  ":<c-u>lua require('ollama').prompt()<cr>",
  { desc = "Open LLM prompt" }
)
vim.keymap.set("n", "gD", vim.lsp.buf.declaration)
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
