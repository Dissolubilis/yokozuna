%% -------------------------------------------------------------------
%%
%% Copyright (c) 2012 Basho Technologies, Inc.  All Rights Reserved.
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

-module(yz_riakdoc_extractor).
-compile(export_all).
-include("yokozuna.hrl").
-define(NO_OPTIONS, []).

%% @doc Extractor for riakdoc format.  YAML headers followed by the
%%      body.

extract(Values) ->
    extract(Values, ?NO_OPTIONS).

-spec extract(binary(), proplist()) -> [{binary(), binary()}] |
                                       {error, any()}.
extract(Value, _Opts) ->
    extract_fields(Value).

extract_fields(Value) ->
    {Headers, Body} = extract_headers(Value),
    HeaderFields = lists:foldl(fun extract_header/2, [], [key_value(H)
                                                          || H <- Headers]),
    HeaderFields ++ [{body_en, Body}].

-spec extract_headers(binary()) -> {[binary()], binary()}.
extract_headers(Value) ->
    YamlPat = "^\-{3}$(.+?)^\-{3}$",
    Opts = [group, dotall, multiline, {newline, anycrlf}],
    case re:split(Value, YamlPat, Opts) of
        [[_, Header],[Body]] ->
            Headers = [H || H <- binary:split(Header, <<"\n">>, [global]), H /= <<>>],
            {Headers, Body};
        [[Body]] ->
            {[], Body}
    end.

key_value(Header) ->
    [list_to_binary(string:strip(S)) || S <- re:split(Header, <<":\s*">>, [{parts,2},{return,list}])].

extract_header([<<"title">>, Title], Fields) ->
    [{title_t, Title}|Fields];
extract_header([<<"project">>, Project], Fields) ->
    [{project_s, Project}|Fields];
extract_header([<<"version">>, Version], Fields) ->
    [{version_s, Version}|Fields];
extract_header([<<"document">>, Document], Fields) ->
    [{document_s, Document}|Fields];
extract_header([<<"audience">>, Audience], Fields) ->
    [{audience_s, Audience}|Fields];
extract_header([<<"keywords">>, Keywords], Fields) ->
    case re:replace(Keywords, <<"\\[|\\]">>, <<"">>, [global]) of
        [_,Keywords2,_] ->
            Keywords3 = re:split(Keywords2, <<",\s*">>),
            Keywords4 = [{keywords_ss, K} || K <- Keywords3],
            Fields ++ Keywords4;
        _ ->
            Fields
    end;
extract_header(_, Fields) ->
    Fields.
