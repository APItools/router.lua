package = "router"
version = "2.1-0"
source = {
  url = "https://github.com/APItools/router.lua/archive/v2.1.0.tar.gz",
  dir = "router.lua-2.1.0"
}
description = {
   summary = "A barebones router for Lua. It matches urls and executes lua functions",
   detailed = "Features: 1) Allows binding a method and a path to a function 2) Parses parameters like /app/services/:service_id 3) It's platform-agnostic. It has been tested with openresty.",
   homepage = "https://github.com/APItools/router.lua",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1"
}
build = {
   type = "builtin",
   modules = {
      router = "router.lua"
   }
}
