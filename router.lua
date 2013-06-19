local router = {}

local function split(str, delimiter)
  local result = {}
  for chunk in str:gmatch("[^/]+") do
    result[#result + 1] = chunk
  end
  return result
end

local function tail(t)
  local result = {}
  for i=2, #t do result[i-1] = t[i] end
  return result
end

function copy(t)
  local result = {}
  for k,v in pairs(t) do result[k] = v end
  return result
end

local function resolve_rec(remaining_path, node, params)
  if not node then return nil end
  -- node is a leaf
  if #remaining_path == 0 then return node[router.leaf], params end

  local child_path = tail(remaining_path)

  -- node is a matched fixed string
  if node[remaining_path[1]] then return resolve_rec(child_path, node[remaining_path[1]], params) end

  -- node is a params; this means it has children
  for key, child in pairs(node) do
    if type(key) == "table" and key.param then
      local child_params = copy(params)
      child_params[key.param] = remaining_path[1]
      local f, bindings = resolve_rec(child_path, child, child_params)
      if f then return f, bindings end
    end
  end
  return false
end

------------------------------ PUBLIC INTERFACE ------------------------------------

router.leaf = {}
router.compiled_routes = {}

router.resolve = function(method, path)
  return resolve_rec(split(path, "/"),  router.compiled_routes[method] , {})
end

router.execute = function(method, path)
  local f,params = router.resolve(method, path)
  if not f then return false end

  f(params)
  return true
end

return router
