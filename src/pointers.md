% Pointers

In systems programming, pointers are an incredibly important topic. Rust has a
very rich set of pointers, and they operate differently than in many other
languages. They are important enough that we have a specific [Pointer
Guide](guide-pointers.html) that goes into pointers in much detail. In fact,
while you're currently reading this guide, which covers the language in broad
overview, there are a number of other guides that put a specific topic under a
microscope. You can find the list of guides on the [documentation index
page](index.html#guides).

In this section, we'll assume that you're familiar with pointers as a general
concept. If you aren't, please read the [introduction to
pointers](guide-pointers.html#an-introduction) section of the Pointer Guide,
and then come back here. We'll wait.

Got the gist? Great. Let's talk about pointers in Rust.

## References

The most primitive form of pointer in Rust is called a **reference**.
References are created using the ampersand (`&`). Here's a simple
reference:

```{rust}
let x = 5i;
let y = &x;
```

`y` is a reference to `x`. To dereference (get the value being referred to
rather than the reference itself) `y`, we use the asterisk (`*`):

```{rust}
let x = 5i;
let y = &x;

assert_eq!(5i, *y);
```

Like any `let` binding, references are immutable by default.

You can declare that functions take a reference:

```{rust}
fn add_one(x: &int) -> int { *x + 1 }

fn main() {
    assert_eq!(6, add_one(&5));
}
```

As you can see, we can make a reference from a literal by applying `&` as well.
Of course, in this simple function, there's not a lot of reason to take `x` by
reference. It's just an example of the syntax.

Because references are immutable, you can have multiple references that
**alias** (point to the same place):

```{rust}
let x = 5i;
let y = &x;
let z = &x;
```

We can make a mutable reference by using `&mut` instead of `&`:

```{rust}
let mut x = 5i;
let y = &mut x;
```

Note that `x` must also be mutable. If it isn't, like this:

```{rust,ignore}
let x = 5i;
let y = &mut x;
```

Rust will complain:

```{ignore,notrust}
error: cannot borrow immutable local variable `x` as mutable
 let y = &mut x;
              ^
```

We don't want a mutable reference to immutable data! This error message uses a
term we haven't talked about yet, 'borrow.' We'll get to that in just a moment.

This simple example actually illustrates a lot of Rust's power: Rust has
prevented us, at compile time, from breaking our own rules. Because Rust's
references check these kinds of rules entirely at compile time, there's no
runtime overhead for this safety.  At runtime, these are the same as a raw
machine pointer, like in C or C++.  We've just double-checked ahead of time
that we haven't done anything dangerous.

Rust will also prevent us from creating two mutable references that alias.
This won't work:

```{rust,ignore}
let mut x = 5i;
let y = &mut x;
let z = &mut x;
```

It gives us this error:

```{notrust,ignore}
error: cannot borrow `x` as mutable more than once at a time
     let z = &mut x;
                  ^
note: previous borrow of `x` occurs here; the mutable borrow prevents subsequent moves, borrows, or modification of `x` until the borrow ends
     let y = &mut x;
                  ^
note: previous borrow ends here
 fn main() {
     let mut x = 5i;
     let y = &mut x;
     let z = &mut x;
 }
 ^
```

This is a big error message. Let's dig into it for a moment. There are three
parts: the error and two notes. The error says what we expected, we cannot have
two mutable pointers that point to the same memory.

The two notes give some extra context. Rust's error messages often contain this
kind of extra information when the error is complex. Rust is telling us two
things: first, that the reason we cannot **borrow** `x` as `z` is that we
previously borrowed `x` as `y`. The second note shows where `y`'s borrowing
ends.

Wait, borrowing?

In order to truly understand this error, we have to learn a few new concepts:
**ownership**, **borrowing**, and **lifetimes**.

## Ownership, borrowing, and lifetimes

Whenever a resource of some kind is created, something must be responsible
for destroying that resource as well. Given that we're discussing pointers
right now, let's discuss this in the context of memory allocation, though
it applies to other resources as well.

When you allocate heap memory, you need a mechanism to free that memory. Many
languages use a garbage collector to handle deallocation. This is a valid,
time-tested strategy, but it's not without its drawbacks: it adds overhead, and
can lead to unpredictable pauses in execution. Because the programmer does not
have to think as much about deallocation, allocation becomes something
commonplace, leading to more memory usage. And if you need precise control
over when something is deallocated, leaving it up to your runtime can make this
difficult.

Rust chooses a different path, and that path is called **ownership**. Any
binding that creates a resource is the **owner** of that resource.

Being an owner affords you some privileges:

1. You control when that resource is deallocated.
2. You may lend that resource, immutably, to as many borrowers as you'd like.
3. You may lend that resource, mutably, to a single borrower.

But it also comes with some restrictions:

1. If someone is borrowing your resource (either mutably or immutably), you may
   not mutate the resource or mutably lend it to someone.
2. If someone is mutably borrowing your resource, you may not lend it out at
   all (mutably or immutably) or access it in any way.

What's up with all this 'lending' and 'borrowing'? When you allocate memory,
you get a pointer to that memory. This pointer allows you to manipulate said
memory. If you are the owner of a pointer, then you may allow another
binding to temporarily borrow that pointer, and then they can manipulate the
memory. The length of time that the borrower is borrowing the pointer
from you is called a **lifetime**.

If two distinct bindings share a pointer, and the memory that pointer points to
is immutable, then there are no problems. But if it's mutable, the result of
changing it can vary unpredictably depending on who happens to access it first,
which is called a **race condition**. To avoid this, if someone wants to mutate
something that they've borrowed from you, you must not have lent out that
pointer to anyone else.

Rust has a sophisticated system called the **borrow checker** to make sure that
everyone plays by these rules. At compile time, it verifies that none of these
rules are broken. If our program compiles successfully, Rust can guarantee it
is free of data races and other memory errors, and there is no runtime overhead
for any of this. The borrow checker works only at compile time. If the borrow
checker did find a problem, it will report an error and your program will
refuse to compile.

That's a lot to take in. It's also one of the _most_ important concepts in
all of Rust. Let's see this syntax in action:

```{rust}
{
    let x = 5i; // x is the owner of this integer, which is memory on the stack.

    // other code here...

} // privilege 1: when x goes out of scope, this memory is deallocated

/// this function borrows an integer. It's given back automatically when the
/// function returns.
fn foo(x: &int) -> &int { x }

{
    let x = 5i; // x is the owner of this integer, which is memory on the stack.

    // privilege 2: you may lend that resource, to as many borrowers as you'd like
    let y = &x;
    let z = &x;

    foo(&x); // functions can borrow too!

    let a = &x; // we can do this alllllll day!
}

{
    let mut x = 5i; // x is the owner of this integer, which is memory on the stack.

    let y = &mut x; // privilege 3: you may lend that resource to a single borrower,
                    // mutably
}
```

If you are a borrower, you get a few privileges as well, but must also obey a
restriction:

1. If the borrow is immutable, you may read the data the pointer points to.
2. If the borrow is mutable, you may read and write the data the pointer points to.
3. You may lend the pointer to someone else, **BUT**
4. When you do so, they must return it before you can give your own borrow back.

This last requirement can seem odd, but it also makes sense. If you have to
return something, and you've lent it to someone, they need to give it back to
you for you to give it back! If we didn't, then the owner could deallocate
the memory, and the person we've loaned it out to would have a pointer to
invalid memory. This is called a 'dangling pointer.'

Let's re-examine the error that led us to talk about all of this, which was a
violation of the restrictions placed on owners who lend something out mutably.
The code:

```{rust,ignore}
let mut x = 5i;
let y = &mut x;
let z = &mut x;
```

The error:

```{notrust,ignore}
error: cannot borrow `x` as mutable more than once at a time
     let z = &mut x;
                  ^
note: previous borrow of `x` occurs here; the mutable borrow prevents subsequent moves, borrows, or modification of `x` until the borrow ends
     let y = &mut x;
                  ^
note: previous borrow ends here
 fn main() {
     let mut x = 5i;
     let y = &mut x;
     let z = &mut x;
 }
 ^
```

This error comes in three parts. Let's go over each in turn.

```{notrust,ignore}
error: cannot borrow `x` as mutable more than once at a time
     let z = &mut x;
                  ^
```

This error states the restriction: you cannot lend out something mutable more
than once at the same time. The borrow checker knows the rules!

```{notrust,ignore}
note: previous borrow of `x` occurs here; the mutable borrow prevents subsequent moves, borrows, or modification of `x` until the borrow ends
     let y = &mut x;
                  ^
```

Some compiler errors come with notes to help you fix the error. This error comes
with two notes, and this is the first. This note informs us of exactly where
the first mutable borrow occurred. The error showed us the second. So now we
see both parts of the problem. It also alludes to rule #3, by reminding us that
we can't change `x` until the borrow is over.

```{notrust,ignore}
note: previous borrow ends here
 fn main() {
     let mut x = 5i;
     let y = &mut x;
     let z = &mut x;
 }
 ^
```

Here's the second note, which lets us know where the first borrow would be over.
This is useful, because if we wait to try to borrow `x` after this borrow is
over, then everything will work.

For more advanced patterns, please consult the [Lifetime
Guide](guide-lifetimes.html).  You'll also learn what this type signature with
the `'a` syntax is:

```{rust,ignore}
pub fn as_maybe_owned(&self) -> MaybeOwned<'a> { ... }
```

## Boxes

Most of the types we've seen so far have a fixed size or number of components.
The compiler needs this fact to lay out values in memory. However, some data
structures, such as a linked list, do not have a fixed size. You might think to
implement a linked list with an enum that's either a `Node` or the end of the
list (`Nil`), like this:

```{rust,ignore}
enum List {             // error: illegal recursive enum type
    Node(u32, List),
    Nil
}
```

But the compiler complains that the type is recursive, that is, it could be
arbitrarily large. To remedy this, Rust provides a fixed-size container called
a **box** that can hold any type. You can box up any value with the `box`
keyword. Our boxed List gets the type `Box<List>` (more on the notation when we
get to generics):

```{rust}
enum List {
    Node(u32, Box<List>),
    Nil
}

fn main() {
    let list = List::Node(0, box List::Node(1, box List::Nil));
}
```

A box dynamically allocates memory to hold its contents. The great thing about
Rust is that that memory is *automatically*, *efficiently*, and *predictably*
deallocated when you're done with the box.

A box is a pointer type, and you access what's inside using the `*` operator,
just like regular references. This (rather silly) example dynamically allocates
an integer `5` and makes `x` a pointer to it:

```{rust}
{
    let x = box 5i;
    println!("{}", *x);     // Prints 5
}
```

The great thing about boxes is that we don't have to manually free this
allocation! Instead, when `x` reaches the end of its lifetime -- in this case,
when it goes out of scope at the end of the block -- Rust `free`s `x`. This
isn't because Rust has a garbage collector (it doesn't). Instead, by tracking
the ownership and lifetime of a variable (with a little help from you, the
programmer), the compiler knows precisely when it is no longer used.

