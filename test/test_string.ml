(*---------------------------------------------------------------------------
   Copyright (c) 2015 Daniel C. Bünzli. All rights reserved.
   Distributed under the BSD3 license, see license at the end of the file.
   %%NAME%% release %%VERSION%%
  ---------------------------------------------------------------------------*)

open Testing
open Astring

let pp_pair ppf (a, b) =
  Format.fprintf ppf "@[<1>(%a,%a)@]" String.pp_string a String.pp_string b

let misc = test "Misc. base functions" @@ fun () ->
  eq_str String.empty  "";
  app_invalid ~pp:pp_str (String.v ~len:(-1)) (fun i -> 'a');
  app_invalid ~pp:pp_str (String.v ~len:(Sys.max_string_length + 1))
    (fun i -> 'a');
  eq_int (String.length "") 0;
  eq_int (String.length "1") 1;
  eq_int (String.length "12") 2;
  eq_char (String.get "12" 0) '1';
  eq_char (String.get "12" 1) '2';
  app_invalid ~pp:pp_char (String.get "12") 3;
  app_invalid ~pp:pp_char (String.get "12") (-1);
  eq_int (String.get_byte "12" 0) 0x31;
  eq_int (String.get_byte "12" 1) 0x32;
  app_invalid ~pp:pp_int (String.get_byte "12") 3;
  app_invalid ~pp:pp_int (String.get_byte "12") (-1);
  eq_str (String.v ~len:3 (fun i -> Char.of_byte (0x30 + i))) "012";
  eq_str (String.v ~len:0 (fun i -> Char.of_byte (0x30 + i))) "";
  ()

(* Appending strings *)

let append = test "String.append" @@ fun () ->
  let no_allocl s s' = eq_bool (s ^ s' == s) true in
  let no_allocr s s' = eq_bool (s ^ s' == s') true in
  no_allocl String.empty String.empty;
  no_allocr String.empty String.empty;
  no_allocl "bla" "";
  no_allocr "" "bli";
  eq_str (String.append "a" "") "a";
  eq_str (String.append "" "a") "a";
  eq_str (String.append "ab" "") "ab";
  eq_str (String.append "" "ab") "ab";
  eq_str (String.append "ab" "cd") "abcd";
  eq_str (String.append "cd" "ab") "cdab";
  ()

let concat = test "String.concat" @@ fun () ->
  let no_alloc ~sep s = eq_bool (String.concat ~sep [s] == s) true in
  no_alloc ~sep:"" "";
  no_alloc ~sep:"-" "";
  no_alloc ~sep:"" "abc";
  no_alloc ~sep:"-" "abc";
  eq_str (String.concat ~sep:"" []) "";
  eq_str (String.concat ~sep:"" [""]) "";
  eq_str (String.concat ~sep:"" ["";""]) "";
  eq_str (String.concat ~sep:"" ["a";"b";]) "ab";
  eq_str (String.concat ~sep:"" ["a";"b";"";"c"]) "abc";
  eq_str (String.concat ~sep:"-" []) "";
  eq_str (String.concat ~sep:"-" [""]) "";
  eq_str (String.concat ~sep:"-" ["a"]) "a";
  eq_str (String.concat ~sep:"-" ["a";""]) "a-";
  eq_str (String.concat ~sep:"-" ["";"a"]) "-a";
  eq_str (String.concat ~sep:"-" ["";"a";""]) "-a-";
  eq_str (String.concat ~sep:"-" ["a";"b";"c"]) "a-b-c";
  eq_str (String.concat ~sep:"--" ["a";"b";"c"]) "a--b--c";
  eq_str (String.concat ~sep:"ab" ["a";"b";"c"]) "aabbabc";
  eq_str (String.concat ["a";"b";""; "c"]) "abc";
  ()

(* Predicates *)

let is_empty = test "String.is_empty" @@ fun () ->
  eq_bool (String.is_empty "") true;
  eq_bool (String.is_empty "heyho") false;
  ()

let is_prefix = test "String.is_prefix" @@ fun () ->
  eq_bool (String.is_prefix ~affix:"" "") true;
  eq_bool (String.is_prefix ~affix:"" "habla") true;
  eq_bool (String.is_prefix ~affix:"ha" "") false;
  eq_bool (String.is_prefix ~affix:"ha" "h") false;
  eq_bool (String.is_prefix ~affix:"ha" "ha") true;
  eq_bool (String.is_prefix ~affix:"ha" "hab") true;
  eq_bool (String.is_prefix ~affix:"ha" "habla") true;
  eq_bool (String.is_prefix ~affix:"ha" "abla") false;
  ()

let is_infix = test "String.is_infix" @@ fun () ->
  eq_bool (String.is_infix ~affix:"" "") true;
  eq_bool (String.is_infix ~affix:"" "habla") true;
  eq_bool (String.is_infix ~affix:"ha" "") false;
  eq_bool (String.is_infix ~affix:"ha" "h") false;
  eq_bool (String.is_infix ~affix:"ha" "ha") true;
  eq_bool (String.is_infix ~affix:"ha" "hab") true;
  eq_bool (String.is_infix ~affix:"ha" "hub") false;
  eq_bool (String.is_infix ~affix:"ha" "hubhab") true;
  eq_bool (String.is_infix ~affix:"ha" "hubh") false;
  eq_bool (String.is_infix ~affix:"ha" "hubha") true;
  eq_bool (String.is_infix ~affix:"ha" "hubhb") false;
  eq_bool (String.is_infix ~affix:"ha" "abla") false;
  eq_bool (String.is_infix ~affix:"ha" "ablah") false;
  ()

let is_suffix = test "String.is_suffix" @@ fun () ->
  eq_bool (String.is_suffix ~affix:"" "") true;
  eq_bool (String.is_suffix ~affix:"" "adsf") true;
  eq_bool (String.is_suffix ~affix:"ha" "") false;
  eq_bool (String.is_suffix ~affix:"ha" "a") false;
  eq_bool (String.is_suffix ~affix:"ha" "h") false;
  eq_bool (String.is_suffix ~affix:"ha" "ah") false;
  eq_bool (String.is_suffix ~affix:"ha" "ha") true;
  eq_bool (String.is_suffix ~affix:"ha" "aha") true;
  eq_bool (String.is_suffix ~affix:"ha" "haha") true;
  eq_bool (String.is_suffix ~affix:"ha" "hahb") false;
  ()

let for_all = test "String.for_all" @@ fun () ->
  eq_bool (String.for_all (fun _ -> false) "") true;
  eq_bool (String.for_all (fun _ -> true) "") true;
  eq_bool (String.for_all (fun c -> Char.to_int c < 0x34) "123") true;
  eq_bool (String.for_all (fun c -> Char.to_int c < 0x34) "412") false;
  eq_bool (String.for_all (fun c -> Char.to_int c < 0x34) "142") false;
  eq_bool (String.for_all (fun c -> Char.to_int c < 0x34) "124") false;
  ()

let exists = test "String.exists" @@ fun () ->
  eq_bool (String.exists (fun _ -> false) "") false;
  eq_bool (String.exists (fun _ -> true) "") false;
  eq_bool (String.exists (fun c -> Char.to_int c < 0x34) "541") true;
  eq_bool (String.exists (fun c -> Char.to_int c < 0x34) "541") true;
  eq_bool (String.exists (fun c -> Char.to_int c < 0x34) "154") true;
  eq_bool (String.exists (fun c -> Char.to_int c < 0x34) "654") false;
  ()

let equal = test "String.equal" @@ fun () ->
  eq_bool (String.equal "" "") true;
  eq_bool (String.equal "" "a") false;
  eq_bool (String.equal "a" "") false;
  eq_bool (String.equal "ab" "ab") true;
  eq_bool (String.equal "cd" "ab") false;
  ()

let compare = test "String.compare" @@ fun () ->
  eq_int (String.compare "" "ab") (-1);
  eq_int (String.compare "" "") (0);
  eq_int (String.compare "ab" "") (1);
  eq_int (String.compare "ab" "abc") (-1);
  ()

(* Finding and keeping bytes *)

