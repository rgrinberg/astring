(*---------------------------------------------------------------------------
   Copyright (c) 2015 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

(* Commonalities for strings and substrings *)

open Astring_unsafe

let strf = Format.asprintf

(* Errors *)

let err_empty_sep = "~sep is an empty string"

let err_pos_range start stop len =
  strf "invalid start:%d stop:%d for position range [0;%d]" start stop len

let err_pos_len start len s_len =
  strf "invalid start:%d len:%d for position range [0;%d]" start len s_len

let err_index_range first last len =
  strf "invalid first:%d last:%d for position range [0;%d]" first last len

(* Making substrings *)

let with_pos_range make_sub ?(start = 0) ?stop s =
  let s_len = string_length s in
  let stop = match stop with None -> s_len | Some stop -> stop in
  if start < 0 || stop > s_len || stop < start
  then invalid_arg (err_pos_range start stop s_len)
  else make_sub s ~start ~stop

let with_pos_len make_sub ?(start = 0) ?len s =
  let s_len = string_length s in
  let len = match len with None -> s_len - start | Some l -> l in
  let stop = start + len in
  if start < 0 || stop > s_len || stop < start
  then invalid_arg (err_pos_len start len s_len)
  else make_sub s ~start ~stop

let with_index_range make_sub ?(first = 0) ?last s =
  let s_len = string_length s in
  let last = match last with None -> s_len - 1 | Some l -> l in
  if first < 0 || last > s_len - 1 || last < first
  then invalid_arg (err_index_range first last s_len)
  else make_sub s ~start:first ~stop:(last + 1)

(* Base *)

let empty = ""

(* Predicates *)

let for_all sat s ~start ~stop =
  let max_idx = stop - 1 in
  let rec loop i =
    if i > max_idx then true else
    if sat (string_unsafe_get s i) then loop (i + 1) else false
  in
  loop start

let exists sat s ~start ~stop =
  let max_idx = stop - 1 in
  let rec loop i =
    if i > max_idx then false else
    if sat (string_unsafe_get s i) then true else loop (i + 1)
  in
  loop start

(* Traversing *)

let fold_left f acc s ~start ~stop =
  let max_idx = stop - 1 in
  let rec loop acc i =
    if i > max_idx then acc else
    loop (f acc (string_unsafe_get s i)) (i + 1)
  in
  loop acc start

let fold_right f s acc ~start ~stop =
  let max_idx = stop - 1 in
  let rec loop i acc =
    if i < start then acc else
    loop (i - 1) (f (string_unsafe_get s i) acc)
  in
  loop max_idx acc

(* OCaml conversions *)

let of_char c =
  let b = Bytes.create 1 in
  bytes_unsafe_set b 0 c;
  bytes_unsafe_to_string b

let to_char s = match string_length s with
| 0 -> None
| 1 -> Some (string_unsafe_get s 0)
| _ -> None

let of_bool = string_of_bool
let to_bool s =
  try Some (bool_of_string s) with Invalid_argument (* good joke *) _ -> None

let of_int = string_of_int
let to_int s = try Some (int_of_string s) with Failure _ -> None
let of_nativeint = Nativeint.to_string
let to_nativeint s = try Some (Nativeint.of_string s) with Failure _ -> None
let of_int32 = Int32.to_string
let to_int32 s = try Some (Int32.of_string s) with Failure _ -> None
let of_int64 = Int64.to_string
let to_int64 s = try Some (Int64.of_string s) with Failure _ -> None
let of_float = Pervasives.string_of_float
let to_float s = try Some (float_of_string s) with Failure _ -> None

(*---------------------------------------------------------------------------
   Copyright (c) 2015 Daniel C. Bünzli.
   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

   3. Neither the name of Daniel C. Bünzli nor the names of
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  ---------------------------------------------------------------------------*)
