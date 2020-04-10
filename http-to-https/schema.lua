--
-- Created by IntelliJ IDEA.
-- User: Yang
-- Date: 2020/4/10
-- Time: 10:13
-- To change this template use File | Settings | File Templates.
--
local typedefs = require "kong.db.schema.typedefs"

return {
    name = "http-to-https",
    fields = {
        { consumer = typedefs.no_consumer },
        { protocols = typedefs.protocols_http },
        { config = {
            type = "record",
            fields = {
                {
                    exclude_uri_pattern = {
                        type = "string",
                        required = false
                    }
                },
            },
        },
        },
    }
}