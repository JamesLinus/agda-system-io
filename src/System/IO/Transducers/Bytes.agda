open import Coinduction using ( ♯_ )
open import Data.Bool using ( Bool ; true ; false ; not )
open import Data.ByteString using ( null ) renaming ( span to #span )
open import Data.Natural using ( Natural )
open import Data.Product using ( _×_ ; _,_ )
open import Data.Word using ( Byte )
open import System.IO.Transducers.Lazy using ( _⇒_ ; inp ; out ; done ; _⟫_ ; π₁ ; π₂ ; _[&]_ )
open import System.IO.Transducers.Weight using ( weight )
open import System.IO.Transducers.Stateful using ( loop )
open import System.IO.Transducers.Session using ( ⟨_⟩ ; _&_ ; ¿ ; * ; _&*_ )
open import System.IO.Transducers.Strict using ( _⇛_ )

module System.IO.Transducers.Bytes where

open System.IO.Transducers.Session public using ( Bytes ; Bytes' )

mutual

  span' : (Byte → Bool) → Bytes' ⇛ (Bytes & Bytes)
  span' φ x with #span φ x
  span' φ x | (x₁ , x₂) with null x₁ | null x₂ 
  span' φ x | (x₁ , x₂) | true  | true  = inp (♯ span φ)
  span' φ x | (x₁ , x₂) | true  | false = out false (out true (out x₂ done))
  span' φ x | (x₁ , x₂) | false | true  = out true (out x₁ (inp (♯ span φ)))
  span' φ x | (x₁ , x₂) | false | false = out true (out x₁ (out false (out true (out x₂ done))))
  
  span : (Byte → Bool) → Bytes ⇛ (Bytes & Bytes)
  span φ false = out false (out false done)
  span φ true  = inp (♯ span' φ)

break : (Byte → Bool) → Bytes ⇛ (Bytes & Bytes)
break φ = span (λ x → not (φ x))

mutual

  nonempty' : Bytes' & Bytes ⇛ ¿ Bytes & Bytes
  nonempty' x with null x
  nonempty' x | true  = inp (♯ nonempty)
  nonempty' x | false = out true (out true (out x done))

  nonempty : Bytes & Bytes ⇛ ¿ Bytes & Bytes
  nonempty true  = inp (♯ nonempty')
  nonempty false = out false done

split? : (Byte → Bool) → Bytes ⇒ (¿ Bytes & Bytes)
split? φ = inp (♯ span φ) ⟫ π₂ {Bytes} ⟫ inp (♯ break φ) ⟫ inp (♯ nonempty)

split : (Byte → Bool) → Bytes ⇒ * Bytes
split φ = loop {Bytes} (split? φ) ⟫ π₁

bytes : Bytes ⇒ ⟨ Natural ⟩
bytes = weight
