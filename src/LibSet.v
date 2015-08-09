(**************************************************************************
* TLC: A library for Coq                                                  *
* Sets                                                                    *
**************************************************************************)

Set Implicit Arguments.
Generalizable Variables A B.
Require Import LibTactics LibLogic LibReflect LibList
  LibOperation LibStruct LibInt LibNat LibEpsilon.

(*-----------------*)


(* TODO: move *)

Class Monoid_commutative (A:Type) (m:monoid_def A) : Prop := {
   monoid_commutative_monoid : Monoid m;
   monoid_commutative_comm : let (o,n) := m in comm o }.

Section MonoidProp.
Context {A:Type} {m:monoid_def A}.
Class Monoid_comm := {
  monoid_comm : comm (monoid_oper m) }.
End MonoidProp.

Section MonoidInst.
(* TODO: use M as explicit hypothesis *)
Context {A:Type} {m:monoid_def A}.
Global Instance Monoid_commutative_Monoid : 
  forall {M:Monoid_commutative m},
  Monoid m.
Proof using.
  introv M; destruct M as [U ?]. destruct m. simpl. apply U.
Qed.
Global Instance Monoid_commutative_Monoid_comm : 
  forall {M:Monoid_commutative m},
  Monoid_comm (m:=m).
Proof using.
  constructor. destruct M as [? U]. destruct m. simpl. apply U.
Qed.
End MonoidInst.



(*-----------------------*)

(* TEMPORARY some of these definitions are redundant with LibFix 
   and LibMMin from credits *)

Require Import LibRelation.

(* [lower_bound le P x] means that [x] is a lower bound for the
   set [P] with respect to the ordering [le]. *)

Definition lower_bound (A:Type) (le:binary A) (P:A->Prop) (x:A) :=
  forall y, P y -> le x y.

(* [min_element le P x] means that [x] is a minimal element of
   [P], i.e., it is both a member of [P] and a lower bound for
   [P]. *)

Definition min_element (A:Type) (le:binary A) (P:A->Prop) (x:A) :=
  P x /\ lower_bound le P x.

(* [mmin le P] is a minimal element of [P] with respect to [le],
   when such an element exists. *)

Definition mmin `{Inhab A} (le:binary A) (P:A->Prop) :=
  epsilon (min_element le P).


(* TODO: move *)

(* The type [nat] enjoys this property. *)

Lemma increment_lower_bound_nat:
  forall (P : nat -> Prop) x,
  lower_bound le P x ->
  ~ P x ->
  lower_bound le P (x + 1)%nat.
Proof using.
  introv hlo ?. intros y ?.
  destruct (eq_nat_dec x y).
    { subst. tauto. }
    { forwards: hlo; eauto. math. }
Qed.

Definition bounded_has_minimal (A:Type) (le:binary A) :=
  (* Recall that [ex P] means that [P] has an inhabitant; i.e.,
     it is equivalent to [exists x, P x]. *)
  forall P,
  ex P ->
  ex (lower_bound le P) ->
  ex (min_element le P).


Lemma bounded_has_minimal_nat:
  @bounded_has_minimal nat le.
Proof using.
  (* Assume a set [P], such that [y] is an inhabitant of [P]
     and [x] is a lower bound for [P]. *)
  intros P [ y ? ].
  (* We reason by induction on the difference [y + 1 - x].
     Reasoning with [y - x] would work too, but this choice
     is more elegant, as it makes the base case a contradiction,
     and avoids a little duplication. *)
  cut (
    forall (k x : nat), (y + 1 - x)%nat = k ->
    lower_bound le P x ->
    exists z, min_element le P z
  ). { intros ? [ x ? ]. eauto. }
  induction k; introv ? hlo.
  (* Base. *)
  (* Our hypotheses imply that [x] must be less than or equal to
     [y]. Because in this case the difference [y + 1 - x] is zero,
     this leads to a contradiction. *)
  { false. forwards: hlo; eauto. math. }
  (* Step. *)
  (* Eeither [P x] holds, or it does not. If it does, then [x]
     is the desired minimal element. If it does not, this implies
     that [x + 1] is a lower bound for [P], and the induction
     hypothesis can be used. *)
  destruct (classic (P x)).
    { exists x. split; eauto. }
    { eapply (IHk (x + 1)%nat). math. eauto using increment_lower_bound_nat. }
Qed.

Lemma admits_lower_bound_nat:
  forall P : nat -> Prop,
  ex (lower_bound le P).
Proof using.
  exists 0%nat. unfold lower_bound. math.
Qed.

Lemma mmin_spec:
  forall `{Inhab A} (le:binary A) (P:A->Prop) m,
  m = mmin le P ->
  ex P ->
  ex (lower_bound le P) ->
  bounded_has_minimal le ->
  min_element le P m.
Proof using.
  intros. subst. unfold mmin. spec_epsilon* as m.
Qed.

Lemma mmin_spec_nat:
  forall (P:nat->Prop) m,
  m = mmin le P ->
  ex P ->
  P m /\ (forall x, P x -> m <= x).
Proof using.
  introv E Q. applys (@mmin_spec _ _ _ P m E Q).
  applys admits_lower_bound_nat. 
  applys bounded_has_minimal_nat.
Qed.

(*-----------------*)





Require Export LibBag.


(* ********************************************************************** *)
(** * Construction of sets as predicates *)


(* ---------------------------------------------------------------------- *)
(** ** Basic definitions *)

Definition set (A : Type) := A -> Prop.

Section Operations.
Variables (A B : Type).
Implicit Types x : A.
Implicit Types E F G : set A.

Definition set_st (P:A->Prop) : set A := P.
Definition empty_impl : set A := (fun _ => False).
Definition full_impl : set A := (fun _ => True).
Definition single_impl x := (= x).
Definition in_impl x E := E x.
Definition compl_impl : set A -> set A := @pred_not A. (* todo: as typeclass? *)
Definition union_impl : set A -> set A -> set A := @pred_or A.
Definition inter_impl : set A -> set A -> set A := @pred_and A.
Definition remove_impl : set A -> set A -> set A := 
  fun E F x => E x /\ ~ F x.
Definition incl_impl : set A -> set A -> Prop := @pred_le A.
Definition list_repr_impl (E:set A) (l:list A) :=
  No_duplicates l /\ forall x, Mem x l <-> E x.
Definition to_list (E:set A) := epsilon (list_repr_impl E).
Definition list_covers_impl (E:set A) L := forall x, E x -> Mem x L.
Definition finite (E:set A) := exists L, list_covers_impl E L.
Definition card_impl (E:set A) : nat := 
  mmin le (fun n => exists L, list_covers_impl E L /\ n = length L).
Definition fold_impl (m:monoid_def B) (f:A->B) (E:set A) := 
  LibList.fold_right (fun x acc => monoid_oper m (f x) acc)
    (monoid_neutral m) (to_list E).

End Operations.


(* ---------------------------------------------------------------------- *)
(** ** Inhabited *)

Instance set_inhab : forall A, Inhab (set A).
Proof using. intros. apply (prove_Inhab (@empty_impl A)). Qed.


(* ---------------------------------------------------------------------- *)
(** ** Notation through typeclasses *)

Lemma in_inst : forall A, BagIn A (set A).
Proof using. constructor. exact (@in_impl A). Defined.
Hint Extern 1 (BagIn _ (set _)) => apply in_inst : typeclass_instances.
(* TODO: why is this not an instance like others ? *)

