local router = require 'router'

describe("Router", function()
  local dummy
  local function write_dummy(params) dummy.params = params end

  local _LEAF = router.leaf

  before_each(function ()
    dummy = {}
  end)

  describe("when given a compiled routes tree", function()

    before_each(function ()
      router.compiled_routes = {}
      router.match( {
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

    describe(".resolve", function()

      it("gets fixed strings", function()
        local f, params = router.resolve("get", "/s")
        assert.equals(type(f), 'function')
        assert.same(params, {})
      end)

      it("gets params", function()
        local f, params = router.resolve("get", "/s/21")
        assert.equals(type(f), 'function')
        assert.same(params, {id = "21"})
      end)

      it("posts params", function()
        local f, params = router.resolve("post", "/s/21")
        assert.equals(type(f), 'function')
        assert.same(params, {id = "21"})
      end)

      it("gets with backtracking over params", function()
        local f, params = router.resolve("get", "/s/21/bar")
        assert.equals(type(f), 'function')
        assert.same(params, {bar = "21"})
      end)

      it("gets with backtracking over fixed string", function()
        local f, params = router.resolve("get", "/s/a/bar")
        assert.equals(type(f), 'function')
        assert.same(params, {bar = "a"})
      end)

      it("matches strings without backtracking", function()
        local f, params = router.resolve("get", "/s/a/b")
        assert.equals(type(f), 'function')
        assert.same(params, {})
      end)

      it("priorizes static variables over params", function()
        local f, p = router.resolve("get", "/s/c")
        assert.equals(type(f), 'function')
        assert.same(p, {})
      end)

    end)

    describe(".execute", function()

      it("runs the specified function with a get fixed string", function()
        router.execute("get", "/s")
        assert.same(dummy.params, {})
      end)

      it("runs the specified function with a param", function()
        router.execute("get", "/s/21")
        assert.same(dummy.params, {id = '21'})
      end)

      it("runs the specified function with a param in a post", function()
        router.execute("post", "/s/21")
        assert.same(dummy.params, {id = '21'})
      end)

      describe('when given extra parameters', function()

        it("adds them to the params list", function()
          router.execute("post", "/s/21", {bar = '22'})
          assert.same(dummy.params, {id = '21', bar = '22'})
        end)

        it("overrides with post params", function()
          router.execute("post", "/s/21", {id = '22'})
          assert.same(dummy.params, {id = '22'})
        end)
      end)

    end)


    describe(".match", function()
      before_each(function()
        router.compiled_routes = {}
      end)

      describe('when first param is a string', function()
        it("understands fixed strings", function()
          router.match("get", "/foo", write_dummy)
          assert.same(router.compiled_routes, {
            get = { foo = { [_LEAF] = write_dummy } }
          })
        end)

        it("understands chained fixed strings", function()
          router.match("get", "/foo/bar", write_dummy)
          assert.same(router.compiled_routes, {
            get = { foo = { bar = { [_LEAF] = write_dummy } } }
          })
        end)

        it("understands params", function()
          router.match("get", "/foo/:id", write_dummy)
          local key, node = next(router.compiled_routes.get.foo)
          assert.same(key, {param = "id"})
          assert.same(node, { [_LEAF] = write_dummy })
        end)

        it("does not duplicate the same node twice for the same param id", function()
          router.match("get", "/foo/:id/bar", write_dummy)
          router.match("get", "/foo/:id/baz", write_dummy)
          local key, node = next(router.compiled_routes.get.foo)
          assert.same(key, {param = "id"})
          assert.same(node, {
            bar = {[_LEAF] = write_dummy },
            baz = {[_LEAF] = write_dummy }
          })
        end)
      end)

      describe('when first param is a table', function()
        it("understands fixed strings", function()
          router.match({ get = { ["/foo"] = write_dummy} })
          assert.same(router.compiled_routes, {
            get = { foo = { [_LEAF] = write_dummy } }
          })
        end)

        it("understands chained fixed strings", function()
          router.match({ get = { ["/foo/bar"] = write_dummy } })
          assert.same(router.compiled_routes, {
            get = { foo = { bar = { [_LEAF] = write_dummy } } }
          })
        end)

        it("understands params", function()
          router.match({get = {["/foo/:id"] = write_dummy}})
          local key, node = next(router.compiled_routes.get.foo)
          assert.same(key, {param = "id"})
          assert.same(node, { [_LEAF] = write_dummy })
        end)

        it("does not duplicate the same node twice for the same param id", function()
          router.match({
            get = {
              ["/foo/:id/bar"] = write_dummy,
              ["/foo/:id/baz"] = write_dummy
            }
          })
          local key, node = next(router.compiled_routes.get.foo)
          assert.same(key, {param = "id"})
          assert.same(node, {
            bar = {[_LEAF] = write_dummy },
            baz = {[_LEAF] = write_dummy }
          })
        end)
      end)


    end)


  end)
end)
