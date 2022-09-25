-- Automatically run :PackerCompile whenever plugins.lua is updated with an autocommand:
vim.api.nvim_create_autocmd('BufWritePost', {
    group = vim.api.nvim_create_augroup('PACKER', { clear = true }),
    pattern = 'plugins.lua',
    command = 'source <afile> | PackerCompile',
});

return require('packer').startup({
    function(use)
        ---------------------
        -- Package Manager --
        ---------------------

        use('wbthomason/packer.nvim');

        ----------------------
        -- Required plugins --
        ----------------------

        use('nvim-lua/plenary.nvim');

        ----------------------
        --    Dashboard     --
        ----------------------

        use({
            'glepnir/dashboard-nvim',
            config = function()
                require('amaanq.plugins.dashboard');
            end
        });

        ----------------------------------------
        -- Theme, Icons, Statusbar, Bufferbar --
        ----------------------------------------

        use({
            'kyazdani42/nvim-web-devicons',
            config = function()
                require('nvim-web-devicons').setup();
            end,
        });

        use({
            'numToStr/Sakura.nvim',
            config = function()
                require('amaanq.plugins.sakura');
            end,
        });

        use({
            {
                'nvim-lualine/lualine.nvim',
                after = 'Sakura.nvim',
                event = 'BufEnter',
                requires = { 'kyazdani42/nvim-web-devicons', opt = true },
                config = function()
                    require('amaanq.plugins.lualine');
                end,
            },
            {
                'j-hui/fidget.nvim',
                after = 'lualine.nvim',
                config = function()
                    require('fidget').setup();
                end,
            },
        });

        use({
            'akinsho/bufferline.nvim',
            tag = "v2.*",
            requires = 'kyazdani42/nvim-web-devicons',
            config = function()
                require('amaanq.plugins.bufferline');
            end,
        });

        -----------------------------------
        -- Treesitter: Better Highlights --
        -----------------------------------

        use({
            {
                'nvim-treesitter/nvim-treesitter',
                event = 'CursorHold',
                run = ':TSUpdate',
                config = function()
                    require('amaanq.plugins.treesitter');
                end,
            },
            { 'nvim-treesitter/playground', after = 'nvim-treesitter' },
            { 'nvim-treesitter/nvim-treesitter-textobjects', after = 'nvim-treesitter' },
            { 'nvim-treesitter/nvim-treesitter-refactor', after = 'nvim-treesitter' },
            { 'windwp/nvim-ts-autotag', after = 'nvim-treesitter' },
            { 'JoosepAlviste/nvim-ts-context-commentstring', after = 'nvim-treesitter' },
        });

        --------------------------
        -- Editor UI Niceties --
        --------------------------

        use({
            'lukas-reineke/indent-blankline.nvim',
            event = 'BufRead',
            config = function()
                require('amaanq.plugins.indentline');
            end,
        });

        use({
            'norcalli/nvim-colorizer.lua',
            event = 'CursorHold',
            config = function()
                require('colorizer').setup();
            end,
        });

        use({
            'lewis6991/gitsigns.nvim',
            event = 'BufRead',
            config = function()
                require('amaanq.plugins.gitsigns');
            end,
        });

        use({
            'rhysd/git-messenger.vim',
            event = 'BufRead',
            config = function()
                require('amaanq.plugins.git-messenger');
            end,
        });

        ---------------------------------
        -- Navigation and Fuzzy Search --
        ---------------------------------

        use({
            'kyazdani42/nvim-tree.lua',
            event = 'CursorHold',
            config = function()
                require('amaanq.plugins.nvim-tree');
            end,
        });

        use({
            {
                'nvim-telescope/telescope.nvim',
                event = 'CursorHold',
                config = function()
                    require('amaanq.plugins.telescope');
                end,
            },
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                after = 'telescope.nvim',
                run = 'make',
                config = function()
                    require('telescope').load_extension('fzf');
                end,
            },
            {
                'nvim-telescope/telescope-symbols.nvim',
                after = 'telescope.nvim',
            },
        });

        use({
            'numToStr/Navigator.nvim',
            event = 'CursorHold',
            config = function()
                require('amaanq.plugins.navigator');
            end,
        });

        use({
            'phaazon/hop.nvim',
            event = 'BufRead',
            config = function()
                require('amaanq.plugins.hop');
            end,
        });

        use({
            'karb94/neoscroll.nvim',
            event = 'WinScrolled',
            config = function()
                require('neoscroll').setup({ hide_cursor = false });
            end,
        });

        -------------------------
        -- Editing to the MOON --
        -------------------------

        use({
            'numToStr/Comment.nvim',
            event = 'BufRead',
            config = function()
                require('amaanq.plugins.comment');
            end,
        });

        -- use('numToStr/prettierrc.nvim');

        use({
            'tpope/vim-surround',
            event = 'BufRead',
            requires = {
                {
                    'tpope/vim-repeat',
                    event = 'BufRead',
                },
            },
        });

        use({
            'wellle/targets.vim',
            event = 'BufRead',
        });

        use({
            'AndrewRadev/splitjoin.vim',
            -- NOTE: splitjoin won't work with `BufRead` event
            event = 'CursorHold',
        });

        use({
            'numToStr/Buffers.nvim',
            event = 'BufRead',
            config = function()
                require('amaanq.plugins.buffers');
            end,
        });

        --------------
        -- Terminal --
        --------------

        use({
            "akinsho/toggleterm.nvim",
            tag = '*',
            config = function()
                require('amaanq.plugins.toggleterm');
            end,
        });

        -----------------------------------
        -- LSP, Completions and Snippets --
        -----------------------------------

        use({
            'neovim/nvim-lspconfig',
            event = 'BufRead',
            config = function()
                require('amaanq.plugins.lsp.servers')
            end,
            requires = {
                {
                    -- WARN: Unfortunately we won't be able to lazy load this
                    'hrsh7th/cmp-nvim-lsp',
                },
            },
        });

        use({
            'jose-elias-alvarez/null-ls.nvim',
            event = 'BufRead',
            config = function()
                require('amaanq.plugins.lsp.null-ls');
            end,
        });

        use({
            {
                'hrsh7th/nvim-cmp',
                event = 'InsertEnter',
                config = function()
                    require('amaanq.plugins.lsp.nvim-cmp')
                end,
                requires = {
                    {
                        'L3MON4D3/LuaSnip',
                        event = 'InsertEnter',
                        config = function()
                            require('amaanq.plugins.lsp.luasnip')
                        end,
                        requires = {
                            {
                                'rafamadriz/friendly-snippets',
                                event = 'CursorHold',
                            },
                        },
                    },
                },
            },
            { 'saadparwaiz1/cmp_luasnip', after = 'nvim-cmp' },
            { 'hrsh7th/cmp-path', after = 'nvim-cmp' },
            { 'hrsh7th/cmp-buffer', after = 'nvim-cmp' },
        });

        -- NOTE: nvim-autopairs needs to be loaded after nvim-cmp, so that <CR> would work properly
        use({
            'windwp/nvim-autopairs',
            event = 'InsertCharPre',
            after = 'nvim-cmp',
            config = function()
                require('amaanq.plugins.pairs')
            end,
        });

    end,
    config = {
        display = {
            open_fn = function()
                return require('packer.util').float({ border = 'single' });
            end,
        },
    },
})
