local router = {
  _VERSION     = 'router.lua v2.1.0',
  _DESCRIPTION = 'A simple router for Lua',
  _LICENSE     = [[
    MIT LICENSE

    * Copyright (c) 2013 Enrique García Cota
    * Copyright (c) 2013 Raimon Grau
    * Copyright (c) 2015 Lloyd Zhou

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local COLON_BYTE = string.byte(':', 1)
local WILDCARD_BYTE = string.byte('*', 1)
local HTTP_METHODS = {'get', 'post', 'put', 'patch', 'delete', 'trace', 'connect', 'options', 'head'}

local function match_one_path(node, path, f)
  for token in path:gmatch("[^/.]+") do
    if WILDCARD_BYTE == token:byte(1) then
      node['WILDCARD'] = {['LEAF'] = f, ['TOKEN'] = token:sub(2)}
      return
    end
    if COLON_BYTE == token:byte(1) then -- if match the ":", store the param_name in "TOKEN" array.
      node['TOKEN'] = node['TOKEN'] or {}
      token = token:sub(2)
      node = node['TOKEN']
    end
    node[token] = node[token] or {}
    node = node[token]
  end
  node["LEAF"] = f
end

local function resolve(path, node, params)
  local _, _, current_token, rest = path:find("([^/.]+)(.*)")
  if not current_token then return node["LEAF"], params end

  if node['WILDCARD'] then
    params[node['WILDCARD']['TOKEN']] = current_token .. rest
    return node['WILDCARD']['LEAF'], params
  end

  if node[current_token] then
    local f, bindings = resolve(rest, node[current_token], params)
    if f then return f, bindings end
  end

  for param_name, child_node in pairs(node['TOKEN'] or {}) do
    local param_value = params[param_name]
    params[param_name] = current_token or param_value -- store the value in params, resolve tail path

    local f, bindings = resolve(rest, child_node, params)
    if f then return f, bindings end

    params[param_name] = param_value -- reset the params table.
  end

  return false
end

local function merge(destination, origin, visited)
  if type(origin) ~= 'table' then return origin end
  if visited[origin] then return visited[origin] end
  if destination == nil then destination = {} end

  for k,v in pairs(origin) do
    k = merge(nil, k, visited) -- makes a copy of k
    if destination[k] == nil then
      destination[k] = merge(nil, v, visited)
    end
  end

  return destination
end

local function merge_params(...)
  local params_list = {...}
  local result, visited = {}, {}

  for i=1, #params_list do
    merge(result, params_list[i], visited)
  end

  return result
end

------------------------------ INSTANCE METHODS ------------------------------------
local Router = {}

function Router:resolve(method, path, ...)
  local node   = self._tree[method]
  if not node then return nil, ("Unknown method: %s"):format(tostring(method)) end
  return resolve(path, node, merge_params(...))
end

function Router:execute(method, path, ...)
  local f,params = self:resolve(method, path, ...)
  if not f then return nil, ('Could not resolve %s %s - %s'):format(tostring(method), tostring(path), tostring(params)) end
  return true, f(params)
end

function Router:match(method, path, fun)
  if type(method) == 'string' then -- always make the method to table.
    method = {method}
  end

  local parsed_methods = {}
  for k, v in pairs(method) do
    if type(v) == 'string' then
      -- convert shorthand methods into longhand
      if parsed_methods[v] == nil then parsed_methods[v] = {} end
      parsed_methods[v][path] = fun
    else
      -- pass methods already in longhand format onwards
      parsed_methods[k] = v
    end
  end

  for m, routes in pairs(parsed_methods) do
    for p, f in pairs(routes) do
      if not self._tree[m] then self._tree[m] = {} end
      match_one_path(self._tree[m], p, f)
    end
  end
end

for _,method in ipairs(HTTP_METHODS) do
  Router[method] = function(self, path, f)  -- Router.get = function(self, path, f)
    self:match(method:upper(), path, f)     --   return self:match('GET', path, f)
  end                                       -- end
end

Router['any'] = function(self, path, f) -- match any method
  for _,method in ipairs(HTTP_METHODS) do
    self:match(method:upper(), path, function(params) return f(params, method) end)
  end
end

local router_mt = { __index = Router }

------------------------------ PUBLIC INTERFACE ------------------------------------
router.new = function()
  return setmetatable({ _tree = {} }, router_mt)
end

return router
