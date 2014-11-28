% Macros

One of Rust's most advanced features is its system of **macro**s. While
functions allow you to provide abstractions over values and operations, macros
allow you to provide abstractions over syntax. Do you wish Rust had the ability
to do something that it can't currently do? You may be able to write a macro
to extend Rust's capabilities.

You've already used one macro extensively: `println!`. When we invoke
a Rust macro, we need to use the exclamation mark (`!`). There are two reasons
why this is so: the first is that it makes it clear when you're using a
macro. The second is that macros allow for flexible syntax, and so Rust must
be able to tell where a macro starts and ends. The `!(...)` helps with this.

Let's talk some more about `println!`. We could have implemented `println!` as
a function, but it would be worse. Why? Well, what macros allow you to do
is write code that generates more code. So when we call `println!` like this:

```{rust}
let x = 5i;
println!("x is: {}", x);
```

The `println!` macro does a few things:

1. It parses the string to find any `{}`s.
2. It checks that the number of `{}`s matches the number of other arguments.
3. It generates a bunch of Rust code, taking this in mind.

What this means is that you get type checking at compile time, because
Rust will generate code that takes all of the types into account. If
`println!` was a function, it could still do this type checking, but it
would happen at run time rather than compile time.

We can check this out using a special flag to `rustc`. Put this code in a file
called `print.rs`:

```{rust}
fn main() {
    let x = 5i;
    println!("x is: {}", x);
}
```

You can have the macros expanded like this: `rustc print.rs --pretty=expanded` – which will
give us this huge result:

```{rust,ignore}
#![feature(phase)]
#![no_std]
#![feature(globs)]
#[phase(plugin, link)]
extern crate "std" as std;
extern crate "native" as rt;
#[prelude_import]
use std::prelude::*;
fn main() {
    let x = 5i;
    match (&x,) {
        (__arg0,) => {
            #[inline]
            #[allow(dead_code)]
            static __STATIC_FMTSTR: [&'static str, ..1u] = ["x is: "];
            let __args_vec =
                &[::std::fmt::argument(::std::fmt::secret_show, __arg0)];
            let __args =
                unsafe {
                    ::std::fmt::Arguments::new(__STATIC_FMTSTR, __args_vec)
                };
            ::std::io::stdio::println_args(&__args)
        }
    };
}
```

Whew! This isn't too terrible. You can see that we still `let x = 5i`,
but then things get a little bit hairy. Three more bindings get set: a
static format string, an argument vector, and the arguments. We then
invoke the `println_args` function with the generated arguments.

This is the code that Rust actually compiles. You can see all of the extra
information that's here. We get all of the type safety and options that it
provides, but at compile time, and without needing to type all of this out.
This is how macros are powerful: without them you would need to type all of
this by hand to get a type-checked `println`.

For more on macros, please consult [the Macros Guide](guide-macros.html).
Macros are a very advanced and still slightly experimental feature, but they don't
require a deep understanding to be called, since they look just like functions. The
Guide can help you if you want to write your own.
