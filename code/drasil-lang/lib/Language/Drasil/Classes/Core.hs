-- | Defining the core classes which represent knowledge-about-knowledge.
module Language.Drasil.Classes.Core (
    HasRefAddress(getRefAdd)
  , HasSymbol(symbol)
  , Referable(refAdd, renderRef)
  ) where

import Language.Drasil.Stages (Stage)
import Language.Drasil.Symbol (Symbol)
import Language.Drasil.UID
import Language.Drasil.Label.Type (LblType)

-- | A HasSymbol is anything which has a 'Symbol'.
class HasSymbol c where
  -- | Provides the 'Symbol' for a particular stage of generation.
  symbol  :: c -> Stage -> Symbol
 
-- | Members must have a reference address.
class HasRefAddress b where
  -- | Provides the ability to hold a reference address.
  getRefAdd :: b -> LblType

-- | Members of this class have the ability to be referenced.
class (HasUID s, HasRefAddress s) => Referable s where
  -- | The referencing address (what we're linking to).
  -- Only visible in the source (tex/html).
  refAdd    :: s -> String 
  -- | Alternate form of reference.
  renderRef :: s -> LblType 
