local sampev = require 'samp.events'

function sampev.onInitGame()
  bs = raknetNewBitStream()
  raknetBitStreamWriteInt8(bs, 0x54)
  raknetBitStreamWriteInt8(bs, 0x09)
  raknetBitStreamWriteInt8(bs, 0x00)
  raknetBitStreamWriteInt32(bs, 1)
  raknetBitStreamWriteString(bs, "1")
  raknetEmulPacketReceiveBitStream(220, bs)
  raknetDeleteBitStream(bs)

  bs = raknetNewBitStream()
  raknetBitStreamWriteInt8(bs, 0x54)
  raknetBitStreamWriteInt8(bs, 0x09)
  raknetBitStreamWriteInt8(bs, 0x03)
  raknetBitStreamWriteInt32(bs, 7)
  raknetBitStreamWriteString(bs, "success")
  raknetEmulPacketReceiveBitStream(220, bs)
  raknetDeleteBitStream(bs)

  print("Fucked connection screen!")
end