let find = test "String.find" @@ fun () ->
  let eq = eq_option ~eq:(=) ~pp:pp_int in
  let app_invalid = app_invalid ~pp:(pp_option pp_int) in
  let a c = c = 'a' in
  app_invalid (String.find ~start:1 a) "";
  app_invalid (String.find ~start:(-1) a) "";
  app_invalid (String.find ~rev:true ~start:1 a) "";
  app_invalid (String.find ~rev:true ~start:2 a) "a";
  app_invalid (String.find ~rev:true ~start:(-1) a) "a";
  eq (String.find ~rev:true a "") None;
  eq (String.find ~rev:false a "") None;
  eq (String.find ~rev:true ~start:0 a "") None;
  eq (String.find ~rev:false ~start:0 a "") None;
  eq (String.find ~rev:false ~start:0 a "ba") (Some 1);
  eq (String.find ~rev:false ~start:1 a "ba") (Some 1);
  eq (String.find ~rev:false ~start:2 a "ba") None;
  eq (String.find ~rev:true ~start:0 a "ba") None;
  eq (String.find ~rev:true ~start:1 a "ba") None;
  eq (String.find ~rev:true ~start:2 a "ba") (Some 1);
  app_invalid (String.find ~rev:true ~start:3 a) "ba";
  eq (String.find ~rev:false a "aba") (Some 0);
  eq (String.find ~rev:false ~start:0 a "aba") (Some 0);
  eq (String.find ~rev:false ~start:1 a "aba") (Some 2);
  eq (String.find ~rev:false ~start:2 a "aba") (Some 2);
  eq (String.find ~rev:false ~start:3 a "aba") None;
  app_invalid (String.find ~rev:false ~start:4 a) "aba";
  eq (String.find ~rev:true a "aba") (Some 2);
  eq (String.find ~rev:true ~start:0 a "aba") None;
  eq (String.find ~rev:true ~start:1 a "aba") (Some 0);
  eq (String.find ~rev:true ~start:2 a "aba") (Some 0);
  eq (String.find ~rev:true ~start:3 a "aba") (Some 2);
  app_invalid (String.find ~rev:true ~start:4 a) "aba";
  eq (String.find ~rev:false a "bab") (Some 1);
  eq (String.find ~rev:false ~start:0 a "bab") (Some 1);
  eq (String.find ~rev:false ~start:1 a "bab") (Some 1);
  eq (String.find ~rev:false ~start:2 a "bab") None;
  eq (String.find ~rev:false ~start:3 a "bab") None;
  app_invalid (String.find ~rev:false ~start:4 a) "bab";
  eq (String.find ~rev:true a "bab") (Some 1);
  eq (String.find ~rev:true ~start:0 a "bab") None;
  eq (String.find ~rev:true ~start:1 a "bab") None;
  eq (String.find ~rev:true ~start:2 a "bab") (Some 1);
  eq (String.find ~rev:true ~start:3 a "bab") (Some 1);
  app_invalid (String.find ~rev:true ~start:4 a) "bab";
  eq (String.find ~rev:false a "baab") (Some 1);
  eq (String.find ~rev:false ~start:0 a "baab") (Some 1);
  eq (String.find ~rev:false ~start:1 a "baab") (Some 1);
  eq (String.find ~rev:false ~start:2 a "baab") (Some 2);
  eq (String.find ~rev:false ~start:3 a "baab") None;
  eq (String.find ~rev:false ~start:4 a "baab") None;
  app_invalid (String.find ~rev:true ~start:5 a) "baab";
  eq (String.find ~rev:true ~start:0 a "baab") None;
  eq (String.find ~rev:true ~start:1 a "baab") None;
  eq (String.find ~rev:true ~start:2 a "baab") (Some 1);
  eq (String.find ~rev:true ~start:3 a "baab") (Some 2);
  eq (String.find ~rev:true ~start:4 a "baab") (Some 2);
  app_invalid (String.find ~rev:true ~start:5 a) "baab";
  ()

let find_sub = test "String.find_sub" @@ fun () ->
  let eq = eq_option ~eq:(=) ~pp:pp_int in
  let app_invalid = app_invalid ~pp:(pp_option pp_int) in
  app_invalid (String.find_sub ~start:1 ~sub:"ab") "";
  app_invalid (String.find_sub ~start:(-1) ~sub:"ab") "";
  app_invalid (String.find_sub ~rev:true ~start:1 ~sub:"ab") "";
  app_invalid (String.find_sub ~rev:true ~start:2 ~sub:"ab") "a";
  app_invalid (String.find_sub ~rev:true ~start:(-1) ~sub:"ab") "a";
  eq (String.find_sub ~rev:true ~sub:"ab" "") None;
  eq (String.find_sub ~rev:false ~sub:"ab" "") None;
  eq (String.find_sub ~rev:true ~start:0 ~sub:"ab" "") None;
  eq (String.find_sub ~rev:false ~start:0 ~sub:"ab" "") None;
  eq (String.find_sub ~rev:false ~start:0 ~sub:"ab" "ab") (Some 0);
  eq (String.find_sub ~rev:false ~start:1 ~sub:"ab" "ab") None;
  eq (String.find_sub ~rev:false ~start:2 ~sub:"ab" "ab") None;
  eq (String.find_sub ~rev:true ~start:0 ~sub:"ab" "ab") None;
  eq (String.find_sub ~rev:true ~start:1 ~sub:"ab" "ab") None;
  eq (String.find_sub ~rev:true ~start:2 ~sub:"ab" "ab") (Some 0);
  app_invalid (String.find_sub ~rev:true ~start:3 ~sub:"ab") "ab";
  eq (String.find_sub ~rev:false ~sub:"ab" "aba") (Some 0);
  eq (String.find_sub ~rev:false ~start:0 ~sub:"ab" "aba") (Some 0);
  eq (String.find_sub ~rev:false ~start:1 ~sub:"ab" "aba") None;
  eq (String.find_sub ~rev:false ~start:2 ~sub:"ab" "aba") None;
  eq (String.find_sub ~rev:false ~start:3 ~sub:"ab" "aba") None;
  app_invalid (String.find_sub ~rev:false ~start:4 ~sub:"ab") "aba";
  eq (String.find_sub ~rev:true ~sub:"ab" "aba") (Some 0);
  eq (String.find_sub ~rev:true ~start:0 ~sub:"ab" "aba") None;
  eq (String.find_sub ~rev:true ~start:1 ~sub:"ab" "aba") None;
  eq (String.find_sub ~rev:true ~start:2 ~sub:"ab" "aba") (Some 0);
  eq (String.find_sub ~rev:true ~start:3 ~sub:"ab" "aba") (Some 0);
  app_invalid (String.find_sub ~rev:true ~start:4 ~sub:"ab") "aba";
  eq (String.find_sub ~rev:false ~sub:"ab" "bab") (Some 1);
  eq (String.find_sub ~rev:false ~start:0 ~sub:"ab" "bab") (Some 1);
  eq (String.find_sub ~rev:false ~start:1 ~sub:"ab" "bab") (Some 1);
  eq (String.find_sub ~rev:false ~start:2 ~sub:"ab" "bab") None;
  eq (String.find_sub ~rev:false ~start:3 ~sub:"ab" "bab") None;
  app_invalid (String.find_sub ~rev:false ~start:4 ~sub:"ab") "bab";
  eq (String.find_sub ~rev:true ~sub:"ab" "bab") (Some 1);
  eq (String.find_sub ~rev:true ~start:0 ~sub:"ab" "bab") None;
  eq (String.find_sub ~rev:true ~start:1 ~sub:"ab" "bab") None;
  eq (String.find_sub ~rev:true ~start:2 ~sub:"ab" "bab") None;
  eq (String.find_sub ~rev:true ~start:3 ~sub:"ab" "bab") (Some 1);
  app_invalid (String.find_sub ~rev:true ~start:4 ~sub:"ab") "bab";
  eq (String.find_sub ~rev:false ~sub:"ab" "abab") (Some 0);
  eq (String.find_sub ~rev:false ~start:0 ~sub:"ab" "abab") (Some 0);
  eq (String.find_sub ~rev:false ~start:1 ~sub:"ab" "abab") (Some 2);
  eq (String.find_sub ~rev:false ~start:2 ~sub:"ab" "abab") (Some 2);
  eq (String.find_sub ~rev:false ~start:3 ~sub:"ab" "abab") None;
  eq (String.find_sub ~rev:false ~start:4 ~sub:"ab" "abab") None;
  app_invalid (String.find_sub ~rev:true ~start:5 ~sub:"ab") "abab";
  eq (String.find_sub ~rev:true ~start:0 ~sub:"ab" "abab") None;
  eq (String.find_sub ~rev:true ~start:1 ~sub:"ab" "abab") None;
  eq (String.find_sub ~rev:true ~start:2 ~sub:"ab" "abab") (Some 0);
  eq (String.find_sub ~rev:true ~start:3 ~sub:"ab" "abab") (Some 0);
  eq (String.find_sub ~rev:true ~start:4 ~sub:"ab" "abab") (Some 2);
  app_invalid (String.find_sub ~rev:true ~start:5 ~sub:"ab") "abab";
  ()

