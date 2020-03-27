import tactic
import data.fin

universe variables v v₁ v₂ v₃ u u₁ u₂ u₃

set_option old_structure_cmd true

structure multigraph (V : Type u) :=
(edge : V → V → Sort v)

attribute [class] multigraph

def multigraph.vertices {V : Type u} (G : multigraph V) := V

structure directed_graph (V : Type u) extends multigraph.{0} V.

attribute [class] directed_graph

def directed_graph.vertices {V : Type u} (G : directed_graph V) := V

structure graph (V : Type u) extends directed_graph V :=
(symm {} : symmetric edge)

attribute [class] graph

notation x `~[`G`]` y := G.edge x y

namespace graph
variables {V : Type u} {V₁ : Type u₁} {V₂ : Type u₂} {V₃ : Type u₃}
variables (G : graph V) (G₁ : graph V₁) (G₂ : graph V₂) (G₃ : graph V₃)

def vertices (G : graph V) := V

def edge.symm {G : graph V} {x y : V} (e : x ~[G] y) : y ~[G] x := G.symm e

def is_linked (G : graph V) (x y : V) : Prop :=
relation.refl_trans_gen G.edge x y

def is_connected (G : graph V) : Prop :=
∀ {x y}, G.is_linked x y

def is_loopless (G : graph V) : Prop :=
∀ {x}, ¬ (x ~[G] x)

def complete (V : Type u) : graph V :=
{ edge := assume x y, x ≠ y,
  symm := assume x y h, h.symm }

lemma complete_is_loopless (V : Type u) :
  (complete V).is_loopless :=
assume x, ne.irrefl

section

