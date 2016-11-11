local wibox = require 'wibox'
local awful = require 'awful'

local keymap = {}
local metatable = {__index = keymap}

function keymap.new(...)
  local self = {
    cmd = 'setxkbmap',
    widget = wibox.widget.textbox(),
    mappings = {...},
    active = 1,
  }
  setmetatable(self, metatable)
  local mapping = self.mappings[self.active]
  self.widget:set_text(mapping.text)
  awful.util.spawn(table.concat({self.cmd, mapping.layout}, ' '))
  self.widget:buttons(awful.util.table.join(
    awful.button({ }, 1, function() self:switch() end),
    awful.button({ }, 3, function() self:switch(true) end)
  ))
  return self
end

function keymap:switch(reverse)
  if reverse then
    if self.active == 1 then
      self.active = #self.mappings
    else
      self.active = self.active - 1
    end
  else
    if self.active == #self.mappings then
      self.active = 1
    else
      self.active = self.active + 1
    end
  end
  local mapping = self.mappings[self.active]
  awful.util.spawn(table.concat({self.cmd, mapping.layout}, ' '))
  self.widget:set_text(mapping.text)
end

return keymap
