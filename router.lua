local router = {}

local function match_one_path(self, method, path, f)
  self._tree[method] = self._tree[method] or {}
  local node = self._tree[method]
  for token in path:gmatch("([^/]+)") do
    node[token] = node[token] or {}
    node = node[token]
  end
  node["LEAF"] = f
end

local function resolve( path, node, params)
  local _, _, token, path = path:find("([^/]+)(.*)")
  if not token then return node["LEAF"], params end

  for key, child in pairs(node) do
    if key == token then 
      local f, bindings = resolve(path, child, params) 
      if f then return f, bindings end
    end
  end

  for key, child in pairs(node) do
    if key:byte(1) == 58 then
      params[key:sub(2)] = token
      local f, bindings = resolve(path, child, params)
      if f then return f, bindings end
      params[key:sub(2)] = nil
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
        match_one_path(self, method, path, f)
      end
    end
  else
    match_one_path(self, method, path, f)
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
