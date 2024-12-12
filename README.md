# Rsync for Neovim

An rsync wrapper for Neovim fully written in Lua. This is currently a WIP, more features should eventually make their way into this plugin.

## Installation

Dependencies:

- [rsync](https://github.com/WayneD/rsync)
- [sshpass](https://sourceforge.net/projects/sshpass/) - required if using a password

Using [Lazy](https://github.com/folke/lazy.nvim):

```lua
{
    "michel-garcia/rsync.nvim",
    config = function ()
        require("rsync").setup({
            sync_up_on_write = false
        })
    end
}
```

## Usage

Create a file `.rsync.lua` in the root directory of your project:

```lua
return {
    host = "example.com", -- required
    port = 2222,
    user = "admin", -- required
    pass = "thereisnocowlevel",
    path = "/home/admin/public_html", -- required
    exclude = {
        ".htaccess",
        "uploads/"
    },
    disable_mkpath = false -- set to true for compatibility with rsync v3.2.3 and lower
}
```

This config file (`.rsync.lua`) will not be uploaded/downloaded as it is automatically added to the exclusion list.

### Commands

| Command | Description |
| --- | --- |
| `SyncDown [current?] [delete?]` | Downloads remote files/dirs |
| `SyncUp [current?] [delete?]` | Uploads local files/dirs |
| `SyncStop` | Stops all active jobs (if any) |

Both `SyncDown` and `SyncUp` accept `delete` as an **optional** argument which maps to `--delete` when executing `rsync`. **Use with caution as this could potentially result in data loss**. Refer to the manpages for `rsync` for more information.

Similarly, passing `current` to either `SyncDown` or `SyncUp` will make the command sync the file in the current buffer only.
