%% -------------------------------------------------------------------
%%
%% Copyright (c) 2014 SyncFree Consortium.  All Rights Reserved.
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

-module(lasp_execute_coverage_fsm).
-author('Christopher Meiklejohn <cmeiklejohn@basho.com>').

-behaviour(riak_core_coverage_fsm).

-include_lib("lasp.hrl").

-export([execute/1,
         execute/2]).

-export([init/2,
         process_results/2,
         finish/2]).

-record(state, {from, module, result}).

%% ===================================================================
%% API functions
%% ===================================================================

execute(Module) ->
    execute(Module, 1).

execute(Module, NVal) ->
    ReqId = lasp:mk_reqid(),
    _ = lasp_execute_coverage_fsm_sup:start_child([{raw, ReqId, self()},
                                                   [?TIMEOUT, NVal, Module]]),
    {ok, ReqId}.

init(From={_, _, _}, [Timeout, NVal, Module]) ->
    Req = ?EXECUTE_REQUEST{module=Module},
    Result = gb_trees:empty(),
    {Req, all, NVal, 1, lasp, lasp_vnode_master, Timeout,
     #state{from=From, module=Module, result=Result}}.

process_results({error, Reason}, _State) ->
    {error, Reason};
process_results({From, {Key, Value}=Element}, #state{result=Result0}=State) ->
    lager:info("Received from: ~p element: ~p", [From, Element]),
    Result = gb_trees:enter(Key, Value, Result0),
    {ok, State#state{result=Result}};
process_results(done, State) ->
    lager:info("Received done", []),
    {done, State};
process_results(Message, State) ->
    lager:info("Unhandled result: ~p", [Message]),
    {ok, State}.

finish({error, Reason}=Error,
       StateData=#state{from={raw, ReqId, ClientPid}}) ->
    lager:info("Finish triggered with error: ~p", [Reason]),
    ClientPid ! {ReqId, Error},
    {stop, normal, StateData};
finish(clean,
       StateData=#state{from={raw, ReqId, ClientPid},
                        module=Module,
                        result=Result}) ->
    {ok, Value} = Module:value(Result),
    ClientPid ! {ReqId, ok, Value},
    {stop, normal, StateData};
finish(Message, StateData) ->
    lager:info("Unhandled finish: ~p", [Message]),
    {stop, normal, StateData}.
