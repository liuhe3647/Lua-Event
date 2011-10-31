--[[
Example usage:

-- create generic event handling function for a Cat class
function Cat:OnEvent(eventname, ...)
	if eventname == "MOUSE_SPAWNED" and not self.chasing then
		local mouse = ...
		self:ChaseMouse(mouse)
	end
end

-- use a regular function to process the event as well
function PrintWhenMouseSpawns(eventname, mouse)
	print("MOUSE SPAWNED! "..tostring(mouse))
end

function Mouse:initialize(x, y)
	self:Spawn(x, y)
	Event.Trigger("MOUSE_SPAWNED", self) -- trigger the event and pass any arguments you want
end

-- register the Cat class and function we created with the MOUSE_SPAWNED event
Event.Register(Cat, "MOUSE_SPAWNED")
Event.Register(PrintWhenMouseSpawns, "MOUSE_SPAWNED")


NOTE: an 'object' (the thing you register) can be either a function or a table.
If it is a table, then when the event it's associated with is triggered, it will
first look for a function of the same name as the event in the table, and if it
doesn't find one it will fall back to the table's "OnEvent" method, if it exists.
	
]]



Event = {}

local events = {}

function printregistered(eventname)
	for k,v in pairs(events[eventname]) do
		print(k, v)
	end
end

local mt = {__mode="k"} -- weak keys so registered objects will be GC'd properly


-- accepts any amount and type of arguments after the event name
-- NOTE: triggered events have no guaranteed order in which callback objects are called
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


-- returns array of event names registered to an object
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
