return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  config = function()
    flavour = 'latte'
    vim.cmd.colorscheme "catppuccin"
  end
}
