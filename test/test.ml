open OUnit2;;

(* To check that the error has occured curreclty, we only check
   that the place where the error was found is the right one.  *)

let find_msg msgs typ during loc_str =
  let m = Msgs.filter 
    (fun msg -> match msg with 
      | t,d,_,l when String.compare (Msgs.string_of_loc l) loc_str == 0
            && t == typ
            && d == during -> true 
      | _ -> false)
    msgs
  in Msgs.elements m

let test_raise (parse:(string->Msgs.t)) (during:Msgs.during) typ nth_msg (loc_expected:string) text =
  let raised_error,msgs = (try let msgs = parse text in false,msgs with Msgs.Fatal msgs -> true,msgs) in
  if typ == Msgs.Error && raised_error == false then
    OUnit2.assert_failure ("this test didn't raise an error at location '"^loc_expected^"' as expected")
  else
  match find_msg msgs typ during loc_expected with
    | (t,d,msg,loc)::_ -> () (* OK *)
    | _ -> OUnit2.assert_failure ("this test didn't give a message at location '"^loc_expected^"' as expected. Instead, got:\n"^Msgs.string_of_msgs msgs)

let sat text = let ast,msgs = Parse.parse_sat text |> Eval.eval in let _ = Cnf.ast_to_cnf ast |> Sat.cnf_to_clauses in !msgs
let smt logic text = let ast,msgs = Parse.parse_smt text |> Eval.eval ~smt:true in let _ = Smt.to_smt2 logic ast in !msgs

(* The ending _ is necessary because the testing function
   must accept the 'context' thing. *)
let test_sat text _ =
  try let msgs = sat text in
  if Msgs.has_error msgs then OUnit2.assert_failure
    ("this test didn't raise any exceptions but errors had been outputed:\n"^
      Msgs.string_of_msgs msgs)
  with Msgs.Fatal msg -> OUnit2.assert_failure 
    ("this test shouldn't have raised a Fatal exception. Here is the exception:\n"^
      Msgs.string_of_msgs msg)

let test_smt ?(logic="QF_IDL") text _ =
  try let msgs = (smt logic) text in ();
  if Msgs.has_error msgs then OUnit2.assert_failure
      ("this test didn't raise any exceptions but errors had been outputed:\n"^
        Msgs.string_of_msgs msgs)
    with Msgs.Fatal msg -> OUnit2.assert_failure 
      ("this test shouldn't have raised a Fatal exception. Here is the exception:\n"^
        Msgs.string_of_msgs msg)

let test_sat_raise ?(during=Msgs.Eval) ?(typ=Msgs.Error) ?(nth=0) loc text _ = test_raise sat during typ nth loc text
let test_smt_raise ?(during=Msgs.Eval) ?(typ=Msgs.Error) ?(nth=0) ?(logic="QF_IDL") loc text _ = test_raise (smt logic) during typ nth loc text

let sat_models_are text expected _ =
  OUnit2.assert_equal ~printer:(fun s -> s)
    expected
    (let ast,msgs = Parse.parse_sat text |> Eval.eval in let cl,tbl = Cnf.ast_to_cnf ast |> Sat.cnf_to_clauses in
      let models_str = ref [] in
        let _ = Sat.solve_clauses ~print:(fun m _ -> models_str := (Sat.Model.pprint ~sep:" " tbl m)::!models_str) (cl,tbl)
          in List.fold_left (fun acc s -> match acc with "" -> s | _ -> s^" | "^acc) "" !models_str)

(* Tests if the given [text] is translated into the [expected] expanded
   text. *)
let sat_expands_to text expected _ =
  OUnit2.assert_equal ~printer:(fun s -> s)
    expected (let ast,_ = Parse.parse_sat text |> Eval.eval in Pprint.string_of_ast ast)
                       
(*  A standard test in oUnit should first define a function 
        let test1 context : unit = OUnit2.assert_bool true
    and then you add it to the suite:
        let suite = "suite">:::["test1">::test1;"test2">::test2]
    but instead, I chose to put these functions directly inside the
    list.
    Example of test checking that the exception is raised:
      fun c -> OUnit2.assert_raises (Eval.Error 
      ("incorrect types with '<', which expects a float or int.\n"
       "The content of the variable '$i' has type 'int':\n"
       "    1\n"
       "The other operand is of type 'float':\n    3.",loc))
      (fun _ -> eval "let $i=1: if $i < 3.0 then a else b end"));
*)

and read_file (filename:string) : string list =
  let lines = ref [] in
  let chan = open_in filename in
  try
    while true; do
      lines := input_line chan :: !lines
    done; !lines
  with End_of_file ->
    close_in chan;
    List.rev !lines ;;

