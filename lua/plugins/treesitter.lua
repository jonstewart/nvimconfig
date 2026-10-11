-- Highlight, edit, and navigate code — nvim-treesitter's rewrite (the `main`
-- branch). There is no `configs` module and no `ensure_installed` any more:
-- parsers are installed with require('nvim-treesitter').install, and
-- highlighting / indent are switched on per buffer from a FileType autocmd.
-- Needs neovim >= 0.12, a C compiler, and the tree-sitter CLI (>= 0.26.1)
-- on PATH: the rewrite compiles every parser through `tree-sitter build`.
-- Incremental selection is not part of the rewrite, but neovim 0.12 has it
-- built in (:h v_an, v_in); <c-space> / <M-space> below map onto that.
local languages = {
  'c', 'cpp', 'go', 'lua', 'python', 'rust',
  'tsx', 'javascript', 'typescript', 'vimdoc', 'vim',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local ts = require('nvim-treesitter')
      ts.setup({})
      -- Async; a no-op once everything is installed. Parsers land under
      -- stdpath('data')/site, never in the (read-only in VMs) config dir.
      ts.install(languages)

      local filetypes = {}
      for _, lang in ipairs(languages) do
        vim.list_extend(filetypes, vim.treesitter.language.get_filetypes(lang))
      end
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('nvimconfig-treesitter', { clear = true }),
        pattern = filetypes,
        callback = function(args)
          -- On a fresh install the parser may still be compiling: skip
          -- quietly, the next buffer of that type gets it.
          if not pcall(vim.treesitter.start, args.buf) then
            return
          end
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      -- The old incremental_selection keys, onto the built-in node selection.
      vim.keymap.set('n', '<c-space>', 'van', { remap = true, desc = 'Increment selection' })
      vim.keymap.set('x', '<c-space>', 'an', { remap = true, desc = 'Increment selection' })
      vim.keymap.set('x', '<M-space>', 'in', { remap = true, desc = 'Decrement selection' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    lazy = false,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('nvim-treesitter-textobjects').setup({
        select = { lookahead = true }, -- jump forward to the textobj, like targets.vim
        move = { set_jumps = true },   -- movements land in the jumplist
      })

      local function select(keys, capture)
        vim.keymap.set({ 'x', 'o' }, keys, function()
          require('nvim-treesitter-textobjects.select').select_textobject(capture, 'textobjects')
        end, { desc = 'select ' .. capture })
      end
      select('aa', '@parameter.outer')
      select('ia', '@parameter.inner')
      select('af', '@function.outer')
      select('if', '@function.inner')
      select('ac', '@class.outer')
      select('ic', '@class.inner')

      local function move(keys, fn, capture)
        vim.keymap.set({ 'n', 'x', 'o' }, keys, function()
          require('nvim-treesitter-textobjects.move')[fn](capture, 'textobjects')
        end, { desc = fn .. ' ' .. capture })
      end
      move(']m', 'goto_next_start', '@function.outer')
      move(']]', 'goto_next_start', '@class.outer')
      move(']M', 'goto_next_end', '@function.outer')
      move('][', 'goto_next_end', '@class.outer')
      move('[m', 'goto_previous_start', '@function.outer')
      move('[[', 'goto_previous_start', '@class.outer')
      move('[M', 'goto_previous_end', '@function.outer')
      move('[]', 'goto_previous_end', '@class.outer')

      vim.keymap.set('n', '<leader>a', function()
        require('nvim-treesitter-textobjects.swap').swap_next('@parameter.inner')
      end, { desc = 'swap with next parameter' })
      vim.keymap.set('n', '<leader>A', function()
        require('nvim-treesitter-textobjects.swap').swap_previous('@parameter.inner')
      end, { desc = 'swap with previous parameter' })
    end,
  },
}
