open import Coinduction using ( ∞ ; ♭ ; ♯_ )
open import Data.Empty using ( ⊥ )
open import Data.Bool using ( Bool ; true ; false ; if_then_else_ )
open import Data.Product using ( ∃ ; _×_ ; _,_ ; ,_ )
open import Data.Strict using ( Strict ; ! )
open import Data.Sum using ( _⊎_ ; inj₁ ; inj₂ )
open import Data.Unit using ( ⊤ ; tt )
open import System.IO.Transducers.Session
  using ( Session ; I ; Σ ; _∼_ ; ∼-sym ; Γ ; _/_ ; IsΣ ; ⟨_⟩ ; _&_ ; ¿ ; _+_  )
  renaming ( unit₁ to ∼-unit₁ ; unit₂ to ∼-unit₂ ; assoc to ∼-assoc )
open import System.IO.Transducers.Trace using ( _≥_ ; _≤_ ; Trace ; _⊑_ ; [] ; [✓] ; _∷_ )
open import Relation.Binary.PropositionalEquality using ( _≡_ ; refl )

module System.IO.Transducers.Lazy where

-- S ⇛ T is the type of transducers whose inputs
-- are traces through S, and whose output are traces through T.

-- Note that input is coinductive, but output is inductive,
-- which guarantees that transducers will map finite traces
-- to finite traces.

-- The name transducer comes from automata theory -- these
-- are essentially I/O automata, or strategies in a two-player 
-- game without the move alternation restriction.

-- In this module, we give definitions for lazy transducers,
-- there is a separate module for stict transducers.

infixr 4 _⇒_ _≃_ _≲_ 
infixr 6 _⟫_
infixr 8 _[&]_ _⟨&⟩_ _⟨+⟩_ _⟨¿⟩_

-- Lazy transducers, which may perform output before input.
-- A bit of hoop-jumping here, to get S ⇒ T to be a Set rather than a Set₁.

data _⇒_ (S T : Session) : Set where
  inp : {isΣ : IsΣ S} → ∞ (∀ a → (S / a ⇒ T)) → (S ⇒ T)
  out : ∀ b → (S ⇒ T / b) → (S ⇒ T)
  id : (S ≡ T) → (S ⇒ T)

-- Identity transducer

done : ∀ {S} → (S ⇒ S)
done = id refl

-- Helper function to output a whole trace.

out* : ∀ {S T U} → (T ≤ U) → (S ⇒ T) → (S ⇒ U)
out* []       P = P
out* (b ∷ bs) P = out* bs (out b P)

-- Semantics as a function from partial traces to partial traces

⟦_⟧ : ∀ {S T} → (S ⇒ T) → (Trace S) → (Trace T)
⟦ inp P   ⟧ []       = []
⟦ inp P   ⟧ (a ∷ as) = ⟦ ♭ P a ⟧ as
⟦ out b P ⟧ as       = b ∷ ⟦ P ⟧ as
⟦ id refl ⟧ as       = as
⟦_⟧ {I}     (inp {} P) [✓]
⟦_⟧ {Σ V F} (inp P)    ([✓] {})

-- Extensional equivalence on trace functions

_≃_ : ∀ {S T} → (f g : Trace S → Trace T) → Set
f ≃ g = ∀ as → f as ≡ g as

-- Improvement order on trace functions

_≲_ : ∀ {S T} → (f g : Trace S → Trace T) → Set
f ≲ g = ∀ as → f as ⊑ g as

-- Equivalent sessions give rise to a transducer

equiv : ∀ {S T} → (S ∼ T) → (S ⇒ T)
equiv I       = done
equiv (Σ V F) = inp (♯ λ a → out a (equiv (♭ F a)))

-- Transducers form a category with composition given by 
-- parallel (data flow) composition.  This is defined by the
-- usual expansion laws for parallel composition, together with
-- the unit law for done.  Since composition is deterministic,
-- we prioritize output over input.

_⟫_ : ∀ {S T U} → (S ⇒ T) → (T ⇒ U) → (S ⇒ U)
_⟫_         (id refl)  Q         = Q
_⟫_         P          (id refl) = P
_⟫_         P          (out b Q) = out b (P ⟫ Q)
_⟫_         (out b P)  (inp Q)   = P ⟫ ♭ Q b
_⟫_ {I}     (inp {} P) Q
_⟫_ {Σ V F} (inp P)    Q         = inp (♯ λ a → ♭ P a ⟫ Q)

-- Delay a process

delay : ∀ S {T U} → (T ⇒ U) → (S & T) ⇒ U
delay I       P         = P
delay (Σ V F) (out b P) = out b (delay (Σ V F) P)
delay (Σ V F) P         = inp (♯ λ a → delay (♭ F a) P)

-- The category has monoidal structure given by &, with
-- action on morphisms:
 
_[&]_ : ∀ {S T U V} → (S ⇒ T) → (U ⇒ V) → ((S & U) ⇒ (T & V))
_[&]_ {Σ V F}          (inp P)    Q = inp (♯ λ a → ♭ P a [&] Q)
_[&]_ {S}      {Σ W G} (out b P)  Q = out b (P [&] Q)
_[&]_ {I}              (id refl)  Q = Q
_[&]_ {Σ V F}          (id refl)  Q = inp (♯ λ a → out a (done {♭ F a} [&] Q))
_[&]_ {I}              (inp {} P) Q
_[&]_ {S}      {I}     (out () P) Q

