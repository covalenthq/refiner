# Block Processor

## supervision tree

```txt

                         PoolSupervisor
                          /            \
                         /              \ (dynamically gen)
                     Server           WorkerSupervisor
                  (permanent)            (temporary)
                                             \
                                              \
                                              Executor
                                              (transient)

```

Executor does it's job successfully (status code from evm 0 or otherwise), it has to send `:success` or `:failure` to the GenServer.

If there's some error in the executor like evm cli wrongly invoked or executable not present etc. The whole chain upto the PoolSupervisor is probably not useful (concluded after some process crashes), and should - send an exit signal which indicates that the evm processor can't be worked with now.

There should be some way to update the code.

Also, some persistence of request queue (like mnesia??) so that restarts of PoolSupervisor can resume from unprocessed blocks.


test/evm has 2 evm executables - evm and evm-with-exit12. The latter is a special executable which just exits with status code 12.









----
Rough notes


stash, executor - transient
stateful executor - temporary
server - transient



[block specimen -> tracing -> block result -> contract snapshots] 