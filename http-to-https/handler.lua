--
-- Created by IntelliJ IDEA.
-- User: Yang
-- Date: 2020/4/10
-- Time: 9:58
-- To change this template use File | Settings | File Templates.
--

local BasePlugin = require "kong.plugins.base_plugin"
local HttpFilterHandler = BasePlugin:extend()

HttpFilterHandler.PRIORITY = 1500

function HttpFilterHandler:new()
    HttpFilterHandler.super.new(self, "http-to-https")
end

function HttpFilterHandler:access(conf)
    HttpFilterHandler.super.access(self)

    if ngx.var.https ~= "on" and ngx.var.http_x_forwarded_proto ~= "https" then
        local matches_exclude_pattern = conf.exclude_uri_pattern and string.find(ngx.var.request_uri, conf.exclude_uri_pattern)
        if not matches_exclude_pattern then
            return ngx.redirect("https://" .. ngx.var.host .. ngx.var.request_uri, ngx.HTTP_MOVED_PERMANENTLY)
        end
    end
end

return HttpFilterHandler