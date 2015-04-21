local router = require 'router'

local LEAF = "LEAF"

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
        r:execute("GET", "/foo", "ok")
        assert.same(dummy.params, "ok")
      end)

      it("understands chained fixed strings", function()
        r:match("GET", "/foo/bar", write_dummy)
        r:execute("GET", "/foo/bar", "ok")
        assert.same(dummy.params, "ok")
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
        r:execute("GET", "/foo", "ok")
        assert.same(dummy.params, "ok")
      end)

      it("understands chained fixed strings", function()
        r:match({ GET = { ["/foo/bar"] = write_dummy } })

        r:execute("GET", "/foo/bar", "ok")
        assert.same(dummy.params, "ok")
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

      it("gets params", function()
        local f, params = r:resolve("GET", "/s/21")
        assert.equals(type(f), 'function')
        assert.same(params, {id = "21"})
      end)

      it("posts params", function()
        local f, params = r:resolve("POST", "/s/21")
        assert.equals(type(f), 'function')
        assert.same(params, {id = "21"})
      end)

      it("gets params with an extension", function()
        local f, params = r:resolve("GET", "/s/21.json")
        assert.equals(type(f), 'function')
        assert.same(params, {id = "21"})
      end)

      it("posts params with an extension", function()
        local f, params = r:resolve("POST", "/s/21.json")
        assert.equals(type(f), 'function')
        assert.same(params, {id = "21"})
      end)

      it("gets with backtracking over params", function()
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

      it("priorizes static variables over params", function()
        local f, p = r:resolve("GET", "/s/c")
        assert.equals(type(f), 'function')
        assert.same(p, {})
      end)

    end)

    describe(":execute", function()

      it("runs the specified function with a get fixed string", function()
        r:execute("GET", "/s")
        assert.same(dummy.params, {})
      end)

      it("runs the specified function with a param", function()
        r:execute("GET", "/s/21")
        assert.same(dummy.params, {id = '21'})
      end)

      it("runs the specified function with a param with an extension", function()
        r:execute("GET", "/s/21.json")
        assert.same(dummy.params, {id = '21'})
      end)

      it("runs the specified function with a param in a post", function()
        r:execute("POST", "/s/21")
        assert.same(dummy.params, {id = '21'})
      end)

      it("runs the specified function with a param in a post with an extension", function()
        r:execute("POST", "/s/21.json")
        assert.same(dummy.params, {id = '21'})
      end)

      describe('when given extra parameters', function()

        it("adds them to the params list", function()
          r:execute("POST", "/s/21", {bar = '22'})
          assert.same(dummy.params, {id = '21', bar = '22'})
        end)
        -- no need to override the params
        it("overrides with post params", function()
          r:execute("POST", "/s/21", {id = '22'})
          assert.same(dummy.params, {id = '22'})
        end)
      end)
    end) -- :execute
  end) -- default params

  describe(":get", function()
    it("defines a GET shortcut", function()
      r:get("/s/:id", write_dummy)
      r:execute("GET", "/s/21")
      assert.same(dummy.params, {id = '21'})
    end)
  end)

end)
