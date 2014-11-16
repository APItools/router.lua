local router = {}

local function table_merge(dest, src)
  if not src then return end
  for k,v in pairs(src) do
    dest[k] = tostring(v)
  end
end

local function match_one_path(self, method, path, f)
  self._tree[method] = self._tree[method] or {}
  local node = self._tree[method]
  for token in path:gmatch("([^/]+)") do
    node[token] = node[token] or {}
    node = node[token]
  end
  node["LEAF"] = f
end

local function resolve( it, node, params)
  local token = it() 
  
  if not token then return node["LEAF"], params end

  for key, child in pairs(node) do
    if key == token then return resolve(it, child, params) end
  end

  for key, child in pairs(node) do
    if key:byte(1) == 58 then
      params[key:sub(2)] = token
      local f, bindings = resolve(it, child, params)
      if f then return f, bindings end
      params[key:sub(2)] = nil
    end
  end
  return false
end

------------------------------ INSTANCE METHODS ------------------------------------

local Router = {}

function Router:resolve(method, path)
  return resolve(path:gmatch("([^/]+)"), self._tree[method] , {})
end

function Router:execute(method, path, query_params)
  local f,params = self:resolve(method, path)
  if not f then return nil, ('Could not resolve %s %s'):format(method, path) end

  table_merge(params, query_params)

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
