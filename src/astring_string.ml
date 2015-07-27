(*---------------------------------------------------------------------------
   Copyright (c) 2015 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

open Astring_unsafe

let strf = Format.asprintf

(* Errors *)

let err_start pos s =
  strf "invalid start position: %d not in [0;%d]" pos (string_length s)

(* String *)

type t = string

let empty = Astring_base.empty
let v ~len f =
  let b = Bytes.create len in
  for i = 0 to len - 1 do bytes_unsafe_set b i (f i) done;
  bytes_unsafe_to_string b

let length = string_length
let get = string_safe_get
let get_byte s i = char_to_byte (get s i)
let unsafe_get = string_unsafe_get
let unsafe_get_byte s i = char_to_byte (unsafe_get s i)
let hash c = Hashtbl.hash c

(* Appending strings *)

let append s0 s1 =
  let l0 = string_length s0 in
  if l0 = 0 then s1 else
  let l1 = string_length s1 in
  if l1 = 0 then s0 else
  let b = Bytes.create (l0 + l1) in
  bytes_unsafe_blit_string s0 0 b 0 l0;
  bytes_unsafe_blit_string s1 0 b l0 l1;
  bytes_unsafe_to_string b

let concat ?(sep = empty) = function
| [] -> empty
| [s] -> s
| s :: ss ->
    let s_len = length s in
    let sep_len = length sep in
    let rec cat_len l = function
    | [] -> l
    | h :: t -> cat_len (l + sep_len + length h) t
    in
    let cat_len = cat_len s_len ss in
    let b = Bytes.create cat_len in
    bytes_unsafe_blit_string s 0 b 0 s_len;
    let rec loop i = function
    | [] -> bytes_unsafe_to_string b
    | str :: ss ->
        let sep_pos = i in
        let str_pos = i + sep_len in
        let str_len = length str in
        bytes_unsafe_blit_string sep 0 b sep_pos sep_len;
        bytes_unsafe_blit_string str 0 b str_pos str_len;
        loop (str_pos + str_len) ss
    in
    loop s_len ss

(* Predicates *)

let is_empty s = length s = 0

let is_prefix ~affix s =
  let len_a = length affix in
  let len_s = length s in
  if len_a > len_s then false else
  let max_idx_a = len_a - 1 in
  let rec loop i =
    if i > max_idx_a then true else
    if unsafe_get affix i <> unsafe_get s i then false else loop (i + 1)
  in
  loop 0

let is_infix ~affix s =
  let len_a = length affix in
  let len_s = length s in
  if len_a > len_s then false else
  let max_idx_a = len_a - 1 in
  let max_idx_s = len_s - len_a in
  let rec loop i k =
    if i > max_idx_s then false else
    if k > max_idx_a then true else
    if k > 0 then
      if unsafe_get affix k = unsafe_get s (i + k) then loop i (k + 1) else
      loop (i + 1) 0
    else if unsafe_get affix 0 = unsafe_get s i then loop i 1 else
    loop (i + 1) 0
  in
  loop 0 0

let is_suffix ~affix s =
  let max_idx_a = length affix - 1 in
  let max_idx_s = length s - 1 in
  if max_idx_a > max_idx_s then false else
  let rec loop i =
    if i > max_idx_a then true else
    if unsafe_get affix (max_idx_a - i) <> unsafe_get s (max_idx_s - i)
    then false
    else loop (i + 1)
  in
  loop 0

let for_all sat s = Astring_base.for_all sat s ~start:0 ~stop:(length s)
let exists sat s = Astring_base.exists sat s ~start:0 ~stop:(length s)
let equal = string_equal
let compare s0 s1 = Pervasives.compare s0 s1

(* Finding and keeping bytes *)

let rfind_start ?start s = match start with
| None -> length s
| Some p when p < 0 || p > length s -> invalid_arg (err_start p s)
| Some p -> p

let ffind_start ?start s = match start with
| None -> 0
| Some p when p < 0 || p > length s -> invalid_arg (err_start p s)
| Some p -> p

let find ?(rev = false) ?start sat s =
  if rev then begin
    let start = rfind_start ?start s in
    let rec loop i =
      if i < 0 then None else
      if sat (unsafe_get s i) then Some i else loop (i - 1)
    in
    loop (start - 1)
  end else begin
    let start = ffind_start ?start s in
    let max_idx = length s - 1 in
    let rec loop i =
      if i > max_idx then None else
      if sat (unsafe_get s i) then Some i else loop (i + 1)
    in
    loop start
  end

let find_sub ?(rev = false) ?start ~sub s =
  if rev then begin
    let start = rfind_start ?start s in
    let len_sub = length sub in
    if len_sub > start then None else
    let max_idx_sub = len_sub - 1 in
    let rec loop i k =
      if i < 0 then None else
      if k > max_idx_sub then Some i else
      if k > 0 then
        if unsafe_get sub k = unsafe_get s (i + k) then loop i (k + 1) else
        loop (i - 1) 0
      else if unsafe_get sub 0 = unsafe_get s i then loop i 1 else
      loop (i - 1) 0
    in
    loop (start - len_sub) 0
  end else begin
    let start = ffind_start ?start s in
    let len_sub = length sub in
    let len_s = length s in
    if len_sub > len_s - start then None else
    let max_idx_sub = len_sub - 1 in
    let max_idx_s = len_s - len_sub in
    let rec loop i k =
      if i > max_idx_s then None else
      if k > max_idx_sub then Some i else
      if k > 0 then
        if unsafe_get sub k = unsafe_get s (i + k) then loop i (k + 1) else
        loop (i + 1) 0
      else if unsafe_get sub 0 = unsafe_get s i then loop i 1 else
      loop (i + 1) 0
    in
    loop start 0
  end

let keep sat s =
  let max_idx = length s - 1 in
  let rec with_buf b k i = (* k is the write index in b *)
    if i > max_idx then Bytes.sub_string b 0 k else
    let c = unsafe_get s i in
    if sat c then (bytes_unsafe_set b k c; with_buf b (k + 1) (i + 1)) else
    with_buf b k (i + 1)
  in
  let rec try_no_alloc i =
    if i > max_idx then s else
    if (sat (unsafe_get s i)) then try_no_alloc (i + 1) else
    if i = max_idx then unsafe_string_sub s 0 i else
    let b = Bytes.of_string s in (* copy and overwrite starting from i *)
    with_buf b i (i + 1)
  in
  try_no_alloc 0

let keep_map f s =
  let max_idx = length s - 1 in
  let rec with_buf b k i = (* k is the write index in b *)
    if i > max_idx then
      (if k > max_idx then bytes_unsafe_to_string b else Bytes.sub_string b 0 k)
    else
    match f (unsafe_get s i) with
    | None -> with_buf b k (i + 1)
    | Some c -> bytes_unsafe_set b k c; with_buf b (k + 1) (i + 1)
  in
  let rec try_no_alloc i =
    if i > max_idx then s else
    let c = unsafe_get s i in
    match f c with
    | None ->
        if i = max_idx then unsafe_string_sub s 0 i else
        let b = Bytes.of_string s in
        with_buf b i (i + 1)
    | Some cm when cm <> c ->
        let b = Bytes.of_string s in
        bytes_unsafe_set b i cm;
        with_buf b (i + 1) (i + 1)
    | Some _ ->
        try_no_alloc (i + 1)
  in
  try_no_alloc 0

(* Extracting substrings *)

let make_sub s ~start ~stop =
  let len = stop - start in
  if len = 0 then empty else
  if start = 0 && len = length s then s else
  unsafe_string_sub s start (stop - start)

let with_pos_range ?start ?stop s =
  Astring_base.with_pos_range make_sub ?start ?stop s

let with_pos_len ?start ?len s =
  Astring_base.with_pos_len make_sub ?start ?len s

let with_index_range ?first ?last s =
  Astring_base.with_index_range make_sub ?first ?last s

let slice ?(start = 0) ?stop s =
  let max_pos = length s in
  let clip_pos p = if p < 0 then 0 else if p > max_pos then max_pos else p in
  let start = clip_pos (if start < 0 then max_pos + start else start) in
  let stop = match stop with None -> max_pos | Some stop -> stop in
  let stop = clip_pos (if stop < 0 then max_pos + stop else stop) in
  if start >= stop then empty else
  if start = 0 && stop = max_pos then s else
  unsafe_string_sub s start (stop - start)

let span ?(rev = false) sat s =
  let len = string_length s in
  let max_pos = len - 1 in
  if rev then begin
    let rec loop i =
      if i < 0 then (empty, s) else
      if sat (unsafe_get s i) then loop (i - 1) else
      if i = max_pos then (s, empty) else
      let cut = i + 1 in
      unsafe_string_sub s 0 cut, unsafe_string_sub s cut (len - cut)
    in
    loop max_pos
  end else begin
    let rec loop i =
      if i > max_pos then (s, empty) else
      if sat (unsafe_get s i) then loop (i + 1) else
      if i = 0 then (empty, s) else
      unsafe_string_sub s 0 i, unsafe_string_sub s i (len - i)
    in
    loop 0
  end

let trim ?(drop = Astring_char.Ascii.is_white) s =
  let max_pos = length s in
  if max_pos = 0 then s else
  let max_idx = max_pos - 1 in
  let rec left_pos i =
    if i > max_idx then max_pos else
    if drop (unsafe_get s i) then left_pos (i + 1) else i
  in
  let rec right_pos i =
    if i < 0 then 0 else
    if drop (unsafe_get s i) then right_pos (i - 1) else (i + 1)
  in
  let left = left_pos 0 in
  if left = max_pos then empty else
  let right = right_pos max_idx in
  if left = 0 && right = max_pos then s else
  unsafe_string_sub s left (right - left)

let fcut ~sep s =
  let sep_len = length sep in
  if sep_len = 0 then invalid_arg Astring_base.err_empty_sep else
  let s_len = length s in
  let max_sep_idx = sep_len - 1 in
  let max_s_idx = s_len - sep_len in
  let rec check_sep i k =
    if k > max_sep_idx then
      let r_start = i + sep_len in
      Some (unsafe_string_sub s 0 i,
            unsafe_string_sub s r_start (s_len - r_start))
    else if unsafe_get s (i + k) = unsafe_get sep k
    then check_sep i (k + 1)
    else scan (i + 1)
  and scan i =
    if i > max_s_idx then None else
    if unsafe_get s i = unsafe_get sep 0 then check_sep i 1 else scan (i + 1)
  in
  scan 0

let rcut ~sep s =
  let sep_len = length sep in
  if sep_len = 0 then invalid_arg Astring_base.err_empty_sep else
  let s_len = length s in
  let max_sep_idx = sep_len - 1 in
  let max_s_idx = s_len - 1 in
  let rec check_sep i k =
    if k > max_sep_idx then
      let r_start = i + sep_len in
      Some (unsafe_string_sub s 0 i,
            unsafe_string_sub s r_start (s_len - r_start))
    else if unsafe_get s (i + k) = unsafe_get sep k
    then check_sep i (k + 1)
    else rscan (i - 1)
  and rscan i =
    if i < 0 then None else
    if unsafe_get s i = unsafe_get sep 0 then check_sep i 1 else rscan (i - 1)
  in
  rscan (max_s_idx - max_sep_idx)

let cut ?(rev = false) ~sep s = if rev then rcut ~sep s else fcut ~sep s

let add_sub ~no_empty s ~start ~stop acc =
  if start = stop then (if no_empty then acc else empty :: acc) else
  unsafe_string_sub s start (stop - start) :: acc

let fcuts ~no_empty ~sep s =
  let sep_len = length sep in
  if sep_len = 0 then invalid_arg Astring_base.err_empty_sep else
  let s_len = length s in
  let max_sep_idx = sep_len - 1 in
  let max_s_idx = s_len - sep_len in
  let rec check_sep start i k acc =
    if k > max_sep_idx then
      let new_start = i + sep_len in
      scan new_start new_start (add_sub ~no_empty s ~start ~stop:i acc)
    else if unsafe_get s (i + k) = unsafe_get sep k
    then check_sep start i (k + 1) acc
    else scan start (i + 1) acc
  and scan start i acc =
    if i > max_s_idx then
      if start = 0 then (if no_empty && s_len = 0 then [] else [s]) else
      List.rev (add_sub ~no_empty s ~start ~stop:s_len acc)
    else if unsafe_get s i = unsafe_get sep 0
    then check_sep start i 1 acc
    else scan start (i + 1) acc
  in
  scan 0 0 []

let rcuts ~no_empty ~sep s =
  let sep_len = length sep in
  if sep_len = 0 then invalid_arg Astring_base.err_empty_sep else
  let s_len = length s in
  let max_sep_idx = sep_len - 1 in
  let max_s_idx = s_len - 1 in
  let rec check_sep stop i k acc =
    if k > max_sep_idx then
      let start = i + sep_len in
      rscan i (i - sep_len) (add_sub ~no_empty s ~start ~stop acc)
    else if unsafe_get s (i + k) = unsafe_get sep k
    then check_sep stop i (k + 1) acc
    else rscan stop (i - 1) acc
  and rscan stop i acc =
    if i < 0 then
      if stop = s_len then (if no_empty && s_len = 0 then [] else [s]) else
      add_sub ~no_empty s ~start:0 ~stop:stop acc
    else if unsafe_get s i = unsafe_get sep 0
    then check_sep stop i 1 acc
    else rscan stop (i - 1) acc
  in
  rscan s_len (max_s_idx - max_sep_idx) []

let cuts ?(rev = false) ?(empty = true) ~sep s =
  let no_empty = not empty in
  if rev then rcuts ~no_empty ~sep  s else fcuts ~no_empty ~sep  s

let fields ?(empty = true) ?(is_sep = Astring_char.Ascii.is_white) s =
  let no_empty = not empty in
  let max_pos = length s in
  let rec loop i end_pos acc =
    if i < 0 then begin
      if end_pos = max_pos
      then (if no_empty && max_pos = 0 then [] else [s])
      else add_sub ~no_empty s ~start:0 ~stop:end_pos acc
    end else begin
      if not (is_sep (unsafe_get s i)) then loop (i - 1) end_pos acc else
      loop (i - 1) i (add_sub ~no_empty s ~start:(i + 1) ~stop:end_pos acc)
    end
  in
  loop (max_pos - 1) max_pos []

(* Substrings *)

type sub = Astring_sub.t

module Sub = Astring_sub

let sub = Sub.of_string_with_pos_range
let sub_with_pos_range = Sub.of_string_with_pos_range
let sub_with_pos_len = Sub.of_string_with_pos_len
let sub_with_index_range = Sub.of_string_with_index_range

(* Traversing *)

let iter f s = for i = 0 to length s - 1 do f (unsafe_get s i) done
let iteri f s = for i = 0 to length s - 1 do f i (unsafe_get s i) done

let map f s =
  let max_idx = length s - 1 in
  let rec with_buf b i =
    if i > max_idx then bytes_unsafe_to_string b else
    (bytes_unsafe_set b i (f (unsafe_get s i)); with_buf b (i + 1))
  in
  let rec try_no_alloc i =
    if i > max_idx then s else
    let c = unsafe_get s i in
    match f c with
    | cm when cm <> c ->
        let b = Bytes.of_string s in
        bytes_unsafe_set b i cm;
        with_buf b (i + 1)
    | _ ->
        try_no_alloc (i + 1)
  in
  try_no_alloc 0

let mapi f s =
  let max_idx = length s - 1 in
  let rec with_buf b i =
    if i > max_idx then bytes_unsafe_to_string b else
    (bytes_unsafe_set b i (f i (unsafe_get s i)); with_buf b (i + 1))
  in
  let rec try_no_alloc i =
    if i > max_idx then s else
    let c = unsafe_get s i in
    match f i c with
    | cm when cm <> c ->
        let b = Bytes.of_string s in
        bytes_unsafe_set b i cm;
        with_buf b (i + 1)
    | _ ->
        try_no_alloc (i + 1)
  in
  try_no_alloc 0

let fold_left f acc s =
  Astring_base.fold_left f acc s ~start:0 ~stop:(length s)

let fold_right f s acc =
  Astring_base.fold_right f s acc ~start:0 ~stop:(length s)

(* Strings as US-ASCII code point sequences *)

module Ascii = struct

  let is_valid s =
    let max_idx = length s - 1 in
    let rec loop i =
      if i > max_idx then true else
      if unsafe_get s i > Astring_char.Ascii.max_ascii then false else
      loop (i + 1)
    in
    loop 0

  (* Casing transforms *)

  let caseify is_not_case to_case s =
    let max_idx = length s - 1 in
    let caseify b i =
      for k = i to max_idx do
        bytes_unsafe_set b k (to_case (unsafe_get s k))
      done;
      bytes_unsafe_to_string b
    in
    let rec try_no_alloc i =
      if i > max_idx then s else
      if is_not_case (unsafe_get s i) then caseify (Bytes.of_string s) i else
      try_no_alloc (i + 1)
    in
    try_no_alloc 0

  let uppercase s =
    caseify Astring_char.Ascii.is_lower Astring_char.Ascii.uppercase s

  let lowercase s =
    caseify Astring_char.Ascii.is_upper Astring_char.Ascii.lowercase s

  let caseify_first is_not_case to_case s =
    if length s = 0 then s else
    let c = unsafe_get s 0 in
    if not (is_not_case c) then s else
    let b = Bytes.of_string s in
    bytes_unsafe_set b 0 (to_case c);
    bytes_unsafe_to_string b

  let capitalize s =
    caseify_first Astring_char.Ascii.is_lower Astring_char.Ascii.uppercase s

  let uncapitalize s =
    caseify_first Astring_char.Ascii.is_upper Astring_char.Ascii.lowercase s

  (* Escape *)

  let escape = Astring_escape.escape
  let unescape = Astring_escape.unescape
  let escape_string = Astring_escape.escape_string
  let unescape_string = Astring_escape.unescape_string
end

(* Pretty printing *)

let pp = Format.pp_print_string
let pp_string ppf s =
  Format.pp_print_char ppf '"';
  Format.pp_print_string ppf (Ascii.escape_string s);
  Format.pp_print_char ppf '"';
  ()

(* String sets and maps *)

module Set = struct
  include Set.Make (String)

  let pp ppf ss =
    let pp_elt elt not_first =
      if not_first then Format.fprintf ppf ",@ ";
      Format.fprintf ppf "%a" pp_string elt;
      true
    in
    Format.fprintf ppf "@[<1>{";
    ignore (fold pp_elt ss false);
    Format.fprintf ppf "}@]";
    ()

  let err_empty () = invalid_arg "empty set"
  let err_absent s ss = invalid_arg (strf "%s not in set %a" s pp ss)

  let get_min_elt ss = try min_elt ss with Not_found -> err_empty ()
  let min_elt ss = try Some (min_elt ss) with Not_found -> None

  let get_max_elt ss = try max_elt ss with Not_found -> err_empty ()
  let max_elt ss = try Some (max_elt ss) with Not_found -> None

  let get_any_elt ss = try choose ss with Not_found -> err_empty ()
  let choose ss = try Some (choose ss) with Not_found -> None

  let get s ss = try find s ss with Not_found -> err_absent s ss
  let find s ss = try Some (find s ss) with Not_found -> None

  let of_list = List.fold_left (fun acc s -> add s acc) empty
end

module Map = struct
  include Map.Make (String)

  let err_empty () = invalid_arg "empty map"
  let err_absent s = invalid_arg (strf "%s is not bound in map" s)

  let get_min_binding m = try min_binding m with Not_found -> err_empty ()
  let min_binding m = try Some (min_binding m) with Not_found -> None

  let get_max_binding m = try max_binding m with Not_found -> err_empty ()
  let max_binding m = try Some (max_binding m) with Not_found -> None

  let get_any_binding m = try choose m with Not_found -> err_empty ()
  let choose m = try Some (choose m) with Not_found -> None

  let get k s = try find k s with Not_found -> err_absent k
  let find k m = try Some (find k m) with Not_found -> None

  let dom m = fold (fun k _ acc -> Set.add k acc) m Set.empty

  let of_list bs = List.fold_left (fun m (k,v) -> add k v m) empty bs

  let pp pp_v ppf m =
    let pp_binding k v not_first =
      if not_first then Format.fprintf ppf ",@ ";
      Format.fprintf ppf "@[<1>(%a,@ %a)@]" pp_string k pp_v v;
      true
    in
    Format.fprintf ppf "@[<1>{";
    ignore (fold pp_binding m false);
    Format.fprintf ppf "}@]";
    ()

  let pp_string_map ppf m = pp pp_string ppf m
end

type set = Set.t
type 'a map = 'a Map.t

(* Uniqueness *)

let uniquify ss =
  let add (seen, ss as acc) v =
    if Set.mem v seen then acc else (Set.add v seen, v :: ss)
  in
  List.rev (snd (List.fold_left add (Set.empty, []) ss))

let default_suff = format_of_string "~%d"
let err_can't_unique elt = strf "could not make %s unique in set" elt
let make_unique_in set ?(suff = default_suff) elt =
  if not (Set.mem elt set) then elt else
  let rec loop i =
    if i < 0 (* overflow *) then invalid_arg (err_can't_unique elt) else
    let candidate = (strf ("%s" ^^ suff) elt i) in
    if not (Set.mem candidate set) then candidate else
    loop (i + 1)
  in
  loop 1

(* OCaml base type conversions *)

let of_char = Astring_base.of_char
let to_char = Astring_base.to_char
let of_bool = Astring_base.of_bool
let to_bool = Astring_base.to_bool
let of_int = Astring_base.of_int
let to_int = Astring_base.to_int
let of_nativeint = Astring_base.of_nativeint
let to_nativeint = Astring_base.to_nativeint
let of_int32 = Astring_base.of_int32
let to_int32 = Astring_base.to_int32
let of_int64 = Astring_base.of_int64
let to_int64 = Astring_base.to_int64
let of_float = Astring_base.of_float
let to_float = Astring_base.to_float

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