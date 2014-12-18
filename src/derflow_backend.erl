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

-module(derflow_backend).
-author("Christopher Meiklejohn <cmeiklejohn@basho.com>").

-include("derflow.hrl").

%% @TODO: add spec for select

-callback next(id(), store()) -> {ok, id()}.
-callback next(id(), store(), function()) -> {ok, id()}.

-callback read(id(), store()) -> {ok, type(), value(), id()}.
-callback read(id(), value(), store()) -> {ok, type(), value(), id()}.
-callback read(id(), value(), store(), pid(), function(), function()) ->
    {ok, type(), value(), id()}.

-callback fetch(id(), id(), pid(), store(), function(), function(),
                function(), function()) -> term().

-callback declare(store()) -> {ok, id()}.
-callback declare(type(), store()) -> {ok, id()}.
-callback declare(id(), type(), store()) -> {ok, id()}.

-callback bind(id(), {id, id()}, store(), function(), pid()) -> any().
-callback bind(id(), {id, id()} | value(), store()) -> {ok, id()}.
-callback bind(id(), {id, id()} | value(), store(), function()) -> {ok, id()}.

-callback is_det(id(), store()) -> {ok, bound()}.

-callback thread(module(), func(), args(), store()) -> {ok, pid()}.

-callback next_key(undefined | id(), type(), store()) -> id().

-callback write(type(), value(), id(), id(), store()) -> ok.
-callback write(type(), value(), id(), id(), store(), function()) -> ok.

-callback wait_needed(id(), store()) -> ok.
-callback wait_needed(id(), store(), pid(), function(), function()) -> ok.

-callback notify_value(id(), value(), store(), function()) -> ok.
-callback notify_all(function(), list(#dv{}), value()) -> ok.

-callback reply_to_all(list(pending_threshold()), term()) ->
    {ok, list(pending_threshold())}.
-callback reply_to_all(list(pending_threshold()),
                       list(pending_threshold()),
                       term()) ->
    {ok, list(pending_threshold())}.

-callback select_harness(store(), id(), function(), id(), function(),
                         value()) -> function().