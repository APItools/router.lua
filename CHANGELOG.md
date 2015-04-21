
# v2.0.0

* The documentation now uses uppercase http verbs instead of lowercase ones (`r:match('GET', ...)` instead of `r:match('get', ...)`)
* The shortcut methods now define uppercase http verbs. In other words, `r:get(...)` is equivalent to `r:match('GET', ...)` instead of `r:match('get', ...)`. This is a backwards-incompatible change, hence the version bump.
