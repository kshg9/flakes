local o = vim.opt

o.number = true
o.relativenumber = true
o.swapfile = false
o.undofile = true
o.undodir = os.getenv("HOME") .. "/.local/share/nvim/undo"
o.smartcase = true
o.ignorecase = true
o.hlsearch = true
o.incsearch = true
o.wrap = false
o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.clipboard = "unnamedplus"
o.mouse = "a"
o.termguicolors = true
o.splitbelow = true
o.splitright = true
o.scrolloff = 8
o.signcolumn = "yes"

vim.g.mapleader = " "
