return {
  "roobert/hoversplit.nvim",
  config = function()
    require("hoversplit").setup({
      key_bindings = {
        split_remain_focused = "<leader>hs",
        vsplit_remain_focused = "<leader>hv",
        split = "<leader>hS",
        vsplit = "<leader>hV",
      },
    })
  end,
}

