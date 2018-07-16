%% Copyright (c) 2018 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(emqx_stomp).

-behaviour(application).

-export([start/2, stop/1]).
-export([start_listener/0, stop_listener/0]).

-define(APP, ?MODULE).

-define(SOCK_OPTS, [binary, {packet, raw}, {reuseaddr, true}, {nodelay, true}]).

%%--------------------------------------------------------------------
%% Application callbacks
%%--------------------------------------------------------------------

start(_StartType, _StartArgs) ->
    {ok, Sup} = supervisor:start_link({local, emqx_stomp_sup}, ?MODULE, []),
    start_listener(),
    emqx_stomp_config:register(),
    {ok, Sup}.

stop(_State) ->
    stop_listener(),
    emqx_stomp_config:unregister().

%%--------------------------------------------------------------------
%% Supervisor callbacks
%%--------------------------------------------------------------------

init([]) ->
    {ok, {{one_for_all, 10, 100}, []}}.

%%--------------------------------------------------------------------
%% Start/Stop listeners
%%--------------------------------------------------------------------

start_listener() ->
    {ok, {Port, Opts}} = application:get_env(?APP, listener),
    {ok, Env} = application:get_env(?APP, frame),
    MFArgs = {emqx_stomp_connection, start_link, [Env]},
    esockd:open(stomp, Port, merge_sockopts(Opts), MFArgs).

merge_sockopts(Opts) ->
    SockOpts = emqx_misc:merge_opts(
                 ?SOCK_OPTS, proplists:get_value(sockopts, Opts, [])),
    emqx_misc:merge_opts(Opts, [{sockopts, SockOpts}]).

stop_listener() ->
    {ok, {Port, _Opts}} = application:get_env(?APP, listener),
    esockd:close({stomp, Port}).
