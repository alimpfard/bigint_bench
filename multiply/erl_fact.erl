-module(erl_fact).
-export([main/1]).

factorial(0, X) -> X;
factorial(N, X) ->
    factorial(N-1, N*X).

main(_) -> io:format("~w", [factorial(500000, 1)]).