let keep = test "String.keep[_map]" @@ fun () ->
  let no_alloc k f s = eq_bool (k f s == s) true in
  no_alloc String.keep (fun _ -> true) "";
  no_alloc String.keep (fun _ -> true) "abcd";
  no_alloc String.keep_map (fun c -> Some c) "";
  no_alloc String.keep_map (fun c -> Some c) "abcd";
  let gen_keep :
    'a. ('a -> string -> string) -> 'a -> unit =
  fun keep a ->
    no_alloc keep a "";
    no_alloc keep a "a";
    no_alloc keep a "aa";
    no_alloc keep a "aaa";
    eq_str (keep a "ab") "a";
    eq_str (keep a "ba") "a";
    eq_str (keep a "abc") "a";
    eq_str (keep a "bac") "a";
    eq_str (keep a "bca") "a";
    eq_str (keep a "aba") "aa";
    eq_str (keep a "aab") "aa";
    eq_str (keep a "baa") "aa";
    eq_str (keep a "aabc") "aa";
    eq_str (keep a "abac") "aa";
    eq_str (keep a "abca") "aa";
    eq_str (keep a "baca") "aa";
    eq_str (keep a "bcaa") "aa";
  in
  gen_keep String.keep (fun c -> c = 'a');
  gen_keep String.keep_map (fun c -> if c = 'a' then Some c else None);
  let subst_a = function 'a' -> Some 'z' | c -> Some c in
  no_alloc String.keep_map subst_a "";
  no_alloc String.keep_map subst_a "b";
  no_alloc String.keep_map subst_a "bcd";
  eq_str (String.keep_map subst_a "a") "z";
  eq_str (String.keep_map subst_a "aa") "zz";
  eq_str (String.keep_map subst_a "aaa") "zzz";
  eq_str (String.keep_map subst_a "ab") "zb";
  eq_str (String.keep_map subst_a "ba") "bz";
  eq_str (String.keep_map subst_a "abc") "zbc";
  eq_str (String.keep_map subst_a "bac") "bzc";
  eq_str (String.keep_map subst_a "bca") "bcz";
  eq_str (String.keep_map subst_a "aba") "zbz";
  eq_str (String.keep_map subst_a "aab") "zzb";
  eq_str (String.keep_map subst_a "baa") "bzz";
  eq_str (String.keep_map subst_a "aabc") "zzbc";
  eq_str (String.keep_map subst_a "abac") "zbzc";
  eq_str (String.keep_map subst_a "abca") "zbcz";
  eq_str (String.keep_map subst_a "baca") "bzcz";
  eq_str (String.keep_map subst_a "bcaa") "bczz";
  let subst_a_del_b = function 'a' -> Some 'z' | 'b' -> None | c -> Some c in
  no_alloc String.keep_map subst_a_del_b "";
  no_alloc String.keep_map subst_a_del_b "c";
  no_alloc String.keep_map subst_a_del_b "cd";
  eq_str (String.keep_map subst_a_del_b "a") "z";
  eq_str (String.keep_map subst_a_del_b "aa") "zz";
  eq_str (String.keep_map subst_a_del_b "aaa") "zzz";
  eq_str (String.keep_map subst_a_del_b "ab") "z";
  eq_str (String.keep_map subst_a_del_b "ba") "z";
  eq_str (String.keep_map subst_a_del_b "abc") "zc";
  eq_str (String.keep_map subst_a_del_b "bac") "zc";
  eq_str (String.keep_map subst_a_del_b "bca") "cz";
  eq_str (String.keep_map subst_a_del_b "aba") "zz";
  eq_str (String.keep_map subst_a_del_b "aab") "zz";
  eq_str (String.keep_map subst_a_del_b "baa") "zz";
  eq_str (String.keep_map subst_a_del_b "aabc") "zzc";
  eq_str (String.keep_map subst_a_del_b "abac") "zzc";
  eq_str (String.keep_map subst_a_del_b "abca") "zcz";
  eq_str (String.keep_map subst_a_del_b "baca") "zcz";
  eq_str (String.keep_map subst_a_del_b "bcaa") "czz";
  ()

(* Extracting substrings *)

let with_pos_range = test "String.with_pos_range" @@ fun () ->
  let no_alloc ?start ?stop s =
    eq_bool (String.with_pos_range s ?start ?stop == s ||
             String.(equal empty s)) true
  in
  let invalid ?start ?stop s =
    app_invalid ~pp:pp_str (String.with_pos_range ?start ?stop) s
  in
  no_alloc "";
  no_alloc ~start:0 ~stop:0 "";
  invalid "" ~start:1 ~stop:0;
  invalid "" ~start:0 ~stop:1;
  invalid "" ~start:(-1) ~stop:1;
  invalid "" ~start:0 ~stop:(-1);
  no_alloc "a";
  eq_str (String.with_pos_range "a" ~start:0 ~stop:0) "";
  no_alloc "a" ~start:0 ~stop:1;
  eq_str (String.with_pos_range "a" ~start:1 ~stop:1) "";
  invalid "a" ~start:1 ~stop:2;
  invalid "a" ~start:(-1) ~stop:1;
  no_alloc "abc";
  eq_str (String.with_pos_range ~start:1 "abc") "bc";
  eq_str (String.with_pos_range ~start:2 "abc") "c";
  eq_str (String.with_pos_range ~start:3 "abc") "";
  invalid ~start:4 "abc";
  eq_str (String.with_pos_range "abc" ~start:0 ~stop:0) "";
  eq_str (String.with_pos_range "abc" ~start:0 ~stop:1) "a";
  eq_str (String.with_pos_range "abc" ~start:0 ~stop:2) "ab";
  no_alloc  "abc" ~start:0 ~stop:3;
  invalid "abc" ~start:0 ~stop:4;
  eq_str (String.with_pos_range "abc" ~start:1 ~stop:1) "";
  eq_str (String.with_pos_range "abc" ~start:1 ~stop:2) "b";
  eq_str (String.with_pos_range "abc" ~start:1 ~stop:3) "bc";
  invalid "abc" ~start:1 ~stop:0;
  invalid "abc" ~start:1 ~stop:4;
  eq_str (String.with_pos_range "abc" ~start:2 ~stop:2) "";
  eq_str (String.with_pos_range "abc" ~start:2 ~stop:3) "c";
  invalid "abc" ~start:2 ~stop:0;
  invalid "abc" ~start:2 ~stop:1;
  invalid "abc" ~start:2 ~stop:4;
  eq_str (String.with_pos_range "abc" ~start:3 ~stop:3) "";
  invalid "abc" ~start:3 ~stop:0;
  invalid "abc" ~start:3 ~stop:1;
  invalid "abc" ~start:3 ~stop:2;
  invalid "abc" ~start:3 ~stop:4;
  invalid "abc" ~start:(-1) ~stop:0;
  ()

