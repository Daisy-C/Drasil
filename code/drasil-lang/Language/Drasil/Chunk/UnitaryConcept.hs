{-# Language TemplateHaskell #-}
module Language.Drasil.Chunk.UnitaryConcept (ucw, UnitaryConceptDict) where

import Control.Lens ((^.), makeLenses)

import Language.Drasil.Chunk.Unitary (UnitaryChunk, mkUnitary, Unitary(unit))
import Language.Drasil.Classes.Core (HasUID(uid), HasSymbol(symbol))
import Language.Drasil.Classes (NamedIdea(term), Idea(getA), Quantity, Concept,
  Definition(defn), ConceptDomain(cdom), HasSpace(typ))
import Language.Drasil.Chunk.UnitDefn (MayHaveUnit(getUnit))
import Language.Drasil.Sentence (Sentence)
import Language.Drasil.UID (UID)

-- | Contains a 'UnitaryChunk', a definition, and a list of related 'UID's.
data UnitaryConceptDict = UCC { _unitary :: UnitaryChunk
                              , _defn' :: Sentence
                              , cdom' :: [UID]
                              }
makeLenses ''UnitaryConceptDict

instance HasUID        UnitaryConceptDict where uid = unitary . uid
-- ^ Finds 'UID' of the 'UnitaryChunk' used to make the 'UnitaryConceptDict'.
instance NamedIdea     UnitaryConceptDict where term = unitary . term
-- ^ Finds term ('NP') of the 'UnitaryChunk' used to make the 'UnitaryConceptDict'.
instance Idea          UnitaryConceptDict where getA u = getA (u ^. unitary)
-- ^ Finds the idea contained in the 'UnitaryChunk' used to make the 'UnitaryConceptDict'.
instance Definition    UnitaryConceptDict where defn = defn'
-- ^ Finds definition of the 'UnitaryConceptDict'.
instance ConceptDomain UnitaryConceptDict where cdom = cdom'
-- ^ Finds the domain of the 'UnitaryConceptDict'.
instance HasSpace      UnitaryConceptDict where typ = unitary . typ
-- ^ Finds the 'Space' of the 'UnitaryChunk' used to make the 'UnitaryConceptDict'.
instance HasSymbol     UnitaryConceptDict where symbol c = symbol (c^.unitary)
-- ^ Finds the 'Symbol' of the 'UnitaryChunk' used to make the 'UnitaryConceptDict'.
instance Quantity      UnitaryConceptDict where
-- ^ 'UnitaryConceptDict's have a 'Quantity'. 
instance Eq            UnitaryConceptDict where a == b = (a ^. uid) == (b ^. uid)
-- ^ Equal if 'UID's are equal.
instance MayHaveUnit   UnitaryConceptDict where getUnit u = getUnit $ u ^. unitary
-- ^ Finds the units of the 'UnitaryChunk' used to make the 'UnitaryConceptDict'.
instance Unitary       UnitaryConceptDict where unit x = unit (x ^. unitary)
-- ^ Finds the quantity of the 'UnitaryChunk' used to make the 'UnitaryConceptDict'.


-- | Constructs a UnitaryConceptDict from a 'Concept' with 'Units'.
ucw :: (Unitary c, Concept c, MayHaveUnit c) => c -> UnitaryConceptDict
ucw c = UCC (mkUnitary c) (c ^. defn) (cdom c)
