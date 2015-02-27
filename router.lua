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
  -- match the token or placeholder stored in var "tp"
  for tp in path:gmatch("([^/.]+)") do
    node[tp] = node[tp] or {}
    node = node[tp]
  end
  node["LEAF"] = f
end

local function resolve( path, node, params)
  -- match the token or value stored in var "tv"
  local _, _, tv, path = path:find("([^/.]+)(.*)")
  if not tv then return node["LEAF"], params end

  for tp, child in pairs(node) do
    -- if "token_or_placeholder" equal "token_or_value", it's must be token
    if tp == tv then
      local f, bindings = resolve(path, child, params)
      if f then return f, bindings end
    end
  end
  for tp, child in pairs(node) do
    if tp:byte(1) == 58 then -- the placeholder start with ":" (ascii is 58)
      local token = tp:sub(2)
      local value = params[token]
      params[token] = value or tv -- store the value in params, resolve tail path
      local f, bindings = resolve(path, child, params)
      if f then return f, bindings end
      params[token] = value -- reset the params table.
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
  if type(method) == 'string' then -- always make the method to table.
    method = {[method] = {[path] = f}}
  end
  for m, routes in pairs(method) do
    for path, f in pairs(routes) do
      if not self._tree[m] then self._tree[m] = {} end
      match_one_path(self._tree[m], method, path, f)
    end
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
