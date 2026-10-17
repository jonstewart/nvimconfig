-- GitHub Copilot
--
-- copilot.vim stopped seeing releases in January 2026 and runs a vendored
-- JavaScript language server, so it needs Node.js. copilot.lua defaults to the
-- native Copilot server binary instead, downloading and checksumming it on
-- first use, which keeps Node out of the picture entirely.
return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',

  config = function()
    require('copilot').setup({
      suggestion = {
        -- copilot.vim suggested as you typed; copilot.lua waits to be asked
        auto_trigger = true,
        -- with nothing visible, <Tab> falls through to sidekick's NES mapping
        -- (lua/plugins/sidekick.lua) and then a literal tab, instead of asking
        -- for a suggestion that auto_trigger is already fetching
        trigger_on_accept = false,
        keymap = {
          -- the bindings copilot.vim used, so muscle memory carries over
          accept = '<Tab>',
          next = '<M-]>',
          prev = '<M-[>',
          dismiss = '<C-]>',
        },
      },
    })
  end,
}
