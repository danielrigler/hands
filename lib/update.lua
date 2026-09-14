local Update = {}
Update.__index = Update

local function trim(s)
  s = (s or ""):gsub("^%s+", "")
  return (s:gsub("%s+$", ""))
end

local function git(self, args)
  return trim(util.os_capture("git -C '" .. self.path .. "' " .. args .. " 2>/dev/null"))
end

function Update:new(args)
  local m = setmetatable({}, Update)
  for k, v in pairs(args or {}) do m[k] = v end
  local st = norns.state or {}
  m.path = trim(m.path or st.path):gsub("/$", "")
  m.name = m.name or st.shortname or "script"
  m.state, m.behind, m.message = nil, 0, nil
  return m
end

function Update:is_git()
  return git(self, "rev-parse --is-inside-work-tree") == "true"
end

function Update:is_dirty()
  return git(self, "status --porcelain --untracked-files=no") ~= ""
end

function Update:count_behind()
  return tonumber(git(self, "rev-list --count HEAD..@{u}")) or 0
end

function Update:check()
  if self.state or self.path == "" or not self:is_git() then return end
  self.state = "checking"
  norns.system_cmd("timeout -k 5 20 git -C '" .. self.path .. "' fetch --quiet 2>/dev/null; echo _done_",
    function()
      self.behind = self:count_behind()
      if self.behind <= 0 then
        self.state = nil
      elseif self:is_dirty() then
        print("[" .. self.name .. "] " .. self.behind ..
              " update(s) available, but there are local changes; skipping.")
        self.state = nil
      else
        self.state = "update"
      end
      if self.on_change then self.on_change() end
    end)
end

function Update:install()
  self.state = "installing"
  self.message = nil
  if self.on_change then self.on_change() end
  norns.system_cmd("git -C '" .. self.path .. "' pull --ff-only 2>&1", function(out)
    if self:count_behind() == 0 then
      self.state = "reloading"
      if self.on_change then self.on_change() end
      clock.run(function() clock.sleep(0.4); norns.rerun() end)
    else
      self.message = "update failed"
      self.state = "error"
      print("[" .. self.name .. "] update failed: " .. tostring(out))
      if self.on_change then self.on_change() end
    end
  end)
end

local PENDING = {update = true, installing = true, reloading = true, error = true}

function Update:pending()
  return PENDING[self.state] == true
end

function Update:key(k, z)
  if z ~= 1 then return end
  local s = self.state
  if s == "update" then
    if k == 2 then self.state = nil
    elseif k == 3 then self:install() end
  elseif s == "error" then
    if k == 2 or k == 3 then self.state = nil end
  end
end

function Update:redraw()
  screen.clear()
  screen.aa(0)
  screen.blend_mode(0)
  screen.level(15)
  local s = self.state
  if s == "update" then
    screen.move(64, 18); screen.text_center(self.name .. " update available")
    screen.level(1)
    screen.move(64, 30)
    screen.text_center(self.behind .. " new commit" .. (self.behind == 1 and "" or "s"))
    screen.level(15)
    screen.move(64, 46); screen.text_center("K2: skip   K3: install")
  elseif s == "installing" then
    screen.move(64, 28); screen.text_center("installing update...")
  elseif s == "reloading" then
    screen.move(64, 28); screen.text_center("updated - reloading...")
  elseif s == "error" then
    screen.move(64, 24); screen.text_center(self.message or "update error")
    screen.move(64, 40); screen.text_center("K2/K3: dismiss")
  end
  screen.update()
end

return Update
