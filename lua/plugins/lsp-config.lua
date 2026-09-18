-- LSP, neovim >= 0.11 style: servers are configured with vim.lsp.config and
-- switched on with vim.lsp.enable; nvim-lspconfig only contributes the
-- per-server defaults (cmd, root markers, filetypes) from its lsp/ directory.
--
-- mason-lspconfig v2 installs the servers where Mason's prebuilt binaries can
-- run (Debian, macOS) and enables the ones it installed (automatic_enable;
-- setup_handlers is gone). On NixOS (/etc/NIXOS) those binaries cannot run —
-- no FHS loader — so Mason installs nothing and the image's own clangd and
-- rust-analyzer on PATH, version-matched to its toolchain, are enabled here.
local servers = {
  -- name = config table merged over nvim-lspconfig's defaults for that
  -- server: e.g. `settings = { ... }`, `filetypes = { ... }`.
  clangd = {},
  rust_analyzer = {},
}
local on_nixos = vim.uv.fs_stat('/etc/NIXOS') ~= nil

return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'mason-org/mason.nvim', opts = {} },
    'mason-org/mason-lspconfig.nvim',

    -- Useful status updates for LSP
    { 'j-hui/fidget.nvim', opts = {} },

    -- Lua: completion for the neovim API and plugin sources (neodev's successor)
    { 'folke/lazydev.nvim', ft = 'lua', opts = {} },

    'hrsh7th/cmp-nvim-lsp',
  },
  config = function()
    -- Buffer-local keymaps, once a server attaches.
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('nvimconfig-lsp-attach', { clear = true }),
      callback = function(event)
        local bufnr = event.buf
        local nmap = function(keys, func, desc)
          if desc then
            desc = 'LSP: ' .. desc
          end
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
        end

        nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

        nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
        nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
        nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
        nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

        -- See `:help K` for why this keymap
        nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
        nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

        -- Lesser used LSP functionality
        nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
        nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
        nmap('<leader>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, '[W]orkspace [L]ist Folders')

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
          vim.lsp.buf.format()
        end, { desc = 'Format current buffer with LSP' })
      end,
    })

    -- nvim-cmp supports additional completion capabilities; every server gets them.
    vim.lsp.config('*', {
      capabilities = require('cmp_nvim_lsp').default_capabilities(),
    })
    for name, config in pairs(servers) do
      vim.lsp.config(name, config)
    end

    require('mason-lspconfig').setup({
      ensure_installed = on_nixos and {} or vim.tbl_keys(servers),
      automatic_enable = not on_nixos,
    })
    if on_nixos then
      vim.lsp.enable(vim.tbl_keys(servers))
    end
  end,
}