The Rust code above will do the same thing as the following C code:

```{c,ignore}
{
    int *x = (int *)malloc(sizeof(int));
    if (!x) abort();
    *x = 5;
    printf("%d\n", *x);
    free(x);
}
```

We get the benefits of manual memory management, while ensuring we don't
introduce any bugs. We can't forget to `free` our memory.

Boxes are the sole owner of their contents, so you cannot take a mutable
reference to them and then use the original box:

```{rust,ignore}
let mut x = box 5i;
let y = &mut x;

*x; // you might expect 5, but this is actually an error
```

This gives us this error:

```{notrust,ignore}
error: cannot use `*x` because it was mutably borrowed
 *x;
 ^~
note: borrow of `x` occurs here
 let y = &mut x;
              ^
```

As long as `y` is borrowing the contents, we cannot use `x`. After `y` is
done borrowing the value, we can use it again. This works fine:

```{rust}
let mut x = box 5i;

{
    let y = &mut x;
} // y goes out of scope at the end of the block

*x;
```

Boxes are simple and efficient pointers to dynamically allocated values with a
single owner. They are useful for tree-like structures where the lifetime of a
child depends solely on the lifetime of its (single) parent. If you need a
value that must persist as long as any of several referrers, read on.

## Rc and Arc

Sometimes you need a variable that is referenced from multiple places
(immutably!), lasting as long as any of those places, and disappearing when it
is no longer referenced. For instance, in a graph-like data structure, a node
might be referenced from all of its neighbors. In this case, it is not possible
for the compiler to determine ahead of time when the value can be freed -- it
needs a little run-time support.

Rust's **Rc** type provides shared ownership of a dynamically allocated value
that is automatically freed at the end of its last owner's lifetime. (`Rc`
stands for 'reference counted,' referring to the way these library types are
implemented.) This provides more flexibility than single-owner boxes, but has
some runtime overhead.

To create an `Rc` value, use `Rc::new()`. To create a second owner, use the
`.clone()` method:

```{rust}
use std::rc::Rc;

let x = Rc::new(5i);
let y = x.clone();

println!("{} {}", *x, *y);      // Prints 5 5
```

The `Rc` will live as long as any of its owners are alive. After that, the
memory will be `free`d.

**Arc** is an 'atomically reference counted' value, identical to `Rc` except
that ownership can be safely shared among multiple threads. Why two types?
`Arc` has more overhead, so if you're not in a multi-threaded scenario, you
don't have to pay the price.

If you use `Rc` or `Arc`, you have to be careful about introducing cycles. If
you have two `Rc`s that point to each other, they will happily keep each other
alive forever, creating a memory leak. To learn more, check out [the section on
`Rc` and `Arc` in the pointers guide](guide-pointers.html#rc-and-arc).
