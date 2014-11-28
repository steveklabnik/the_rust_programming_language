% Testing

Traditionally, testing has not been a strong suit of most systems programming
languages. Rust, however, has very basic testing built into the language
itself.  While automated testing cannot prove that your code is bug-free, it is
useful for verifying that certain behaviors work as intended.

Here's a very basic test:

```{rust}
#[test]
fn is_one_equal_to_one() {
    assert_eq!(1i, 1i);
}
```

You may notice something new: that `#[test]`. Before we get into the mechanics
of testing, let's talk about attributes.

## Attributes

Rust's testing system uses **attribute**s to mark which functions are tests.
Attributes can be placed on any Rust **item**. Remember how most things in
Rust are an expression, but `let` is not? Item declarations are also not
expressions. Here's a list of things that qualify as an item:

* functions
* modules
* type definitions
* structures
* enumerations
* static items
* traits
* implementations

You haven't learned about all of these things yet, but that's the list. As
you can see, functions are at the top of it.

Attributes can appear in three ways:

1. A single identifier, the attribute name. `#[test]` is an example of this.
2. An identifier followed by an equals sign (`=`) and a literal. `#[cfg=test]`
   is an example of this.
3. An identifier followed by a parenthesized list of sub-attribute arguments.
   `#[cfg(unix, target_word_size = "32")]` is an example of this, where one of
    the sub-arguments is of the second kind.

There are a number of different kinds of attributes, enough that we won't go
over them all here. Before we talk about the testing-specific attributes, I
want to call out one of the most important kinds of attributes: stability
markers.

## Stability attributes

Rust provides six attributes to indicate the stability level of various
parts of your library. The six levels are:

* deprecated: This item should no longer be used. No guarantee of backwards
  compatibility.
* experimental: This item was only recently introduced or is otherwise in a
  state of flux. It may change significantly, or even be removed. No guarantee
  of backwards-compatibility.
* unstable: This item is still under development, but requires more testing to
  be considered stable. No guarantee of backwards-compatibility.
* stable: This item is considered stable, and will not change significantly.
  Guarantee of backwards-compatibility.
* frozen: This item is very stable, and is unlikely to change. Guarantee of
  backwards-compatibility.
* locked: This item will never change unless a serious bug is found. Guarantee
  of backwards-compatibility.

All of Rust's standard library uses these attribute markers to communicate
their relative stability, and you should use them in your code, as well.
There's an associated attribute, `warn`, that allows you to warn when you
import an item marked with certain levels: deprecated, experimental and
unstable. For now, only deprecated warns by default, but this will change once
the standard library has been stabilized.

You can use the `warn` attribute like this:

```{rust,ignore}
#![warn(unstable)]
```

And later, when you import a crate:

```{rust,ignore}
extern crate some_crate;
```

You'll get a warning if you use something marked unstable.

You may have noticed an exclamation point in the `warn` attribute declaration.
The `!` in this attribute means that this attribute applies to the enclosing
item, rather than to the item that follows the attribute. So this `warn`
attribute declaration applies to the enclosing crate itself, rather than
to whatever item statement follows it:

```{rust,ignore}
// applies to the crate we're in
#![warn(unstable)]

extern crate some_crate;

// applies to the following `fn`.
#[test]
fn a_test() {
  // ...
}
```

## Writing tests

Let's write a very simple crate in a test-driven manner. You know the drill by
now: make a new project:

```{bash,ignore}
$ cd ~/projects
$ cargo new testing --bin
$ cd testing
```

And try it out:

```{notrust,ignore}
$ cargo run
   Compiling testing v0.0.1 (file:///home/you/projects/testing)
     Running `target/testing`
Hello, world!
```

Great. Rust's infrastructure supports tests in two sorts of places, and they're
for two kinds of tests: you include **unit test**s inside of the crate itself,
and you place **integration test**s inside a `tests` directory. "Unit tests"
are small tests that test one focused unit, "integration tests" tests multiple
units in integration. That said, this is a social convention, they're no different
in syntax. Let's make a `tests` directory:

```{bash,ignore}
$ mkdir tests
```

Next, let's create an integration test in `tests/lib.rs`:

```{rust,no_run}
#[test]
fn foo() {
    assert!(false);
}
```

It doesn't matter what you name your test functions, though it's nice if
you give them descriptive names. You'll see why in a moment. We then use a
macro, `assert!`, to assert that something is true. In this case, we're giving
it `false`, so this test should fail. Let's try it!

