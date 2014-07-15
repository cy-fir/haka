------------------------------------
-- Loading dissectors
------------------------------------
local ipv4 = require('protocol/ipv4')

-- drop all packets originating from
-- blacklisted network 192.168.10.0/22
haka.rule{
	-- This rule is applied on each ip incoming packet
	hook = ipv4.events.receive_packet,
	eval = function (pkt)
		-- Create network object
		local bad_network = ipv4.network("192.168.10.0/27")
		if bad_network:contains(pkt.src) then
			-- Raise an alert
			haka.alert{
				description = string.format("Filtering IP %s", pkt.src),
				severity = 'low'
			}
			-- and drop the packet
			pkt:drop()
		end
		-- All other packets will be accepted
	end
}