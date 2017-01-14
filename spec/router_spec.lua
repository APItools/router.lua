local router = require 'router'

describe("Router", function()
  local r
  local dummy
  local function write_dummy(params) dummy.params = params end

  before_each(function ()
    dummy = {}
    r = router.new()
  end)

  describe(":match", function()
    describe('when first param is a string', function()
      it("understands fixed strings", function()
        r:match("GET", "/foo", write_dummy)
        r:execute("GET", "/foo", {status = "ok"})
        assert.same(dummy.params, {status = "ok"})
      end)

      it("understands chained fixed strings", function()
        r:match("GET", "/foo/bar", write_dummy)
        r:execute("GET", "/foo/bar", {status = "ok"})
        assert.same(dummy.params, {status = "ok"})
      end)

      it("understands params", function()
        r:match("GET", "/foo/:id", write_dummy)
        r:execute("GET", "/foo/bar")
        assert.same(dummy.params, {id="bar"})
      end)

      it("does not duplicate the same node twice for the same param id", function()
        r:match("GET", "/foo/:id/bar", write_dummy)
        r:match("GET", "/foo/:id/baz", write_dummy)

        r:execute("GET", "/foo/1/bar")
        assert.same(dummy.params, {id="1"})

        r:execute("GET", "/foo/2/baz")
        assert.same(dummy.params, {id="2"})
      end)

      it("supports an extension on a param", function()
        r:match("GET", "/foo/:id.json", write_dummy)

        r:execute("GET", "/foo/1.json")
        assert.same(dummy.params, {id="1"})
      end)
    end)

    describe('when first param is a table', function()
      it("understands fixed strings", function()
        r:match({ GET = { ["/foo"] = write_dummy} })
        r:execute("GET", "/foo", {status = "ok"})
        assert.same(dummy.params, {status = "ok"})
      end)

      it("understands chained fixed strings", function()
        r:match({ GET = { ["/foo/bar"] = write_dummy } })

        r:execute("GET", "/foo/bar", {status = "ok"})
        assert.same(dummy.params, {status = "ok"})
      end)

      it("understands params", function()
        r:match({GET = {["/foo/:id"] = write_dummy}})
        r:execute("GET", "/foo/bar")
        assert.same(dummy.params, {id="bar"})
      end)

      it("does not duplicate the same node twice for the same param id", function()
        r:match({
          GET = {
            ["/foo/:id/bar"] = write_dummy,
            ["/foo/:id/baz"] = write_dummy
          }
        })
        r:execute("GET", "/foo/1/bar")
        assert.same(dummy.params, {id="1"})

        r:execute("GET", "/foo/2/baz")
        assert.same(dummy.params, {id="2"})
      end)

      it("supports an extension on a param", function()
        r:match({
          GET = {
            ["/foo/:id.json"] = write_dummy
          }
        })
        r:execute("GET", "/foo/1.json")
        assert.same(dummy.params, {id="1"})
      end)
    end)
  end)


  describe("when given some routes", function()

    before_each(function ()
      r:match( {
        GET = {
          ["/s"]          = write_dummy,
          ["/s/a/b"]      = write_dummy,
          ["/s/c"]        = write_dummy,
          ["/s/:id"]      = write_dummy,
          ["/s/:id/foo"]  = write_dummy,
          ["/s/:bar/bar"] = write_dummy,
          ["/s/:id.json"] = write_dummy
        },
        POST = {
          ["/s/:id"] = write_dummy,
          ["/s/:id.json"] = write_dummy
        }
      })
    end)

    describe(":resolve", function()

      it("gets fixed strings", function()
        local f, params = r:resolve("GET", "/s")
        assert.equals(type(f), 'function')
        assert.same(params, {})
      end)

      it("gets url params", function()
        local f, params = r:resolve("GET", "/s/21")
        assert.equals(type(f), 'function')
        assert.same(params, {id = "21"})
      end)

      it("posts url params", function()
        local f, params = r:resolve("POST", "/s/21")
        assert.equals(type(f), 'function')
        assert.same(params, {id = "21"})
      end)

      it("gets url params with an extension", function()
        local f, params = r:resolve("GET", "/s/21.json")
        assert.equals(type(f), 'function')
        assert.same(params, {id = "21"})
      end)

      it("posts url params with an extension", function()
        local f, params = r:resolve("POST", "/s/21.json")
        assert.equals(type(f), 'function')
        assert.same(params, {id = "21"})
      end)

      it("gets with backtracking over url params", function()
        local f, params = r:resolve("GET", "/s/21/bar")
        assert.equals(type(f), 'function')
        assert.same(params, {bar = "21"})
      end)

      it("gets with backtracking over fixed string", function()
        local f, params = r:resolve("GET", "/s/a/bar")
        assert.equals(type(f), 'function')
        assert.same(params, {bar = "a"})
      end)

      it("matches strings without backtracking", function()
        local f, params = r:resolve("GET", "/s/a/b")
        assert.equals(type(f), 'function')
        assert.same(params, {})
      end)

      it("priorizes static url tokens over url params", function()
        local f, p = r:resolve("GET", "/s/c")
        assert.equals(type(f), 'function')
        assert.same(p, {})
      end)

    end)

    describe(":execute", function()
      it("returns nil and an error string when the http verb is unknown", function()
        local result, message = r:execute("FOO", "/s")

        assert.is_nil(result)
        assert.equal("Could not resolve FOO /s - Unknown method: FOO", message)
      end)

      it("runs the specified function with a get fixed string", function()
        r:execute("GET", "/s")
        assert.same(dummy.params, {})
      end)

      it("runs the specified function with a url param", function()
        r:execute("GET", "/s/21")
        assert.same(dummy.params, {id = '21'})
      end)

      it("runs the specified function with a url param with an extension", function()
        r:execute("GET", "/s/21.json")
        assert.same(dummy.params, {id = '21'})
      end)

      it("runs the specified function with a url param in a post", function()
        r:execute("POST", "/s/21")
        assert.same(dummy.params, {id = '21'})
      end)

      it("runs the specified function with a url param in a post with an extension", function()
        r:execute("POST", "/s/21.json")
        assert.same(dummy.params, {id = '21'})
      end)

      describe('when given extra parameters', function()

        it("adds them to the params list", function()
          r:execute("POST", "/s/21", {bar = '22'})
          assert.same(dummy.params, {id = '21', bar = '22'})
        end)

        it("does not override with post params", function()
          r:execute("POST", "/s/21", {id = '22'})
          assert.same(dummy.params, {id = '21'})
        end)

        it("merges the params", function()
          r:execute("POST", "/s/21", {bar = 'bar'}, {baz = 'baz'})
          assert.same(dummy.params, {id = '21', bar = 'bar', baz = 'baz'})
        end)

        it("respects the merging order of the params", function()
          r:execute("POST", "/s/21", {bar = 'bar', baz = 'baz'}, {baz = 'hey'})
          assert.same(dummy.params, {id = '21', bar = 'bar', baz = 'baz'})
        end)
      end)
    end) -- :execute
  end) -- default params

  describe('Wildcard routes', function()
    before_each(function ()
      r:match({
        GET = {
          ["/a/b/*args"]      = write_dummy,
        },
        POST = {
        }
      })
    end)

    it("match a single segment", function()
      local ok, _ = r:execute("GET", "/a/b/c")
      assert.is_true(ok)
      assert.same(dummy.params.args, "c")
    end)

    it("match multiple segments", function()
      local ok, _ = r:execute("GET", "/a/b/c/d/e/f")
      assert.is_true(ok)
      assert.same(dummy.params.args, "c/d/e/f")
    end)

    it("don't match if the segment is empty", function() 
      local ok, err = r:execute("GET", "/a/b")
      assert.is_nil(ok)
      assert.same(err, 'Could not resolve GET /a/b - nil')
    end)
  end)

  describe("shortcuts", function()
    for method in ("get post put patch delete trace connect options head"):gmatch("%S+") do
      local verb = method:upper()
      it(("defines a %s shortcut"):format(verb), function() -- it("defines a GET shortcut", function()
        r[method](r, "/s/:id", write_dummy)                 --   r["get"](r, "/s/:id", write_dummy)
        r:execute(verb, "/s/21")                            --   r:execute(verb, "/s/21")
        assert.same(dummy.params, {id = '21'})              --   assert.same(dummy.params, {id = '21'})
      end)                                                  -- end)
    end
  end)

  describe("'any' shortcut", function()
    for method in ("get post put patch delete trace connect options head"):gmatch("%S+") do
      local verb = method:upper()
      it(("matches a %s request"):format(verb), function()  -- it("matches a GET request", function()
        r:any("/s/:id", write_dummy)                        --   r:any(r, "/s/:id", write_dummy)
        r:execute(verb, "/s/21")                            --   r:execute(verb, "/s/21")
        assert.same(dummy.params, {id = '21'})              --   assert.same(dummy.params, {id = '21'})
      end)                                                  -- end)
    end

    it("passes the http method", function()
      for method in ("get post put patch delete trace connect options head"):gmatch("%S+") do
        local verb = method:upper()
        r:any("/s/:id", function(params, http_method) dummy.params = {params = params, method = http_method} end)
        r:execute(verb, "/s/21")
        assert.same(dummy.params, {params = {id = '21'}, method = method})
      end
    end)
  end)

end)
