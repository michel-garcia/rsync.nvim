# Rsync for Neovim

An rsync wrapper for Neovim fully written in Lua. This is currently a WIP, more features should eventually make their way into this plugin.

## Installation

This plugin requires [rsync](https://github.com/WayneD/rsync) to be installed. You must also install [sshpass](https://sourceforge.net/projects/sshpass/) **only if the remote connection requires a password**.

Using [Lazy](https://github.com/folke/lazy.nvim):

```lua
{
    "michel-garcia/rsync.nvim",
    config = function ()
        require("rsync").setup()
    end
}
```

Calling `setup` initializes the plugin. Currently this only registers two commands. Refer to [Usage](#usage) below for more information about these commands.

## Usage

First create a file `.rsync.lua`. This will be your local configuration and must exist in the root directory of your project.

Structure of the local config file:

```lua
return {
    host = "example.com",
    user = "admin",
    pass = "thereisnocowlevel",
    path = "/home/admin/public_html/",
    exclude = {
        ".htaccess",
        "uploads/"
    }
}
```

Once that has been set up you are ready to use the following commands:

- `:SyncDown` will download remote files/dirs.
- `:SyncUp` will upload local files/dirs.

Both commands accept `delete` as an argument which maps to `--delete` when executing `rsync`. **Use with caution as this may result in data loss**. Refer to the manpages for `rsync` for more information.

The local configuration file (`.rsync.lua`) will not be uploaded/downloaded as it is automatically added to the exclusion list.
