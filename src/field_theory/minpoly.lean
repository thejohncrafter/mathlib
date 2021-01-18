/-
Copyright (c) 2019 Chris Hughes. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Chris Hughes, Johan Commelin
-/
import ring_theory.integral_closure
import data.polynomial.field_division
import ring_theory.polynomial.gauss_lemma

/-!
# Minimal polynomials

This file defines the minimal polynomial of an element `x` of an `A`-algebra `B`,
under the assumption that x is integral over `A`.

After stating the defining property we specialize to the setting of field extensions
and derive some well-known properties, amongst which the fact that minimal polynomials
are irreducible, and uniquely determined by their defining property.

-/

open_locale classical
open polynomial set function

variables {A B : Type*}

section min_poly_def
variables [comm_ring A] [ring B] [algebra A B]

/-- Let `B` be an `A`-algebra, and `x` an element of `B` that is integral over `A`
so we have some term `hx : is_integral A x`.
The minimal polynomial `minpoly hx` of `x` is a monic polynomial of smallest degree
that has `x` as its root.
For instance, if `V` is a `K`-vector space for some field `K`, and `f : V →ₗ[K] V` then
the minimal polynomial of `f` is `minpoly f.is_integral`. -/
noncomputable def minpoly {x : B} (hx : is_integral A x) : polynomial A :=
well_founded.min degree_lt_wf _ hx

end min_poly_def

namespace minpoly

section ring
variables [comm_ring A] [ring B] [algebra A B]
variables {x : B} (hx : is_integral A x)

/--A minimal polynomial is monic.-/
lemma monic : monic (minpoly hx) :=
(well_founded.min_mem degree_lt_wf _ hx).1

/--An element is a root of its minimal polynomial.-/
@[simp] lemma aeval : aeval x (minpoly hx) = 0 :=
(well_founded.min_mem degree_lt_wf _ hx).2

/--The defining property of the minimal polynomial of an element x:
it is the monic polynomial with smallest degree that has x as its root.-/
lemma min {p : polynomial A} (pmonic : p.monic) (hp : polynomial.aeval x p = 0) :
  degree (minpoly hx) ≤ degree p :=
le_of_not_lt $ well_founded.not_lt_min degree_lt_wf _ hx ⟨pmonic, hp⟩

/-- A minimal polynomial is nonzero. -/
lemma ne_zero [nontrivial A] : (minpoly hx) ≠ 0 :=
ne_zero_of_monic (monic hx)

/-- If an element `x` is a root of a nonzero monic polynomial `p`,
then the degree of `p` is at least the degree of the minimal polynomial of `x`. -/
lemma degree_le_of_monic
  {p : polynomial A} (hmonic : p.monic) (hp : polynomial.aeval x p = 0) :
  degree (minpoly hx) ≤ degree p :=
min _ hmonic (by simp [hp])

end ring

section integral_domain

variables [integral_domain A]

section ring

variables [ring B] [algebra A B] [nontrivial B]
variables {x : B} (hx : is_integral A x)

/-- The degree of a minimal polynomial is positive. -/
lemma degree_pos [nontrivial A] : 0 < degree (minpoly hx) :=
begin
  apply lt_of_le_of_ne,
  { simpa only [zero_le_degree_iff] using ne_zero hx },
  assume deg_eq_zero,
  rw eq_comm at deg_eq_zero,
  have ndeg_eq_zero : nat_degree (minpoly hx) = 0,
  { simpa using congr_arg nat_degree (eq_C_of_degree_eq_zero deg_eq_zero) },
  have eq_one : minpoly hx = 1,
  { rw eq_C_of_degree_eq_zero deg_eq_zero, convert C_1,
    simpa only [ndeg_eq_zero.symm] using (monic hx).leading_coeff },
  simpa only [eq_one, alg_hom.map_one, one_ne_zero] using aeval hx
end

/-- If `L/K` is a ring extension, and `x` is an element of `L` in the image of `K`,
then the minimal polynomial of `x` is `X - C x`. -/
lemma eq_X_sub_C_of_algebra_map_inj [nontrivial A] (a : A)
  (hf : function.injective (algebra_map A B)) :
  minpoly (@is_integral_algebra_map A B _ _ _ a) = X - C a :=
