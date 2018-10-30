require 'luarocks.loader'
local wibox = require "wibox"
local timer = require "gears.timer"
local awful = require 'awful'
local ldbus = require 'ldbus'

local bluetooth = {}
function bluetooth.check()
  local conn = assert(ldbus.bus.get("system"))

  local msg = assert(ldbus.message.new_method_call(
  "org.bluez",
  "/org/bluez/hci0",
  "org.freedesktop.DBus.Properties",
  "Get"))

  local params = ldbus.message.iter.new()
  msg:iter_init_append(params)
  params:append_basic("org.bluez.Adapter1")
  params:append_basic("Powered")

  local reply = assert(conn:send_with_reply_and_block(msg))

  -- Need to recurse, because it's a variant
  return reply:iter_init():recurse():get_basic()
end

function bluetooth.toggle(poweron)
  local conn = assert(ldbus.bus.get("system"))

  local msg = assert(ldbus.message.new_method_call(
  "org.bluez",
  "/org/bluez/hci0",
  "org.freedesktop.DBus.Properties",
  "Set"))

  local params = msg:iter_init_append()
  params:append_basic("org.bluez.Adapter1")
  params:append_basic("Powered")
  local variant = params:open_container('v', 'b')
  variant:append_basic(poweron)
  params:close_container(variant)

  assert(conn:send_with_reply_and_block(msg))

  if poweron then
    local msg = assert(ldbus.message.new_method_call(
    "org.bluez",
    "/org/bluez/hci0",
    "org.freedesktop.DBus.Properties",
    "Set"))

    local params = msg:iter_init_append()
    params:append_basic("org.bluez.Adapter1")
    params:append_basic("Discoverable")
    local variant = params:open_container('v', 'b')
    variant:append_basic(true)
    params:close_container(variant)

    assert(conn:send_with_reply_and_block(msg))
  end
end

function bluetooth:callcheck()
  return function()
    local good, powered = pcall(self.check)
    if good then
      if powered then
        self.widget:set_image(self.images.on)
      else
        self.widget:set_image(self.images.off)
      end
    else
      self.widget:set_image(self.images.err)
    end
  end
end

function bluetooth.new(on, off, loading, err, timeout)
  timeout = timeout or 10

  local self = {
    widget = wibox.widget.imagebox(),
    images = {
      on = on, off = off, err = err
    }}
    self.widget:set_image(loading)
    setmetatable(self, {__index = bluetooth})
    local bluetoothtimer = timer{timeout = timeout}
    bluetoothtimer:connect_signal('timeout', self:callcheck())
    bluetoothtimer:start()
    self.widget:buttons(awful.util.table.join(awful.button({ }, 1, function()
      local good, powered = pcall(bluetooth.check)
      if good then
        if powered then
          bluetooth.toggle(false)
        else
          bluetooth.toggle(true)
        end
      end
      self:callcheck()()
    end)))
    return self
end

return bluetooth
