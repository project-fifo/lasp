%% -------------------------------------------------------------------
%%
%% Copyright (c) 2015 Christopher Meiklejohn.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

-module(lasp_dynamic_scope_test).
-author("Christopher Meiklejohn <christopher.meiklejohn@gmail.com>").

-export([test/1]).

-ifdef(TEST).

-export([confirm/0]).

-define(HARNESS, (rt_config:get(rt_harness))).

-include_lib("eunit/include/eunit.hrl").

confirm() ->
    [Nodes] = lasp_test_helpers:build_clusters([3]),
    lager:info("Nodes: ~p", [Nodes]),
    Node = hd(Nodes),

    lager:info("Remotely loading code on node ~p", [Node]),
    ok = lasp_test_helpers:load(Nodes),
    lager:info("Remote code loading complete."),

    ok = lasp_test_helpers:wait_for_cluster(Nodes),

    lager:info("Remotely executing the test."),
    ?assertEqual(ok, rpc:call(Node, ?MODULE, test, [Nodes])),

    lager:info("Done!"),

    pass.

-endif.

-define(ID, <<"myidentifier">>).

test(Nodes) ->
    test_ivar_declare(Nodes),
    test_ivar_update(Nodes),
    ok.

test_ivar_declare([Node1, Node2, _Node3]) ->
    %% Setup a dynamic variable.
    {ok, {Id, _, _, Value}} = rpc:call(Node1, lasp, declare_dynamic, [?ID, lasp_ivar]),

    %% Now, the following action should be idempotent.
    {ok, {Id, _, _, Value}} = rpc:call(Node2, lasp, declare_dynamic, [?ID, lasp_ivar]),

    %% Bind node 1's name to the value on node 1: this should not
    %% trigger a broadcast message because the variable is dynamic.
    {ok, {Id, _, _, Node1}} = rpc:call(Node1, lasp, bind, [?ID, Node1]),

    %% Bind node 1's name to the value on node 1: this should not
    %% trigger a broadcast message because the variable is dynamic.
    {ok, {Id, _, _, Node2}} = rpc:call(Node2, lasp, bind, [?ID, Node2]),

    %% Verify variable has the correct value.
    {ok, Node1} = rpc:call(Node1, lasp, query, [?ID]),

    %% Verify variable has the correct value.
    {ok, Node2} = rpc:call(Node2, lasp, query, [?ID]),

    ok.

test_ivar_update([_Node1, _Node2, Node3]) ->
    %% Setup a dynamic variable.
    {ok, {Id, _, _, _}} = rpc:call(Node3, lasp, declare_dynamic, [?ID, lasp_ivar]),

    %% Update it.
    {ok, {Id, _, _, Node3}} = rpc:call(Node3, lasp, update, [?ID, {set, Node3}, Node3]),

    ok.
