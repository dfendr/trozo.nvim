# Creta for Neovim

## Name

Latin for "chalk," symbolizing writing and sharing.

- Creta is a Neovim plugin that allows you to easily upload selected text to `paste.rs` and retrieve a shareable URL. It is designed to be simple and work out of the box.

## Features

- Upload selected text to `paste.rs` directly from Neovim.
- Automatically open the resulting URL in your default web browser.
- Option to copy the URL to the clipboard.

## Prerequisites

- cURL must be installed on your system.

## Installation

### Using packer.nvim

```lua
use {
  'postfen/creta.nvim',
  config = function()
    require('creta').setup()
  end
}
```

### Using lazy.nvim

```lua
return {
  'postfen/creta.nvim',
  config = {
        clipboard = true,
        browser = true
    },
}
```

## Usage

Select the text you want to upload in visual mode and run the `:Creta` command.

## Configuration

Creta aims to work well without configuration, but it does offer a couple of options for those who want them:

\`\`\`lua
require('creta').setup({
auto_open_browser = true, -- Automatically open the URL in the default web browser (default: true)
copy_to_clipboard = false, -- Copy the URL to the clipboard (default: false)
})
\`\`\`