begin
  have hdegle : (minpoly (@is_integral_algebra_map A B _ _ _ a)).nat_degree ≤ 1,
  { apply with_bot.coe_le_coe.1,
    rw [←degree_eq_nat_degree (ne_zero (@is_integral_algebra_map A B _ _ _ a)),
      with_top.coe_one, ←degree_X_sub_C a],
    refine degree_le_of_monic (@is_integral_algebra_map A B _ _ _ a) (monic_X_sub_C a) _,
    simp only [aeval_C, aeval_X, alg_hom.map_sub, sub_self] },
  have hdeg : (minpoly (@is_integral_algebra_map A B _ _ _ a)).degree = 1,
  { apply (degree_eq_iff_nat_degree_eq (ne_zero (@is_integral_algebra_map A B _ _ _ a))).2,
    exact (has_le.le.antisymm hdegle (nat.succ_le_of_lt (with_bot.coe_lt_coe.1
    (lt_of_lt_of_le (degree_pos (@is_integral_algebra_map A B _ _ _ a)) degree_le_nat_degree)))) },
  have hrw := eq_X_add_C_of_degree_eq_one hdeg,
  simp only [monic (@is_integral_algebra_map A B _ _ _ a), one_mul,
    monic.leading_coeff, ring_hom.map_one] at hrw,
  have h0 : (minpoly (@is_integral_algebra_map A B _ _ _ a)).coeff 0 = -a,
  { have hroot := aeval (@is_integral_algebra_map A B _ _ _ a),
    rw [hrw, add_comm] at hroot,
    simp only [aeval_C, aeval_X, aeval_add] at hroot,
    replace hroot := eq_neg_of_add_eq_zero hroot,
    rw [←ring_hom.map_neg _ a] at hroot,
    exact (hf hroot) },
  rw hrw,
  simp only [h0, ring_hom.map_neg, sub_eq_add_neg],
end

/-- A minimal polynomial is not a unit. -/
lemma not_is_unit : ¬ is_unit (minpoly hx) :=
assume H, (ne_of_lt (degree_pos hx)).symm $ degree_eq_zero_of_is_unit H

end ring

section domain

variables [domain B] [algebra A B]
variables {x : B} (hx : is_integral A x)

/-- If `a` strictly divides the minimal polynomial of `x`, then `x` cannot be a root for `a`. -/
lemma aeval_ne_zero_of_dvd_not_unit_minpoly {a : polynomial A}
  (hamonic : a.monic) (hdvd : dvd_not_unit a (minpoly hx)) :
  polynomial.aeval x a ≠ 0 :=
begin
  intro ha,
  refine not_lt_of_ge (minpoly.min hx hamonic ha) _,
  obtain ⟨hzeroa, b, hb_nunit, prod⟩ := hdvd,
  have hbmonic : b.monic,
  { rw monic.def,
    have := monic hx,
    rwa [monic.def, prod, leading_coeff_mul, monic.def.mp hamonic, one_mul] at this },
  have hzerob : b ≠ 0 := hbmonic.ne_zero,
  have degbzero : 0 < b.nat_degree,
  { apply nat.pos_of_ne_zero,
    intro h,
    have h₁ := eq_C_of_nat_degree_eq_zero h,
    rw [←h, ←leading_coeff, monic.def.1 hbmonic, C_1] at h₁,
    rw h₁ at hb_nunit,
    have := is_unit_one,
    contradiction },
  rw [prod, degree_mul, degree_eq_nat_degree hzeroa, degree_eq_nat_degree hzerob],
  exact_mod_cast lt_add_of_pos_right _ degbzero,
end

