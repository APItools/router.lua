router.lua
==========

A very basic router for lua.

Features:

* Allows binding a method and a path to a function
* Parses parameters like `/app/services/:service_id`
* It's platform-agnostic. It has been tested with openresty.

Example of use
==============

    local router = require 'router'

    router.get('/hello',       function()       print('someone said hello') end)
    router.get('/hello/:name', function(params) print('hello ' .. params.name) end)

    router.post('/app/:id/comments', function(params) print('comment ' .. params.comment .. ' created on app ' .. params.id))

    router.execute('get',  '/hello')
    -- someone said hello

    router.execute('get',  '/hello/peter')
    -- hello peter

    router.execute('post', '/app/4/comments', { comment = 'fascinating'})
    -- comment fascinating created on app 4


License
=======

MIT licenxe

Specs
=====

This library uses [busted](http://olivinelabs.com/busted) for its specs. In order to run the specs, install `busted` and then do

    cd path/to/the/folder/where/the/spec/folder/is
    busted
