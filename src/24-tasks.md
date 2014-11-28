% Tasks

Concurrency and parallelism are topics that are of increasing interest to a
broad subsection of software developers. Modern computers are often multi-core,
to the point that even embedded devices like cell phones have more than one
processor. Rust's semantics lend themselves very nicely to solving a number of
issues that programmers have with concurrency. Many concurrency errors that are
runtime errors in other languages are compile-time errors in Rust.

Rust's concurrency primitive is called a **task**. Tasks are lightweight, and
do not share memory in an unsafe manner, preferring message passing to
communicate.  It's worth noting that tasks are implemented as a library, and
not part of the language.  This means that in the future, other concurrency
libraries can be written for Rust to help in specific scenarios.  Here's an
example of creating a task:

```{rust}
spawn(proc() {
    println!("Hello from a task!");
});
```

The `spawn` function takes a proc as an argument, and runs that proc in a new
task. A proc takes ownership of its entire environment, and so any variables
that you use inside the proc will not be usable afterward:

```{rust,ignore}
let mut x = vec![1i, 2i, 3i];

spawn(proc() {
    println!("The value of x[0] is: {}", x[0]);
});

println!("The value of x[0] is: {}", x[0]); // error: use of moved value: `x`
```

`x` is now owned by the proc, and so we can't use it anymore. Many other
languages would let us do this, but it's not safe to do so. Rust's borrow
checker catches the error.

If tasks were only able to capture these values, they wouldn't be very useful.
Luckily, tasks can communicate with each other through **channel**s. Channels
work like this:

```{rust}
let (tx, rx) = channel();

spawn(proc() {
    tx.send("Hello from a task!".to_string());
});

let message = rx.recv();
println!("{}", message);
```

The `channel()` function returns two endpoints: a `Receiver<T>` and a
`Sender<T>`. You can use the `.send()` method on the `Sender<T>` end, and
receive the message on the `Receiver<T>` side with the `recv()` method.  This
method blocks until it gets a message. There's a similar method, `.try_recv()`,
which returns an `Result<T, TryRecvError>` and does not block.

If you want to send messages to the task as well, create two channels!

```{rust}
let (tx1, rx1) = channel();
let (tx2, rx2) = channel();

spawn(proc() {
    tx1.send("Hello from a task!".to_string());
    let message = rx2.recv();
    println!("{}", message);
});

let message = rx1.recv();
println!("{}", message);

tx2.send("Goodbye from main!".to_string());
```

The proc has one sending end and one receiving end, and the main task has one
of each as well. Now they can talk back and forth in whatever way they wish.

Notice as well that because `Sender` and `Receiver` are generic, while you can
pass any kind of information through the channel, the ends are strongly typed.
If you try to pass a string, and then an integer, Rust will complain.

## Futures

With these basic primitives, many different concurrency patterns can be
developed. Rust includes some of these types in its standard library. For
example, if you wish to compute some value in the background, `Future` is
a useful thing to use:

```{rust}
use std::sync::Future;

let mut delayed_value = Future::spawn(proc() {
    // just return anything for examples' sake

    12345i
});
println!("value = {}", delayed_value.get());
```

Calling `Future::spawn` works just like `spawn()`: it takes a proc. In this
case, though, you don't need to mess with the channel: just have the proc
return the value.

`Future::spawn` will return a value which we can bind with `let`. It needs
to be mutable, because once the value is computed, it saves a copy of the
value, and if it were immutable, it couldn't update itself.

The proc will go on processing in the background, and when we need the final
value, we can call `get()` on it. This will block until the result is done,
but if it's finished computing in the background, we'll just get the value
immediately.

## Success and failure

Tasks don't always succeed, they can also panic. A task that wishes to panic
can call the `panic!` macro, passing a message:

```{rust}
spawn(proc() {
    panic!("Nope.");
});
```

If a task panics, it is not possible for it to recover. However, it can
notify other tasks that it has panicked. We can do this with `task::try`:

```{rust}
use std::task;
use std::rand;

let result = task::try(proc() {
    if rand::random() {
        println!("OK");
    } else {
        panic!("oops!");
    }
});
```

This task will randomly panic or succeed. `task::try` returns a `Result`
type, so we can handle the response like any other computation that may
fail.

