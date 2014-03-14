-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

local http = require("protocol/http")

http.install_tcp_rule(80)

haka.rule {
	hook = haka.event('http', 'request'),
	eval = function (http, request)
		print("HTTP REQUEST")
		haka.debug.pprint(http.request, nil, nil, { haka.debug.hide_underscore, haka.debug.hide_function })
	end
}

haka.rule {
	hook = haka.event('http', 'response'),
	eval = function (http, response)
		print("HTTP RESPONSE")
		haka.debug.pprint(http.response, nil, nil, { haka.debug.hide_underscore, haka.debug.hide_function })

		-- Modify a part of the response
		http.response.version = "2.0"
		-- Remove a header
		http.response.headers["Server"] = nil
		-- Add a header
		http.response.headers["Haka"] = "Done"
		-- Modify a header
		http.response.headers["Date"] = "Sat, 34 Jun 2048 15:14:20 GMT"
		print("HTTP MODIFIED RESPONSE")
		haka.debug.pprint(http.response, nil, nil, { haka.debug.hide_underscore, haka.debug.hide_function })
	end
}
