local router = {}

local function split(str, delimiter)
  local result = {}
  for chunk in str:gmatch("[^/]+") do
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

  for key, child in pairs(node) do
    local f, bindings
    if key == current_token then
      f, bindings = resolve_rec(child_path, child, params)
    elseif type(key) == "table" and key.param then
      local child_params = copy(params)
      child_params[key.param] = current_token
      f, bindings = resolve_rec(child_path, child, child_params)
    end
    if f then return f, bindings end
  end
  return false
end

local function find_param_key(node, param_name)
  for key,_ in pairs(node) do
    if type(key) == 'table' and key.param == param_name then return key end
  end
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

router.match = function(method, path, f)
  router.compiled_routes[method] = router.compiled_routes[method] or {}
  node = router.compiled_routes[method]
  for _,token in ipairs(split(path, "/")) do
    local key = token

    local param_name = token:match("^:(.+)$")
    if param_name then
      key = find_param_key(node, param_name) or {param = param_name}
    end

    node[key] = node[key] or {}
    node = node[key]
  end
  node[router.leaf] = f
end

for _,http_method in ipairs({'get', 'post', 'put', 'delete', 'trace', 'connect', 'options', 'head'}) do
  router[http_method] = function(path, f) -- router.get = function(path, f)
    router.match(http_method, path, f)    --   router.match('get', path, f)
  end                                     -- end
end

return router
