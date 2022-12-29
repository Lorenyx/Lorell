ccemux.attach("back", "wireless_modem", {
  -- The range of this modem
  range = 64,

  -- Whether this is an ender modem
  interdimensional = false,

  -- The current world's name. Sending messages between worlds requires an interdimensional modem
  world = "main",

  -- The position of this wireless modem within the world
  posX = 0, posY = 0, posZ = 0,
})