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

-- Alt-tab: jump back and forth between the last two focused tabs/panes.
-- Focus history is recorded by alt-tab-tracker.lua, a background `rex do`
-- script started here (once) when the config loads.
do
  local home = os.getenv("HOME")
  local tracker = home .. "/.config/rex/alt-tab-tracker.lua"
  local rex_bin = home .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
  rex.exec.start({ "sh", "-c",
    'mkdir -p "$HOME/.local/state/rex/alt-tab"; pgrep -f "[r]ex do --all .*alt-tab-tracker[.]lua" >/dev/null || exec "$0" do --all "$1" >"$HOME/.local/state/rex/alt-tab.log" 2>&1',
    rex_bin, tracker }, { detach = true })
end

rex.action{
  name     = "alt_tab",
  title    = "Go to Previous Tab or Pane",
  keywords = "alt tab last recent previous toggle switch back",
  run      = function(ctx, args)
    local here_s, here_b = ctx.session_id, nil
    if here_s == nil then return end
    -- The focused block of the session's active tab (more reliable than
    -- ctx.block_id, which can come from the caller's environment).
    local hv = rex.session.view{ session_id = here_s }
    for _, w in ipairs(hv and hv.windows or {}) do
      if w.window_id == hv.active_window_id then here_b = w.focused_block_id end
    end
    here_b = here_b or ctx.block_id
    if here_b == nil then return end
    local mru_path = os.getenv("HOME") .. "/.local/state/rex/alt-tab/mru"

    -- Read the MRU list ("session_id block_id" per line, most recent first).
    local list = {}
    local f = io.open(mru_path, "r")
    if f then
      for line in f:lines() do
        local s, b = line:match("^(%S+) (%S+)$")
        if s and b ~= here_b then list[#list + 1] = { s, b } end
      end
      f:close()
    end

    -- Jump to the most recent other block that still exists.
    local target
    while #list > 0 do
      local s, b = list[1][1], list[1][2]
      table.remove(list, 1)
      local _, err = rex.session.focus_block{ session_id = s, block_id = b }
      if err == nil then target = { s, b }; break end
    end

    -- New order: target, where we came from, then the rest.
    local out = {}
    if target then out[#out + 1] = target end
    out[#out + 1] = { here_s, here_b }
    for _, e in ipairs(list) do out[#out + 1] = e end
    f = io.open(mru_path, "w")
    if f then
      for i, e in ipairs(out) do
        if i > 30 then break end
        f:write(e[1], " ", e[2], "\n")
      end
      f:close()
    end

    -- Tell the app to show the target tab: it doesn't follow server-side
    -- focus changes made from its own key binding. pcall: from the CLI there
    -- may be no client, and the server-side focus above is enough.
    if target then
      local v = rex.session.view{ session_id = target[1] }
      pcall(rex.client.queue, "session.select", {
        session_id = target[1],
        window_id  = v and v.active_window_id or nil,
      })
    end
  end,
}

rex.bind("cmd+`", "alt_tab")
