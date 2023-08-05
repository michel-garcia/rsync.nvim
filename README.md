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
            max_concurrent_jobs = 1,
            on_update = function (job)
                -- your custom callback
            end
        })
    end
}
```

Calling `setup` registers the [Commands](#commands) besides overriding the plugin configuration.

## Usage

Create a file `.rsync.lua` in the root directory of your project. This will serve as your local configuration.

Structure of the local config file:

```lua
return {
    host = "example.com", -- required
    port = 2222,
    user = "admin", -- required
    pass = "thereisnocowlevel",
    path = "/home/admin/public_html/", -- required
    exclude = {
        ".htaccess",
        "uploads/"
    }
}
```

This configuration file (`.rsync.lua`) will not be uploaded/downloaded as it is automatically added to the exclusion list.

### Commands

| Command | Description |
| --- | --- |
| `SyncDown [delete?]` | Downloads remote files/dirs |
| `SyncUp [delete?]` | Uploads local files/dirs |
| `SyncStop [job_id]` | Stops a sync job |
| `SyncStopAll` | Stops all sync jobs |

Both `SyncDown` and `SyncUp` accept `delete` as an **optional** argument which maps to `--delete` when executing `rsync`. **Use with caution as this could potentially result in data loss**. Refer to the manpages for `rsync` for more information.