-- Units for &

unit₁ : ∀ {S} → (I & S) ⇒ S
unit₁ = equiv ∼-unit₁

unit₁⁻¹ : ∀ {S} → S ⇒ (I & S)
unit₁⁻¹ = equiv (∼-sym ∼-unit₁)

unit₂ : ∀ {S} → (S & I) ⇒ S
unit₂ = equiv ∼-unit₂

unit₂⁻¹ : ∀ {S} → S ⇒ (S & I)
unit₂⁻¹ = equiv (∼-sym ∼-unit₂)

-- Associativity of &

assoc : ∀ {S T U} → (S & (T & U)) ⇒ ((S & T) & U)
assoc {S} = equiv (∼-assoc {S})

assoc⁻¹ : ∀ {S T U} → ((S & T) & U) ⇒ (S & (T & U))
assoc⁻¹ {S} = equiv (∼-sym (∼-assoc {S}))

-- Discard all input

discard : ∀ {S} → (S ⇒ I)
discard {I}     = done
discard {Σ V F} = inp (♯ λ a → discard)

-- The projection morphisms for [] and &:

π₁ : ∀ {S T} → ((S & T) ⇒ S)
π₁ {I}     = discard
π₁ {Σ W F} = inp (♯ λ a → out a π₁)

π₂ : ∀ {S T} → ((S & T) ⇒ T)
π₂ {I}     = done
π₂ {Σ W F} = inp (♯ λ a → π₂ {♭ F a})

-- The category is almost cartesian, at the cost of
-- buffering.  WARNING.  BUFFERING.  This is bad.  Do not do this.

-- The "almost" is due to a failure of the projection properties:
-- P ⟨&⟩ Q ⟫ π₂ is not equivalent to Q, since Q may do output immediately,
-- and P ⟨&⟩ Q ⟫ π₂ can only output after it has consumed all its input.
-- Similarly π₁ ⟨&⟩ π₂ is not equivalent to done, as π₂'s output will
-- be bufferred.

-- This implementation uses output buffering, hopefully output
-- is usually smaller than input.

buffer : ∀ {S T U V} → (S ⇒ T) → (S ⇒ U) → (U ≤ V) → (S ⇒ T & V)
buffer {I}             (inp {} P) Q         cs
buffer {Σ V F} {I}     (inp P)    Q         cs = out* cs Q
buffer {Σ V F} {Σ W G} (inp P)    (inp Q)   cs = inp (♯ λ a → buffer (♭ P a) (♭ Q a) cs)
buffer {Σ V F} {Σ W G} (inp P)    (out c Q) cs = buffer (inp P) Q (c ∷ cs)
buffer {Σ V F} {Σ W G} (inp P)    (id refl) cs = inp (♯ λ c → buffer (♭ P c) done (c ∷ cs))
buffer {S}     {I}     (out () P) Q         cs
buffer {S}     {Σ W G} (out b P)  Q         cs = out b (buffer P Q cs)
buffer {I}             (id refl)  Q         cs = out* cs Q
buffer {Σ V F}         (id refl)  (inp Q)   cs = inp (♯ λ a → out a (buffer done (♭ Q a) cs))
buffer {Σ V F}         (id refl)  (out c Q) cs = buffer done Q (c ∷ cs)
buffer {Σ V F}         (id refl)  (id refl) cs = inp (♯ λ c → out c (buffer done done (c ∷ cs)))

_⟨&⟩_ : ∀ {S T U} → (S ⇒ T) → (S ⇒ U) → (S ⇒ T & U)
P ⟨&⟩ Q = buffer P Q []

-- If you want input buffering, you can implement it using copy and _[&]_.

copy : ∀ {S} → (S ⇒ (S & S))
copy = done ⟨&⟩ done

swap : ∀ {S T} → ((S & T) ⇒ (T & S))
swap {S} = π₂ {S} ⟨&⟩ π₁ {S}

-- Lazy coproduct structure.

ι₁ : ∀ {S T} → (S ⇒ S + T)
ι₁ = out true done

ι₂ : ∀ {S T} → (T ⇒ S + T)
ι₂ = out false done

choice : ∀ {S T U} → (S ⇒ U) → (T ⇒ U) → ∀ b → ((if b then S else T) ⇒ U)
choice P Q true  = P
choice P Q false = Q

_[+]_ : ∀ {S T U V} → (S ⇒ U) → (T ⇒ V) → ((S + T) ⇒ (U + V))
P [+] Q = inp (♯ choice (out true P) (out false Q))

_⟨+⟩_ : ∀ {S T U} → (S ⇒ U) → (T ⇒ U) → ((S + T) ⇒ U)
P ⟨+⟩ Q = inp (♯ choice P Q)

-- Options.

some : ∀ {S} → (S ⇒ ¿ S)
some = ι₁

none : ∀ {S} → (I ⇒ ¿ S)
none = ι₂

[¿] : ∀ {S T} → (S ⇒ T) → (¿ S ⇒ ¿ T)
[¿] P = P [+] done

_⟨¿⟩_ : ∀ {S T} → (S ⇒ T) → (I ⇒ T) → (¿ S ⇒ T)
P ⟨¿⟩ Q = P ⟨+⟩ Q
