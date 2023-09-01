# Trozo for Neovim

- Trozo is a Neovim plugin that allows you to easily upload selected text or the entire file to \`paste.rs\` and retrieve a shareable URL. It is designed to be simple and work out of the box.

## Features

- Upload selected text to `paste.rs` directly from Neovim.
- Upload the entire file to `paste.rs`.
- Automatically open the resulting URL in your default web browser.
- Option to copy the URL to the clipboard.

## Prerequisites

- cURL must be installed on your system.

## Configuration

Trozo aims to work well without configuration, but it does offer a couple of options for those who want them:

### Defaults

```lua
require('trozo').setup({
  auto_open_browser = true,  -- Automatically open the URL in the default web browser (default: true)
  copy_to_clipboard = false, -- Copy the URL to the clipboard (default: false)
})
```

## Installation

### Using packer.nvim

```lua
use {
  'postfen/trozo.nvim',
  config = function()
    require('trozo').setup()
  end
}
```

### Using lazy.nvim

```lua
return {
    {
        "postfen/trozo.nvim",
        config = true,
        cmd = {"TrozoUploadSelection", "TrozoUploadFile"}
    },
}
```

## Usage

| Command          | Action                                           |
|------------------|--------------------------------------------------|
| TrozoUpload     | Uploads the selected text to paste.rs.       |
| TrozoUploadFile | Uploads the entire file to paste.rs.         |

### Using Which-Key.nvim

```lua
    local status_ok, which_key = pcall(require, "which-key")
    if not status_ok then
        return
    end

    local xmappings = {
        s = {
            ":'<,'>TrozoUploadSelection<CR>",
            "Upload V-Selection To paste.rs",
        },
        S = {
            ":TrozoUploadFile<CR>",
            "Upload File To paste.rs",
        },
    }
    local xopts = {
        mode = "x", -- VISUAL mode
        prefix = "<leader>",
        buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
        silent = true, -- use `silent` when creating keymaps
        noremap = true, -- use `noremap` when creating keymaps
        nowait = true, -- use `nowait` when creating keymaps
    }

    which_key.register(xmappings, xopts)

```

## Warning

> paste.rs is heavily rate limited.
> You may find that some selections aren't being fully uploaded.
> If this is the case, wait a few minutes before trying to upload again.
