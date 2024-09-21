return {
  -- NOTE: First, some plugins that don't require any configuration

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  {
    -- Autocompletion
    'hrsh7th/nvim-cmp',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',

      -- Adds a number of user-friendly snippets
      'rafamadriz/friendly-snippets',
    },
  },

  -- Useful plugin to show you pending keybinds.
  { 'folke/which-key.nvim', opts = {} },

  -- {
  --   -- solarized theme
  --   'lifepillar/vim-solarized8.git',
  --   priority = 1000,
  --   config = function()
  --     -- set background light
  --     vim.cmd.colorscheme 'solarized8'
  --   end,
  -- },


  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },


  {
    -- GitHub Copilot
    'github/copilot.vim'
  },

  {
    'glepnir/nerdicons.nvim', cmd = 'NerdIcons', 
    config = function() 
      require('nerdicons').setup({}) 
    end
  },
}