Instance empty_inst : forall A, BagEmpty (set A).
  constructor. apply (@empty_impl A). Defined.
Instance single_inst : forall A, BagSingle A (set A).
  constructor. rapply (@single_impl A). Defined.
Instance union_inst : forall A, BagUnion (set A).
  constructor. rapply (@union_impl A). Defined.
Instance inter_inst : forall A, BagInter (set A).
  constructor. rapply (@inter_impl A). Defined.
Instance remove_inst : forall A, BagRemove (set A) (set A).
  constructor. rapply (@remove_impl A). Defined.
Instance incl_inst : forall A, BagIncl (set A).
  constructor. rapply (@incl_impl A). Defined.
Instance disjoint_inst : forall A, BagDisjoint (set A).
  constructor. rapply (fun E F : set A => E \n F = \{}). Defined.
Instance fold_inst : forall A B, BagFold B (A->B) (set A).
  constructor. rapply (@fold_impl A B). Defined.
Instance card_inst : forall A, BagCard (set A).
  constructor. rapply (@card_impl A). Defined.

Global Opaque set finite in_inst empty_inst single_inst union_inst inter_inst  
  remove_inst incl_inst disjoint_inst card_inst fold_inst.


(* ---------------------------------------------------------------------- *)
(** exposed *)

Definition list_repr A (E:set A) L :=
  No_duplicates L /\ forall x, Mem x L <-> x \in E.

Definition list_covers A (E:set A) L := 
  forall x, x \in E -> Mem x L.


(* ---------------------------------------------------------------------- *)
(** ** Notations for building sets *)

Notation "\set{ x | P }" := (@set_st _ (fun x => P))
 (at level 0, x ident, P at level 200) : set_scope.
Notation "\set{ x : A | P }" := (@set_st A (fun x => P))
 (at level 0, x ident, P at level 200) : set_scope.
Notation "\set{ x '\in' E | P }" := (@set_st _ (fun x => x \in E /\ P))
 (at level 0, x ident, P at level 200) : set_scope.

Notation "\set{= e | x '\in' E }" := 
 (@set_st _ (fun a => exists_ x \in E, a = e ))
 (at level 0, x ident, E at level 200) : set_scope.
Notation "\set{= e | x '\in' E , y ''\in' F }" := 
 (@set_st _ (fun a => exists_ x \in E, exists_ y \in F, a = e ))
 (at level 0, x ident, F at level 200) : set_scope.
Notation "\set{= e | x y '\in' E }" := 
 (@set_st _ (fun a => exists_ x y \in E, a = e ))
 (at level 0, x ident, y ident, E at level 200) : set_scope.


(* ********************************************************************** *)
(** * Properties of sets *)

Section Instances.
Variables (A:Type).
Transparent set finite empty_inst single_inst single_impl in_inst 
  incl_inst inter_inst union_inst card_inst fold_inst remove_inst 
  disjoint_inst. 
Hint Constructors Mem.

Ltac unf := unfold finite, 
  card_inst, card_impl, card,
  to_list, 
  disjoint_inst, disjoint,
  incl_inst, incl_impl,
  empty_inst, empty_impl, empty,
  single_inst, single_impl, single,
  in_inst, in_impl, is_in,
  incl_inst, incl_impl, incl,
  compl_impl, pred_not,
  inter_inst, inter_impl, inter, pred_and,
  union_inst, union_impl, union, pred_or,
  remove_inst, remove_impl, remove,
  fold_inst, fold_impl, fold in *. 

(* ---------------------------------------------------------------------- *)
(** set_st *)

Lemma in_set_st_eq : forall A (P:A->Prop) x,
  x \in set_st P = P x.
Proof using. intros. apply* prop_ext. Qed.

(* ---------------------------------------------------------------------- *)
(** to_list *)


(* TODO: factorize this wiht later proofs *)
Lemma list_covers_impl_to_list_repr_impl : forall A (E:set A),
  ex (list_covers_impl E) -> ex (list_repr_impl E).
Proof using.
  introv (L&M). sets_eq L1 EQL1: (Remove_duplicates L).
  forwards~ (HN&HM): Remove_duplicates_spec EQL1.
  sets L2: (Filter (fun x => x \in E) L1).
  exists L2. split. 
    applys* Filter_No_duplicates.
    intros x. specializes M x. rewrite <- HM in M. unf. iff N.
      subst L2. forwards*: Filter_Mem_inv N.    
      applys* Filter_Mem.
Qed.

Lemma finite_list_repr : forall A (E:set A),
  finite E -> list_repr E (to_list E).
Proof using.
  introv FE. unfolds to_list, finite, list_repr_impl.
  spec_epsilon~ as L' (HL'&EL').
  applys~ list_covers_impl_to_list_repr_impl. splits~.
Qed.

Lemma to_list_spec : forall (E:set A) L,
  L = to_list E -> finite E -> No_duplicates L /\ (forall x, Mem x L <-> x \in E).
Proof. 
  introv EQ HE. subst. forwards* (?&?): finite_list_repr HE.
Qed.

Lemma to_list_empty : 
  to_list (\{}:set A) = nil.
Proof using.
  unf. spec_epsilon as l.
  exists (@nil A). split. constructor. iff; false_invert. 
  inverts Hl. simpls. destruct~ l. false. rewrite <- H0. simple~.
Qed.

Lemma to_list_single : forall (x:A), 
  to_list (\{x}) = x::nil.
Proof using.
  intros. unfold to_list. spec_epsilon as l.
    exists (x::nil). split. 
      constructor*. introv M. inverts M.
      unfold single_inst, single_impl. simple~.
       iff H. inverts* H. inverts* H1. inverts* H.
  unfolds single_inst, single_impl. simpls~.
  inverts Hl as H H0. destruct (H0 x). specializes~ H2.
  destruct l.
    inverts H2.
    tests E: (x = a).
      fequals. destruct l. auto. forwards~: (proj1 (H0 a0)).
       subst. inverts H as M1 M2. false* M1.
      inverts H2. false. forwards~: (proj1 (H0 a)). false.
Qed.


(* ---------------------------------------------------------------------- *)
(** double inclusion *)

Lemma set_ext_eq : forall (E F : set A), 
  (E = F) = (forall (x:A), x \in E <-> x \in F).
Proof using.
  intros. apply prop_ext. iff H. subst*. apply* prop_ext_1.
Qed.

Lemma set_ext : forall (E F : set A), 
  (forall (x:A), x \in E <-> x \in F) -> E = F.
Proof using. intros. rewrite~ set_ext_eq. Qed.




(* ---------------------------------------------------------------------- *)
(** set_in, incl *)

Global Instance in_extens_inst : In_extens (A:=A) (T:=set A).
Proof using. constructor. intros. rewrite* set_ext_eq. Qed.

Global Instance in_empty_eq_inst : In_empty_eq (A:=A) (T:=set A).
Proof using. constructor. intros. apply* prop_ext. Qed.

Global Instance in_single_eq_inst : In_single_eq (A:=A) (T:=set A).
Proof using. constructor. intros. apply* prop_ext. Qed.

Global Instance in_union_eq_inst : In_union_eq (A:=A) (T:=set A).
Proof using. constructor. intros. unf. simpl. apply* prop_ext. Qed.

Global Instance in_inter_eq_inst : In_inter_eq (A:=A) (T:=set A).
Proof using. constructor. intros. unf. apply* prop_ext. Qed.

Global Instance in_remove_eq_inst : In_remove_eq (A:=A) (T:=set A).
Proof using. constructor. intros. unf. applys* prop_ext. Qed.

