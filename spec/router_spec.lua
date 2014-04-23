local router = require 'router'

local LEAF = router._LEAF

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
        r:match("get", "/foo", write_dummy)
        assert.same(r._tree, {
          get = { foo = { [LEAF] = write_dummy } }
        })
      end)

      it("understands chained fixed strings", function()
        r:match("get", "/foo/bar", write_dummy)
        assert.same(r._tree, {
          get = { foo = { bar = { [LEAF] = write_dummy } } }
        })
      end)

      it("understands params", function()
        r:match("get", "/foo/:id", write_dummy)
        local key, node = next(r._tree.get.foo)
        assert.same(key, {param = "id"})
        assert.same(node, { [LEAF] = write_dummy })
      end)

      it("does not duplicate the same node twice for the same param id", function()
        r:match("get", "/foo/:id/bar", write_dummy)
        r:match("get", "/foo/:id/baz", write_dummy)
        local key, node = next(r._tree.get.foo)
        assert.same(key, {param = "id"})
        assert.same(node, {
          bar = {[LEAF] = write_dummy },
          baz = {[LEAF] = write_dummy }
        })
      end)
    end)

    describe('when first param is a table', function()
      it("understands fixed strings", function()
        r:match({ get = { ["/foo"] = write_dummy} })
        assert.same(r._tree, {
          get = { foo = { [LEAF] = write_dummy } }
        })
      end)

      it("understands chained fixed strings", function()
        r:match({ get = { ["/foo/bar"] = write_dummy } })
        assert.same(r._tree, {
          get = { foo = { bar = { [LEAF] = write_dummy } } }
        })
      end)

      it("understands params", function()
        r:match({get = {["/foo/:id"] = write_dummy}})
        local key, node = next(r._tree.get.foo)
        assert.same(key, {param = "id"})
        assert.same(node, { [LEAF] = write_dummy })
      end)

      it("does not duplicate the same node twice for the same param id", function()
        r:match({
          get = {
            ["/foo/:id/bar"] = write_dummy,
            ["/foo/:id/baz"] = write_dummy
          }
        })
        local key, node = next(r._tree.get.foo)
        assert.same(key, {param = "id"})
        assert.same(node, {
          bar = {[LEAF] = write_dummy },
          baz = {[LEAF] = write_dummy }
        })
      end)
    end)
  end)


  describe("when given some routes", function()

    before_each(function ()
      r:match( {
        get = {
          ["/s"]          = write_dummy,
          ["/s/a/b"]      = write_dummy,
          ["/s/c"]        = write_dummy,
          ["/s/:id"]      = write_dummy,
          ["/s/:id/foo"]  = write_dummy,
          ["/s/:bar/bar"] = write_dummy
        },
        post = {
          ["/s/:id"] = write_dummy
        }
      })
    end)

    describe(":resolve", function()

      it("gets fixed strings", function()
        local f, params = r:resolve("get", "/s")
        assert.equals(type(f), 'function')
        assert.same(params, {})
      end)

      it("gets params", function()
        local f, params = r:resolve("get", "/s/21")
        assert.equals(type(f), 'function')
        assert.same(params, {id = "21"})
      end)

      it("posts params", function()
        local f, params = r:resolve("post", "/s/21")
        assert.equals(type(f), 'function')
        assert.same(params, {id = "21"})
      end)

      it("gets with backtracking over params", function()
        local f, params = r:resolve("get", "/s/21/bar")
        assert.equals(type(f), 'function')
        assert.same(params, {bar = "21"})
      end)

      it("gets with backtracking over fixed string", function()
        local f, params = r:resolve("get", "/s/a/bar")
        assert.equals(type(f), 'function')
        assert.same(params, {bar = "a"})
      end)

      it("matches strings without backtracking", function()
        local f, params = r:resolve("get", "/s/a/b")
        assert.equals(type(f), 'function')
        assert.same(params, {})
      end)

      it("priorizes static variables over params", function()
        local f, p = r:resolve("get", "/s/c")
        assert.equals(type(f), 'function')
        assert.same(p, {})
      end)

    end)

    describe(":execute", function()

      it("runs the specified function with a get fixed string", function()
        r:execute("get", "/s")
        assert.same(dummy.params, {})
      end)

      it("runs the specified function with a param", function()
        r:execute("get", "/s/21")
        assert.same(dummy.params, {id = '21'})
      end)

      it("runs the specified function with a param in a post", function()
        r:execute("post", "/s/21")
        assert.same(dummy.params, {id = '21'})
      end)

      describe('when given extra parameters', function()

        it("adds them to the params list", function()
          r:execute("post", "/s/21", {bar = '22'})
          assert.same(dummy.params, {id = '21', bar = '22'})
        end)

        it("overrides with post params", function()
          r:execute("post", "/s/21", {id = '22'})
          assert.same(dummy.params, {id = '22'})
        end)
      end)
    end) -- :execute
  end) -- default params

end)