let open_stream name = 
  let chan = open_in name 
  in Stream.from (
    fun _ -> try Some (input_line chan) 
             with End_of_file -> None)


let check_solution (sorted_solution:string) (stream:char Stream.t) =
  let rec one_line stream : string =
    try match Stream.next stream with
      | '\n' -> ""
      | c -> (Printf.sprintf "%c" c) ^ one_line stream
    with Stream.Failure -> ""
  in 
  let lines_from_stream (stream:char Stream.t) : string list =
    let rec multiple_lines stream = match one_line stream with
    | "" -> []
    | line -> line::(multiple_lines stream)
    in multiple_lines stream
  in
  let rec rm_unwanted_lines (l:string list) : string list = match l with
    | [] -> []
    | x::xs -> if Str.string_match (Str.regexp "^=") x 0
               then rm_unwanted_lines xs
               else x::(rm_unwanted_lines xs)
  in
  let expected = read_file sorted_solution in
  let actual = rm_unwanted_lines (List.sort (compare) (lines_from_stream stream)) in
  let rec check expected actual = match expected,actual with
    | [],[] -> ()
    | [],_ | _,[] -> OUnit2.assert_failure "not the same number of output"
    | exp::xs, act::ys -> OUnit2.assert_equal ~printer:(fun e -> e) exp act;
        (*Printf.fprintf stdout "expected: %s actual: %s\n" exp act;*) check xs ys
  in check expected actual

