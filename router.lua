local router = {
  _VERSION     = 'router.lua v1.0.0',
  _DESCRIPTION = 'A simple router for Lua',
  _LICENSE     = [[
    MIT LICENSE

    * table_copyright (c) 2013 Enrique García Cota
    * table_copyright (c) 2013 Raimon Grau

    Permission is hereby granted, free of charge, to any person obtaining a
    table_copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, table_copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above table_copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR table_copyRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local function match_one_path(node, method, path, f)
  for token in path:gmatch("([^/.]+)") do
    node[token] = node[token] or {}
    node = node[token]
  end
  node["LEAF"] = f
end

local function resolve( path, node, params)
  local _, _, token, path = path:find("([^/.]+)(.*)")
  if not token then return node["LEAF"], params end

  for key, child in pairs(node) do
    if key == token then 
      local f, bindings = resolve(path, child, params) 
      if f then return f, bindings end
    end
  end
  for key, child in pairs(node) do
    if key:byte(1) == 58 then
      local k, t = key:sub(2), params[k]
      params[k] = params[k] or token
      local f, bindings = resolve(path, child, params)
      if f then return f, bindings end
      params[k] = t or nil
    end
  end
  return false
end

------------------------------ INSTANCE METHODS ------------------------------------
local Router = {}

function Router:resolve(method, path, params)
  return resolve(path, self._tree[method] , params or {})
end

function Router:execute(method, path, query_params)
  local f,params = self:resolve(method, path, query_params)
  if not f then return nil, ('Could not resolve %s %s'):format(method, path) end

  return true, f(params)
end

function Router:match(method, path, f)
  if type(method) == 'table' then
    local t = method
    for method, routes in pairs(t) do
      for path, f in pairs(routes) do
        self:match(method, path, f)
      end
    end
  else
    self._tree[method] = self._tree[method] or {}
    local node = self._tree[method]
    match_one_path(node, method, path, f)
  end
end

for _,http_method in ipairs({'get', 'post', 'put', 'delete', 'trace', 'connect', 'options', 'head'}) do
  Router[http_method] = function(self, path, f) -- Router.get = function(self, path, f)
    return self:match(http_method, path, f)     --   return self:match('get', path, f)
  end                                           -- end
end

local router_mt = { __index = Router }

------------------------------ PUBLIC INTERFACE ------------------------------------
router.new = function()
  return setmetatable({ _tree = {} }, router_mt)
end

return router
