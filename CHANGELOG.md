
# v2.0.0

* The documentation now uses uppercase http verbs instead of lowercase ones (`r:match('GET', ...)` instead of `r:match('get', ...)`)
* The shortcut methods now define uppercase http verbs. In other words, `r:get(...)` is equivalent to `r:match('GET', ...)` instead of `r:match('get', ...)`. This is a backwards-incompatible change, hence the version bump.

# v2.0.1

* Throws an error when an unknown verb gets received

# v2.1.0

* Parameters can now be given in a splat list. So if before you had to do `r:resolve('GET', '/foo/bar', table_merge(params1, params2))`, now you can do `r:resolve('GET', '/foo/bar', params1, params2)`.
* Passed-in parameters no longer override url parameters (url parameters are stronger). This allows using the params in a "default params" quality.
