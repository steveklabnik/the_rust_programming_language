% Unsafe

Finally, there's one more Rust concept that you should be aware of: `unsafe`.
There are two circumstances where Rust's safety provisions don't work well.
The first is when interfacing with C code, and the second is when building
certain kinds of abstractions.

Rust has support for [FFI](http://en.wikipedia.org/wiki/Foreign_function_interface)
(which you can read about in the [FFI Guide](guide-ffi.html)), but can't guarantee
that the C code will be safe. Therefore, Rust marks such functions with the `unsafe`
keyword, which indicates that the function may not behave properly.

Second, if you'd like to create some sort of shared-memory data structure, Rust
won't allow it, because memory must be owned by a single owner. However, if
you're planning on making access to that shared memory safe – such as with a
mutex – _you_ know that it's safe, but Rust can't know. Writing an `unsafe`
block allows you to ask the compiler to trust you. In this case, the _internal_
implementation of the mutex is considered unsafe, but the _external_ interface
we present is safe. This allows it to be effectively used in normal Rust, while
being able to implement functionality that the compiler can't double check for
us.

Doesn't an escape hatch undermine the safety of the entire system? Well, if
Rust code segfaults, it _must_ be because of unsafe code somewhere. By
annotating exactly where that is, you have a significantly smaller area to
search.

We haven't even talked about any examples here, and that's because I want to
emphasize that you should not be writing unsafe code unless you know exactly
what you're doing. The vast majority of Rust developers will only interact with
it when doing FFI, and advanced library authors may use it to build certain
kinds of abstraction.
