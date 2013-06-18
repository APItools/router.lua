require 'lib.ngx_mock'

local router = {}

local function split(str, delimiter)
  local res = {}
  for i in string.gmatch(str, "[^/]+") do
    table.insert(res, i)
  end
  return res
end

local function tail(t)
  local result = {}
  for i=2, #t do result[i-1] = t[i] end
  return result
end

function copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

router.leaf = {}

router.compiled_routes = {}

router.resolve = function(method, path)
  return router.resolve_rec(split(path, "/"),  router.compiled_routes[method] , {})
end

-- gets all the available routes with wildcards from a given node
local function parameters_of(root)
  local params = {}
  for key, child in pairs(root) do
    if type(key) == "table" and key.param then           -- params
      table.insert(params, key)
    end
  end
  return params
end

router.resolve_rec = function(tokenized_path, root, params)
   if not root then
      return nil
   elseif #tokenized_path == 0 and root[router.leaf] then
    return root[router.leaf], params
  elseif root and root[tokenized_path[1]] then -- fixed string
    return router.resolve_rec(tail(tokenized_path), root[tokenized_path[1]], params)
  else
    local child_params = parameters_of(root)
    local child_path   = tail(tokenized_path)
    if child_params ~= {} then
      for k, v in ipairs(parameters_of(root)) do
        local p2 = copy(params)
        p2[v.param] = tokenized_path[1]
        local f, bindings = router.resolve_rec(
          child_path,
          root[v],
          p2)
        if f then return f, bindings end
      end
    end
  end
  return false
end

router.execute = function(method, path)
  local f,params = router.resolve(method, path)
  if f then
     return f(params)
  else
     router.default_action({})
  end
end

router.default_action = function(params) ngx.exit(ngx.HTTP_NOT_FOUND) end

return router                   --
