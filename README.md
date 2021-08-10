# Multithreading
## Use GCD Concepts

### Quick guide of how and when to use the various queues with async
- Main Queue: This is a common choice to update the UI after completing work in a task on a concurrent queue. To do this, you code one closure inside another. Targeting the main queue and calling async guarantees that this new task will execute sometime after the current method finishes.
- Global Queue: This is a common choice to perform non-UI work in the background.
- Custom Serial Queue: A good choice when you want to perform background work serially and track it. This eliminates resource contention and race conditions since you know only one task at a time is executing. Note that if you need the data from a method, you must declare another closure to retrieve it or consider using sync.

### Quick guide of how and when to use the various queues with sync
- Main Queue: Be VERY careful for the same reasons as above; this situation also has potential for a deadlock condition. This is especially bad on the main queue because the whole app will become unresponsive.
- Global Queue: This is a good candidate to sync work through dispatch barriers or when waiting for a task to complete so you can perform further processing.
- Custom Serial Queue: Be VERY careful in this situation; if you’re running in a queue and call sync targeting the same queue, you’ll definitely create a deadlock.
