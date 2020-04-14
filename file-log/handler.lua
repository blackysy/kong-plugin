-- Copyright (C) Kong Inc.
local ffi = require "ffi"
local cjson = require "cjson"
local system_constants = require "lua_system_constants"
local basic_serializer = require "kong.plugins.log-serializers.basic"

local O_CREAT = system_constants.O_CREAT()
local O_WRONLY = system_constants.O_WRONLY()
local O_APPEND = system_constants.O_APPEND()
local S_IRUSR = system_constants.S_IRUSR()
local S_IWUSR = system_constants.S_IWUSR()
local S_IRGRP = system_constants.S_IRGRP()
local S_IROTH = system_constants.S_IROTH()

local oflags = bit.bor(O_WRONLY, O_CREAT, O_APPEND)

local mode = bit.bor(S_IRUSR, S_IWUSR, S_IRGRP, S_IROTH)

local C = ffi.C
local serialize = basic_serializer.serialize

ffi.cdef[[
int write(int fd, const void * ptr, int numbytes);
]]

-- fd tracking utility functions
local file_descriptors = {}

-- Log to a file. Function used as callback from an nginx timer.
-- @param `premature` see OpenResty `ngx.timer.at()`
-- @param `conf`     Configuration table, holds http endpoint details
-- @param `message`  Message to be logged
local function log(conf, message)
  local msg = cjson.encode(message) .. "\n"

  -- Get log directory, if is no then create directory.
  local conf_dir = string.match(conf.path, "(.+)/[^/]*%.%w+$")
  if os.execute("cd " .. "\"" .. conf_dir .. "\" >/dev/null 2>&1") ~= true then
      os.execute("mkdir " .. conf_dir)
  end

  local fd = file_descriptors[conf.path]

  if fd and conf.reopen then
    -- close fd, we do this here, to make sure a previously cached fd also
    -- gets closed upon dynamic changes of the configuration
    C.close(fd)
    file_descriptors[conf.path] = nil
    fd = nil
  end

  if not fd then
    fd = C.open(conf.path, oflags, mode)
    if fd < 0 then
      local errno = ffi.errno()
      ngx.log(ngx.ERR, "[file-log] failed to open the file: ", ffi.string(C.strerror(errno)))
    else
      file_descriptors[conf.path] = fd
    end
  end

  C.write(fd, msg, #msg)
end

local FileLogHandler = {}

FileLogHandler.PRIORITY = 9
FileLogHandler.VERSION = "2.0.1"

function FileLogHandler:log(conf)
  -- local message = serialize(ngx)
  local remote_addr = ngx.var.remote_addr
  local remote_user = ngx.var.remote_user or ''
  local time_local = ngx.var.time_local
  local request = ngx.var.request
  local status = ngx.var.status
  local body_bytes_sent = ngx.var.body_bytes_sent
  local http_referer = ngx.var.http_referer or ''
  local http_user_agent = ngx.var.http_user_agent
  local http_x_forwarded_for = ngx.var.http_x_forwarded_for or ''
  local upstream_addr = ngx.var.upstream_addr
  local message = string.format("%s - %s - %s - %s - %s - %s - %s - %s - %s - %s",
                                remote_addr, remote_user, time_local, request,
                                status, body_bytes_sent, http_referer, http_user_agent,
                                http_x_forwarded_for, upstream_addr)

  log(conf, message)
end

return FileLogHandler
