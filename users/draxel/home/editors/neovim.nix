# Neovim configuration
{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      # LSP servers
      nil                    # Nix
      lua-language-server    # Lua
      nodePackages.typescript-language-server  # TypeScript/JavaScript
      nodePackages.vscode-langservers-extracted  # HTML/CSS/JSON
      pyright                # Python

      # Formatters
      nixpkgs-fmt            # Nix
      stylua                 # Lua
      nodePackages.prettier  # Web
      black                  # Python

      # Tools
      ripgrep
      fd
    ];

    extraLuaConfig = ''
      -- Basic settings
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.expandtab = true
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.smartindent = true
      vim.opt.clipboard = "unnamedplus"
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.termguicolors = true
      vim.opt.signcolumn = "yes"
      vim.opt.updatetime = 250
      vim.opt.timeoutlen = 300
      vim.opt.splitright = true
      vim.opt.splitbelow = true
      vim.opt.scrolloff = 8
      vim.opt.cursorline = true
      vim.opt.undofile = true
      vim.opt.mouse = "a"

      -- Leader key
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      -- Basic keymaps
      vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
      vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
      vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search" })

      -- Window navigation
      vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
      vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
      vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
      vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

      -- Buffer navigation
      vim.keymap.set("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
      vim.keymap.set("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
      vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

      -- Better indenting in visual mode
      vim.keymap.set("v", "<", "<gv")
      vim.keymap.set("v", ">", ">gv")

      -- Move lines
      vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move down" })
      vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move up" })

      -- Diagnostic keymaps
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
      vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic error" })
    '';

    plugins = with pkgs.vimPlugins; [
      # Colorscheme - One Dark Pro
      {
        plugin = onedarkpro-nvim;
        type = "lua";
        config = ''
          require("onedarkpro").setup({
            options = {
              transparency = false,
              cursorline = true,
            },
          })
          vim.cmd.colorscheme "onedark"
        '';
      }

      # Syntax highlighting
      {
        plugin = nvim-treesitter.withAllGrammars;
        type = "lua";
        config = ''
          require("nvim-treesitter.configs").setup({
            highlight = { enable = true },
            indent = { enable = true },
          })
        '';
      }

      # File explorer
      {
        plugin = neo-tree-nvim;
        type = "lua";
        config = ''
          require("neo-tree").setup({
            close_if_last_window = true,
            filesystem = {
              follow_current_file = { enabled = true },
              use_libuv_file_watcher = true,
            },
          })
          vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "File explorer" })
        '';
      }
      nvim-web-devicons
      plenary-nvim

      # Fuzzy finder
      {
        plugin = telescope-nvim;
        type = "lua";
        config = ''
          local telescope = require("telescope")
          telescope.setup({
            defaults = {
              path_display = { "truncate" },
            },
          })
          local builtin = require("telescope.builtin")
          vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
          vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
          vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
          vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
          vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
          vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Search in buffer" })
        '';
      }
      telescope-fzf-native-nvim

      # LSP
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = ''
          -- LSP keymaps on attach
          vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(event)
              local map = function(keys, func, desc)
                vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
              end
              map("gd", vim.lsp.buf.definition, "Go to definition")
              map("gD", vim.lsp.buf.declaration, "Go to declaration")
              map("gr", vim.lsp.buf.references, "Go to references")
              map("gi", vim.lsp.buf.implementation, "Go to implementation")
              map("K", vim.lsp.buf.hover, "Hover documentation")
              map("<leader>ca", vim.lsp.buf.code_action, "Code action")
              map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
              map("<leader>D", vim.lsp.buf.type_definition, "Type definition")
            end,
          })

          -- LSP servers using new vim.lsp.config API (nvim 0.11+)
          vim.lsp.config("nil_ls", {})
          vim.lsp.config("lua_ls", {})
          vim.lsp.config("ts_ls", {})
          vim.lsp.config("pyright", {})

          -- Enable the configured LSP servers
          vim.lsp.enable({ "nil_ls", "lua_ls", "ts_ls", "pyright" })
        '';
      }

      # Autocompletion
      {
        plugin = nvim-cmp;
        type = "lua";
        config = ''
          local cmp = require("cmp")
          cmp.setup({
            snippet = {
              expand = function(args)
                require("luasnip").lsp_expand(args.body)
              end,
            },
            mapping = cmp.mapping.preset.insert({
              ["<C-b>"] = cmp.mapping.scroll_docs(-4),
              ["<C-f>"] = cmp.mapping.scroll_docs(4),
              ["<C-Space>"] = cmp.mapping.complete(),
              ["<C-e>"] = cmp.mapping.abort(),
              ["<CR>"] = cmp.mapping.confirm({ select = true }),
              ["<Tab>"] = cmp.mapping.select_next_item(),
              ["<S-Tab>"] = cmp.mapping.select_prev_item(),
            }),
            sources = cmp.config.sources({
              { name = "nvim_lsp" },
              { name = "luasnip" },
              { name = "path" },
            }, {
              { name = "buffer" },
            }),
          })
        '';
      }
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      cmp_luasnip

      # Git
      {
        plugin = gitsigns-nvim;
        type = "lua";
        config = ''
          require("gitsigns").setup({
            signs = {
              add = { text = "│" },
              change = { text = "│" },
              delete = { text = "_" },
              topdelete = { text = "‾" },
              changedelete = { text = "~" },
            },
          })
        '';
      }

      # Which key
      {
        plugin = which-key-nvim;
        type = "lua";
        config = ''
          require("which-key").setup({})
        '';
      }

      # Statusline
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''
          require("lualine").setup({
            options = {
              theme = "onedark",
              component_separators = { left = "", right = "" },
              section_separators = { left = "", right = "" },
            },
          })
        '';
      }

      # Auto pairs
      {
        plugin = nvim-autopairs;
        type = "lua";
        config = ''require("nvim-autopairs").setup({})'';
      }

      # Comment
      {
        plugin = comment-nvim;
        type = "lua";
        config = ''require("Comment").setup({})'';
      }

      # Indent guides
      {
        plugin = indent-blankline-nvim;
        type = "lua";
        config = ''
          require("ibl").setup({
            indent = { char = "│" },
            scope = { enabled = true },
          })
        '';
      }
    ];
  };
}