/--A minimal polynomial is irreducible.-/
lemma irreducible : irreducible (minpoly hx) :=
begin
  cases irreducible_or_factor (minpoly hx) (not_is_unit hx) with hirr hred,
  { exact hirr },
  exfalso,
  obtain ⟨a, b, ha_nunit, hb_nunit, hab_eq⟩ := hred,
  have coeff_prod : a.leading_coeff * b.leading_coeff = 1,
  { rw [←monic.def.1 (monic hx), ←hab_eq],
    simp only [leading_coeff_mul] },
  have hamonic : (a * C b.leading_coeff).monic,
  { rw monic.def,
    simp only [coeff_prod, leading_coeff_mul, leading_coeff_C] },
  have hbmonic : (b * C a.leading_coeff).monic,
  { rw [monic.def, mul_comm],
    simp only [coeff_prod, leading_coeff_mul, leading_coeff_C] },
  have prod : minpoly hx = (a * C b.leading_coeff) * (b * C a.leading_coeff),
  { symmetry,
    calc a * C b.leading_coeff * (b * C a.leading_coeff)
        = a * b * (C a.leading_coeff * C b.leading_coeff) : by ring
    ... = a * b * (C (a.leading_coeff * b.leading_coeff)) : by simp only [ring_hom.map_mul]
    ... = a * b : by rw [coeff_prod, C_1, mul_one]
    ... = minpoly hx : hab_eq },
  have hzero := aeval hx,
  rw [prod, aeval_mul, mul_eq_zero] at hzero,
  cases hzero,
  { refine aeval_ne_zero_of_dvd_not_unit_minpoly hx hamonic _ hzero,
    exact ⟨hamonic.ne_zero, _, mt is_unit_of_mul_is_unit_left hb_nunit, prod⟩ },
  { refine aeval_ne_zero_of_dvd_not_unit_minpoly hx hbmonic _ hzero,
    rw mul_comm at prod,
    exact ⟨hbmonic.ne_zero, _, mt is_unit_of_mul_is_unit_left ha_nunit, prod⟩ },
end

end domain

end integral_domain

section field
variables [field A]

section ring
variables [ring B] [algebra A B]
variables {x : B} (hx : is_integral A x)

/-- If an element `x` is a root of a nonzero polynomial `p`,
then the degree of `p` is at least the degree of the minimal polynomial of `x`. -/
lemma degree_le_of_ne_zero
  {p : polynomial A} (pnz : p ≠ 0) (hp : polynomial.aeval x p = 0) :
  degree (minpoly hx) ≤ degree p :=
calc degree (minpoly hx) ≤ degree (p * C (leading_coeff p)⁻¹) :
    min _ (monic_mul_leading_coeff_inv pnz) (by simp [hp])
  ... = degree p : degree_mul_leading_coeff_inv p pnz

/-- The minimal polynomial of an element `x` is uniquely characterized by its defining property:
if there is another monic polynomial of minimal degree that has `x` as a root,
then this polynomial is equal to the minimal polynomial of `x`. -/
lemma unique {p : polynomial A} (pmonic : p.monic) (hp : polynomial.aeval x p = 0)
  (pmin : ∀ q : polynomial A, q.monic → polynomial.aeval x q = 0 → degree p ≤ degree q) :
  p = minpoly hx :=
begin
  symmetry, apply eq_of_sub_eq_zero,
  by_contra hnz,
  have := degree_le_of_ne_zero hx hnz (by simp [hp]),
  contrapose! this,
  apply degree_sub_lt _ (ne_zero hx),
  { rw [(monic hx).leading_coeff, pmonic.leading_coeff] },
  { exact le_antisymm (min hx pmonic hp)
      (pmin (minpoly hx) (monic hx) (aeval hx)) },
end

/-- If an element `x` is a root of a polynomial `p`, then the minimal polynomial of `x` divides `p`.
-/
lemma dvd {p : polynomial A} (hp : polynomial.aeval x p = 0) :
  minpoly hx ∣ p :=
begin
  rw ← dvd_iff_mod_by_monic_eq_zero (monic hx),
  by_contra hnz,
  have := degree_le_of_ne_zero hx hnz _,
  { contrapose! this,
    exact degree_mod_by_monic_lt _ (monic hx) (ne_zero hx) },
  { rw ← mod_by_monic_add_div p (monic hx) at hp,
    simpa using hp }
end

lemma dvd_map_of_is_scalar_tower {A γ : Type*} (B : Type*) [comm_ring A] [field B] [comm_ring γ]
  [algebra A B] [algebra A γ] [algebra B γ] [is_scalar_tower A B γ] {x : γ} (hx : is_integral A x) :
  minpoly (is_integral_of_is_scalar_tower x hx) ∣ (minpoly hx).map (algebra_map A B) :=