```{notrust,ignore}
$ cargo test
   Compiling testing v0.0.1 (file:///home/you/projects/testing)
/home/you/projects/testing/src/main.rs:1:1: 3:2 warning: function is never used: `main`, #[warn(dead_code)] on by default
/home/you/projects/testing/src/main.rs:1 fn main() {
/home/you/projects/testing/src/main.rs:2     println!("Hello, world!")
/home/you/projects/testing/src/main.rs:3 }
     Running target/lib-654ce120f310a3a5

running 1 test
test foo ... FAILED

failures:

---- foo stdout ----
        task 'foo' failed at 'assertion failed: false', /home/you/projects/testing/tests/lib.rs:3



failures:
    foo

test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured

task '<main>' failed at 'Some tests failed', /home/you/src/rust/src/libtest/lib.rs:243
```

Lots of output! Let's break this down:

```{notrust,ignore}
$ cargo test
   Compiling testing v0.0.1 (file:///home/you/projects/testing)
```

You can run all of your tests with `cargo test`. This runs both your tests in
`tests`, as well as the tests you put inside of your crate.

```{notrust,ignore}
/home/you/projects/testing/src/main.rs:1:1: 3:2 warning: function is never used: `main`, #[warn(dead_code)] on by default
/home/you/projects/testing/src/main.rs:1 fn main() {
/home/you/projects/testing/src/main.rs:2     println!("Hello, world!")
/home/you/projects/testing/src/main.rs:3 }
```

Rust has a **lint** called 'warn on dead code' used by default. A lint is a
bit of code that checks your code, and can tell you things about it. In this
case, Rust is warning us that we've written some code that's never used: our
`main` function. Of course, since we're running tests, we don't use `main`.
We'll turn this lint off for just this function soon. For now, just ignore this
output.

```{notrust,ignore}
     Running target/lib-654ce120f310a3a5

running 1 test
test foo ... FAILED
```

Now we're getting somewhere. Remember when we talked about naming our tests
with good names? This is why. Here, it says 'test foo' because we called our
test 'foo.' If we had given it a good name, it'd be more clear which test
failed, especially as we accumulate more tests.

```{notrust,ignore}
failures:

---- foo stdout ----
        task 'foo' failed at 'assertion failed: false', /home/you/projects/testing/tests/lib.rs:3



failures:
    foo

test result: FAILED. 0 passed; 1 failed; 0 ignored; 0 measured

task '<main>' failed at 'Some tests failed', /home/you/src/rust/src/libtest/lib.rs:243
```

After all the tests run, Rust will show us any output from our failed tests.
In this instance, Rust tells us that our assertion failed, with false. This was
what we expected.

Whew! Let's fix our test:

```{rust}
#[test]
fn foo() {
    assert!(true);
}
```

And then try to run our tests again:

```{notrust,ignore}
$ cargo test
   Compiling testing v0.0.1 (file:///home/you/projects/testing)
     Running target/lib-654ce120f310a3a5

running 1 test
test foo ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

     Running target/testing-6d7518593c7c3ee5

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured
```

Nice! Our test passes, as we expected. Note how we didn't get the
`main` warning this time? This is because `src/main.rs` didn't
need recompiling, but we'll get that warning again if we
change (and recompile) that file. Let's get rid of that
warning; change your `src/main.rs` to look like this:

```{rust}
#[cfg(not(test))]
fn main() {
    println!("Hello, world!")
}
```

This attribute combines two things: `cfg` and `not`. The `cfg` attribute allows
you to conditionally compile code based on something. The following item will
only be compiled if the configuration says it's true. And when Cargo compiles
our tests, it sets things up so that `cfg(test)` is true. But we want to only
include `main` when it's _not_ true. So we use `not` to negate things:
`cfg(not(test))` will only compile our code when the `cfg(test)` is false.

With this attribute we won't get the warning (even
though `src/main.rs` gets recompiled this time):

```{notrust,ignore}
$ cargo test
   Compiling testing v0.0.1 (file:///home/you/projects/testing)
     Running target/lib-654ce120f310a3a5

running 1 test
test foo ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

     Running target/testing-6d7518593c7c3ee5

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured
```

Nice. Okay, let's write a real test now. Change your `tests/lib.rs`
to look like this:

```{rust,ignore}
#[test]
fn math_checks_out() {
    let result = add_three_times_four(5i);

    assert_eq!(32i, result);
}
```

And try to run the test:

```{notrust,ignore}
$ cargo test
   Compiling testing v0.0.1 (file:///home/you/projects/testing)
/home/you/projects/testing/tests/lib.rs:3:18: 3:38 error: unresolved name `add_three_times_four`.
/home/you/projects/testing/tests/lib.rs:3     let result = add_three_times_four(5i);
                                                           ^~~~~~~~~~~~~~~~~~~~
error: aborting due to previous error
Build failed, waiting for other jobs to finish...
Could not compile `testing`.

To learn more, run the command again with --verbose.
```

Rust can't find this function. That makes sense, as we didn't write it yet!