let with_pos_len = test "String.with_pos_len" @@ fun () ->
  let no_alloc ?start ?len s =
    eq_bool (String.with_pos_len s ?start ?len == s ||
             String.(equal empty s)) true
  in
  let invalid ?start ?len s =
    app_invalid ~pp:pp_str (String.with_pos_len ?start ?len) s
  in
  no_alloc "";
  no_alloc "";
  invalid "" ~start:1 ~len:0;
  invalid "" ~start:0 ~len:1;
  invalid "" ~start:(-1) ~len:1;
  invalid "" ~start:0 ~len:(-1);
  no_alloc "a";
  eq_str (String.with_pos_len "a" ~start:0 ~len:0) "";
  no_alloc "a" ~start:0 ~len:1;
  eq_str (String.with_pos_len "a" ~start:1 ~len:0) "";
  invalid "a" ~start:1 ~len:1;
  invalid "a" ~start:(-1) ~len:1;
  no_alloc "abc";
  eq_str (String.with_pos_len ~start:1 "abc") "bc";
  eq_str (String.with_pos_len ~start:2 "abc") "c";
  eq_str (String.with_pos_len ~start:3 "abc") "";
  invalid ~start:4 "abc";
  eq_str (String.with_pos_len "abc" ~start:0 ~len:0) "";
  eq_str (String.with_pos_len "abc" ~start:0 ~len:1) "a";
  eq_str (String.with_pos_len "abc" ~start:0 ~len:2) "ab";
  no_alloc ~start:0 ~len:3 "abc";
  invalid "abc" ~start:0 ~len:4;
  eq_str (String.with_pos_len "abc" ~start:1 ~len:0) "";
  eq_str (String.with_pos_len "abc" ~start:1 ~len:1) "b";
  eq_str (String.with_pos_len "abc" ~start:1 ~len:2) "bc";
  invalid "abc" ~start:1 ~len:3;
  eq_str (String.with_pos_len "abc" ~start:2 ~len:0) "";
  eq_str (String.with_pos_len "abc" ~start:2 ~len:1) "c";
  invalid "abc" ~start:2 ~len:2;
  eq_str (String.with_pos_len "abc" ~start:3 ~len:0) "";
  invalid "abc" ~start:1 ~len:4;
  invalid "abc" ~start:(-1) ~len:1;
  ()

let with_index_range = test "String.with_index_range" @@ fun () ->
  let no_alloc ?first ?last s =
    eq_bool (String.with_index_range s ?first ?last == s) true
  in
  let invalid ?first ?last s =
    app_invalid ~pp:pp_str (String.with_index_range ?first ?last) s
  in
  invalid "";
  invalid "" ~first:0 ~last:0;
  invalid "" ~first:1 ~last:0;
  invalid "" ~first:0 ~last:1;
  invalid "" ~first:(-1) ~last:1;
  invalid "" ~first:0 ~last:(-1);
  no_alloc ~first:0 ~last:0 "a";
  invalid "a" ~first:0 ~last:1;
  invalid "a" ~first:0 ~last:(-1);
  invalid "a" ~first:0 ~last:2;
  invalid "a" ~first:(-1) ~last:0;
  no_alloc "abc";
  no_alloc ~first:0 "abc";
  eq_str (String.with_index_range ~first:1 "abc") "bc";
  eq_str (String.with_index_range ~first:2 "abc") "c";
  invalid ~first:3 "abc";
  invalid ~first:4 "abc";
  eq_str (String.with_index_range "abc" ~first:0 ~last:0) "a";
  eq_str (String.with_index_range "abc" ~first:0 ~last:1) "ab";
  no_alloc "abc" ~first:0 ~last:2;
  invalid "abc" ~first:0 ~last:3;
  eq_str (String.with_index_range "abc" ~first:1 ~last:1) "b";
  eq_str (String.with_index_range "abc" ~first:1 ~last:2) "bc";
  invalid "abc" ~first:1 ~last:0;
  invalid "abc" ~first:1 ~last:3;
  eq_str (String.with_index_range "abc" ~first:2 ~last:2) "c";
  invalid "abc" ~first:2 ~last:0;
  invalid "abc" ~first:2 ~last:1;
  invalid "abc" ~first:2 ~last:3;
  invalid "abc" ~first:3 ~last:0;
  invalid "abc" ~first:3 ~last:1;
  invalid "abc" ~first:3 ~last:2;
  invalid "abc" ~first:3 ~last:3;
  invalid "abc" ~first:(-1) ~last:0;
  ()

let slice = test "String.slice" @@ fun () ->
  let no_alloc ?start ?stop s =
    eq_bool (String.slice ?start ?stop s == s) true
  in
  no_alloc String.empty;
  no_alloc "abcd";
  no_alloc ~start:0 ~stop:4 "abcd";
  no_alloc ~stop:4 "abcd";
  no_alloc ~start:0 "abcd";
  eq_str (String.slice ~start:0 ~stop:0 "") "";
  eq_str (String.slice ~start:(-1) ~stop:0 "") "";
  eq_str (String.slice ~start:0 ~stop:(-1) "") "";
  eq_str (String.slice ~start:1 ~stop:(-1) "") "";
  eq_str (String.slice ~start:(-244) ~stop:(-455) "") "";
  no_alloc "abcd" ~start:0;
  eq_str (String.slice "abcd" ~start:1) "bcd";
  eq_str (String.slice "abcd" ~start:2) "cd";
  eq_str (String.slice "abcd" ~start:3) "d";
  eq_str (String.slice "abcd" ~start:4) "";
  eq_str (String.slice "abcd" ~start:5) "";
  eq_str (String.slice "abcd" ~start:(-1)) "d";
  eq_str (String.slice "abcd" ~start:(-2)) "cd";
  eq_str (String.slice "abcd" ~start:(-3)) "bcd";
  no_alloc "abcd" ~start:(-4);
  no_alloc "abcd"~start:(-5);
  eq_str (String.slice "abcd" ~stop:0) "";
  eq_str (String.slice "abcd" ~stop:1) "a";
  eq_str (String.slice "abcd" ~stop:2) "ab";
  eq_str (String.slice "abcd" ~stop:3) "abc";
  no_alloc "abcd" ~stop:4;
  no_alloc "abcd" ~stop:5;
  eq_str (String.slice "abcd" ~stop:(-1)) "abc";
  eq_str (String.slice "abcd" ~stop:(-2)) "ab";
  eq_str (String.slice "abcd" ~stop:(-3)) "a";
  eq_str (String.slice "abcd" ~stop:(-4)) "";
  eq_str (String.slice "abcd" ~stop:(-5)) "";
  eq_str (String.slice "abcd" ~start:(-1) ~stop:2) "";
  eq_str (String.slice "abcd" ~start:(-1) ~stop:(-1)) "";
  eq_str (String.slice "abcd" ~start:(-2) ~stop:(-1)) "c";
  eq_str (String.slice "abcd" ~start:2 ~stop:3) "c";
  eq_str (String.slice "abcd" ~start:23423 ~stop:2342) "";
  eq_str (String.slice "abcd" ~start:(-3)) "bcd";
  eq_str (String.slice "abc" ~start:(-3)) "abc";
  eq_str (String.slice "ab" ~start:(-3)) "ab";
  eq_str (String.slice "a" ~start:(-3)) "a";
  eq_str (String.slice "" ~start:(-3)) "";
  ()

let trim = test "String.trim" @@ fun () ->
  let drop_a c = c = 'a' in
  let no_alloc ?drop s = eq_bool (String.trim ?drop s == s) true in
  no_alloc "";
  no_alloc ~drop:drop_a "";
  no_alloc "bc";
  no_alloc ~drop:drop_a "bc";
  eq_str (String.trim "\t abcd \r ") "abcd";
  no_alloc ~drop:drop_a "\x00 abcd \x1F ";
  no_alloc "aaaabcdaaaa";
  eq_str (String.trim ~drop:drop_a "aaaabcdaaaa") "bcd";
  eq_str (String.trim ~drop:drop_a "aaaabcd") "bcd";
  eq_str (String.trim ~drop:drop_a "bcdaaaa") "bcd";
  eq_str (String.trim ~drop:drop_a "aaaa") "";
  eq_str (String.trim "     ") "";
  ()

