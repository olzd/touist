This should be UNSAT. I added this test because it is a special case when
calling minisat: during the adding of the clauses, the formula becomes
UNSAT. I added this test in order to make sure this bug won't be
re-introduced.
  $ touist --solve --sat - <<'EOF'
  > $length = 1
  > $I = [F_free_left,F_free_right,F_at_ball1_rooma,F_at_robby_rooma]
  > $G = [F_at_ball1_roomb]
  > 
  > $O = [A_MOVE_roomb_rooma,A_MOVE_rooma_roomb,A_PICK_ball1_rooma_right,A_PICK_ball1_rooma_left,A_PICK_ball1_roomb_left,A_PICK_ball1_roomb_right,A_DROP_ball1_roomb_right,A_DROP_ball1_roomb_left,A_DROP_ball1_rooma_right,A_DROP_ball1_rooma_left]
  > $F = [F_free_right,F_at_ball1_roomb,F_at_robby_rooma,F_free_left,F_at_robby_roomb,F_at_ball1_rooma,F_carry_ball1_left,F_carry_ball1_right]
  > $Fp = [F_carry_ball1_right,F_carry_ball1_left,F_at_ball1_rooma,F_at_robby_roomb,F_free_left,F_at_robby_rooma,F_at_ball1_roomb,F_free_right]
  > $Fa = [F_carry_ball1_right,F_carry_ball1_left,F_at_ball1_rooma,F_at_robby_roomb,F_free_left,F_at_robby_rooma,F_at_ball1_roomb,F_free_right]
  > $Fd = [F_carry_ball1_right,F_carry_ball1_left,F_at_ball1_rooma,F_at_robby_roomb,F_free_left,F_at_robby_rooma,F_at_ball1_roomb,F_free_right]
  > 
  > $Cond(A_DROP_ball1_rooma_left) = [F_at_robby_rooma,F_carry_ball1_left]
  > $Add(A_DROP_ball1_rooma_left) = [F_free_left,F_at_ball1_rooma]
  > $Del(A_DROP_ball1_rooma_left) = [F_carry_ball1_left]
  > 
  > $Cond(A_DROP_ball1_rooma_right) = [F_at_robby_rooma,F_carry_ball1_right]
  > $Add(A_DROP_ball1_rooma_right) = [F_free_right,F_at_ball1_rooma]
  > $Del(A_DROP_ball1_rooma_right) = [F_carry_ball1_right]
  > 
  > $Cond(A_DROP_ball1_roomb_left) = [F_at_robby_roomb,F_carry_ball1_left]
  > $Add(A_DROP_ball1_roomb_left) = [F_free_left,F_at_ball1_roomb]
  > $Del(A_DROP_ball1_roomb_left) = [F_carry_ball1_left]
  > 
  > $Cond(A_DROP_ball1_roomb_right) = [F_at_robby_roomb,F_carry_ball1_right]
  > $Add(A_DROP_ball1_roomb_right) = [F_free_right,F_at_ball1_roomb]
  > $Del(A_DROP_ball1_roomb_right) = [F_carry_ball1_right]
  > 
  > $Cond(A_PICK_ball1_roomb_right) = [F_free_right,F_at_robby_roomb,F_at_ball1_roomb]
  > $Add(A_PICK_ball1_roomb_right) = [F_carry_ball1_right]
  > $Del(A_PICK_ball1_roomb_right) = [F_free_right,F_at_ball1_roomb]
  > 
  > $Cond(A_PICK_ball1_roomb_left) = [F_free_left,F_at_robby_roomb,F_at_ball1_roomb]
  > $Add(A_PICK_ball1_roomb_left) = [F_carry_ball1_left]
  > $Del(A_PICK_ball1_roomb_left) = [F_free_left,F_at_ball1_roomb]
  > 
  > $Cond(A_PICK_ball1_rooma_left) = [F_free_left,F_at_robby_rooma,F_at_ball1_rooma]
  > $Add(A_PICK_ball1_rooma_left) = [F_carry_ball1_left]
  > $Del(A_PICK_ball1_rooma_left) = [F_free_left,F_at_ball1_rooma]
  > 
  > $Cond(A_PICK_ball1_rooma_right) = [F_free_right,F_at_robby_rooma,F_at_ball1_rooma]
  > $Add(A_PICK_ball1_rooma_right) = [F_carry_ball1_right]
  > $Del(A_PICK_ball1_rooma_right) = [F_free_right,F_at_ball1_rooma]
  > 
  > $Cond(A_MOVE_rooma_roomb) = [F_at_robby_rooma]
  > $Add(A_MOVE_rooma_roomb) = [F_at_robby_roomb]
  > $Del(A_MOVE_rooma_roomb) = [F_at_robby_rooma]
  > 
  > $Cond(A_MOVE_roomb_rooma) = [F_at_robby_roomb]
  > $Add(A_MOVE_roomb_rooma) = [F_at_robby_rooma]
  > $Del(A_MOVE_roomb_rooma) = [F_at_robby_roomb]
  > 
  > ;; (SAT-EFA1) Etat initial et but
  > 
  > bigand $f in $I: $f(0) end
  > bigand $f in ($F diff $I): not $f(0) end
  > bigand $f in $G: $f($length) end
  > 
  > ;; (SAT-EFA2) Conditions et effets des actions
  > 
  > bigand $i in [1..$length]:
  >   bigand $a in $O:
  >     ($a($i) =>
  >       ((bigand $f in $Cond($a): $f($i-1) end)
  >         and
  >         (bigand $f in $Add($a): $f($i) end)
  >         and
  >         (bigand $f in $Del($a): (not $f($i)) end)))
  >   end
  > end
  > 
  > ;; (SAT-EFA3.1) Frames-axiomes de retrait
  > 
  > bigand $i in [1..$length]:
  >   bigand $f in $F:
  >     ($f($i-1) and not $f($i))
  >     => (bigor $a in $O when $f in $Del($a): $a($i) end)
  >   end
  > end
  > 
  > ;; (SAT-EFA3.2) Frames-axiomes d'ajout
  > 
  > bigand $i in [1..$length]:
  >   bigand $f in $F:
  >     (not $f($i-1) and $f($i))
  >     => (bigor $a in $O when $f in $Add($a): $a($i) end)
  >   end
  > end
  > 
  > ;; (SAT-EFA4) Mutex (Forall-step semantics)
  > bigand $i in [1..$length]:
  >   bigand $a1 in $O:
  >     bigand $f in $Cond($a1):
  >       bigand $a2 in $O when ($a1 != $a2) and ($f in $Del($a2)):
  >         (not $a1($i) or not $a2($i))
  >       end
  >     end
  >   end
  > end
  > EOF
  unsat
  [8]

