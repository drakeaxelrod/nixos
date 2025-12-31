# Neovim configuration using NixVim
{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # =========================================================================
    # General Settings
    # =========================================================================
    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    opts = {
      # Line numbers
      number = true;
      relativenumber = true;

      # Tabs and indentation
      expandtab = true;
      tabstop = 2;
      shiftwidth = 2;
      smartindent = true;
      autoindent = true;

      # Search
      ignorecase = true;
      smartcase = true;
      hlsearch = true;
      incsearch = true;

      # UI
      termguicolors = true;
      signcolumn = "yes";
      cursorline = true;
      scrolloff = 8;
      sidescrolloff = 8;
      splitright = true;
      splitbelow = true;

      # Editing
      clipboard = "unnamedplus";
      mouse = "a";
      undofile = true;
      updatetime = 250;
      timeoutlen = 300;
      completeopt = "menu,menuone,noselect";

      # Appearance
      showmode = false;
      wrap = false;
    };

    # =========================================================================
    # Colorscheme - One Dark Pro
    # =========================================================================
    colorschemes.onedark = {
      enable = true;
      settings = {
        style = "dark";
        transparent = false;
        ending_tildes = true;
        code_style = {
          comments = "italic";
          keywords = "bold";
          functions = "none";
          strings = "none";
          variables = "none";
        };
      };
    };

    # =========================================================================
    # Plugins
    # =========================================================================

    # Syntax highlighting
    plugins.treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
        incremental_selection.enable = true;
      };
    };

    # File explorer
    plugins.neo-tree = {
      enable = true;
      settings = {
        close_if_last_window = true;
        filesystem = {
          follow_current_file = {
            enabled = true;
          };
          use_libuv_file_watcher = true;
        };
      };
    };

    # Fuzzy finder
    plugins.telescope = {
      enable = true;
      extensions.fzf-native.enable = true;
      settings = {
        defaults = {
          path_display = ["truncate"];
          mappings = {
            i = {
              "<C-j>".__raw = "require('telescope.actions').move_selection_next";
              "<C-k>".__raw = "require('telescope.actions').move_selection_previous";
            };
          };
        };
      };
      keymaps = {
        "<leader>ff" = {
          action = "find_files";
          options.desc = "Find files";
        };
        "<leader>fg" = {
          action = "live_grep";
          options.desc = "Live grep";
        };
        "<leader>fb" = {
          action = "buffers";
          options.desc = "Buffers";
        };
        "<leader>fh" = {
          action = "help_tags";
          options.desc = "Help tags";
        };
        "<leader>fr" = {
          action = "oldfiles";
          options.desc = "Recent files";
        };
        "<leader>/" = {
          action = "current_buffer_fuzzy_find";
          options.desc = "Search in buffer";
        };
      };
    };

    # LSP
    plugins.lsp = {
      enable = true;
      servers = {
        nil_ls.enable = true;  # Nix
        lua_ls.enable = true;  # Lua
        ts_ls.enable = true;   # TypeScript/JavaScript
        pyright.enable = true; # Python
        html.enable = true;    # HTML
        cssls.enable = true;   # CSS
        jsonls.enable = true;  # JSON
      };
      keymaps = {
        diagnostic = {
          "[d" = "goto_prev";
          "]d" = "goto_next";
          "<leader>e" = "open_float";
        };
        lspBuf = {
          "gd" = "definition";
          "gD" = "declaration";
          "gr" = "references";
          "gi" = "implementation";
          "K" = "hover";
          "<leader>ca" = "code_action";
          "<leader>rn" = "rename";
          "<leader>D" = "type_definition";
        };
      };
    };

    # Autocompletion
    plugins.cmp = {
      enable = true;
      autoEnableSources = true;
      settings = {
        snippet.expand = ''
          function(args)
            require('luasnip').lsp_expand(args.body)
          end
        '';
        mapping = {
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-e>" = "cmp.mapping.abort()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";
          "<Tab>" = "cmp.mapping.select_next_item()";
          "<S-Tab>" = "cmp.mapping.select_prev_item()";
        };
        sources = [
          { name = "nvim_lsp"; }
          { name = "luasnip"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
      };
    };

    plugins.cmp-nvim-lsp.enable = true;
    plugins.cmp-buffer.enable = true;
    plugins.cmp-path.enable = true;
    plugins.luasnip.enable = true;
    plugins.cmp_luasnip.enable = true;

    # Formatting
    plugins.conform-nvim = {
      enable = true;
      settings = {
        formatters_by_ft = {
          nix = ["nixpkgs_fmt"];
          lua = ["stylua"];
          javascript = ["prettier"];
          typescript = ["prettier"];
          python = ["black"];
          html = ["prettier"];
          css = ["prettier"];
          json = ["prettier"];
          markdown = ["prettier"];
        };
        format_on_save = {
          lsp_fallback = true;
          timeout_ms = 500;
        };
      };
    };

    # Git integration
    plugins.gitsigns = {
      enable = true;
      settings = {
        signs = {
          add.text = "│";
          change.text = "│";
          delete.text = "_";
          topdelete.text = "‾";
          changedelete.text = "~";
        };
      };
    };

    # Which key - shows keybindings
    plugins.which-key = {
      enable = true;
    };

    # Statusline
    plugins.lualine = {
      enable = true;
      settings = {
        options = {
          theme = "onedark";
          component_separators = {
            left = "";
            right = "";
          };
          section_separators = {
            left = "";
            right = "";
          };
        };
      };
    };

    # Auto pairs
    plugins.nvim-autopairs.enable = true;

    # Comment
    plugins.comment.enable = true;

    # Indent guides
    plugins.indent-blankline = {
      enable = true;
      settings = {
        indent.char = "│";
        scope.enabled = true;
      };
    };

    # Git blame
    plugins.gitblame.enable = true;

    # Surround
    plugins.nvim-surround.enable = true;

    # Better f/t motions
    plugins.leap.enable = true;

    # Web devicons (required by telescope and neo-tree)
    plugins.web-devicons.enable = true;

    # =========================================================================
    # Keymaps
    # =========================================================================
    keymaps = [
      # General
      {
        mode = "n";
        key = "<leader>w";
        action = "<cmd>w<cr>";
        options.desc = "Save";
      }
      {
        mode = "n";
        key = "<leader>q";
        action = "<cmd>q<cr>";
        options.desc = "Quit";
      }
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<cr>";
        options.desc = "Clear search";
      }

      # Window navigation
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options.desc = "Go to left window";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options.desc = "Go to lower window";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options.desc = "Go to upper window";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options.desc = "Go to right window";
      }

      # Buffer navigation
      {
        mode = "n";
        key = "<S-h>";
        action = "<cmd>bprevious<cr>";
        options.desc = "Prev buffer";
      }
      {
        mode = "n";
        key = "<S-l>";
        action = "<cmd>bnext<cr>";
        options.desc = "Next buffer";
      }
      {
        mode = "n";
        key = "<leader>bd";
        action = "<cmd>bdelete<cr>";
        options.desc = "Delete buffer";
      }

      # File explorer
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "File explorer";
      }

      # Better indenting
      {
        mode = "v";
        key = "<";
        action = "<gv";
      }
      {
        mode = "v";
        key = ">";
        action = ">gv";
      }

      # Move lines
      {
        mode = "v";
        key = "J";
        action = ":m '>+1<CR>gv=gv";
        options.desc = "Move down";
      }
      {
        mode = "v";
        key = "K";
        action = ":m '<-2<CR>gv=gv";
        options.desc = "Move up";
      }
    ];

    # =========================================================================
    # Extra Packages
    # =========================================================================
    extraPackages = with pkgs; [
      # Formatters
      nixpkgs-fmt
      stylua
      nodePackages.prettier
      black

      # Tools
      ripgrep
      fd
    ];
  };
}