Global Instance incl_in_eq_inst : Incl_in_eq (A:=A) (T:=set A).
Proof using. constructor. intros. unf. autos*. Qed.

Global Instance disjoint_eq_inst : Disjoint_eq (T:=set A).
Proof using.
  constructor. intros. unf. simpl. applys prop_ext. iff M.
    intros x. rewrite* <- (@func_same_1 _ _ x _ _ M).
    applys* prop_ext_1.
Qed.



(* ---------------------------------------------------------------------- *)
(** structural decomposition *)

Lemma set_isolate : forall A (E : set A) x,
  x \in E ->
  E = \{x} \u (E \- \{x}).
Proof using.
  introv H. unf. apply prop_ext_1. intros y. iff M. 
    simpls. tests*: (y = x).
    destruct M. subst*. autos*.
Qed.



(* ---------------------------------------------------------------------- *)
(** finite *)

Lemma finite_prove : forall A (E:set A) L,
  list_covers E L -> finite E.
Proof using. introv H. exists* L. Qed.


(* todo: move *)
Lemma list_repr_covers : forall A (E:set A) L,
  list_repr E L -> list_covers E L.
Proof using. introv (ND&EQ). introv Hx. rewrite~ EQ. Qed.

Lemma finite_prove_repr : forall A (E:set A) L,
  list_repr E L -> finite E.
Proof using. introv (ND&EQ). exists~ L. introv Hx. rewrite~ EQ. Qed.



(* useful? *)
Lemma finite_prove_exists : forall A (E:set A),
  ex (list_covers E) -> finite E.
Proof using. introv (L&H). applys* finite_prove. Qed.

Lemma finite_inv_basic : forall A (E:set A),
  finite E -> exists L, list_covers E L.
Proof using. introv (L&HN). exists L. intros. applys* HN. Qed.

Lemma finite_empty : forall A,
  finite (\{} : set A).
Proof using.
  intros. apply finite_prove_exists. unf.
  exists (@nil A). introv M. inverts M.
Qed.

Lemma finite_singleton : forall A (a : A),
  finite \{a}.
Proof using.
  intros. apply finite_prove_exists. unf.
  exists (a::nil). introv M. hnf in M. subst*.
Qed.

Lemma finite_union : forall A (E F : set A),
  finite E ->
  finite F ->
  finite (E \u F).
Proof using.
  introv H1 H2. apply finite_prove_exists.
  lets (L1&E1): finite_inv_basic H1.
  lets (L2&E2): finite_inv_basic H2.
  exists (L1++L2). unfolds list_covers.
  introv M. rewrite @in_union_eq in M; try typeclass.
  rewrite* Mem_app_or_eq. 
Qed.

Lemma finite_inter : forall A (E F : set A),
  finite E \/ finite F ->
  finite (E \n F).
Proof using.
  introv H. apply finite_prove_exists. destruct H.
  lets (L&EQ): finite_inv_basic H. exists L. unfold list_covers. unf. autos*.
  lets (L&EQ): finite_inv_basic H. exists L. unfold list_covers. unf. autos*.
Qed.

Lemma finite_incl : forall A (E F : set A),
  E \c F ->
  finite F ->
  finite E.
Proof using.
  introv HI HF. apply finite_prove_exists.
  lets (L&EQ): finite_inv_basic HF. unfold list_covers.
  unf. exists* L. introv Ex. applys EQ. applys~ HI. 
Qed.

Lemma finite_remove : forall A (E F : set A),
  finite E ->
  finite (E \- F).
Proof using.
  introv HE. apply finite_prove_exists.
  lets (L&EQ): finite_inv_basic HE. unfold list_covers. unf. exists* L.
Qed.

(* ---------------------------------------------------------------------- *)
(** card *)


(** TODO: move to LibList *)

