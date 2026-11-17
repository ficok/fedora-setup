-- Plugins
local vim = vim
local Plug = vim.fn['plug#']

vim.call('plug#begin')
    -- LSP
    Plug('mason-org/mason.nvim')
    Plug('mason-org/mason-lspconfig.nvim')
    Plug('neovim/nvim-lspconfig')
    Plug('hrsh7th/cmp-nvim-lsp')
    Plug('hrsh7th/nvim-cmp')
    Plug('elkowar/yuck.vim')
    Plug('saghen/blink.cmp', { ['tag'] = 'v1.*' })
    Plug('windwp/nvim-autopairs')

    -- Tools
    Plug('numToStr/Comment.nvim')

    -- Look & feel
    Plug('folke/tokyonight.nvim')
    Plug('Shatur/neovim-ayu')
    Plug('ellisonleao/gruvbox.nvim')
vim.call('plug#end')

require('Comment').setup()
require('mason').setup()
require('mason-lspconfig').setup()

-- Options
vim.wo.number = true
vim.wo.relativenumber = true
vim.bo.tabstop = 4
vim.o.shiftwidth = 4
vim.bo.expandtab = true
vim.bo.autoindent = true
vim.wo.colorcolumn = "90"
vim.opt.syntax = "on"
vim.opt.cursorline = true
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})

-- Look & feel
vim.opt.termguicolors = true
require('ayu').setup({
    mirage = false,
    terminal = true,
    overrides = {},
})
-- vim.o.guifont = "JetBrains Mono:h12"
require("gruvbox").setup({
    overrides = {
        SignColumn = { bg = "#141414" },
        CursorLine = { bg = "#212121" },
    },
    palette_overrides = {
        dark0 = "#141414",
        dark1 = "#191919",
        dark2 = "#212121",
        dark3 = "#252525",
    },
    italic = {
        strings = false,
        operators = false,
    },
})
vim.cmd("colorscheme gruvbox")
-- vim.cmd.colorscheme('tokyonight')

-- LSP
require('blink.cmp').setup({
    keymap = { preset = 'default' },
    appearance = {
        nerd_font_variant = 'mono'
    },
    completion = {
        documentation = { auto_show = false }
    },
    sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
    },
    fuzzy = {
        implementation = "prefer_rust_with_warning"
    }
})
require('nvim-autopairs').setup({
    check_ts = true,
    fast_wrap = {
        -- is the cursor is just before a "word", pressing Alt+e+( will automatically
        -- wrap "word": (word). same for any other bracket
        map = "<M-e>",
    },
    disable_filetype = { "TelescopePrompt" },
})
vim.lsp.config('clangd', {
    init_options = {
        fallbackFlags = { '--std=c++17' }
    },
})

vim.lsp.config('pyright', {
    settings = {
        python = {
            analysis = { autoSearchPaths = true }
        }
    }
})
vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
            diagnostics = {
                globals = { 'vim' },
            },
            telemetry = {
                enable = false,
            },
        }
    }
})

vim.lsp.config('*', {
    capabilities = require('blink.cmp').get_lsp_capabilities()
})

vim.lsp.enable({
    'clangd',
    'pyright'
})

