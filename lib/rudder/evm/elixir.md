
# iex

use `iex` to start a REPL.

exit - `Ctrl-C` twice

## type of a variable
`i <varname>`
```elixir
iex(6)> i pid
Term
  #PID<0.115.0>
Data type
  PID
Alive
  false
Description
  Use Process.info/1 to get more info about this process
Reference modules
  Process, Node
Implemented protocols
  IEx.Info, Inspect
```

## load a file
`Code.compile_file("start.exs")`


# processes

## spawn_link

`spawn_link` to have the errors propagate up the process heirarchy.
link processes to supervisors which will restart a process when it dies.

Use `Task` instead of spawn* functions to create and link processes. (for now just remember that Task provides better error reporting)


# alias, require, import
- alias: `use Counter.CounterN, as: CounterN`

setting alias for a given **module name**
future: aliases play a crucial role in macros (to guarantee that they're hygienic)

- require:
```elixir
require Integer  
```

require is needed to say use macros

- import

```elixir
import List, only: [duplicate, 2]
import List, except: [duplicate, 2]
```

when you want to use a specific function from another module several times.

- use
allows the "use"-d code to inject new code/state (it does so by using the `__using__/1` callback)

```elixir
defmodule Example do
  use Feature, option: :value
end
```

is compiled into

```elixir
defmodule Example do
  require Feature
  Feature.__using__(option: :value)
end
```


## module and functions

`&` is the capture operator, bridging the gap between anonymous and named functions

```elixir

iex(6)> defmodule MModule do
...(6)>   def afunc(), do: 2
...(6)> end
{:module, MModule,
 <<70, 79, 82, 49, 0, 0, 4, 172, 66, 69, 65, 77, 65, 116, 85, 56, 0, 0,
   0, 139, 0, 0, 0, 14, 14, 69, 108, 105, 120, 105, 114, 46, 77, 77, 111,
   100, 117, 108, 101, 8, 95, 95, 105, 110, 102, 111, 95, ...>>,
 {:afunc, 0}}
iex(7)> MModule.afunc()
2
iex(8)> f=&MModule.afunc/0
&MModule.afunc/0
iex(9)> f.()
2
iex(10)> is_function(f)
true

```

can also be used to create short function definitions

```elixir
iex(15)> increment = &(&1 + 1)
#Function<44.65746770/1 in :erl_eval.expr/5>
iex(16)> increment.(3)
4
```

here, `&1` is first argument of the function, while the outer `&` captures the functions. It's the same as: `fn a -> a+1 end`

default arguments 

```