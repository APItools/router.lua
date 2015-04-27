router.lua
==========

[![Build Status](https://travis-ci.org/APItools/router.lua.svg)](https://travis-ci.org/APItools/router.lua)

A very basic router for lua.

Features:

* Allows binding a method and a path to a function
* Parses parameters like `/app/services/:service_id`
* It's platform-agnostic. It has been tested with openresty.

Usage
=====

A router is created with `router.new`:
``` lua
local router = require 'router'
local r = router.new()
```

You can define a route with `r:match`:

``` lua
local router = require 'router'
local r = router.new()

r:match('GET', '/hello', function(params)
  print('someone said hello')
end)
```

You can use `r:get(...)` instead of `r:match('GET', ...)`. There are similar shortcuts for the usual http verbs (`r:post`, `r:put`, `r:delete` ...).

In addition to that, `router.lua` supports router parameters (like `/users/:id/comment`) and extra parameters (which come from outside the route).

```
local router = require 'router'
local r = router.new()

r:get('/hello', function(params)
  print('someone said hello')
end)

-- route parameters
r:get('/hello/:name', function(params)
  print('hello, ' .. params.name)
end)

-- extra parameters (i.e. from a query or form)
r:post('/app/:id/comments', function(params)
  print('comment ' .. params.comment .. ' created on app ' .. params.id)
end)
```

Once the routes are defined, you can trigger their actions by using `r:execute`.
Given the 3 routes above, execute will work like this:

``` lua
r:execute('GET',  '/hello')
-- prints "someone said hello"

r:execute('GET',  '/hello/peter')
-- prints "hello peter"

r:execute('POST', '/app/4/comments', { comment = 'fascinating'})
-- prints "comment fascinating created on app 4"
```

`r:execute` returns either `nil` followed by an error message if no routes where found, or `true` and
whatever the matched action returned.

If you are defining lots of routes in one go, there is an extra-compact syntax to do so using a table.
The following code is equivalent to the previous one:

``` lua
local router = require 'router'
local r = router.new()

r:match({
  GET = {
    ['/hello']       = function(params) print('someone said hello') end,
    ['/hello/:name'] = function(params) print('hello, ' .. params.name) end
  },
  POST = {
    ['/app/:id/comments'] = function(params)
      print('comment ' .. params.comment .. ' created on app ' .. params.id)
    end
  }
})

r:execute('GET',  '/hello')
r:execute('GET',  '/hello/peter')
r:execute('POST', '/app/4/comments', { comment = 'fascinating'})
```

Usage with openresty
====================

`router.lua` is platform-agnostic, but you can use it with openresty like this:

``` conf
# nginx.conf
http {
  server {
    listen 80;

    location / {
      content_by_lua '
      local router = require 'router'
      local r = router.new()

      r:match({
        GET = {
          ["/hello"]       = function(params) ngx.print("someone said hello") end,
          ["/hello/:name"] = function(params) ngx.print("hello, " .. params.name) end
        },
        POST = {
          ["/app/:id/comments"] = function(params)
            ngx.print("comment " .. params.comment .. " created on app " .. params.id)
          end
        }
      })

      local ok, errmsg = r:execute(
        ngx.var.request_method,
        ngx.var.request_uri,
        ngx.req.get_uri_args(),  -- all these parameters
        ngx.req.get_post_args(), -- will be merged in order
        {other_arg = 1})         -- into a single "params" table

      if ok then
        ngx.status = 200
      else
        ngx.status = 404
        ngx.print("Not found!")
        ngx.log(ngx.ERROR, errmsg)
      end
    }
  }
```

Read more about it in https://docs.apitools.com/blog/2014/04/24/a-small-router-for-openresty.html


License
=======

MIT license

Specs
=====

This library uses [busted](http://olivinelabs.com/busted) for its specs. In order to run the specs, install `busted` and then do

    cd path/to/the/folder/where/the/spec/folder/is
    busted
