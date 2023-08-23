# Rsync for Neovim

An rsync wrapper for Neovim fully written in Lua. This is currently a WIP, more features should eventually make their way into this plugin.

## Installation

Dependencies:

- [rsync](https://github.com/WayneD/rsync)
- [sshpass](https://sourceforge.net/projects/sshpass/) - required only if using remote password

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
    }
}
```

This config file (`.rsync.lua`) will not be uploaded/downloaded as it is automatically added to the exclusion list.

### Commands

| Command | Description |
| --- | --- |
| `SyncDown [delete?]` | Downloads remote files/dirs |
| `SyncUp [delete?]` | Uploads local files/dirs |
| `SyncCurDown` | Downloads file in current buffer |
| `SyncCurUp` | Uploads file in current buffer |
| `SyncStop` | Stops the current sync job (if any) |

Both `SyncDown` and `SyncUp` accept `delete` as an **optional** argument which maps to `--delete` when executing `rsync`. **Use with caution as this could potentially result in data loss**. Refer to the manpages for `rsync` for more information.
