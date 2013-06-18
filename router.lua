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

-- gets all the available routes with wildcards from a given node
local function collect_parameters_for(node)
  local params = {}
  for key, child in pairs(node) do
    if type(key) == "table" and key.param then           -- params
      params[#params + 1] = key
    end
  end
  return params
end

local function is_empty(t)
  return not next(t)
end

local function resolve_rec(tokenized_path, node, params)
  if not node then
    return nil
  elseif #tokenized_path == 0 and node[router.leaf] then
    return node[router.leaf], params
  elseif node and node[tokenized_path[1]] then -- fixed string
    return resolve_rec(tail(tokenized_path), node[tokenized_path[1]], params)
  else
    local child_params = collect_parameters_for(node)
    if not is_empty(child_params) then
      local child_path = tail(tokenized_path)
      for k, v in ipairs(child_params) do
        local p2 = copy(params)
        p2[v.param] = tokenized_path[1]
        local f, bindings = resolve_rec(child_path, node[v], p2)
        if f then return f, bindings end
      end
    end
  end
  return false
end

router.leaf = {}
router.compiled_routes = {}

router.resolve = function(method, path)
  return resolve_rec(split(path, "/"),  router.compiled_routes[method] , {})
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