let cut = test "String.cut" @@ fun () ->
  let ppp = pp_option pp_pair in
  let eqo = eq_option ~eq:(=) ~pp:pp_pair in
  app_invalid ~pp:ppp (String.cut ~sep:"") "";
  app_invalid ~pp:ppp (String.cut ~sep:"") "123";
  eqo (String.cut "," "")  None;
  eqo (String.cut "," ",") (Some ("", ""));
  eqo (String.cut "," ",,") (Some ("", ","));
  eqo (String.cut "," ",,,") (Some ("", ",,"));
  eqo (String.cut "," "123") None;
  eqo (String.cut "," ",123") (Some ("", "123"));
  eqo (String.cut "," "123,") (Some ("123", ""));
  eqo (String.cut "," "1,2,3") (Some ("1", "2,3"));
  eqo (String.cut "," " 1,2,3") (Some (" 1", "2,3"));
  eqo (String.cut "<>" "") None;
  eqo (String.cut "<>" "<>") (Some ("", ""));
  eqo (String.cut "<>" "<><>") (Some ("", "<>"));
  eqo (String.cut "<>" "<><><>") (Some ("", "<><>"));
  eqo (String.cut ~rev:true ~sep:"<>" "1") None;
  eqo (String.cut "<>" "123") None;
  eqo (String.cut "<>" "<>123") (Some ("", "123"));
  eqo (String.cut "<>" "123<>") (Some ("123", ""));
  eqo (String.cut "<>" "1<>2<>3") (Some ("1", "2<>3"));
  eqo (String.cut "<>" " 1<>2<>3") (Some (" 1", "2<>3"));
  eqo (String.cut "<>" ">>><>>>><>>>><>>>>") (Some (">>>", ">>><>>>><>>>>"));
  eqo (String.cut "<->" "<->>->") (Some ("", ">->"));
  eqo (String.cut ~rev:true ~sep:"<->" "<-") None;
  eqo (String.cut "aa" "aa") (Some ("", ""));
  eqo (String.cut "aa" "aaa") (Some ("", "a"));
  eqo (String.cut "aa" "aaaa") (Some ("", "aa"));
  eqo (String.cut "aa" "aaaaa") (Some ("", "aaa";));
  eqo (String.cut "aa" "aaaaaa") (Some ("", "aaaa"));
  eqo (String.cut ~sep:"ab" "faaaa") None;
  let rev = true in
  app_invalid ~pp:ppp (String.cut ~rev ~sep:"") "";
  app_invalid ~pp:ppp (String.cut ~rev ~sep:"") "123";
  eqo (String.cut ~rev ~sep:"," "") None;
  eqo (String.cut ~rev ~sep:"," ",") (Some ("", ""));
  eqo (String.cut ~rev ~sep:"," ",,") (Some (",", ""));
  eqo (String.cut ~rev ~sep:"," ",,,") (Some (",,", ""));
  eqo (String.cut ~rev ~sep:"," "123") None;
  eqo (String.cut ~rev ~sep:"," ",123") (Some ("", "123"));
  eqo (String.cut ~rev ~sep:"," "123,") (Some ("123", ""));
  eqo (String.cut ~rev ~sep:"," "1,2,3") (Some ("1,2", "3"));
  eqo (String.cut ~rev ~sep:"," "1,2,3 ") (Some ("1,2", "3 "));
  eqo (String.cut ~rev ~sep:"<>" "") None;
  eqo (String.cut ~rev ~sep:"<>" "<>") (Some ("", ""));
  eqo (String.cut ~rev ~sep:"<>" "<><>") (Some ("<>", ""));
  eqo (String.cut ~rev ~sep:"<>" "<><><>") (Some ("<><>", ""));
  eqo (String.cut ~rev ~sep:"<>" "1") None;
  eqo (String.cut ~rev ~sep:"<>" "123") None;
  eqo (String.cut ~rev ~sep:"<>" "<>123") (Some ("", "123"));
  eqo (String.cut ~rev ~sep:"<>" "123<>") (Some ("123", ""));
  eqo (String.cut ~rev ~sep:"<>" "1<>2<>3") (Some ("1<>2", "3"));
  eqo (String.cut ~rev ~sep:"<>" "1<>2<>3 ") (Some ("1<>2", "3 "));
  eqo (String.cut ~rev ~sep:"<>" ">>><>>>><>>>><>>>>")
    (Some (">>><>>>><>>>>", ">>>"));
  eqo (String.cut ~rev ~sep:"<->" "<->>->") (Some ("", ">->"));
  eqo (String.cut ~rev ~sep:"<->" "<-") None;
  eqo (String.cut ~rev ~sep:"aa" "aa") (Some ("", ""));
  eqo (String.cut ~rev ~sep:"aa" "aaa") (Some ("a", ""));
  eqo (String.cut ~rev ~sep:"aa" "aaaa") (Some ("aa", ""));
  eqo (String.cut ~rev ~sep:"aa" "aaaaa") (Some ("aaa", "";));
  eqo (String.cut ~rev ~sep:"aa" "aaaaaa") (Some ("aaaa", ""));
  eqo (String.cut ~rev ~sep:"ab" "afaaaa") None;
  ()