by { apply minpoly.dvd, rw [← is_scalar_tower.aeval_apply, minpoly.aeval] }

variables [nontrivial B]

theorem unique' {p : polynomial A} (hp1 : _root_.irreducible p) (hp2 : polynomial.aeval x p = 0)
  (hp3 : p.monic) : p = minpoly hx :=
let ⟨q, hq⟩ := dvd hx hp2 in
eq_of_monic_of_associated hp3 (monic hx) $
mul_one (minpoly hx) ▸ hq.symm ▸ associated_mul_mul (associated.refl _) $
associated_one_iff_is_unit.2 $ (hp1.is_unit_or_is_unit hq).resolve_left $ not_is_unit hx

section gcd_domain

/-- For GCD domains, the minimal polynomial over the ring is the same as the minimal polynomial
over the fraction field. -/
lemma gcd_domain_eq_field_fractions {A K R : Type*} [integral_domain A]
  [gcd_monoid A] [field K] [integral_domain R] (f : fraction_map A K) [algebra f.codomain R]
  [algebra A R] [is_scalar_tower A f.codomain R] {x : R} (hx : is_integral A x) :
  minpoly (@is_integral_of_is_scalar_tower A f.codomain R _ _ _ _ _ _ _ x hx) =
    ((minpoly hx).map (localization_map.to_ring_hom f)) :=