In order to share this code with our tests, we'll need to make a library crate.
This is also just good software design: as we mentioned before, it's a good idea
to put most of your functionality into a library crate, and have your executable
crate use that library. This allows for code re-use.

To do that, we'll need to make a new module. Make a new file, `src/lib.rs`,
and put this in it:

```{rust}
# fn main() {}
pub fn add_three_times_four(x: int) -> int {
    (x + 3) * 4
}
```

We're calling this file `lib.rs`, because Cargo uses that filename as the crate
root by convention.

We'll then need to use this crate in our `src/main.rs`:

```{rust,ignore}
extern crate testing;

#[cfg(not(test))]
fn main() {
    println!("Hello, world!")
}
```

Finally, let's import this function in our `tests/lib.rs`:

```{rust,ignore}
extern crate testing;
use testing::add_three_times_four;

#[test]
fn math_checks_out() {
    let result = add_three_times_four(5i);

    assert_eq!(32i, result);
}
```

Let's give it a run:

```{ignore,notrust}
$ cargo test
   Compiling testing v0.0.1 (file:///home/you/projects/testing)
     Running target/lib-654ce120f310a3a5

running 1 test
test math_checks_out ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

     Running target/testing-6d7518593c7c3ee5

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured

     Running target/testing-8a94b31f7fd2e8fe

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured

   Doc-tests testing

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured
```

Great! One test passed. We've got an integration test showing that our public
method works, but maybe we want to test some of the internal logic as well.
While this function is simple, if it were more complicated, you can imagine
we'd need more tests. So let's break it up into two helper functions, and
write some unit tests to test those.

Change your `src/lib.rs` to look like this:

```{rust,ignore}
pub fn add_three_times_four(x: int) -> int {
    times_four(add_three(x))
}

fn add_three(x: int) -> int { x + 3 }

fn times_four(x: int) -> int { x * 4 }
```

If you run `cargo test`, you should get the same output:

```{ignore,notrust}
$ cargo test
   Compiling testing v0.0.1 (file:///home/you/projects/testing)
     Running target/lib-654ce120f310a3a5

running 1 test
test math_checks_out ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

     Running target/testing-6d7518593c7c3ee5

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured

     Running target/testing-8a94b31f7fd2e8fe

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured

   Doc-tests testing

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured
```

If we tried to write a test for these two new functions, it wouldn't
work. For example:

```{rust,ignore}
extern crate testing;
use testing::add_three_times_four;
use testing::add_three;

#[test]
fn math_checks_out() {
    let result = add_three_times_four(5i);

    assert_eq!(32i, result);
}

#[test]
fn test_add_three() {
    let result = add_three(5i);

    assert_eq!(8i, result);
}
```

We'd get this error:

```{notrust,ignore}
   Compiling testing v0.0.1 (file:///home/you/projects/testing)
/home/you/projects/testing/tests/lib.rs:3:5: 3:24 error: function `add_three` is private
/home/you/projects/testing/tests/lib.rs:3 use testing::add_three;
                                              ^~~~~~~~~~~~~~~~~~~
```

Right. It's private. So external, integration tests won't work. We need a
unit test. Open up your `src/lib.rs` and add this:

```{rust,ignore}
pub fn add_three_times_four(x: int) -> int {
    times_four(add_three(x))
}

fn add_three(x: int) -> int { x + 3 }

fn times_four(x: int) -> int { x * 4 }

#[cfg(test)]
mod test {
    use super::add_three;
    use super::times_four;

    #[test]
    fn test_add_three() {
        let result = add_three(5i);

        assert_eq!(8i, result);
    }

    #[test]
    fn test_times_four() {
        let result = times_four(5i);

        assert_eq!(20i, result);
    }
}
```

Let's give it a shot:

```{ignore,notrust}
$ cargo test
   Compiling testing v0.0.1 (file:///home/you/projects/testing)
     Running target/lib-654ce120f310a3a5

running 1 test
test math_checks_out ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

     Running target/testing-6d7518593c7c3ee5

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured

     Running target/testing-8a94b31f7fd2e8fe

running 2 tests
test test::test_times_four ... ok
test test::test_add_three ... ok

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured

   Doc-tests testing

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured
```

Cool! We now have two tests of our internal functions. You'll note that there
are three sets of output now: one for `src/main.rs`, one for `src/lib.rs`, and
one for `tests/lib.rs`. There's one interesting thing that we haven't talked
about yet, and that's these lines:

```{rust,ignore}
use super::add_three;
use super::times_four;
```

Because we've made a nested module, we can import functions from the parent
module by using `super`. Sub-modules are allowed to 'see' private functions in
the parent.

We've now covered the basics of testing. Rust's tools are primitive, but they
work well in the simple cases. There are some Rustaceans working on building
more complicated frameworks on top of all of this, but they're just starting
out.