let cuts = test "String.cuts" @@ fun () ->
  let ppl = pp_list String.pp_string in
  let eql = eq_list ~eq:String.equal ~pp:String.pp_string in
  let no_alloc ?rev ~sep s =
    eq_bool (List.hd (String.cuts ?rev ~sep s) == s) true
  in
  app_invalid ~pp:ppl (String.cuts ~sep:"") "";
  app_invalid ~pp:ppl (String.cuts ~sep:"") "123";
  no_alloc ~sep:"," "";
  no_alloc ~sep:"," "abcd";
  eql (String.cuts ~empty:true  ~sep:"," "") [""];
  eql (String.cuts ~empty:false ~sep:"," "") [];
  eql (String.cuts ~empty:true  ~sep:"," ",") [""; ""];
  eql (String.cuts ~empty:false ~sep:"," ",") [];
  eql (String.cuts ~empty:true  ~sep:"," ",,") [""; ""; ""];
  eql (String.cuts ~empty:false ~sep:"," ",,") [];
  eql (String.cuts ~empty:true  ~sep:"," ",,,") [""; ""; ""; ""];
  eql (String.cuts ~empty:false ~sep:"," ",,,") [];
  eql (String.cuts ~empty:true  ~sep:"," "123") ["123"];
  eql (String.cuts ~empty:false ~sep:"," "123") ["123"];
  eql (String.cuts ~empty:true  ~sep:"," ",123") [""; "123"];
  eql (String.cuts ~empty:false ~sep:"," ",123") ["123"];
  eql (String.cuts ~empty:true  ~sep:"," "123,") ["123"; ""];
  eql (String.cuts ~empty:false ~sep:"," "123,") ["123";];
  eql (String.cuts ~empty:true  ~sep:"," "1,2,3") ["1"; "2"; "3"];
  eql (String.cuts ~empty:false ~sep:"," "1,2,3") ["1"; "2"; "3"];
  eql (String.cuts ~empty:true  ~sep:"," "1, 2, 3") ["1"; " 2"; " 3"];
  eql (String.cuts ~empty:false  ~sep:"," "1, 2, 3") ["1"; " 2"; " 3"];
  eql (String.cuts ~empty:true ~sep:"," ",1,2,,3,") [""; "1"; "2"; ""; "3"; ""];
  eql (String.cuts ~empty:false ~sep:"," ",1,2,,3,") ["1"; "2"; "3";];
  eql (String.cuts ~empty:true ~sep:"," ", 1, 2,, 3,")
    [""; " 1"; " 2"; ""; " 3"; ""];
  eql (String.cuts ~empty:false ~sep:"," ", 1, 2,, 3,") [" 1"; " 2";" 3";];
  eql (String.cuts ~empty:true ~sep:"<>" "") [""];
  eql (String.cuts ~empty:false ~sep:"<>" "") [];
  eql (String.cuts ~empty:true ~sep:"<>" "<>") [""; ""];
  eql (String.cuts ~empty:false ~sep:"<>" "<>") [];
  eql (String.cuts ~empty:true ~sep:"<>" "<><>") [""; ""; ""];
  eql (String.cuts ~empty:false ~sep:"<>" "<><>") [];
  eql (String.cuts ~empty:true ~sep:"<>" "<><><>") [""; ""; ""; ""];
  eql (String.cuts ~empty:false ~sep:"<>" "<><><>") [];
  eql (String.cuts ~empty:true ~sep:"<>" "123") [ "123" ];
  eql (String.cuts ~empty:false ~sep:"<>" "123") [ "123" ];
  eql (String.cuts ~empty:true ~sep:"<>" "<>123") [""; "123"];
  eql (String.cuts ~empty:false ~sep:"<>" "<>123") ["123"];
  eql (String.cuts ~empty:true ~sep:"<>" "123<>") ["123"; ""];
  eql (String.cuts ~empty:false ~sep:"<>" "123<>") ["123"];
  eql (String.cuts ~empty:true ~sep:"<>" "1<>2<>3") ["1"; "2"; "3"];
  eql (String.cuts ~empty:false ~sep:"<>" "1<>2<>3") ["1"; "2"; "3"];
  eql (String.cuts ~empty:true ~sep:"<>" "1<> 2<> 3") ["1"; " 2"; " 3"];
  eql (String.cuts ~empty:false ~sep:"<>" "1<> 2<> 3") ["1"; " 2"; " 3"];
  eql (String.cuts ~empty:true ~sep:"<>" "<>1<>2<><>3<>")
    [""; "1"; "2"; ""; "3"; ""];
  eql (String.cuts ~empty:false ~sep:"<>" "<>1<>2<><>3<>") ["1"; "2";"3";];
  eql (String.cuts ~empty:true ~sep:"<>" "<> 1<> 2<><> 3<>")
    [""; " 1"; " 2"; ""; " 3";""];
  eql (String.cuts ~empty:false ~sep:"<>" "<> 1<> 2<><> 3<>")[" 1"; " 2"; " 3"];
  eql (String.cuts ~empty:true ~sep:"<>" ">>><>>>><>>>><>>>>")
    [">>>"; ">>>"; ">>>"; ">>>" ];
  eql (String.cuts ~empty:false ~sep:"<>" ">>><>>>><>>>><>>>>")
    [">>>"; ">>>"; ">>>"; ">>>" ];
  eql (String.cuts ~empty:true ~sep:"<->" "<->>->") [""; ">->"];
  eql (String.cuts ~empty:false ~sep:"<->" "<->>->") [">->"];
  eql (String.cuts ~empty:true ~sep:"aa" "aa") [""; ""];
  eql (String.cuts ~empty:false ~sep:"aa" "aa") [];
  eql (String.cuts ~empty:true ~sep:"aa" "aaa") [""; "a"];
  eql (String.cuts ~empty:false ~sep:"aa" "aaa") ["a"];
  eql (String.cuts ~empty:true ~sep:"aa" "aaaa") [""; ""; ""];
  eql (String.cuts ~empty:false ~sep:"aa" "aaaa") [];
  eql (String.cuts ~empty:true ~sep:"aa" "aaaaa") [""; ""; "a"];
  eql (String.cuts ~empty:false ~sep:"aa" "aaaaa") ["a"];
  eql (String.cuts ~empty:true ~sep:"aa" "aaaaaa") [""; ""; ""; ""];
  eql (String.cuts ~empty:false ~sep:"aa" "aaaaaa") [];
  let rev = true in
  app_invalid ~pp:ppl (String.cuts ~rev ~sep:"") "";
  app_invalid ~pp:ppl (String.cuts ~rev ~sep:"") "123";
  no_alloc ~rev ~sep:"," "";
  no_alloc ~rev ~sep:"," "abcd";
  eql (String.cuts ~rev ~empty:true ~sep:"," "") [""];
  eql (String.cuts ~rev ~empty:false ~sep:"," "") [];
  eql (String.cuts ~rev ~empty:true ~sep:"," ",") [""; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"," ",") [];
  eql (String.cuts ~rev ~empty:true ~sep:"," ",,") [""; ""; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"," ",,") [];
  eql (String.cuts ~rev ~empty:true ~sep:"," ",,,") [""; ""; ""; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"," ",,,") [];
  eql (String.cuts ~rev ~empty:true ~sep:"," "123") ["123"];
  eql (String.cuts ~rev ~empty:false ~sep:"," "123") ["123"];
  eql (String.cuts ~rev ~empty:true ~sep:"," ",123") [""; "123"];
  eql (String.cuts ~rev ~empty:false ~sep:"," ",123") ["123"];
  eql (String.cuts ~rev ~empty:true ~sep:"," "123,") ["123"; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"," "123,") ["123";];
  eql (String.cuts ~rev ~empty:true ~sep:"," "1,2,3") ["1"; "2"; "3"];
  eql (String.cuts ~rev ~empty:false ~sep:"," "1,2,3") ["1"; "2"; "3"];
  eql (String.cuts ~rev ~empty:true ~sep:"," "1, 2, 3") ["1"; " 2"; " 3"];
  eql (String.cuts ~rev ~empty:false ~sep:"," "1, 2, 3") ["1"; " 2"; " 3"];
  eql (String.cuts ~rev ~empty:true ~sep:"," ",1,2,,3,")
    [""; "1"; "2"; ""; "3"; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"," ",1,2,,3,") ["1"; "2"; "3"];
  eql (String.cuts ~rev ~empty:true ~sep:"," ", 1, 2,, 3,")
    [""; " 1"; " 2"; ""; " 3"; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"," ", 1, 2,, 3,") [" 1"; " 2"; " 3"];
  eql (String.cuts ~rev ~empty:true ~sep:"<>" "") [""];
  eql (String.cuts ~rev ~empty:false ~sep:"<>" "") [];
  eql (String.cuts ~rev ~empty:true ~sep:"<>" "<>") [""; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"<>" "<>") [];
  eql (String.cuts ~rev ~empty:true ~sep:"<>" "<><>") [""; ""; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"<>" "<><>") [];
  eql (String.cuts ~rev ~empty:true ~sep:"<>" "<><><>") [""; ""; ""; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"<>" "<><><>") [];
  eql (String.cuts ~rev ~empty:true ~sep:"<>" "123") [ "123" ];
  eql (String.cuts ~rev ~empty:false ~sep:"<>" "123") [ "123" ];
  eql (String.cuts ~rev ~empty:true ~sep:"<>" "<>123") [""; "123"];
  eql (String.cuts ~rev ~empty:false ~sep:"<>" "<>123") ["123"];
  eql (String.cuts ~rev ~empty:true ~sep:"<>" "123<>") ["123"; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"<>" "123<>") ["123";];
  eql (String.cuts ~rev ~empty:true ~sep:"<>" "1<>2<>3") ["1"; "2"; "3"];
  eql (String.cuts ~rev ~empty:false ~sep:"<>" "1<>2<>3") ["1"; "2"; "3"];
  eql (String.cuts ~rev ~empty:true ~sep:"<>" "1<> 2<> 3") ["1"; " 2"; " 3"];
  eql (String.cuts ~rev ~empty:false ~sep:"<>" "1<> 2<> 3") ["1"; " 2"; " 3"];
  eql (String.cuts ~rev ~empty:true ~sep:"<>" "<>1<>2<><>3<>")
    [""; "1"; "2"; ""; "3"; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"<>" "<>1<>2<><>3<>")
    ["1"; "2"; "3"];
  eql (String.cuts ~rev ~empty:true ~sep:"<>" "<> 1<> 2<><> 3<>")
                                  [""; " 1"; " 2"; ""; " 3";""];
  eql (String.cuts ~rev ~empty:false ~sep:"<>" "<> 1<> 2<><> 3<>")
                                  [" 1"; " 2"; " 3";];
  eql (String.cuts ~rev ~empty:true ~sep:"<>" ">>><>>>><>>>><>>>>")
                                  [">>>"; ">>>"; ">>>"; ">>>" ];
  eql (String.cuts ~rev ~empty:false ~sep:"<>" ">>><>>>><>>>><>>>>")
                                  [">>>"; ">>>"; ">>>"; ">>>" ];
  eql (String.cuts ~rev ~empty:true ~sep:"<->" "<->>->") [""; ">->"];
  eql (String.cuts ~rev ~empty:false ~sep:"<->" "<->>->") [">->"];
  eql (String.cuts ~rev ~empty:true ~sep:"aa" "aa") [""; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"aa" "aa") [];
  eql (String.cuts ~rev ~empty:true ~sep:"aa" "aaa") ["a"; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"aa" "aaa") ["a"];
  eql (String.cuts ~rev ~empty:true ~sep:"aa" "aaaa") [""; ""; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"aa" "aaaa") [];
  eql (String.cuts ~rev ~empty:true ~sep:"aa" "aaaaa") ["a"; ""; "";];
  eql (String.cuts ~rev ~empty:false ~sep:"aa" "aaaaa") ["a";];
  eql (String.cuts ~rev ~empty:true ~sep:"aa" "aaaaaa") [""; ""; ""; ""];
  eql (String.cuts ~rev ~empty:false ~sep:"aa" "aaaaaa") [];
  ()

