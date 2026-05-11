RakLuaBitStream = {}

function RakLuaBitStream.new()
    local self = {
        bs = raknetNewBitStream()
    }

    setmetatable(self, {
        __index = RakLuaBitStream,
        __gc = function(self)
            raknetDeleteBitStream(self.bs)
        end
    })

    return self
end

function RakLuaBitStream:getReadOffset()
    return raknetBitStreamGetReadOffset(self.bs)
end

function RakLuaBitStream:getWriteOffset()
    return raknetBitStreamGetWriteOffset(self.bs)
end

function RakLuaBitStream:setReadOffset(offset)
    raknetBitStreamSetReadOffset(self.bs, offset)
end

function RakLuaBitStream:setWriteOffset(offset)
    raknetBitStreamSetWriteOffset(self.bs, offset)
end

function RakLuaBitStream:resetReadPointer()
    raknetBitStreamResetReadPointer(self.bs)
end

function RakLuaBitStream:resetWritePointer()
    raknetBitStreamResetWritePointer(self.bs)
end

function RakLuaBitStream:ignoreBits(amount)
    raknetBitStreamIgnoreBits(self.bs, amount)
end

function RakLuaBitStream:ignoreBytes(amount)
    raknetBitStreamIgnoreBits(self.bs, amount * 8)
end

function RakLuaBitStream:skipBits(amount)
    self:ignoreBits(amount)
end

function RakLuaBitStream:skipBytes(amount)
    self:ignoreBytes(amount)
end

function RakLuaBitStream:getNumberOfBitsUsed()
    return raknetBitStreamGetNumberOfBitsUsed(self.bs)
end

function RakLuaBitStream:getNumberOfBytesUsed()
    return raknetBitStreamGetNumberOfBytesUsed(self.bs)
end

function RakLuaBitStream:getNumberOfUnreadBits()
    return raknetBitStreamGetNumberOfUnreadBits(self.bs)
end

function RakLuaBitStream:getNumberOfUnreadBytes()
    return raknetBitStreamGetNumberOfUnreadBits(self.bs) / 8
end

--#region Read
function RakLuaBitStream:readBool()
    return raknetBitStreamReadBool(self.bs)
end

function RakLuaBitStream:readUint8()
    return raknetBitStreamReadInt8(self.bs)
end
function RakLuaBitStream:readInt8()
    return raknetBitStreamReadInt8(self.bs)
end
function RakLuaBitStream:readUint16()
    return raknetBitStreamReadInt16(self.bs)
end
function RakLuaBitStream:readInt16()
    return raknetBitStreamReadInt16(self.bs)
end
function RakLuaBitStream:readUint32()
    return raknetBitStreamReadInt32(self.bs)
end
function RakLuaBitStream:readInt32()
    return raknetBitStreamReadInt32(self.bs)
end

function RakLuaBitStream:readFloat()
    return raknetBitStreamReadFloat(self.bs)
end

function RakLuaBitStream:readString(length)
    return raknetBitStreamReadString(self.bs, length)
end

function RakLuaBitStream:readEncoded(size)
    return raknetBitStreamDecodeString(self.bs, size)
end

function RakLuaBitStream:readBuffer(dest, size)
    raknetBitStreamReadBuffer(bs, dest, size)
end
--#endregion
--#region Write
function RakLuaBitStream:writeBool(value)
    raknetBitStreamWriteBool(self.bs, value)
end

function RakLuaBitStream:writeUInt8(value)
    raknetBitStreamWriteInt8(self.bs, value)
end
function RakLuaBitStream:writeInt8(value)
    raknetBitStreamWriteInt8(self.bs, value)
end
function RakLuaBitStream:writeUInt16(value)
    raknetBitStreamWriteInt16(self.bs, value)
end
function RakLuaBitStream:writeInt16(value)
    raknetBitStreamWriteInt16(self.bs, value)
end
function RakLuaBitStream:writeUInt32(value)
    raknetBitStreamWriteInt32(self.bs, value)
end
function RakLuaBitStream:writeInt32(value)
    raknetBitStreamWriteInt32(self.bs, value)
end

function RakLuaBitStream:writeFloat(value)
    raknetBitStreamWriteFloat(self.bs, value)
end
function RakLuaBitStream:writeString(value)
    raknetBitStreamWriteString(self.bs, value)
end
function RakLuaBitStream:writeEncoded(value)
    raknetBitStreamEncodeString(self.bs, value)
end
function RakLuaBitStream:writeBuffer(dest, size)
    raknetBitStreamWriteBuffer(self.bs, dest, size)
end
function RakLuaBitStream:writeBitStream(bitStream)
    raknetBitStreamWriteBitStream(self.bs, bitStream)
end
--#endregion
--#region RPC
function RakLuaBitStream:sendRPC(rpcId)
    raknetSendRpc(rpcId, self.bs)
end
function RakLuaBitStream:sendPacket()
    raknetSendBitStream(self.bs)
end
function RakLuaBitStream:emulIncomingRPC(rpcId)
    raknetEmulRpcReceiveBitStream(rpcId, self.bs)
end
function RakLuaBitStream:emulIncomingPacket(packetId)
    raknetEmulPacketReceiveBitStream(packetId, self.bs)
end
--#endregion

RakLuaEvents = {
    INCOMING_RPC = "onReceiveRPC",
    INCOMING_PACKET = "onReceivePacket",
    OUTGOING_RPC = "onSendRPC",
    OUTGOING_PACKET = "onSendPacket"
}

RakLuaSampVersions = {
    SAMP_NOT_LOADED = 0,
    SAMP_UNKNOWN = 1,
    SAMP_037_R1 = 2,
    SAMP_037_R3_1 = 3,
}

local RakLua = {}
function RakLua.registerHandler(event, func)
    addEventHandler(event, func)
end

function RakLua.getSampVersion()
    return RakLuaSampVersions.SAMP_037_R3_1
end

return RakLua