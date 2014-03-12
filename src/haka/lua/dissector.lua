-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

local dissector = {}


--
-- Dissector base class
--

dissector.Dissector = class('Dissector')

function haka.event(dname, name)
	local dissec = dissector.get(dname)
	if not dissec then
		error(string.format("unknown dissector '%s'", dname))
	end

	local event = dissec.events[name]
	if not event then
		error(string.format("unknown event '%s' on dissector '%s'", name, dname))
	end

	return event
end

function dissector.Dissector.__class_init(self, cls)
	self.super:__class_init(cls)
	cls.events = {}
	self.inherit_events(cls)
	cls.options = {}
end

function dissector.Dissector.register_event(cls, name, continue, signal, options)
	continue = continue or function (self) return self:continue() end
	cls.events[name] = haka.events.Event:new(string.format('%s:%s', cls.name, name), continue, signal, options)
end

function dissector.Dissector.inherit_events(cls)
	local parent_events = cls.super.events
	if parent_events then
		local events = cls.events
		for name, event in pairs(parent_events) do
			events[name] = event:clone()
			events[name].name = string.format('%s:%s', cls.name, name)
		end
	end
end

function dissector.Dissector.method:__init()
end

dissector.Dissector.property.name = {
	get = function (self) return classof(self).name end
}

function dissector.Dissector:receive(pkt)
	error("not implemented")
end


--
-- Packet based dissector
--

dissector.PacketDissector = class('PacketDissector', dissector.Dissector)

dissector.PacketDissector:register_event('receive_packet')
dissector.PacketDissector:register_event('send_packet')

function dissector.PacketDissector.method:trigger(signal, ...)
	if not haka.pcall(haka.context.signal, haka.context, self, classof(self).events[signal], ...) then
		return self:drop()
	end

	if not self:continue() then
		return
	end

	return true
end

function dissector.PacketDissector.method:continue()
	error("not implemented")
end

function dissector.PacketDissector.method:send()
	error("not implemented")
end

function dissector.PacketDissector.method:inject()
	error("not implemented")
end


dissector.EncapsulatedPacketDissector = class('EncapsulatedPacketDissector', dissector.PacketDissector)

function dissector.EncapsulatedPacketDissector:receive(parent)
	local new = self:new(parent)
	new:parse(parent)
	return new:emit()
end

function dissector.EncapsulatedPacketDissector.method:__init(parent)
	super(dissector.EncapsulatedPacketDissector).__init(self)
	self._parent = parent
end

function dissector.EncapsulatedPacketDissector.method:parse(pkt)
	self._select, self._payload = pkt.payload:sub(0, 'all'):select()
	self:parse_payload(pkt, self._payload)
end

function dissector.EncapsulatedPacketDissector.method:parse_payload(pkt, payload)
	error("not implemented")
end

function dissector.EncapsulatedPacketDissector.method:create(init, pkt)
	self._select, self._payload = pkt.payload:sub(0, 'all'):select()
	self:create_payload(pkt, self._payload, init)
end

function dissector.EncapsulatedPacketDissector.method:create_payload(pkt, payload, init)
	error("not implemented")
end

function dissector.EncapsulatedPacketDissector.method:forge(pkt)
	self:forge_payload(pkt, self._payload)
	self._select:restore(self._payload)
	self._payload = nil
	self._select = nil
end

function dissector.EncapsulatedPacketDissector.method:forge_payload(pkt, payload)
	error("not implemented")
end

function dissector.EncapsulatedPacketDissector.method:continue()
	return self._parent:continue()
end

function dissector.EncapsulatedPacketDissector.method:drop()
	return self._parent:drop()
end

function dissector.EncapsulatedPacketDissector.method:next_dissector()
	return nil
end

function dissector.EncapsulatedPacketDissector.method:emit()
	if self:trigger('receive_packet') then
		local next_dissector = self:next_dissector()
		if next_dissector then
			return next_dissector:receive(self)
		else
			return self:send()
		end
	end
end

function dissector.EncapsulatedPacketDissector.method:send()
	if self:trigger('send_packet') then
		self:forge(self._parent)
		self._parent:send()
		self._parent = nil
	end
end

function dissector.EncapsulatedPacketDissector.method:inject()
	self:forge(self._parent)
	self._parent:inject()
	self._parent = nil
end


--
-- Flow based dissector
--

dissector.FlowDissector = class('FlowDissector', dissector.Dissector)

function dissector.FlowDissector.stream_wrapper(f, options, self, stream, ...)
	local current = stream.current
	if (not current or not current:check_available(1)) and
	   not stream.isfinished then
		return
	end

	if options and options.coroutine then
		local comanager = self:get_comanager(stream, ...)
		if not comanager:has(f) then
			local args = {...}
			comanager:start(f, function (iter) return f(self, iter, unpack(args)) end)
		end

		comanager:process(f)
	else
		local sub = stream.current:sub('available')
		if sub then
			f(self, stream.current:sub('available'), ...)
		end
	end
end

dissector.FlowDissector:register_event('receive_data', nil, dissector.FlowDissector.stream_wrapper)
dissector.FlowDissector:register_event('send_data')

function dissector.FlowDissector.method:connections()
	local connections = classof(self).connections
	if connections then
		return haka.events.ObjectEventConnections:new(self, connections)
	end
end

function dissector.FlowDissector.method:continue()
	error("not implemented")
end

function dissector.FlowDissector.method:get_comanager(stream)
	if not self._costream then
		self._costream = {}
	end

	if not self._costream[stream] then
		self._costream[stream] = haka.vbuffer_stream_comanager:new(stream)
	end

	return self._costream[stream]
end


--
-- Utility functions
--
local dissectors = {}

function dissector.new(args)
	haka.log.info("dissector", "register new dissector '%s'", args.name)
	local d = class(args.name, args.type or dissector.Dissector)
	dissectors[args.name] = d
	return d
end

function dissector.get(name)
	return dissectors[name]
end

local other_direction = {
	up = 'down',
	down = 'up'
};

function dissector.other_direction(dir)
	return other_direction[dir]
end


haka.dissector = dissector