let fields = test "String.fields" @@ fun () ->
  let eql = eq_list ~eq:String.equal ~pp:String.pp_string in
  let no_alloc ?empty ?is_sep s =
    eq_bool (List.hd (String.fields ?empty ?is_sep s) == s) true
  in
  let is_a c = c = 'a' in
  no_alloc ~empty:true "a";
  no_alloc ~empty:false "a";
  no_alloc ~empty:true "abc";
  no_alloc ~empty:false "abc";
  no_alloc ~empty:true ~is_sep:is_a "bcdf";
  no_alloc ~empty:false ~is_sep:is_a "bcdf";
  eql (String.fields ~empty:true "") [""];
  eql (String.fields ~empty:false "") [];
  eql (String.fields ~empty:true "\n\r") ["";"";""];
  eql (String.fields ~empty:false "\n\r") [];
  eql (String.fields ~empty:true " \n\rabc") ["";"";"";"abc"];
  eql (String.fields ~empty:false " \n\rabc") ["abc"];
  eql (String.fields ~empty:true " \n\racd de") ["";"";"";"acd";"de"];
  eql (String.fields ~empty:false " \n\racd de") ["acd";"de"];
  eql (String.fields ~empty:true " \n\racd de ") ["";"";"";"acd";"de";""];
  eql (String.fields ~empty:false " \n\racd de ") ["acd";"de"];
  eql (String.fields ~empty:true "\n\racd\nde \r") ["";"";"acd";"de";"";""];
  eql (String.fields ~empty:false "\n\racd\nde \r") ["acd";"de"];
  eql (String.fields ~empty:true ~is_sep:is_a "") [""];
  eql (String.fields ~empty:false ~is_sep:is_a "") [];
  eql (String.fields ~empty:true ~is_sep:is_a "abaac aaa")
    ["";"b";"";"c ";"";"";""];
  eql (String.fields ~empty:false ~is_sep:is_a "abaac aaa") ["b"; "c "];
  eql (String.fields ~empty:true ~is_sep:is_a "aaaa") ["";"";"";"";""];
  eql (String.fields ~empty:false ~is_sep:is_a "aaaa") [];
  eql (String.fields ~empty:true ~is_sep:is_a "aaaa ") ["";"";"";"";" "];
  eql (String.fields ~empty:false ~is_sep:is_a "aaaa ") [" "];
  eql (String.fields ~empty:true ~is_sep:is_a "aaaab") ["";"";"";"";"b"];
  eql (String.fields ~empty:false ~is_sep:is_a "aaaab") ["b"];
  eql (String.fields ~empty:true ~is_sep:is_a "baaaa") ["b";"";"";"";""];
  eql (String.fields ~empty:false ~is_sep:is_a "baaaa") ["b"];
  eql (String.fields ~empty:true ~is_sep:is_a "abaaaa") ["";"b";"";"";"";""];
  eql (String.fields ~empty:false ~is_sep:is_a "abaaaa") ["b"];
  eql (String.fields ~empty:true ~is_sep:is_a "aba") ["";"b";""];
  eql (String.fields ~empty:false ~is_sep:is_a "aba") ["b"];
  eql (String.fields ~empty:false "tokenize me please")
    ["tokenize"; "me"; "please"];
  ()

(* Traversing strings *)

let iter = test "String.iter[i]" @@ fun () ->
  let s = "abcd" in
  String.iter (fun _ -> fail "invoked") "";
  String.iteri (fun _ _ -> fail "invoked") "";
  (let i = ref 0 in String.iter (fun c -> eq_char s.[!i] c; incr i) s);
  String.iteri (fun i c -> eq_char s.[i] c) s;
  ()

let map = test "String.map[i]" @@ fun () ->
  let next_letter c = Char.(of_byte @@ to_int c + 1) in
  let no_alloc map f s = eq_bool (map f s == s) true in
  no_alloc String.map (fun c -> c) String.empty;
  no_alloc String.map (fun c -> c) "abcd";
  eq_str (String.map (fun c -> fail "invoked"; c) "") "";
  eq_str (String.map next_letter "abcd") "bcde";
  no_alloc String.mapi (fun _ c -> c) String.empty;
  no_alloc String.mapi (fun _ c -> c) "abcd";
  eq_str (String.mapi (fun _ c -> fail "invoked"; c) "") "";
  eq_str (String.mapi (fun i c -> Char.(of_byte @@ to_int c + i)) "abcd")
    "aceg";
  ()

let fold = test "String.fold_{left,right}" @@ fun () ->
  let eql = eq_list ~eq:(=) ~pp:pp_char in
  String.fold_left (fun _ _ -> fail "invoked") () "";
  eql (String.fold_left (fun acc c -> c :: acc) [] "") [];
  eql (String.fold_left (fun acc c -> c :: acc) [] "abc") ['c';'b';'a'];
  String.fold_right (fun _ _ -> fail "invoked") "" ();
  eql (String.fold_right (fun c acc -> c :: acc) "" []) [];
  eql (String.fold_right (fun c acc -> c :: acc) "abc" []) ['a';'b';'c'];
  ()

(* Ascii support *)

let ascii_is_valid = test "String.Ascii.is_valid" @@ fun () ->
  eq_bool (String.Ascii.is_valid "") true;
  eq_bool (String.Ascii.is_valid "a") true;
  eq_bool (String.(Ascii.is_valid (v ~len:(0x7F + 1)
                                     (fun i -> Char.of_byte i)))) true;
  ()

