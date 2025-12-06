return function()
  local luasnip = require("luasnip")

  -- Load friendly-snippets (VSCode style)
  require("luasnip.loaders.from_vscode").lazy_load()

  -- Keymaps for jumping between placeholders
  local opts = { silent = true, expr = true }

  ---- Jump forward
  --vim.keymap.set({ "s", "i" }, "<Tab>", function()
  --  if luasnip.expand_or_jumpable() then
  --    return "<Cmd>lua require('luasnip').expand_or_jump()<CR>"
  --  else
  --    return "<Tab>"
  --  end
  --end, opts)

  ---- Jump backward
  --vim.keymap.set({ "s", "i" }, "<S-Tab>", function()
  --  if luasnip.jumpable(-1) then
  --    return "<Cmd>lua require('luasnip').jump(-1)<CR>"
  --  else
  --    return "<S-Tab>"
  --  end
  --end, opts)
end

