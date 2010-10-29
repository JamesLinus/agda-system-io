open import Coinduction using ( ♭ )
open import Relation.Binary.PropositionalEquality using ( _≡_ ; refl ; sym ; cong )
open import System.IO.Transducers using ( _⇒_ ; inp ; out ; done ; _⟫_ ; ⟦_⟧ ; _≃_ )
open import System.IO.Transducers.Trace using ( Trace ; [] ; _∷_ )

module System.IO.Transducers.Properties.Category where

open Relation.Binary.PropositionalEquality.≡-Reasoning

-- Trace semantics of identity

⟦done⟧ : ∀ {S} → (Trace S)  → (Trace S)
⟦done⟧ as = as

done-semantics  : ∀ {S} → ⟦ done {S} ⟧ ≃ ⟦done⟧
done-semantics as = refl

-- Trace semantics of composition

_⟦⟫⟧_ : ∀ {S T U} → 
  (f : Trace S → Trace T) → (g : Trace T → Trace U) → 
    (Trace S) → (Trace U)
(f ⟦⟫⟧ g) as = g (f as)

⟫-semantics : ∀ {S T U} → 
  (P : S ⇒ T) → (Q : T ⇒ U) →
    (⟦ P ⟫ Q ⟧ ≃ ⟦ P ⟧ ⟦⟫⟧ ⟦ Q ⟧)
⟫-semantics P         (out c Q) as       = cong (_∷_ c) (⟫-semantics P Q as)
⟫-semantics (inp F)   (inp G)   []       = refl
⟫-semantics (inp F)   (inp G)   (a ∷ as) = ⟫-semantics (♭ F a) (inp G) as
⟫-semantics (inp F)   done      []       = refl
⟫-semantics (inp F)   done      (a ∷ as) = ⟫-semantics (♭ F a) done as
⟫-semantics (out b P) (inp G)   as       = ⟫-semantics P (♭ G b) as
⟫-semantics (out b P) done      as       = refl
⟫-semantics done      (inp G)   as       = refl
⟫-semantics done      done      as       = refl

-- Composition respects ≃

⟫-resp-≃ : ∀ {S T U} (P₁ P₂ : S ⇒ T) (Q₁ Q₂ : T ⇒ U) → (⟦ P₁ ⟧ ≃ ⟦ P₂ ⟧) → (⟦ Q₁ ⟧ ≃ ⟦ Q₂ ⟧) → (⟦ P₁ ⟫ Q₁ ⟧ ≃ ⟦ P₂ ⟫ Q₂ ⟧)
⟫-resp-≃ P₁ P₂ Q₁ Q₂ P₁≃P₂ Q₁≃Q₂ as =
  begin
    ⟦ P₁ ⟫ Q₁ ⟧ as
  ≡⟨ ⟫-semantics P₁ Q₁ as ⟩
    ⟦ Q₁ ⟧ (⟦ P₁ ⟧ as)
  ≡⟨ cong ⟦ Q₁ ⟧ (P₁≃P₂ as) ⟩
    ⟦ Q₁ ⟧ (⟦ P₂ ⟧ as)
  ≡⟨ Q₁≃Q₂ (⟦ P₂ ⟧ as) ⟩
    ⟦ Q₂ ⟧ (⟦ P₂ ⟧ as)
  ≡⟨ sym (⟫-semantics P₂ Q₂ as) ⟩
    ⟦ P₂ ⟫ Q₂ ⟧ as
  ∎

-- Left identity of composition

⟫-identity₁ : ∀ {S T} (P : S ⇒ T) → ⟦ done ⟫ P ⟧ ≃ ⟦ P ⟧
⟫-identity₁ P = ⟫-semantics done P

-- Right identity of composition

⟫-identity₂ : ∀ {S T} (P : S ⇒ T) → ⟦ P ⟫ done ⟧ ≃ ⟦ P ⟧
⟫-identity₂ P = ⟫-semantics P done

-- Associativity of composition

⟫-assoc : ∀ {S T U V} (P : S ⇒ T) (Q : T ⇒ U) (R : U ⇒ V) → ⟦ (P ⟫ Q) ⟫ R ⟧ ≃ ⟦ P ⟫ (Q ⟫ R) ⟧
⟫-assoc P Q R as =
  begin
    ⟦ (P ⟫ Q) ⟫ R ⟧ as
  ≡⟨ ⟫-semantics (P ⟫ Q) R as ⟩
    ⟦ R ⟧ (⟦ P ⟫ Q ⟧ as)
  ≡⟨ cong ⟦ R ⟧ (⟫-semantics P Q as) ⟩
    ⟦ R ⟧ (⟦ Q ⟧ (⟦ P ⟧ as))
  ≡⟨ sym (⟫-semantics Q R (⟦ P ⟧ as)) ⟩
    ⟦ Q ⟫ R ⟧ (⟦ P ⟧ as)
  ≡⟨ sym (⟫-semantics P (Q ⟫ R) as) ⟩
    ⟦ P ⟫ (Q ⟫ R) ⟧ as
  ∎