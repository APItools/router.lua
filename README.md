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

Defining routes and actions:

``` lua
local router = require 'router'
local r = router.new()

r:get('/hello', function(params)
  print('someone said hello')
end)

-- alternative way:
r:match('get', '/hello', function(params)
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

Once the routes are defined, you can trigger their actions by using `r:execute`:

``` lua
r:execute('get',  '/hello')
-- prints "someone said hello"

r:execute('get',  '/hello/peter')
-- prints "hello peter"

r:execute('post', '/app/4/comments', { comment = 'fascinating'})
-- prints "comment fascinating created on app 4"
```

`r:execute` returns either `nil` followed by an error message if no routes where found, or `true` and
whatever the matched action returned.

If you are defining lots of routes in one go, there is a more compact syntax to do so using a table.
The following code is equivalent to the previous one:

``` lua
local router = require 'router'
local r = router.new()

r:match({
  get = {
    ['/hello']       = function(params) print('someone said hello') end,
    ['/hello/:name'] = function(params) print('hello, ' .. params.name) end
  },
  post = {
    ['/app/:id/comments'] = function(params)
      print('comment ' .. params.comment .. ' created on app ' .. params.id)
    end
  }
})

r:execute('get',  '/hello')
r:execute('get',  '/hello/peter')
r:execute('post', '/app/4/comments', { comment = 'fascinating'})
```

License
=======

MIT license

Specs
=====

This library uses [busted](http://olivinelabs.com/busted) for its specs. In order to run the specs, install `busted` and then do

    cd path/to/the/folder/where/the/spec/folder/is
    busted
