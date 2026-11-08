-- alt-tab-tracker.lua: keeps a most-recently-used list of focused blocks
-- (across all sessions) for the `alt_tab` action in init.lua.
-- Started automatically from init.lua as: rex do --all alt-tab-tracker.lua
--
-- Tab switches and pane focus changes inside a session emit
-- `session_view_changed`, so we watch the focused block of the active window.
-- Switching sessions in the app emits nothing; the alt_tab action covers that
-- by recording where it was invoked from.
--
-- MRU file format: one "session_id block_id" per line, most recent first.

local MRU = os.getenv("HOME") .. "/.local/state/rex/alt-tab/mru"
local MAX = 30

local function mru_read()
  local t = {}
  local f = io.open(MRU, "r")
  if f then
    for line in f:lines() do
      local s, b = line:match("^(%S+) (%S+)$")
      if s then t[#t + 1] = { s, b } end
    end
    f:close()
  end
  return t
end

local function mru_write(t)
  local f = io.open(MRU, "w")
  if not f then return end
  for _, e in ipairs(t) do f:write(e[1], " ", e[2], "\n") end
  f:close()
end

local function mru_push(s, b)
  local out = { { s, b } }
  for _, e in ipairs(mru_read()) do
    if e[2] ~= b and #out < MAX then out[#out + 1] = e end
  end
  mru_write(out)
end

local function mru_drop(pred)
  local out = {}
  for _, e in ipairs(mru_read()) do
    if not pred(e) then out[#out + 1] = e end
  end
  mru_write(out)
end

local current = {} -- session_id -> focused block_id

local function focused_block(session_id)
  local v = rex.session.view{ session_id = session_id }
  if v == nil then return nil end
  for _, w in ipairs(v.windows or {}) do
    if w.window_id == v.active_window_id then return w.focused_block_id end
  end
end

rex.on("session_view_changed", function(ctx, ev)
  local sid = ctx.session_id or ev.session_id
  if sid == nil then return end
  local now = focused_block(sid)
  if now == nil then return end
  local before = current[sid]
  current[sid] = now
  -- Skip the first observation of a session: it's not a user focus change.
  if before ~= nil and before ~= now then mru_push(sid, now) end
end)

rex.on("block_closed", function(ctx, ev)
  local bid = ev.block_id
  if bid then mru_drop(function(e) return e[2] == bid end) end
end)

rex.on("session_destroyed", function(ctx, ev)
  local sid = ctx.session_id or ev.session_id
  if sid == nil then return end
  current[sid] = nil
  mru_drop(function(e) return e[1] == sid end)
end)
