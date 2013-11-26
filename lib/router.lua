local router = {
  _VERSION     = 'router.lua v0.5',
  _DESCRIPTION = 'A simple router for Lua',
  _LICENSE     = [[
    MIT LICENSE

    * Copyright (c) 2013 Enrique García Cota
    * Copyright (c) 2013 Raimon Grau

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

local function split(str, delimiter)
  local result = {}
  delimiter = delimiter or " "
  for chunk in str:gmatch("[^".. delimiter .. "]+") do
    result[#result + 1] = chunk
  end
  return result
end

local function get_head_and_tail(t)
  local tail = {}
  for i=2, #t do tail[i-1] = t[i] end
  return t[1], tail
end

function copy(t)
  local result = {}
  for k,v in pairs(t) do result[k] = v end
  return result
end

local function resolve_rec(remaining_path, node, params)
  if not node then return nil end

  -- node is a leaf and no remaining tokens; found end
  if #remaining_path == 0 then return node[router.leaf], params end

  local current_token, child_path = get_head_and_tail(remaining_path)

  -- always resolve static strings first
  for key, child in pairs(node) do
    if key == current_token then
      local f, bindings = resolve_rec(child_path, child, params)
      if f then return f, bindings end
    end
  end

  -- then resolve parameters
  for key, child in pairs(node) do
    if type(key) == "table" and key.param then
      local child_params = copy(params)
      child_params[key.param] = current_token
      local f, bindings = resolve_rec(child_path, child, child_params)
      if f then return f, bindings end
    end
  end

  return false
end

local function find_key_for(token, node)
  local param_name = token:match("^:(.+)$")
  -- if token is not a param( it does not begin with :) then return the token
  if not param_name then return token end

  -- otherwise, it's a param, like :id. If it exists as a child of the node, we return it
  for key,_ in pairs(node) do
    if type(key) == 'table' and key.param == param_name then return key end
  end

  -- otherwise, it's a new key to be inserted
  return {param = param_name}
end

local function merge(dest, src)
  if not src then return end
  for k,v in pairs(src) do
    dest[k] = tostring(v)
  end
end

local function match_one_path(method, path, f)
  router.compiled_routes[method] = router.compiled_routes[method] or {}
  node = router.compiled_routes[method]
  for _,token in ipairs(split(path, "/")) do
    local key = find_key_for(token, node)
    node[key] = node[key] or {}
    node = node[key]
  end
  node[router.leaf] = f
end

------------------------------ PUBLIC INTERFACE ------------------------------------

router.leaf = {}
router.compiled_routes = {}

router.resolve = function(method, path)
  return resolve_rec(split(path, "/"),  router.compiled_routes[method] , {})
end

router.execute = function(method, path, query_params)
  local f,params = router.resolve(method, path)
  if not f then return false end

  merge(params, query_params)

  f(params)
  return true
end

router.match = function(method, path, f)
  if type(method) == 'table' then
    local t = method
    for method, routes in pairs(t) do
      for path, f in pairs(routes) do
        match_one_path(method, path, f)
      end
    end
  else
    match_one_path(method, path, f)
  end
end

for _,http_method in ipairs({'get', 'post', 'put', 'delete', 'trace', 'connect', 'options', 'head'}) do
  router[http_method] = function(path, f) -- router.get = function(path, f)
    router.match(http_method, path, f)    --   router.match('get', path, f)
  end                                     -- end
end

return router
