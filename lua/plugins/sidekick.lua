-- sidekick.nvim
--
-- Runs AI CLIs (Claude Code first and foremost) in a terminal split, and can
-- send the current file, line, selection or diagnostics to them as context.
-- It also renders Copilot's Next Edit Suggestions (NES), multi-line edits
-- proposed after you leave insert mode.
--
-- NES needs a Copilot language server, and sidekick uses any running LSP client
-- whose name contains "copilot". copilot.lua already starts one (its native
-- binary, no Node.js), so nothing extra gets enabled here. NES therefore shows
-- up in a buffer once copilot.lua has attached to it (it loads on InsertEnter).
--
-- <leader>a is taken by treesitter's parameter swap. Adding a <leader>a… group
-- would make <leader>a wait out 'timeoutlen' before swapping, so the CLI maps
-- sit under <leader>k ("sideKick") instead of the README's <leader>a.
return {
  'folke/sidekick.nvim',
  -- load before copilot.lua (InsertEnter) so sidekick's LspAttach hooks see it
  event = 'VeryLazy',
  opts = {
    cli = {
      -- no snacks.nvim in this config
      picker = 'telescope',
    },
  },
  keys = {
    -- <Tab> is shared with copilot.lua. In insert mode copilot.lua maps <Tab>
    -- per buffer, accepts its suggestion when one is visible, and otherwise
    -- hands the key on to this global mapping. So insert-mode <Tab> tries
    -- copilot's inline suggestion, then NES, then a literal tab. In normal
    -- mode it is NES, then the usual <Tab> (jump forward, same as <C-i>).
    {
      '<Tab>',
      function()
        if not require('sidekick').nes_jump_or_apply() then
          return '<Tab>'
        end
      end,
      mode = { 'i', 'n' },
      expr = true,
      desc = 'Goto/Apply Next Edit Suggestion',
    },
    {
      '<C-.>',
      function() require('sidekick.cli').focus() end,
      mode = { 'n', 't', 'i', 'x' },
      desc = 'Sidekick Focus',
    },
    {
      '<leader>kk',
      function() require('sidekick.cli').toggle() end,
      desc = 'Sidekick Toggle CLI',
    },
    {
      '<leader>kc',
      function() require('sidekick.cli').toggle({ name = 'claude', focus = true }) end,
      desc = 'Sidekick Toggle Claude',
    },
    {
      '<leader>ks',
      function() require('sidekick.cli').select({ filter = { installed = true } }) end,
      desc = 'Sidekick Select CLI',
    },
    {
      '<leader>kd',
      function() require('sidekick.cli').close() end,
      desc = 'Sidekick Detach CLI Session',
    },
    {
      '<leader>kt',
      function() require('sidekick.cli').send({ msg = '{this}' }) end,
      mode = { 'n', 'x' },
      desc = 'Sidekick Send This',
    },
    {
      '<leader>kf',
      function() require('sidekick.cli').send({ msg = '{file}' }) end,
      desc = 'Sidekick Send File',
    },
    {
      '<leader>kv',
      function() require('sidekick.cli').send({ msg = '{selection}' }) end,
      mode = { 'x' },
      desc = 'Sidekick Send Visual Selection',
    },
    {
      '<leader>kp',
      function() require('sidekick.cli').prompt() end,
      mode = { 'n', 'x' },
      desc = 'Sidekick Select Prompt',
    },
  },
}