begin
  refine (unique' (@is_integral_of_is_scalar_tower A f.codomain R _ _ _ _ _ _ _ x hx) _ _ _).symm,
  { exact (polynomial.is_primitive.irreducible_iff_irreducible_map_fraction_map f
  (polynomial.monic.is_primitive (monic hx))).1 (irreducible hx) },
  { have htower := is_scalar_tower.aeval_apply A f.codomain R x (minpoly hx),
    simp only [localization_map.algebra_map_eq, aeval] at htower,
    exact htower.symm },
  { exact monic_map _ (monic hx) }
end

/-- The minimal polynomial over `ℤ` is the same as the minimal polynomial over `ℚ`. -/
--TODO use `gcd_domain_eq_field_fractions` directly when localizations are defined
-- in terms of algebras instead of `ring_hom`s
lemma over_int_eq_over_rat {A : Type*} [integral_domain A] {x : A} [algebra ℚ A]
  (hx : is_integral ℤ x) :
  minpoly (@is_integral_of_is_scalar_tower ℤ ℚ A _ _ _ _ _ _ _ x hx) =
    map (int.cast_ring_hom ℚ) (minpoly hx) :=
begin
  refine (unique' (@is_integral_of_is_scalar_tower ℤ ℚ A _ _ _ _ _ _ _ x hx) _ _ _).symm,
  { exact (is_primitive.int.irreducible_iff_irreducible_map_cast
  (polynomial.monic.is_primitive (monic hx))).1 (irreducible hx) },
  { have htower := is_scalar_tower.aeval_apply ℤ ℚ A x (minpoly hx),
    simp only [localization_map.algebra_map_eq, aeval] at htower,
    exact htower.symm },
  { exact monic_map _ (monic hx) }
end

/-- For GCD domains, the minimal polynomial divides any primitive polynomial that has the integral
element as root. -/
lemma gcd_domain_dvd {A K R : Type*}
  [integral_domain A] [gcd_monoid A] [field K] [integral_domain R]
  (f : fraction_map A K) [algebra f.codomain R] [algebra A R] [is_scalar_tower A f.codomain R]
  {x : R} (hx : is_integral A x)
  {P : polynomial A} (hprim : is_primitive P) (hroot : polynomial.aeval x P = 0) :
  minpoly hx ∣ P :=
begin
  apply (is_primitive.dvd_iff_fraction_map_dvd_fraction_map f
    (monic.is_primitive (monic hx)) hprim ).2,
  rw [← gcd_domain_eq_field_fractions f hx],
  refine dvd (is_integral_of_is_scalar_tower x hx) _,
  rwa [← localization_map.algebra_map_eq, ← is_scalar_tower.aeval_apply]
end

/-- The minimal polynomial over `ℤ` divides any primitive polynomial that has the integral element
as root. -/
-- TODO use `gcd_domain_dvd` directly when localizations are defined in terms of algebras
-- instead of `ring_hom`s
lemma integer_dvd {A : Type*} [integral_domain A] [algebra ℚ A] {x : A} (hx : is_integral ℤ x)
  {P : polynomial ℤ} (hprim : is_primitive P) (hroot : polynomial.aeval x P = 0) :
  minpoly hx ∣ P :=
begin
  apply (is_primitive.int.dvd_iff_map_cast_dvd_map_cast _ _
    (monic.is_primitive (monic hx)) hprim ).2,
  rw [← over_int_eq_over_rat hx],
  refine dvd (is_integral_of_is_scalar_tower x hx) _,
  rwa [(int.cast_ring_hom ℚ).ext_int (algebra_map ℤ ℚ), ← is_scalar_tower.aeval_apply]
end

end gcd_domain

variable (B)
/-- If `L/K` is a field extension, and `x` is an element of `L` in the image of `K`,
then the minimal polynomial of `x` is `X - C x`. -/
lemma eq_X_sub_C (a : A) :
  minpoly (@is_integral_algebra_map A B _ _ _ a) =
  X - C a :=
eq.symm $ unique' (@is_integral_algebra_map A B _ _ _ a) (irreducible_X_sub_C a)
  (by rw [alg_hom.map_sub, aeval_X, aeval_C, sub_self]) (monic_X_sub_C a)
variable {B}

/-- The minimal polynomial of `0` is `X`. -/
@[simp] lemma zero {h₀ : is_integral A (0:B)} :
  minpoly h₀ = X :=
by simpa only [add_zero, C_0, sub_eq_add_neg, neg_zero, ring_hom.map_zero]
  using eq_X_sub_C B (0:A)

/-- The minimal polynomial of `1` is `X - 1`. -/
@[simp] lemma one {h₁ : is_integral A (1:B)} :
  minpoly h₁ = X - 1 :=
by simpa only [ring_hom.map_one, C_1, sub_eq_add_neg]
  using eq_X_sub_C B (1:A)

end ring

section domain
variables [domain B] [algebra A B]
variables {x : B} (hx : is_integral A x)

/-- A minimal polynomial is prime. -/
lemma prime : prime (minpoly hx) :=
begin
  refine ⟨ne_zero hx, not_is_unit hx, _⟩,
  rintros p q ⟨d, h⟩,
  have :    polynomial.aeval x (p*q) = 0 := by simp [h, aeval hx],
  replace : polynomial.aeval x p = 0 ∨ polynomial.aeval x q = 0 := by simpa,
  exact or.imp (dvd hx) (dvd hx) this
end

/-- If `L/K` is a field extension and an element `y` of `K` is a root of the minimal polynomial
of an element `x ∈ L`, then `y` maps to `x` under the field embedding. -/
lemma root {x : B} (hx : is_integral A x) {y : A} (h : is_root (minpoly hx) y) :
  algebra_map A B y = x :=
have key : minpoly hx = X - C y :=
eq_of_monic_of_associated (monic hx) (monic_X_sub_C y) (associated_of_dvd_dvd
  (dvd_symm_of_irreducible (irreducible_X_sub_C y) (irreducible hx) (dvd_iff_is_root.2 h))
  (dvd_iff_is_root.2 h)),
by { have := aeval hx, rwa [key, alg_hom.map_sub, aeval_X, aeval_C, sub_eq_zero, eq_comm] at this }

/--The constant coefficient of the minimal polynomial of x is 0
if and only if x = 0.-/
@[simp] lemma coeff_zero_eq_zero : coeff (minpoly hx) 0 = 0 ↔ x = 0 :=
begin
  split,
  { intro h,
    have zero_root := zero_is_root_of_coeff_zero_eq_zero h,
    rw ← root hx zero_root,
    exact ring_hom.map_zero _ },
  { rintro rfl, simp }
end

/--The minimal polynomial of a nonzero element has nonzero constant coefficient.-/
lemma coeff_zero_ne_zero (h : x ≠ 0) : coeff (minpoly hx) 0 ≠ 0 :=
by { contrapose! h, simpa using h }

end domain

end field

end minpoly