let ascii_casing =
  test "String.Ascii.{uppercase,lowercase,capitalize,uncapitalize}"
  @@ fun () ->
  let no_alloc f s = eq_bool (f s == s) true in
  no_alloc String.Ascii.uppercase "";
  no_alloc String.Ascii.uppercase "HEHEY \x7F\xFF\x00\x0A";
  eq_str (String.Ascii.uppercase "HeHey \x7F\xFF\x00\x0A")
    "HEHEY \x7F\xFF\x00\x0A";
  eq_str (String.Ascii.uppercase "abcdefghijklmnopqrstuvwxyz")
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  no_alloc String.Ascii.lowercase "";
  no_alloc String.Ascii.lowercase "hehey \x7F\xFF\x00\x0A";
  eq_str (String.Ascii.lowercase "hEhEY \x7F\xFF\x00\x0A")
    "hehey \x7F\xFF\x00\x0A";
  eq_str (String.Ascii.lowercase "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    "abcdefghijklmnopqrstuvwxyz";
  no_alloc String.Ascii.capitalize "";
  no_alloc String.Ascii.capitalize "Hehey";
  no_alloc String.Ascii.capitalize "\x00hehey";
  eq_str (String.Ascii.capitalize "hehey") "Hehey";
  no_alloc String.Ascii.uncapitalize "";
  no_alloc String.Ascii.uncapitalize "hehey";
  no_alloc String.Ascii.uncapitalize "\x00hehey";
  eq_str (String.Ascii.uncapitalize "Hehey") "hehey";
  ()

let ascii_escapes = test "String.Ascii.escape[_string]" @@ fun () ->
  let no_alloc s = eq_bool ((String.Ascii.escape s) == s) true in
  no_alloc "";
  no_alloc "abcd";
  no_alloc "~";
  no_alloc " ";
  eq_str (String.Ascii.escape "\x00abc") "\\x00abc";
  eq_str (String.Ascii.escape "\nabc") "\\x0Aabc";
  eq_str (String.Ascii.escape "\nab\xFFc") "\\x0Aab\\xFFc";
  eq_str (String.Ascii.escape "\nab\xFF") "\\x0Aab\\xFF";
  eq_str (String.Ascii.escape "\nab\\") "\\x0Aab\\\\";
  eq_str (String.Ascii.escape "\\") "\\\\";
  eq_str (String.Ascii.escape "\\\x00\x1F\x7F\xFF") "\\\\\\x00\\x1F\\x7F\\xFF";
  let no_alloc s =
    eq_bool ((String.Ascii.escape_string s) == s) true
  in
  no_alloc "";
  no_alloc "abcd";
  no_alloc "~";
  no_alloc " ";
  eq_str (String.Ascii.escape_string "\x00abc") "\\x00abc";
  eq_str (String.Ascii.escape_string "\nabc") "\\nabc";
  eq_str (String.Ascii.escape_string "\nab\xFFc") "\\nab\\xFFc";
  eq_str (String.Ascii.escape_string "\nab\xFF") "\\nab\\xFF";
  eq_str (String.Ascii.escape_string "\nab\\") "\\nab\\\\";
  eq_str (String.Ascii.escape_string "\\") "\\\\";
  eq_str (String.Ascii.escape_string "\b\t\n\r\"\\\x00\x1F\x7F\xFF")
    "\\b\\t\\n\\r\\\"\\\\\\x00\\x1F\\x7F\\xFF";
  ()

let ascii_unescapes = test "String.Ascii.unescape[_string]" @@ fun () ->
  let no_alloc unescape s = match unescape s with
  | None -> fail "expected (Some %S)" s
  | Some s' -> eq_bool (s == s') true
  in
  let eq_o = eq_option ~eq:String.equal ~pp:pp_str in
  no_alloc String.Ascii.unescape "";
  no_alloc String.Ascii.unescape "abcd";
  no_alloc String.Ascii.unescape "~";
  no_alloc String.Ascii.unescape " ";
  eq_o (String.Ascii.unescape "\\x00abc") (Some "\x00abc");
  eq_o (String.Ascii.unescape "\\x0Aabc") (Some "\nabc");
  eq_o (String.Ascii.unescape "\\x0Aab\\xFFc") (Some "\nab\xFFc");
  eq_o (String.Ascii.unescape "\\x0Aab\\xFF") (Some "\nab\xFF");
  eq_o (String.Ascii.unescape "\\x0Aab\\\\") (Some "\nab\\");
  eq_o (String.Ascii.unescape "a\\\\") (Some "a\\");
  eq_o (String.Ascii.unescape "\\\\") (Some "\\");
  eq_o (String.Ascii.unescape "a\\\\\\x00\\x1F\\x7F\\xFF")
    (Some "a\\\x00\x1F\x7F\xFF");
  eq_o (String.Ascii.unescape "\\x61") (Some "a");
  eq_o (String.Ascii.unescape "\\x20") (Some " ");
  eq_o (String.Ascii.unescape "\\x2") None;
  eq_o (String.Ascii.unescape "\\x") None;
  eq_o (String.Ascii.unescape "\\") None;
  eq_o (String.Ascii.unescape "a\\b") None;
  eq_o (String.Ascii.unescape "a\\t") None;
  eq_o (String.Ascii.unescape "b\\n") None;
  eq_o (String.Ascii.unescape "b\\r") None;
  eq_o (String.Ascii.unescape "b\\\"") None;
  eq_o (String.Ascii.unescape "b\\z") None;
  eq_o (String.Ascii.unescape "b\\1") None;
  no_alloc String.Ascii.unescape_string "";
  no_alloc String.Ascii.unescape_string "abcd";
  no_alloc String.Ascii.unescape_string "~";
  no_alloc String.Ascii.unescape_string " ";
  eq_o (String.Ascii.unescape_string "\\x00abc") (Some "\x00abc");
  eq_o (String.Ascii.unescape_string "\\nabc") (Some "\nabc");
  eq_o (String.Ascii.unescape_string "\\nab\\xFFc") (Some "\nab\xFFc");
  eq_o (String.Ascii.unescape_string "\\nab\\xFF") (Some "\nab\xFF");
  eq_o (String.Ascii.unescape_string "\\nab\\\\") (Some "\nab\\");
  eq_o (String.Ascii.unescape_string "a\\\\") (Some "a\\");
  eq_o (String.Ascii.unescape_string "\\\\") (Some "\\");
  eq_o (String.Ascii.unescape_string
          "\\b\\t\\n\\r\\\"\\\\\\x00\\x1F\\x7F\\xFF")
    (Some "\b\t\n\r\"\\\x00\x1F\x7F\xFF");
  eq_o (String.Ascii.unescape_string "\\x61") (Some "a");
  eq_o (String.Ascii.unescape_string "\\x20") (Some " ");
  eq_o (String.Ascii.unescape_string "\\x2") None;
  eq_o (String.Ascii.unescape_string "\\x") None;
  eq_o (String.Ascii.unescape_string "\\") None;
  eq_o (String.Ascii.unescape_string "a\\b") (Some "a\b");
  eq_o (String.Ascii.unescape_string "a\\t") (Some "a\t");
  eq_o (String.Ascii.unescape_string "b\\n") (Some "b\n");
  eq_o (String.Ascii.unescape_string "b\\r") (Some "b\r");
  eq_o (String.Ascii.unescape_string "b\\\"") (Some "b\"");
  eq_o (String.Ascii.unescape_string "b\\\'") (Some "b'");
  eq_o (String.Ascii.unescape_string "b\\z") None;
  eq_o (String.Ascii.unescape_string "b\\1") None;
  ()

(* Uniqueness *)

let uniquify = test "String.uniquify" @@ fun () ->
  let eq = eq_list ~eq:(=) ~pp:pp_str in
  eq (String.uniquify []) [];
  eq (String.uniquify ["a";"b";"c"]) ["a";"b";"c"];
  eq (String.uniquify ["a";"a";"b";"c"]) ["a";"b";"c"];
  eq (String.uniquify ["a";"b";"a";"c"]) ["a";"b";"c"];
  eq (String.uniquify ["a";"b";"c";"a"]) ["a";"b";"c"];
  eq (String.uniquify ["b";"a";"b";"c"]) ["b";"a";"c"];
  eq (String.uniquify ["a";"b";"b";"c"]) ["a";"b";"c"];
  eq (String.uniquify ["a";"b";"c";"b"]) ["a";"b";"c"];
  ()

let make_unique_in = test "String.make_unique_in" @@ fun () ->
  let set = String.Set.(add "a" @@ add "b" @@ add "c" @@ empty) in
  let set' = String.Set.(add "a~1" @@ set) in
  let no_alloc ?suff set s =
    eq_bool ((String.make_unique_in ?suff set s) == s) true
  in
  no_alloc set "d";
  no_alloc set ~suff:"bla%d" "d";
  eq_str (String.make_unique_in set "a") "a~1";
  eq_str (String.make_unique_in set ~suff:"-%d" "a") "a-1";
  eq_str (String.make_unique_in set' "a") "a~2";
  ()

let suite = suite "String functions"
    [ misc;
      append;
      concat;
      is_empty;
      is_prefix;
      is_infix;
      is_suffix;
      for_all;
      exists;
      equal;
      compare;
      find;
      find_sub;
      keep;
      with_pos_range;
      with_pos_len;
      with_index_range;
      slice;
      trim;
      cut;
      cuts;
      fields;
      iter;
      map;
      fold;
      ascii_is_valid;
      ascii_casing;
      ascii_escapes;
      ascii_unescapes;
      uniquify;
      make_unique_in; ]

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
