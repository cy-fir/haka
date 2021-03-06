-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

local http = require("protocol/http")

http.install_tcp_rule(80)

haka.rule {
	hook = http.events.request,
	eval = function (http, request)
		print(string.format("Ip source %s port source %s", http.flow.srcip, http.flow.srcport))
	end
}