Lemma No_duplicates_length_eq : forall A (L L':list A),
  No_duplicates L ->
  No_duplicates L' ->
  (forall x, Mem x L <-> Mem x L') ->
  (length L = length L')%nat.
Proof using.
  introv HL HL' EQ. 
  forwards~: No_duplicates_length_le L L'. intros. rewrite~ <- EQ.
  forwards~: No_duplicates_length_le L' L. intros. rewrite~ EQ.
  math.
Qed.


Definition finite_covers : forall (E:set A), 
  finite E -> exists L, list_covers E L /\ card E = length L.
Proof.
  introv (L&H). sets m: (card E).
  forwards* (R&P): mmin_spec_nat m.
Qed.

Lemma Remove_duplicates_spec' : forall A (L L':list A),
  L' = Remove_duplicates L ->
  No_duplicates L' /\ (forall x, Mem x L' <-> Mem x L) 
   /\ (length L' <= length L)%nat.
Proof using. 
  introv HL'. forwards~ (ND&EQ): Remove_duplicates_spec HL'.
  splits~.
  applys~ No_duplicates_length_le. introv Hx. rewrite~ <- EQ. 
Qed.

Definition card_prove_le : forall (E:set A) L,
  list_covers E L -> (card E <= length L)%nat.
Proof using.
  introv H. sets m: (card E). unf.
  forwards* (R&P): mmin_spec_nat m.
  simpls. applys P. exists L. splits~.
Qed.


Definition finite_covers_No_duplicates : forall (E:set A), 
  finite E -> exists L, list_repr E L /\ card E = length L.
Proof.
  introv H. forwards (L1&HL1&EL1): finite_covers H.
  sets L2: (Remove_duplicates L1).
  forwards~ (ND&EQ&LE): Remove_duplicates_spec' L1 L2.
  sets L3: (Filter (fun x => x \in E) L2).
  asserts: (length L3 <= length L2)%nat. applys Filter_length_le.
  asserts R3: (list_repr E L3).
    split.
      applys~ Filter_No_duplicates.
      intros x. iff M.
        unfold L3 in M. lets~ (_&?): Filter_Mem_inv M. 
        applys~ Filter_Mem. rewrite~ EQ.
  forwards C3: list_repr_covers R3.
  exists L3. splits*.
  forwards: card_prove_le C3. math.
Qed.

Lemma list_repr_card : forall (E:set A) (L:list A),
  list_repr E L -> card E = length L.
Proof using.
  introv HR. lets (ND&EQ): HR.
  forwards~ (L'&(ND'&HR')&EQ'): finite_covers_No_duplicates E.
    applys* finite_prove_repr.
  unfold card. simpl. rewrite EQ'.
  applys~ No_duplicates_length_eq.
  intros x. rewrite EQ. rewrite* HR'.
Qed. 

Definition card_prove_ge : forall (E:set A) n,
  finite E -> (forall L, list_covers E L -> (length L >= n)%nat) -> (card E >= n)%nat.
Proof using.
  introv H. sets m: (card E).
  forwards* (R&P): mmin_spec_nat m.
    lets (L&EL): finite_inv_basic H. exists~ (length L) L.
  simpls. introv HL. destruct R as (L&CR&ER). 
  forwards~: HL L. math.
Qed.

Definition card_prove_eq : forall (E:set A) L,
  list_covers E L ->
  (forall L', list_covers E L' -> (length L' >= length L)%nat) -> 
  card E = length L.
Proof using.
  introv HC HG.
  forwards~: card_prove_le HC.
  forwards~: card_prove_ge HG. applys* finite_prove.
  math.
Qed.

Lemma card_is_length_to_list : forall (E:set A), 
  card E = length (to_list E).
Admitted.
(*
Proof using. introv HF. unf. spec_epsilon* as L'. Qed.
*)

Global Instance card_empty_inst : Card_empty (T:=set A).
Proof using. 
  constructor. rewrite card_is_length_to_list.
  lets E: to_list_empty. unf. rewrite E. rew_list~. 
Qed.

Global Instance card_single_inst : Card_single (T:=set A).
Proof using.
  constructor. intros a. rewrite card_is_length_to_list.
  lets E: to_list_single a. unf. rewrite E. rew_list~. 
Qed.

Opaque card.
Opaque union.

Lemma set_card_incl_le : forall (E F:set A), 
  finite F -> 
  E \c F ->
  (card E <= card F)%nat.
Proof using. 
  introv FF CF. lets FE: finite_incl CF FF.
  lets (LF&RF&QF): finite_covers FF.
  rewrite QF. applys card_prove_le. introv Ex.
  applys RF. applys* @incl_inv. typeclass.
Qed.

Lemma set_card_union_le : forall (E F:set A), 
  finite E -> finite F ->
  card (E \u F) <= (card E + card F)%nat.
Proof using. 
  introv FE FF.
  lets (LE&RE&QE): finite_covers FE.
  lets (LF&RF&QF): finite_covers FF.
  lets H: card_prove_le (E \u F) (LE++LF) __.
    unfolds list_covers. intros. apply Mem_app_or.
    rewrite in_union_eq in H. autos*.
  rew_length in H. math.
Qed.

(* DEPRECATED
  Local Opaque union. hint finite_union.
  introv FE FF. do 3 rewrite~ card_is_length_to_list.
  forwards~ (NE&HE): to_list_spec E.
  forwards~ (NF&HF): to_list_spec F.
  forwards~ (NG&HG): to_list_spec (E \u F).
  sets LE: (to_list E). sets LF: (to_list F).
  sets G: (E \u F). sets LG: (to_list G).
  asserts RG: (forall x : A, Mem x LG <-> (x \in E \/ x \in F)).   
    intros. specializes HG x. subst G. rewrite in_union_eq in HG. auto.
  clear HG. clearbody LG.
  forwards~ M: No_duplicates_length_le LG (LE ++ LF).
   introv N. apply Mem_app_or. rewrite HE, HF. rewrite <- RG. auto.
  rew_length in M. auto.
  Transparent union. (* should not be needed *)
*)



(* ---------------------------------------------------------------------- *)
(** fold *)

Lemma fold_empty : forall B m (f:A->B),
  fold m f (\{}:set A) = monoid_neutral m.
Proof using.
  intros. unfold fold_inst, fold_impl, fold.
  rewrite to_list_empty. rewrite~ fold_right_nil.
Qed.

Lemma fold_single : forall B (m:monoid_def B) (f:A->B) (x:A),
  Monoid m -> fold m f \{x} = f x.
Proof using.
  intros. unfold fold_inst, fold_impl, fold.
  rewrite to_list_single. rewrite~ fold_right_cons.
  rewrite fold_right_nil. rewrite monoid_neutral_r. auto.
Qed.

End Instances.



Definition list_fold A B m (f:A->B) L : B :=
  LibList.fold_right (fun x acc => monoid_oper m (f x) acc) (monoid_neutral m) L.

Section ListFold.
Variables (A B:Type) (m:monoid_def B) (L:list A) (f:A->B).
Lemma list_fold_nil : 
  list_fold m f nil = monoid_neutral m.
Proof using. auto. Qed.
Lemma list_fold_cons : forall x l,
  list_fold m f (x::l) = monoid_oper m (f x) (list_fold m f l) .
Proof using. auto. Qed.
Lemma list_fold_app : forall l1 l2,
  Monoid m ->
  list_fold m f (l1 ++ l2) = monoid_oper m (list_fold m f l1) (list_fold m f l2).
Proof using.
  unfold list_fold. intros. rewrite fold_right_app. gen l2.
  induction l1; intros.
  rew_list. rewrite~ monoid_neutral_l.
  rew_list. rewrite <- monoid_assoc. fequals.
Qed.
Lemma list_fold_last : forall x l,
  Monoid m ->
  list_fold m f (l & x) = monoid_oper m (list_fold m f l) (f x).
Proof using.
  intros. rewrite~ list_fold_app. rewrite list_fold_cons.
  rewrite list_fold_nil. rewrite monoid_neutral_r. auto.
Qed.
End ListFold.


Lemma set_fold_def : forall A B (m:monoid_def B) (f:A->B) (E: set A),
  fold m f E = list_fold m f (to_list E).
Proof using. reflexivity. Qed. 

Lemma list_fold_equiv_step : forall A B (m:monoid_def B) (f:A->B) (L: list A) a,
  Monoid_commutative m ->
  No_duplicates L ->
  Mem a L ->
  exists L', 
     list_fold m f L = list_fold m f (a::L')
  /\ (forall x, Mem x L <-> Mem x (a::L'))
  /\ No_duplicates (a::L').
Proof using.
  introv Hm. induction L as [|b T]; introv DL La. inverts La.
  tests: (a = b). 
    exists T. splits*. 
    inverts La. false. inverts DL as DLb DT. forwards~ (L'&EL'&EQ&DL'): IHT.
     exists (b::L'). splits. 
       do 3 rewrite list_fold_cons. rewrite EL'.
        rewrite list_fold_cons. do 2 rewrite monoid_assoc.
        rewrite~ (monoid_comm (f b)).
       intros x. specializes EQ x. rewrite Mem_cons_eq in EQ.
        do 3 rewrite Mem_cons_eq. autos*.
       inverts DL'. constructors.
         introv N. inverts N. false. false.         
         constructors~. introv N. applys DLb. rewrite EQ. constructors~. 
Qed.

Lemma list_fold_equiv : forall A B (m:monoid_def B) (f:A->B) (L1 L2: list A),
  Monoid_commutative m ->
  No_duplicates L1 ->
  No_duplicates L2 ->
  (forall x, Mem x L1 <-> Mem x L2) ->
  list_fold m f L1 = list_fold m f L2.
Proof using.
  induction L1; introv HM D1 D2 EQ.
  cuts_rewrite (L2 = nil). rewrite~ list_fold_nil.
    destruct L2; auto. forwards~ M: (proj2 (EQ a)). inverts M.
  inverts D1. asserts L2a: (Mem a L2). rewrite~ <- EQ.
   forwards* (L2'&V2'&EQ'&D2'): list_fold_equiv_step f L2a.
   rewrite V2'. do 2 rewrite list_fold_cons.
  inverts D2'.
  rewrite~ (IHL1 L2'). intros.
  tests: (x = a).
    iff; auto_false*.
  asserts_rewrite (Mem x L1 = Mem x (a::L1)).
    extens. iff~ M. inverts~ M. false.
  asserts_rewrite (Mem x L2' = Mem x (a::L2')).
    extens. iff~ M. inverts~ M. false.
  rewrite EQ. rewrite* EQ'.
Qed.

Lemma set_fold_eq : forall A B (m:monoid_def B) (f:A->B) (E: set A) L,
  Monoid_commutative m ->
  list_repr E L ->
  fold m f E = list_fold m f L.
Proof using.
  introv HM EL. rewrite set_fold_def.
  forwards~ (N&EQ2): to_list_spec E. applys* finite_prove_repr.
  destruct EL as (ND&EQ1).
  applys~ list_fold_equiv. intros. rewrite EQ2. rewrite* EQ1.
Qed.

Lemma No_duplicates_app : forall A (L1 L2 : list A),
  No_duplicates L1 ->
  No_duplicates L2 ->
  (forall x, Mem x L1 -> Mem x L2 -> False) ->
  No_duplicates (L1 ++ L2).
Proof using.
  induction L1; introv N1 N2 EQ; rew_list.
  auto.
  inverts N1 as N N1'. constructors. 
    rewrite Mem_app_or_eq. rew_logic*.
    applys~ IHL1. introv Mx1 Mx2. applys* EQ x. 
Qed.

Lemma list_repr_disjoint_union : forall A (E F : set A) LE LF,
  E \# F ->
  list_repr E LE ->
  list_repr F LF ->
  list_repr (E \u F) (LE ++ LF).
Proof using.
  introv D (HE&QE) (HF&QF). split.
  applys~ No_duplicates_app.
    intros x ? ?. applys* @disjoint_inv x.
      typeclass. rewrite~ <- QE. rewrite~ <- QF.
    intros x. rewrite Mem_app_or_eq. rewrite in_union_eq. 
      rewrite <- QE. rewrite* <- QF.
Qed.


Lemma fold_union : forall A B (m:monoid_def B) (f:A->B) (E F : set A),
  Monoid_commutative m ->
  finite E ->
  finite F ->
  E \# F ->
  fold m f (E \u F) = monoid_oper m (fold m f E) (fold m f F).
Proof using.
  introv HM HE HF HD. 
  rewrites (>> set_fold_def E).
  rewrites (>> set_fold_def F).
  hint finite_list_repr. forwards~ HR: list_repr_disjoint_union HD.
  rewrites~ (>> set_fold_eq HR).
  rewrite~ list_fold_app. typeclass.
Qed.



(* ---------------------------------------------------------------------- *)
(* ---------------------------------------------------------------------- *)

Section Autorewrite.
Variables (A : Type).
Implicit Types x y : A.
Implicit Types E F : set A.

Lemma set_in_empty_eq : forall x, x \in (\{}:set A) = False.
Proof using.
  apply in_empty_eq.
Qed.

Lemma set_in_single_eq : forall x y, x \in (\{y}:set A) = (x = y).
Proof using.
  apply in_single_eq.
Qed.

Lemma set_in_inter_eq : forall x E F, x \in (E \n F) = (x \in E /\ x \in F).
Proof using.
  apply in_inter_eq.
Qed.

Lemma set_in_union_eq : forall x E F, x \in (E \u F) = (x \in E \/ x \in F).
Proof using.
  apply in_union_eq.
Qed.

Lemma set_in_remove_eq : forall x E F, x \in (E \- F) = (x \in E /\ ~ x \in F).
Proof using.
  apply in_remove_eq.
Qed.

Lemma set_in_extens_eq : forall E F, (E = F) = (forall x, x \in E <-> x \in F).
Proof using.
  extens. iff M.
  subst*.
  applys @in_extens_eq. typeclass. intros. extens*. 
Qed.

Lemma set_incl_in_eq : forall E F, (E \c F) = (forall x, x \in E -> x \in F).
Proof using.
  apply incl_in_eq.
Qed.

Lemma set_disjoint_eq : forall E F, (E \# F) = (forall x, x \in E -> x \in F -> False).
Proof using.
  apply disjoint_eq.
Qed.

End Autorewrite.

Hint Rewrite set_in_empty_eq set_in_single_eq set_in_inter_eq set_in_union_eq 
  set_in_remove_eq set_in_extens_eq set_incl_in_eq set_disjoint_eq : set_norm.


(* tactics *)

Ltac set_norm :=
  autorewrite_in_star_patch ltac:(fun tt => autorewrite with set_norm).

Ltac set_specialize_hyps A x :=
  repeat match goal with H: forall _:?A, _ |- _ => 
    specializes H x
  end.

Ltac set_specialize_classic x :=
  repeat match goal with E: set _ |- _ => 
    match goal with 
    | H: x \in E \/ ~ x \in E |- _ => fail 1
    | _ => lets: (classic (x \in E))
    end
  end.

Ltac set_specialize use_classic :=
  match goal with |- forall _:?A, _ =>
    let x := fresh "x" in intros x; 
    set_specialize_hyps A x; 
    match use_classic with 
    | true => set_specialize_classic x
    | false => idtac
    end
  end.

Ltac set_prove_setup use_classic := 
  intros;
  set_norm;
  try set_specialize use_classic;
  set_norm.

Ltac set_prove_conclude :=
  solve [ intros; subst; tauto ].

Ltac set_prove :=
  set_prove_setup false; set_prove_conclude.

Ltac set_prove_classic :=
  set_prove_setup true; set_prove_conclude.

(* demos *)

Lemma inter_union_disjoint_right:
  forall A (E F G : set A),
  F \# G ->
  (E \u F) \n G = (E \n G).
Proof using.
  set_prove.
  (*
  intros.
  set_norm.
  set_specialize.
  set_norm.
  tauto.
  *)
Admitted.

Lemma inter_union_subset_right:
  forall A (E F G : set A),
  F \c G ->
  (E \u F) \n G = (E \n G) \u F.
Proof using.
  set_prove.
Admitted.


Lemma inter_covariant:
  forall A (E E' F F' : set A),
  E \c E' ->
  F \c F' ->
  (E \n F) \c (E' \n F').
Proof using.
  set_prove.
Admitted.

Lemma set_decompose_inter_right :
  forall A (E F : set A),
  E = (E \n F) \u (E \- F).
Proof using.
  set_prove_classic.
Admitted.

Lemma set_decompose_union_right :
  forall A (E F : set A),
  (E \u F) = E \u (F \- E).
Proof using.
  set_prove_classic.
Admitted.




(* ---------------------------------------------------------------------- *)
(* ---------------------------------------------------------------------- *)


Lemma Filter_disjoint_predicates_length : forall A (P Q:A-> Prop) L,
  (forall x, Mem x L -> P x -> Q x -> False) ->
  length (Filter P L) + length (Filter Q L) <= length L.
Proof.
  introv. induction L; introv H.
  rew_list. math.
  specializes IHL. intros. applys* H x. 
  repeat rewrite Filter_cons. do 2 case_if; rew_list.
    false* H.
    math.
    math.
    math.
Qed.

Lemma card_disjoint_union:
  forall A (E F : set A),
  finite E ->
  finite F ->
  E \# F ->
  card (E \u F) = (card E + card F)%nat.
Proof using.
  introv FE FF EF.
  forwards: set_card_union_le FE FF.
  cuts: (card (E \u F) >= (card E + card F)%nat). math. clear H.
  forwards (L&LC&LL): finite_covers (E \u F). applys~ finite_union.
  rewrite LL. clear LL.
  sets PE: (fun x => x \in E). sets LE: (Filter PE L).
  sets PF: (fun x => x \in F). sets LF: (Filter PF L).
  forwards: card_prove_le E LE.
    unfold LE, PE. introv Ex. forwards: LC x. set_prove. applys~ Filter_Mem.
  forwards: card_prove_le F LF. 
    unfold LF, PF. introv Fx. forwards: LC x. set_prove. applys~ Filter_Mem.
  forwards LEF: Filter_disjoint_predicates_length PE PF L.
    introv _ HEx HFx. unfolds PE, PF. applys* @disjoint_inv. typeclass.
  subst LE LF. math.
Qed.




(* ---------------------------------------------------------------------- *)
(** ** Structural properties *)

(** Rewriting tactics *)

Hint Rewrite in_set_st_eq : rew_set.
Tactic Notation "rew_set" :=
  autorewrite with rew_set.
Tactic Notation "rew_set" "in" hyp(H) :=
  autorewrite with rew_set in H.
Tactic Notation "rew_set" "in" "*" :=
  autorewrite with rew_set in *.



(* ********************************************************************** *)
(** * Additional predicates on sets *)

(* ---------------------------------------------------------------------- *)
(** ** Foreach *)

(** TODO: derive these lemmas as typeclasses in a generic way in LibBag *)

Section ForeachProp.
Variables (A : Type).
Implicit Types P Q : A -> Prop.
Implicit Types E F : set A.

Lemma foreach_empty : forall P,
  @foreach A (set A) _ P \{}. 
Proof using. intros_all. false. Qed.
(* TODO: false* @in_empty. typeclass. *)

Lemma foreach_single : forall P X,
  P X -> @foreach A (set A) _ P (\{ X }). 
Proof using. intros_all. rewrite in_single_eq in H0. subst*. Qed.

Lemma foreach_union : forall P E F,
  foreach P E -> foreach P F -> foreach P (E \u F).
Proof using. intros_all. destruct~ (in_union_inv H1). Qed.

Lemma foreach_union_inv : forall P E F,
  foreach P (E \u F) -> foreach P E /\ foreach P F.
Proof using.
  introv H. split; introv K.
  apply H. rewrite~ @in_union_eq. typeclass.
  apply H. rewrite~ @in_union_eq. typeclass.
Qed.

Lemma foreach_union_eq : forall P E F,
  foreach P (E \u F) = (foreach P E /\ foreach P F).
Proof using.
  intros. extens. iff.
  apply~ foreach_union_inv. apply* foreach_union.
Qed.

Lemma foreach_single_eq : forall P X,
  foreach P (\{X}:set A) = P X.
Proof using.
  intros. extens. iff.
  apply H. apply in_single_self.
  apply~ foreach_single.
Qed. 

Lemma foreach_weaken : forall P Q E,
  foreach P E -> pred_le P Q -> foreach Q E.
Proof using. introv H L K. apply~ L. Qed.

Lemma foreach_remove_simple : forall P E F,
  foreach P E -> foreach P (E \- F).
Proof using. introv M H. applys M. rewrite in_remove_eq in H. autos*. Qed.

Lemma foreach_remove : forall P Q E F,
  foreach P E -> pred_le P (fun (x:A) => x \notin F -> Q x) -> foreach Q (E \- F).
Proof using. introv M H Px. rewrite in_remove_eq in Px. applys* H. Qed.

Lemma foreach_notin_prove : forall P x E,
  foreach P E -> ~ P x -> x \notin E.
Proof using. introv M N I. applys N. applys~ M. Qed.

End ForeachProp.

Hint Resolve foreach_empty foreach_single foreach_union.
Hint Rewrite foreach_union_eq foreach_single_eq : rew_foreach.

Tactic Notation "rew_foreach" := 
  autorewrite with rew_foreach.
Tactic Notation "rew_foreach" "in" hyp(H) := 
  autorewrite with rew_foreach in H.
Tactic Notation "rew_foreach" "in" "*" := 
  autorewrite_in_star_patch ltac:(fun tt => autorewrite with rew_foreach).
  (* autorewrite with rew_foreach in *.  *)

Tactic Notation "rew_foreach" "~" :=
  rew_foreach; auto_tilde.
Tactic Notation "rew_foreach" "*" :=
  rew_foreach; auto_star.
Tactic Notation "rew_foreach" "~" "in" constr(H) :=
  rew_foreach in H; auto_tilde.
Tactic Notation "rew_foreach" "*" "in" constr(H) :=
  rew_foreach in H; auto_star.
Tactic Notation "rew_foreach" "~" "in" "*" :=
  rew_foreach in *; auto_tilde.
Tactic Notation "rew_foreach" "*" "in" "*" :=
  rew_foreach in *; auto_star.


(* ********************************************************************** *)
(** * Tactics *)

(* ---------------------------------------------------------------------- *)
(** ** Tactics to prove equalities on unions *)

(* Documentation appears further on *)

Lemma for_set_union_assoc : forall A, assoc (union (T:=set A)).
Proof using. intros. apply union_assoc. Qed.

Lemma for_set_union_comm : forall A, comm (union (T:=set A)).
Proof using. intros. apply union_comm. Qed.

Lemma for_set_union_empty_l : forall A (E:set A), \{} \u E = E.
Proof using. intros. apply union_empty_l. Qed.

Lemma for_set_union_empty_r : forall A (E:set A), E \u \{} = E.
Proof using. intros. apply union_empty_r. Qed.

Hint Rewrite <- for_set_union_assoc : rew_permut_simpl.
Hint Rewrite for_set_union_empty_l for_set_union_empty_r : rew_permut_simpl.
Ltac rew_permut_simpl :=
  autorewrite with rew_permut_simpl; try typeclass.
Ltac rews_permut_simpl :=
  autorewrite with rew_permut_simpl in *; try typeclass.

Section PermutationTactic.
Context (A:Type).
Implicit Types l : set A.

Lemma permut_get_1 : forall l1 l2,
  (l1 \u l2) = (l1 \u l2).
Proof using. intros. auto. Qed.

Lemma permut_get_2 : forall l1 l2 l3,
  (l1 \u l2 \u l3) = (l2 \u l1 \u l3).
Proof using. intros. apply union_comm_assoc. Qed.

Lemma permut_get_3 : forall l1 l2 l3 l4,
  (l1 \u l2 \u l3 \u l4) = (l2 \u l3 \u l1 \u l4).
Proof using.
  intros. do 2 rewrite (union_assoc l2). apply permut_get_2.
Qed.

Lemma permut_get_4 : forall l1 l2 l3 l4 l5,
    (l1 \u l2 \u l3 \u l4 \u l5)
  = (l2 \u l3 \u l4 \u l1 \u l5).
Proof using.
  intros. do 2 rewrite (union_assoc l2). apply permut_get_3.
Qed.

Lemma permut_get_5 : forall l1 l2 l3 l4 l5 l6,
    (l1 \u l2 \u l3 \u l4 \u l5 \u l6) 
  = (l2 \u l3 \u l4 \u l5 \u l1 \u l6).
Proof using.
  intros. do 2 rewrite (union_assoc l2). apply permut_get_4.
Qed.

Lemma permut_get_6 : forall l1 l2 l3 l4 l5 l6 l7,
    (l1 \u l2 \u l3 \u l4 \u l5 \u l6 \u l7) 
  = (l2 \u l3 \u l4 \u l5 \u l6 \u l1 \u l7).
Proof using.
  intros. do 2 rewrite (union_assoc l2). apply permut_get_5.
Qed.

Lemma permut_get_7 : forall l1 l2 l3 l4 l5 l6 l7 l8,
    (l1 \u l2 \u l3 \u l4 \u l5 \u l6 \u l7 \u l8) 
  = (l2 \u l3 \u l4 \u l5 \u l6 \u l7 \u l1 \u l8).
Proof using.
  intros. do 2 rewrite (union_assoc l2). apply permut_get_6.
Qed.

Lemma permut_get_8 : forall l1 l2 l3 l4 l5 l6 l7 l8 l9,
    (l1 \u l2 \u l3 \u l4 \u l5 \u l6 \u l7 \u l8 \u l9) 
  = (l2 \u l3 \u l4 \u l5 \u l6 \u l7 \u l8 \u l1 \u l9).
Proof using.
  intros. do 2 rewrite (union_assoc l2). apply permut_get_7.
Qed.

Lemma permut_cancel_1 : forall l1 l2,
  (l1 \u l1 \u l2) = l1 \u l2.
Proof using. intros. rewrite union_assoc. rewrite union_self. auto. Qed.

Lemma permut_cancel_2 : forall l1 l2 l3,
  (l1 \u l2 \u l1 \u l3) = (l1 \u l2 \u l3).
Proof using.
  intros. rewrite <- (@permut_get_2 l1). apply permut_cancel_1. 
Qed.

Lemma permut_cancel_3 : forall l1 l2 l3 l4,
  (l1 \u l2 \u l3 \u l1 \u l4) = (l1 \u l2 \u l3 \u l4).
Proof using.
  intros. rewrite <- (@permut_get_3 l1). apply permut_cancel_1. 
Qed.

Lemma permut_cancel_4 : forall l1 l2 l3 l4 l5,
    (l1 \u l2 \u l3 \u l4 \u l1 \u l5)
  = (l1 \u l2 \u l3 \u l4 \u l5).
Proof using.
  intros. rewrite <- (@permut_get_4 l1). apply permut_cancel_1. 
Qed.

Lemma permut_cancel_5 : forall l1 l2 l3 l4 l5 l6,
    (l1 \u l2 \u l3 \u l4 \u l5 \u l1 \u l6) 
  = (l1 \u l2 \u l3 \u l4 \u l5 \u l6).
Proof using.
  intros. rewrite <- (@permut_get_5 l1). apply permut_cancel_1. 
Qed.

Lemma permut_tactic_setup : forall l1 l2,
   (\{} \u l1 \u \{}) = (l2 \u \{}) -> l1 = l2.
Proof using. intros. rews_permut_simpl. Qed.

Lemma permut_tactic_keep : forall l1 l2 l3 l4,
  ((l1 \u l2) \u l3) = l4 ->
  (l1 \u (l2 \u l3)) = l4.
Proof using. intros. rews_permut_simpl. Qed.

Lemma permut_tactic_simpl : forall l1 l2 l3 l4,
  (l1 \u l3) = l4 ->
  (l1 \u (l2 \u l3)) = (l2 \u l4).
Proof using. intros. subst. apply permut_get_2. Qed.

Lemma permut_tactic_trans : forall l1 l2 l3,
  l3 = l2 -> l1 = l3 -> l1 = l2.
Proof using. intros. subst~. Qed.

End PermutationTactic.

(** [permut_lemma_get n] returns the lemma [permut_get_n]
    for the given value of [n] *)

Ltac permut_lemma_get n :=
  match nat_from_number n with
  | 1%nat => constr:(permut_get_1)
  | 2%nat => constr:(permut_get_2)
  | 3%nat => constr:(permut_get_3)
  | 4%nat => constr:(permut_get_4)
  | 5%nat => constr:(permut_get_5) 
  end.

(** [permut_prepare] applies to a goal of the form [permut l l']
    and sets [l] and [l'] in the form [l1 \u l2 \u .. \u \{}],
    (some of the lists [li] are put in the form [x::\{}]). *)

Ltac permut_simpl_prepare :=
   rew_permut_simpl;
   apply permut_tactic_setup;
   repeat rewrite <- union_assoc.

(* todo : doc *)

Ltac cancel_all_dup l :=
  repeat first
    [ rewrite (permut_cancel_1 l)
    | rewrite (permut_cancel_2 l)
    | rewrite (permut_cancel_3 l)
    | rewrite (permut_cancel_4 l)
    | rewrite (permut_cancel_5 l) ].

Ltac permut_index_of l lcontainer :=
  match constr:(lcontainer) with
  | l \u _ => constr:(1)
  | _ \u l \u _ => constr:(2)
  | _ \u _ \u l \u _ => constr:(3)
  | _ \u _ \u _ \u l \u _ => constr:(4)
  | _ \u _ \u _ \u _ \u l \u _ => constr:(5)
  | _ \u _ \u _ \u _ \u _ \u l \u _ => constr:(6)
  | _ \u _ \u _ \u _ \u _ \u _ \u l \u _ => constr:(7)
  | _ \u _ \u _ \u _ \u _ \u _ \u _ \u l \u _ => constr:(8)
  | _ => constr:(0) (* not found *)
  end.

(** [permut_simplify] simplifies a goal of the form 
    [permut l l'] where [l] and [l'] are lists built with 
    concatenation and consing, by cancelling syntactically 
    equal elements *)

Ltac permut_simpl_once := 
  match goal with
  | |- (_ \u \{}) = _ => fail 1
  | |- (_ \u (?l \u ?lr)) = ?l' => 
     cancel_all_dup l;
     match permut_index_of l l' with
     | 0 => apply permut_tactic_keep
     | ?n => let F := permut_lemma_get n in
            eapply permut_tactic_trans; 
            [ eapply F; try typeclass
            | apply permut_tactic_simpl ]
     end
  end.

Ltac permut_simpl :=
  permut_simpl_prepare;
  repeat permut_simpl_once;
  rew_permut_simpl;
  try apply refl_equal.

(* TODO: move demos somewhere else *)

Section DemoSetUnion.
Variables (A:Type).

Lemma demo_set_union_permut_simpl_1 : 
  forall l1 l2 l3 : set A,
  (l1 \u l2 \u l3 \u l1) = (l3 \u l2 \u l1).
Proof using.
  intros.
  permut_simpl_prepare.
  permut_simpl_once.
  permut_simpl_once.
  permut_simpl_once.
  rew_permut_simpl.
Qed.


Lemma demo_set_union_permut_simpl_2 : 
  forall 
  (x:A) l1 l2 l3,
  (l1 \u \{x} \u l3 \u l2) = (l1 \u l2 \u (\{x} \u l3)).
Proof using.
  intros.
  permut_simpl_prepare.
  permut_simpl_once.
  permut_simpl_once.
  permut_simpl_once.
  permut_simpl_once.
  rew_permut_simpl.
Qed.

Lemma demo_set_union_permut_simpl_3 : forall (x y:A) l1 l1' l2 l3,
  l1 = l1' ->
  (l1 \u (\{x} \u l2) \u \{x} \u (\{y} \u l3)) = (\{y} \u (l1' \u l2) \u (\{x} \u l3)).
Proof using.
  intros. 
  permut_simpl_prepare.
  permut_simpl_once.
  permut_simpl_once.
  permut_simpl_once.
  permut_simpl_once.
  permut_simpl_once.
  try permut_simpl_once.
  rew_permut_simpl.
Qed.

End DemoSetUnion.

(* ---------------------------------------------------------------------- *)
(** ** Tactics to prove membership *)

(* TODO: doc & sort *)

Section InUnionGet.
Variables (A:Type).
Implicit Types l : set A.

Lemma in_union_get_1 : forall x l1 l2,
  x \in l1 -> x \in (l1 \u l2).
Proof using. intros. apply in_union_l. auto. Qed.

Lemma in_union_get_2 : forall x l1 l2 l3,
  x \in l2 -> x \in (l1 \u l2 \u l3).
Proof using. intros. apply in_union_r. apply~ in_union_get_1. Qed.

Lemma in_union_get_3 : forall x l1 l2 l3 l4,
  x \in l3 -> x \in (l1 \u l2 \u l3 \u l4).
Proof using. intros. apply in_union_r. apply~ in_union_get_2. Qed.

Lemma in_union_get_4 : forall x l1 l2 l3 l4 l5,
  x \in l4 -> x \in (l1 \u l2 \u l3 \u l4 \u l5).
Proof using. intros. apply in_union_r. apply~ in_union_get_3. Qed.

Lemma in_union_get_5 : forall x l1 l2 l3 l4 l5 l6,
  x \in l5 -> x \in (l1 \u l2 \u l3 \u l4 \u l5 \u l6).
Proof using. intros. apply in_union_r. apply~ in_union_get_4. Qed.

End InUnionGet.

Implicit Arguments in_union_get_1 [A x l1 l2].
Implicit Arguments in_union_get_2 [A x l1 l2 l3].
Implicit Arguments in_union_get_3 [A x l1 l2 l3 l4].
Implicit Arguments in_union_get_4 [A x l1 l2 l3 l4 l5].
Implicit Arguments in_union_get_5 [A x l1 l2 l3 l4 l5 l6].

Ltac in_union_get :=
  match goal with H: ?x \in ?A |- ?x \in ?B =>
  match B with context [A] =>
  let go tt := first       
        [ apply (in_union_get_1 H)
        | apply (in_union_get_2 H)
        | apply (in_union_get_3 H)
        | apply (in_union_get_4 H)
        | apply (in_union_get_5 H) ] in
  first [ go tt 
        | rewrite <- (for_set_union_empty_r B);
          repeat rewrite <- for_set_union_assoc;
          go tt ]
  end end. 

Hint Extern 3 (_ \in _ \u _) => in_union_get.

Section InUnionExtract.
Variables (A:Type).
Implicit Types l : set A.

Lemma in_union_extract_1 : forall x l1,
  x \in (\{x} \u l1).
Proof using. intros. apply in_union_get_1. apply in_single_self. Qed.

Lemma in_union_extract_2 : forall x l1 l2,
  x \in (l1 \u \{x} \u l2).
Proof using. intros. apply in_union_get_2. apply in_single_self. Qed.

Lemma in_union_extract_3 : forall x l1 l2 l3,
  x \in (l1 \u l2 \u \{x} \u l3).
Proof using. intros. apply in_union_get_3. apply in_single_self. Qed.

Lemma in_union_extract_4 : forall x l1 l2 l3 l4,
  x \in (l1 \u l2 \u l3 \u \{x} \u l4).
Proof using. intros. apply in_union_get_4. apply in_single_self. Qed.

Lemma in_union_extract_5 : forall x l1 l2 l3 l4 l5,
  x \in (l1 \u l2 \u l3 \u l4 \u \{x} \u l5).
Proof using. intros. apply in_union_get_5. apply in_single_self. Qed.

End InUnionExtract.

Ltac in_union_extract :=
  match goal with |- ?x \in ?A =>
  match A with context [\{x}] =>
  let go tt := first       
        [ apply (in_union_extract_1)
        | apply (in_union_extract_2)
        | apply (in_union_extract_3)
        | apply (in_union_extract_4)
        | apply (in_union_extract_5) ] in
  first [ go tt 
        | rewrite <- (for_set_union_empty_r A);
          repeat rewrite <- for_set_union_assoc;
          go tt ]
  end end. 

Hint Extern 3 (_ \in _) => in_union_extract.


(* ---------------------------------------------------------------------- *)
(** ** Tactics to invert a membership hypothesis *)

(* TODO: doc & sort *)

Section InversionsTactic.
Context (A:Type).
Implicit Types l : set A.
Implicit Types x : A.
Lemma empty_eq_single_inv_1 : forall x l1 l2,
  l1 = l2 -> x \notin l1 -> x \in l2 -> False.
Proof using. intros. subst*. Qed.
Lemma empty_eq_single_inv_2 : forall x l1 l2,
  l1 = l2 -> x \notin l2 -> x \in l1 -> False.
Proof using. intros. subst*. Qed.
Lemma notin_empty : forall x,
  x \notin (\{}:set A).
Proof using. intros. unfold notin. rewrite in_empty_eq. auto. Qed. 
End InversionsTactic.
Hint Resolve notin_empty.

Ltac in_union_meta :=
  match goal with 
  | |- _ \in \{_} => apply in_single_self
  | |- _ \in \{_} \u _ => apply in_union_l; apply in_single_self
  | |- _ \in _ \u _ => apply in_union_r; in_union_meta
  end.

Ltac fset_inv_core_for H :=
  let go L := 
     false L; [ apply H
              | try apply notin_empty 
              | instantiate; try in_union_meta ] in
  match type of H with
  | \{} = _ => go empty_eq_single_inv_1
  | _ = \{} => go empty_eq_single_inv_2
  | _ = _ => go empty_eq_single_inv_1
  end.

Tactic Notation "fset_inv" constr(H) := 
  fset_inv_core_for H.

Ltac fset_inv_core :=
  match goal with
  | |- \{} <> _ => let H := fresh in intro H; fset_inv H
  | |- _ <> \{} => let H := fresh in intro H; fset_inv H
  | H: \{} = _ |- _ => fset_inv H
  | H: _ = \{} |- _ => fset_inv H
  end.

Tactic Notation "fset_inv" := 
  fset_inv_core.

Section InUnionInv.
Variables (A:Type).
Implicit Types l : set A.

Lemma set_in_empty_inv : forall x,
  x \in (\{}:set A) -> False.
Proof using. introv. apply notin_empty. Qed.
Lemma set_in_single_inv : forall x y : A,
  x \in (\{y}:set A) -> x = y.
Proof using. intros. rewrite @in_single_eq in H. auto. typeclass. Qed.
Lemma set_in_union_inv : forall x l1 l2,
  x \in (l1 \u l2) -> x \in l1 \/ x \in l2.
Proof using. introv H. rewrite @in_union_eq in H. auto. typeclass. Qed.

End InUnionInv.

Implicit Arguments set_in_single_inv [A x y].
Implicit Arguments set_in_union_inv [A x l1 l2].


Ltac set_in_inv_base H M :=
  match type of H with
  | _ \in \{} => false; apply (@set_in_empty_inv _ _ H)  
  | _ \in \{_} => 
    generalize (set_in_single_inv H); try clear H; intro_subst
  | _ \in _ \u _ => 
    let H' := fresh "TEMP" in
    destruct (set_in_union_inv H) as [H'|H']; 
    try clear H; set_in_inv_base H' M
  | _ => rename H into M
  end.

Tactic Notation "set_in" constr(H) "as" ident(M) :=
  set_in_inv_base H M.
Tactic Notation "set_in" constr(H) :=
  let M := fresh "H" in set_in H as M.


(* ---------------------------------------------------------------------- *)
(** ** Tactic to prove two sets equal by double-inclusion *)

Tactic Notation "eq_set" :=
  let H := fresh "TEMP" in 
  apply set_ext; iff H; set_in H; in_union_get.
Tactic Notation "eq_set" "*" :=
  eq_set; auto_star.








(* ---------------------------------------------------------------------- *)
(* ---------------------------------------------------------------------- *)

(* FUTURE
  (** Sets of sets *)

  (* todo: typeclass for bigunion and bigintersection *)

  Definition bigunion_impl A (E : set (set A)) : set A := 
    \set{ x | exists_ F \in E, x \in (F:set A) }.

  Definition biguinter_impl A (E : set (set A)) : set A := 
    \set{ x | forall_ F \in E, x \in (F:set A) }.

*)