(* Name the test cases and group them together *)
let () = 
run_test_tt_main (
"touist">:::[

"numerical expressions">:::[ (* 'c' is the testing context *)
  "1 > 10 should be false">::(sat_expands_to "t(1 > 10)" "t(false)");
  "1 < 10 should be true">::(sat_expands_to "t(1 < 10)" "t(true)");
  "1.0 > 10.0 should be false">::(sat_expands_to "t(1.0 > 10.0)" "t(false)");
  "1.0 < 10.0 should be true">::(sat_expands_to "t(1.0 < 10.0)" "t(true)");
  "1 == 1.0 should raise error">::(test_sat_raise "1:3" "t(1==1.0)");
  "1.0 == 1 should raise error">::(test_sat_raise "1:3" "t(1.0==1)");
  "1 == 1 should be true">::(sat_expands_to "t(1==1)" "t(true)");
];
"exact, atleast and atmost">:::[
  "exact(5,[]) should be false">::(sat_expands_to "exact(5,[])" "Bot");
  "exact(0,[]) should be true">::(sat_expands_to "exact(0,[])" "Top");
  "atmost(0,[]) should be true">::(sat_expands_to "atmost(0,[])" "Top");
  "atmost(5,[]) should be true">::(sat_expands_to "atmost(5,[])" "Top");
  "atleast(0,[]) should be true">::(sat_expands_to "atleast(0,[])" "Top");
  "atleast(5,[]) should be false">::(sat_expands_to "atleast(5,[])" "Bot");
  "normal cases">:::[
  "exact(0,[a,b]) should return 'not a and not b'">::(sat_expands_to "exact(0,[a,b])" "(not a and not b)");
  "exact(1,[a,b,c]) should give 3 models">::(sat_models_are "exact(1,[a,b,c])" "0 a 0 b 1 c | 1 a 0 b 0 c | 0 a 1 b 0 c");
  "exact(3,[a,b,c]) should give 1 model">::(sat_models_are "exact(3,[a,b,c])" "1 c 1 b 1 a");
  "'atmost(2,[a,b,c]) a' should give 3 models">::(sat_models_are "atmost(2,[a,b,c]) a" "1 a 0 c 0 b | 1 a 0 c 1 b | 1 a 1 c 0 b");
  "'atmost(2,[a,b,c]) a b' should give 1 model">::(sat_models_are "atmost(2,[a,b,c]) a b" "1 b 1 a 0 c");
  "'atleast(2,[a,b,c])' should give 4 model">::(sat_models_are "atleast(2,[a,b,c])" "1 c 1 b 0 a | 0 c 1 b 1 a | 1 c 0 b 1 a | 1 c 1 b 1 a");
  "'atleast(2,[a,b,c]) a' should give 3 model">::(sat_models_are "atleast(2,[a,b,c]) a" "1 a 1 b 1 c | 1 a 1 b 0 c | 1 a 0 b 1 c");
  "'atleast(2,[a,b,c]) a b' should give 2 model">::(sat_models_are "atleast(2,[a,b,c]) a b" "1 b 1 c 1 a | 1 b 0 c 1 a");
  ];
"bigand and bigor">:::[
  "empty cases">:::[
  "bigand with empty sets should return Top">::(sat_expands_to "bigand $i in []: p($i) end" "Top");
  "bigand with always false 'when' should return Top">::(sat_expands_to "bigand $i in [1] when false: p($i) end" "Top");
  "bigor with empty sets should return Bot">::(sat_expands_to "bigor $i in []: p($i) end" "Bot");
  "bigor with always false 'when' should return Bot">::(sat_expands_to "bigor $i in [1] when false: p($i) end" "Bot");
  ];
  "bigand and >">::    (test_sat "bigand $i in [1..5] when $i > 2: p($i) end");
  "let declaration">:: (test_sat "let $i = 3: p($i-$i*3-1 mod 2 / 1)");
  "bigand">::          (test_sat "bigand $i in [a]: p($i) end");
  "bigor">::           (test_sat "bigor $i in [a,b,c] when $i==a and $i!=d: $i(a) end");
  "bigand imply">::    (test_sat "bigand $i,$j in [1..3],[1..3]:
	                                A($i) and B($i) => not C($j) end");
  "affect before">::   (test_sat "$a = a f($a)");
  "affect after">::    (test_sat "f($a) $a = a");
  "affect between">::  (test_sat "$a = a f($a,$b) $b = b");
  "var-tuple is prop">::(test_sat "$a=p p($a)");
  ];
];
"powerset">:::[
  "powerset should always return a set containing the empty set">::(sat_expands_to "f(powerset([1]))" "f([[],[1]])");
  "powerset simple test">::(sat_expands_to "f(powerset([a,b]))" "f([[],[a],[a,b],[b]])")
];

"samples of code that should raise errors in [Eval.eval]">:::[ (* 'c' is the testing context *)
  "undefined var">::         (test_sat_raise "1:4" "   $a");
  "bigand: too many vars">::(test_sat_raise "1:8" "bigand $i,$j in [1]: p end");
  "bigand: too many sets">::(test_sat_raise "1:8" "bigand $i in [1],[2]: p end");
  "bigor: too many vars">::(test_sat_raise "1:7" "bigor $i,$j in [1]: p end");
  "bigor: too many sets">::(test_sat_raise "1:7" "bigor $i in [1],[2]: p end");
  "condition is bool">::(test_sat_raise "1:23" "bigand $i in [1] when a: p end");
  (*"bigand var is not tuple">::(test_sat_raise "1:23:" "bigand $i(p) in [1]: p end");*)
];

"test of the p([a,b,c]) construct">:::[ (* 'c' is the testing context *)
  "p([a,b]) in a formula should stay p([a,b])">::(sat_expands_to "p([a,b])" "p([a,b])");
  "p([a,b]) in an expr should expand to [p(a),p(b)]">::(sat_expands_to "t(p([a,b]))" "t([p(a),p(b)])");
  "p(a) in an expr shouldn't expand to a set">::(sat_expands_to "t(p(a))" "t(p(a))");
  "p([]) in an expr should return p">::(sat_expands_to "t(p([]))" "t(p)");
  "p([],a) in an expr should return p(a)">::(sat_expands_to "t(p([],a))" "t(p(a))");
  "p(a,[]) in an expr should return p(a)">::(sat_expands_to "t(p(a,[]))" "t(p(a))");
  "p(1,[a]) in an expr should return [p(1,a)]">::(sat_expands_to "t(p(1,[a]))" "t([p(1,a)])");
  "the p([a,b,c]) syntax">:: (fun ctx ->
        OUnit2.skip_if (Sys.os_type = "Win32") "won't work on windows (unix-only??)";
        OUnit2.assert_command ~use_stderr:false ~ctxt:ctx
        ~foutput:(check_solution "test/sat/unittest_setgen_solution.txt")
        "./touist.native" ["--solve";"--sat";"test/sat/unittest_setgen.touistl"]);
];

"samples of code that should be correct with --smt">:::[ (* 'c' is the testing context *)
  "">::(test_smt "a > 1"); 
  "">::(test_smt "a < 1");
  "">::(test_smt "a == 3");
  "">::(test_smt "a != 3");
  "for now, one of the two terms must be a float or int">::(test_smt "(a+1) > 3");
  "takuzu4x4.touistl">:: (test_smt (Parse.string_of_file "test/smt/takuzu4x4.touistl"))
];
"real-size tests">:::[
  "sodoku">:: (fun ctx -> 
      OUnit2.skip_if (Sys.os_type = "Win32") "won't work on windows (unix-only??)";
      OUnit2.assert_command ~use_stderr:false ~ctxt:ctx
      ~foutput:(check_solution "test/sat/sudoku_solution.txt")
      "./touist.native" ["--solve";"--sat";"test/sat/sudoku.touistl"]);
];

])

;;