/-- A homomorphism of graphs is a function on the vertices that preserves edges. -/
structure hom (G₁ : graph V₁) (G₂ : graph V₂) :=
(to_fun    : V₁ → V₂)
(map_edge' : ∀ {x y}, (x ~[G₁] y) → (to_fun x ~[G₂] to_fun y) . obviously)

instance hom.has_coe_to_fun : has_coe_to_fun (hom G₁ G₂) :=
{ F := λ f, V₁ → V₂,
  coe := hom.to_fun }

@[simp] lemma hom.to_fun_eq_coe (f : hom G₁ G₂) (x : V₁) :
  f.to_fun x = f x := rfl

section
variables {G₁ G₂ G₃}

@[simp, ematch] lemma hom.map_edge (f : hom G₁ G₂) :
  ∀ {x y}, (x ~[G₁] y) → (f x ~[G₂] f y) :=
f.map_edge'

@[ext] lemma hom.ext {f g : hom G₁ G₂} (h : (f : V₁ → V₂) = g) : f = g :=
by { cases f, cases g, congr, exact h }

lemma hom.ext_iff (f g : hom G₁ G₂) : f = g ↔ (f : V₁ → V₂) = g :=
⟨congr_arg _, hom.ext⟩

def hom.id : hom G G :=
{ to_fun := id }

def hom.comp (g : hom G₂ G₃) (f : hom G₁ G₂) : hom G₁ G₃ :=
{ to_fun    := g ∘ f,
  map_edge' := assume x y, g.map_edge ∘ f.map_edge }

end

/-- The internal hom in the category of graphs. -/
instance ihom : graph (V₁ → V₂) :=
{ edge := assume f g, ∀ {x y}, (x ~[G₁] y) → (f x ~[G₂] g y),
  symm := assume f g h x y e,
          show g x ~[G₂] f y, from G₂.symm $ h e.symm }

/-- The product in the category of graphs. -/
instance prod : graph (V₁ × V₂) :=
{ edge := assume p q, (p.1 ~[G₁] q.1) ∧ (p.2 ~[G₂] q.2),
  symm := assume p q ⟨e₁, e₂⟩, ⟨e₁.symm, e₂.symm⟩ }

def prod.fst : hom (G₁.prod G₂) G₁ :=
{ to_fun := λ p, p.1 }

def prod.snd : hom (G₁.prod G₂) G₂ :=
{ to_fun := λ p, p.2 }

@[simps]
def hom.pair (f : hom G G₁) (g : hom G G₂) : hom G (G₁.prod G₂) :=
{ to_fun    := λ x, (f x, g x),
  map_edge' := by { intros x y e, split; simp only [e, hom.map_edge] } }

@[simps]
def icurry : hom ((G₁.prod G₂).ihom G₃) (G₁.ihom (G₂.ihom G₃)) :=
{ to_fun    := function.curry,
  map_edge' := assume f g h x₁ y₁ e₁ x₂ y₂ e₂, h $ by exact ⟨e₁, e₂⟩ }

@[simps]
def iuncurry : hom (G₁.ihom (G₂.ihom G₃)) ((G₁.prod G₂).ihom G₃) :=
{ to_fun    := λ f p, f p.1 p.2,
  map_edge' := assume f g h p q e, h e.1 e.2 }

section
variables {G₁ G₂ G₃}

@[simps]
def hom.curry (f : hom (G₁.prod G₂) G₃) : hom G₁ (G₂.ihom G₃) :=
{ to_fun    := icurry G₁ G₂ G₃ f,
  map_edge' := assume x₁ y₁ e₁ x₂ y₂ e₂, f.map_edge ⟨e₁, e₂⟩ }

@[simps]
def hom.uncurry (f : hom G₁ (G₂.ihom G₃)) : hom (G₁.prod G₂) G₃ :=
{ to_fun    := iuncurry G₁ G₂ G₃ f,
  map_edge' := assume p q e, f.map_edge e.1 e.2 }

end

def adj : (hom (G.prod G₁) G₂) ≃ (hom G (graph.ihom G₁ G₂)) :=
{ to_fun := hom.curry,
  inv_fun := hom.uncurry,
  left_inv := λ f, hom.ext $ funext $ λ ⟨x,y⟩, rfl,
  right_inv := λ f, hom.ext $ funext $ λ p, rfl }

end

def colouring (W : Type) (G : graph V) := hom G (complete W)

structure is_nat_colouring (n : ℕ) (G : graph V) (f : V → ℕ) : Prop :=
(is_lt : ∀ x, f x < n)
(edge  : ∀ {x y}, (x ~[G] y) → f x ≠ f y)

structure chromatic_number (G : graph V) (n : ℕ) : Prop :=
(col_exists : ∃ f, is_nat_colouring n G f)
(min        : ∀ {k f}, is_nat_colouring k G f → n ≤ k)

def is_nat_colouring.colouring_fin {n} {G : graph V} {f} (h : is_nat_colouring n G f) :
  G.colouring (fin n) :=
{ to_fun    := λ x, ⟨f x, h.is_lt x⟩,
  map_edge' := λ x y e H, h.edge e $ fin.veq_of_eq H }

variables {G₁ G₂}

lemma is_nat_colouring.comp
  {n} {g} (h : is_nat_colouring n G₂ g) (f : hom G₁ G₂) :
  is_nat_colouring n G₁ (g ∘ f) :=
{ is_lt := assume x, h.is_lt _,
  edge  := assume x y e, h.edge $ f.map_edge e }

section hedetniemi
variables {n₁ n₂ n : ℕ}
variables (h₁ : chromatic_number G₁ n₁)
variables (h₂ : chromatic_number G₂ n₂)
variables (h : chromatic_number (G₁.prod G₂) n)

include h₁ h₂ h

/-- Hedetniemi's conjecture, which has been disproven in <https://arxiv.org/pdf/1905.02167.pdf>. -/
def hedetniemi : Prop :=
n = min n₁ n₂

lemma chromatic_number_prod_le_min : n ≤ min n₁ n₂ :=
begin
  obtain ⟨f₁, hf₁⟩ : ∃ f₁ : V₁ → ℕ, is_nat_colouring n₁ G₁ f₁ := h₁.col_exists,
  obtain ⟨f₂, hf₂⟩ : ∃ f₂ : V₂ → ℕ, is_nat_colouring n₂ G₂ f₂ := h₂.col_exists,
  have c₁ : is_nat_colouring n₁ (G₁.prod G₂) (f₁ ∘ _) := hf₁.comp (prod.fst G₁ G₂),
  have c₂ : is_nat_colouring n₂ (G₁.prod G₂) (f₂ ∘ _) := hf₂.comp (prod.snd G₁ G₂),
  rw le_min_iff,
  split,
  { exact h.min c₁ },
  { exact h.min c₂ }
end

end hedetniemi

lemma chromatic_number.is_loopless {n} (h : chromatic_number G n) :
  G.is_loopless :=
begin
  assume x e,
  rcases h.col_exists with ⟨f, hf⟩,
  exact hf.edge e rfl,
end

lemma chromatic_number_le_card [fintype V] {n m}
 (hn : chromatic_number G n) (hm : m = fintype.card V) :
  n ≤ m :=
begin
  obtain ⟨k, ⟨f⟩⟩ : ∃ k, nonempty (V ≃ fin k) :=
    fintype.exists_equiv_fin V,
  obtain rfl : m = k,
  { rw [hm, fintype.card_congr f, fintype.card_fin] },
  suffices c : is_nat_colouring m G (λ x, f x),
  { exact hn.min c },
  refine
  { is_lt := assume x, (f x).is_lt,
    edge  := assume x y e H, _ },
  obtain rfl : x = y := f.injective (fin.eq_of_veq H),
  exact hn.is_loopless G e
end

end graph
