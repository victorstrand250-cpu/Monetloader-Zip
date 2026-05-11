local mod = {}

function mod.sendInterfaceState(interfaceid, state)
	local bs = raknetNewBitStream()
	raknetBitStreamWriteInt8(bs, 220)
	raknetBitStreamWriteInt8(bs, 66)
	raknetBitStreamWriteInt8(bs, interfaceid)
	raknetBitStreamWriteBool(bs, state)
	raknetSendBitStreamEx(bs, 1, 10, 1)
	raknetDeleteBitStream(bs)
end

function mod.sendFrontendClick(interfaceid, id, subid, data)
	local bs = raknetNewBitStream()
	raknetBitStreamWriteInt8(bs, 220)
	raknetBitStreamWriteInt8(bs, 63)
	raknetBitStreamWriteInt8(bs, interfaceid)
	raknetBitStreamWriteInt32(bs, id)
	raknetBitStreamWriteInt32(bs, subid)
	raknetBitStreamWriteInt32(bs, #data)
	raknetBitStreamWriteString(bs, data)
	raknetSendBitStreamEx(bs, 1, 10, 1)
	raknetDeleteBitStream(bs)
end

function mod.sendInteraction()
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 63)
    raknetBitStreamWriteInt8(bs, 8)
    raknetBitStreamWriteInt32(bs, 7)
    raknetBitStreamWriteInt32(bs, -1)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteString(bs, "")
    raknetSendBitStreamEx(bs, 1, 7, 1)
    raknetDeleteBitStream(bs)
end

function mod.onFrontendMessage(interfaceid, subid, data) end
function mod.onToggleInterface(interfaceid, state) end

local frontend_message_listeners = {}
local toggle_listeners = {}

local function validate_id(id)
    if type(id) ~= "number" then
        error("id must be a number")
        return false
    end
    return true
end

function mod.onlyJsonMiddleware(interfaceid, subid, data)
    local ok, data = pcall(decodeJson, data)
    if not ok then return false end

    return data
end

---Creates a new event chain for the specified interface
---@param id number
---@return EventChain
function mod.on(id)
    validate_id(id)
    
    ---@class EventChain
    local chain = {
        middlewares = {}
    }
    
    function chain:msg_middleware(cb)
        if type(cb) ~= "function" then
            error("callback must be a function")
        end
        table.insert(self.middlewares, cb)
        return self
    end

    ---Executes the callback when the interface receives a frontend message, and optionally a subid
    ---@param cb fun(interfaceid: number, subid: number, data: string)
    ---@param subid number | nil
    ---@return self
    function chain:frontend_message(cb, subid)
        if type(cb) ~= "function" then
            error("callback must be a function")
        end
        frontend_message_listeners[id] = frontend_message_listeners[id] or {}
        table.insert(frontend_message_listeners[id], {
            callback = #self.middlewares == 0 and cb or function(interfaceid, subid, data)
                for _, middleware in ipairs(self.middlewares) do
                    data = middleware(interfaceid, subid, data)
                    if data == false then
                        return
                    end
                end

                cb(interfaceid, subid, data)
            end,
            subid = subid,
        })
        return self
    end
    
    ---Executes the callback when the interface is toggled
    ---@param cb fun(interfaceid: number, state: boolean)
    ---@return self
    function chain:toggle(cb)
        if type(cb) ~= "function" then
            error("callback must be a function")
            return self
        end
        toggle_listeners[id] = toggle_listeners[id] or {}
        table.insert(toggle_listeners[id], {callback = cb})
        return self
    end
    
    return chain
end

addEventHandler('onReceivePacket', function(id, bs)
    if id ~= 220 then return end
    
    raknetBitStreamIgnoreBits(bs, 8)
    local type = raknetBitStreamReadInt8(bs)
    
    if type == 84 then
        local interfaceid = raknetBitStreamReadInt8(bs)
        local subid = raknetBitStreamReadInt8(bs)
        local data = raknetBitStreamReadString(bs, raknetBitStreamReadInt32(bs))
        
        local result
        for _, listener in ipairs(frontend_message_listeners[interfaceid] or {}) do
            if not listener.subid or listener.subid == subid then
                result = listener.callback(interfaceid, subid, data) or result
            end
        end
        
        return mod.onFrontendMessage(interfaceid, subid, data) or result
    
    elseif type == 62 then
        local interfaceid = raknetBitStreamReadInt8(bs)
        local toggle = raknetBitStreamReadBool(bs)
        
        -- Process toggle listeners
        local result
        for _, listener in ipairs(toggle_listeners[interfaceid] or {}) do
            result = listener.callback(interfaceid, toggle) or result
        end
        
        return mod.onToggleInterface(interfaceid, toggle) or result
    end
end)

return mod