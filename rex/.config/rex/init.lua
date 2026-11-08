-- Project picker: fuzzy search git repos under ~/dev and open the chosen project
-- in its own session (or switch to it if that session already exists).
rex.action{
  name     = "project_picker",
  title    = "Open Project…",
  keywords = "project fzf workspace open",
  run      = function(ctx, args)
    local home = os.getenv("HOME")
    local cmd = { home .. "/.config/rex/bin/project-picker" }
    if ctx.client_id ~= nil then
      cmd = { "env", "REX_CLIENT=" .. ctx.client_id, cmd[1] }
    end
    local _, err = rex.session.new_layer{
      bounds = { 0.15, 0.15, 0.7, 0.6 },
      focus  = true,
      layout = rex.layout.block{
        flavor  = "com.superlogical.terminal.shell",
        options = { command = cmd, cwd = home .. "/dev" },
      },
    }
    if err ~= nil then error(err, 0) end
  end,
}

rex.bind("cmd+shift+o", "project_picker")
