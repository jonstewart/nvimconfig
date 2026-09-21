-- Highlight, edit, and navigate code
--
-- nvim-treesitter's default branch moved from `master` to `main`, which is a
-- rewrite: there is no module system, so `require('nvim-treesitter.configs')`
-- is gone. Parsers are installed imperatively, highlight/indent are started
-- per-buffer, and textobjects bring their own setup plus explicit keymaps.
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',

    config = function()
      -- Add languages to be installed here that you want installed for treesitter
      local ensure_installed = {
        'c',
        'cpp',
        'go',
        'lua',
        'python',
        'rust',
        'tsx',
        'javascript',
        'typescript',
        'vimdoc',
        'vim',
      }

      -- [[ Incremental selection ]]
      -- `main` dropped the incremental_selection module, and Neovim has no
      -- built-in equivalent, so this is a small stand-in for the <c-space> and
      -- <c-s> maps below: grow the visual selection to the enclosing node (or
      -- scope), and walk back down through whatever we grew past. Ranges here
      -- are treesitter's own: 0-indexed, with an exclusive end.
      local selections = {} -- per-buffer stack of the ranges we grew out of

      local function in_visual()
        return vim.fn.mode():match('^[vV\22]') ~= nil
      end

      -- The cursor position, or the visual selection, as a range
      local function current_range()
        if not in_visual() then
          local row, col = unpack(vim.api.nvim_win_get_cursor(0))
          return { row - 1, col, row - 1, col + 1 }
        end

        local srow, scol = vim.fn.line('v'), vim.fn.col('v')
        local erow, ecol = vim.fn.line('.'), vim.fn.col('.')
        if srow > erow or (srow == erow and scol > ecol) then
          srow, scol, erow, ecol = erow, ecol, srow, scol
        end
        -- linewise selections report the cursor column, so widen to whole lines
        if vim.fn.mode() == 'V' then
          scol, ecol = 1, #vim.fn.getline(erow) + 1
        end
        return { srow - 1, scol - 1, erow - 1, ecol }
      end

      local function set_cursor(row, col)
        local last = math.max(#vim.fn.getline(row + 1) - 1, 0)
        vim.api.nvim_win_set_cursor(0, { row + 1, math.max(0, math.min(col, last)) })
      end

      local function select_range(range)
        local srow, scol, erow, ecol = unpack(range)
        -- an exclusive end at column 0 really belongs to the end of the line above
        if ecol == 0 and erow > srow then
          erow = erow - 1
          ecol = #vim.fn.getline(erow + 1)
        end
        if in_visual() then
          vim.cmd('normal! \27')
        end
        set_cursor(srow, scol)
        vim.cmd('normal! v')
        set_cursor(erow, ecol - 1)
      end

      local function same_range(a, b)
        return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
      end

      local function node_for_range(buf, range)
        local ok, parser = pcall(vim.treesitter.get_parser, buf)
        if not ok or not parser then
          return nil
        end
        parser:parse(true)
        return parser:named_node_for_range(range)
      end

      -- The nodes a language's locals query captures as `@local.scope`, or nil
      -- when the language ships no locals query
      local function scope_ids(buf, node)
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        local query = lang and vim.treesitter.query.get(lang, 'locals')
        if not query then
          return nil
        end
        local ids = {}
        for id, captured in query:iter_captures(node:tree():root(), buf, 0, -1) do
          if query.captures[id] == 'local.scope' then
            ids[captured:id()] = true
          end
        end
        return ids
      end

      -- Grow the selection. `to_scope` skips past plain nodes to the enclosing scope.
      local function grow(to_scope)
        local buf = vim.api.nvim_get_current_buf()
        if not in_visual() then
          selections[buf] = {}
        end

        local range = current_range()
        local node = node_for_range(buf, range)
        if not node then
          return
        end

        -- a node matching the selection exactly would be a no-op, so climb past it
        local ids = to_scope and scope_ids(buf, node) or nil
        local target = node
        while target and (same_range({ target:range() }, range) or (ids and not ids[target:id()])) do
          target = target:parent()
        end
        if not target then
          return
        end

        local stack = selections[buf] or {}
        stack[#stack + 1] = range
        selections[buf] = stack
        select_range({ target:range() })
      end

      local function shrink()
        local stack = selections[vim.api.nvim_get_current_buf()]
        local previous = stack and table.remove(stack)
        if previous then
          select_range(previous)
        end
      end

      require('nvim-treesitter').setup()

      -- Parsers already present are skipped, so this is cheap on later startups
      require('nvim-treesitter').install(ensure_installed)

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
        desc = 'Enable treesitter highlighting and indentation where a parser exists',
        callback = function(event)
          local lang = vim.treesitter.language.get_lang(event.match)
          if not (lang and vim.treesitter.language.add(lang)) then
            return
          end
          vim.treesitter.start(event.buf, lang)
          vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      vim.keymap.set({ 'n', 'x' }, '<c-space>', function()
        grow(false)
      end, { desc = 'Increment selection' })
      vim.keymap.set('x', '<c-s>', function()
        grow(true)
      end, { desc = 'Increment selection to scope' })
      vim.keymap.set('x', '<M-space>', shrink, { desc = 'Decrement selection' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },

    config = function()
      require('nvim-treesitter-textobjects').setup({
        select = {
          lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        },
        move = {
          set_jumps = true, -- whether to set jumps in the jumplist
        },
      })

      local select = require('nvim-treesitter-textobjects.select')
      local move = require('nvim-treesitter-textobjects.move')
      local swap = require('nvim-treesitter-textobjects.swap')

      -- You can use the capture groups defined in textobjects.scm
      for key, capture in pairs({
        ['aa'] = '@parameter.outer',
        ['ia'] = '@parameter.inner',
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
      }) do
        vim.keymap.set({ 'x', 'o' }, key, function()
          select.select_textobject(capture)
        end, { desc = 'Select ' .. capture })
      end

      for key, spec in pairs({
        [']m'] = { move.goto_next_start, '@function.outer' },
        [']]'] = { move.goto_next_start, '@class.outer' },
        [']M'] = { move.goto_next_end, '@function.outer' },
        [']['] = { move.goto_next_end, '@class.outer' },
        ['[m'] = { move.goto_previous_start, '@function.outer' },
        ['[['] = { move.goto_previous_start, '@class.outer' },
        ['[M'] = { move.goto_previous_end, '@function.outer' },
        ['[]'] = { move.goto_previous_end, '@class.outer' },
      }) do
        local goto_fn, capture = spec[1], spec[2]
        vim.keymap.set({ 'n', 'x', 'o' }, key, function()
          goto_fn(capture)
        end, { desc = 'Jump to ' .. capture })
      end

      vim.keymap.set('n', '<leader>a', function()
        swap.swap_next('@parameter.inner')
      end, { desc = 'Swap next parameter' })
      vim.keymap.set('n', '<leader>A', function()
        swap.swap_previous('@parameter.inner')
      end, { desc = 'Swap previous parameter' })
    end,
  },
}
