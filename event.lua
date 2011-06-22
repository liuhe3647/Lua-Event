Event = {}

local events = {}

local mt = {__mode="k"}

-- accepts any amount and type of arguments after the event name
function Event.Trigger(eventname, ...)
	local eventlist = events[eventname] or {}
	
	for obj, callback in pairs(eventlist) do
		callback(...)
	end
end


-- can register multiple events at the same time
-- any arguments after the object are treated as event names to be registered
function Event.Register(obj, ...)
	if not obj then
		error("Event.Register error: nil callback object", 2)
		return
	end
	
	local eventnames = type(...) == "table" and ... or {...}
	
	if #eventnames == 0 then
		error("Event.Register error: nil event name", 2)
		return
	end
	
	for i, eventname in ipairs(eventnames) do
		if type(eventname) == "string" then
			local eventlist = events[eventname]
		
			if not eventlist then
				eventlist = {}
				setmetatable(eventlist, mt) -- weak keys so garbage collector can clean up properly
			end
		
			local callback
		
			if type(obj) == "function" then
				callback = function(...)
					obj(eventname, ...)
				end
			elseif type(obj) == "table" then
				callback = function(...)
					local func
					if obj[eventname] and type(obj[eventname]) == "function" then
						func = obj[eventname]
					elseif obj.OnEvent and type(obj.OnEvent) == "function" then
						func = obj.OnEvent
					else
						return
					end
					func(obj, eventname, ...)
				end
			else
				error("Event.Register error: callback object is not a table or function", 2)
				return
			end
		
			eventlist[obj] = callback
		
			events[eventname] = eventlist
		end
	end
	
	return obj
end


-- can unregister multiple events at the same time
-- any arguments after the object are treated as event names to be unregistered
function Event.Unregister(obj, ...)
	if not obj then
		error("Event.Unregister error: nil callback object", 2)
		return
	end
	
	local eventnames = type(...) == "table" and ... or {...}
	
	if #eventnames == 0 then
		error("Event.Unregister error: nil event name", 2)
		return
	end
	
	for i, eventname in ipairs(eventnames) do
		local eventlist = events[eventname]
		if eventlist and eventlist[obj] then
			eventlist[obj] = nil
		end
	end
end


function Event.LookUp(obj)
	if type(obj) == "table" or type(obj) == "function" then
		local registeredevents = {}
		for eventname, eventlist in pairs(events) do
			for _obj, callback in pairs(eventlist) do
				if obj == _obj then
					table.insert(registeredevents, eventname)
					break
				end
			end
		end
		return registeredevents
	else
		error("Event.Lookup error: callback object is not a table or function", 2)
		return
	end
end
