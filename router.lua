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
