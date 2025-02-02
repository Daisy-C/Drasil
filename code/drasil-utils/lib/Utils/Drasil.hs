-- | Gather Drasil's utility functions and re-export for easy use.
-- For now, does not include combinators (Sentence.hs, NounPhrase.hs, Concepts.hs)
module Utils.Drasil (
  -- * Documents
  -- | From "Utils.Drasil.Document".
  blank, indent, indentList,

  -- * Language
  -- | From "Utils.Drasil.English".
  capitalize, stringList,
  
  -- * Lists
  -- | From "Utils.Drasil.Lists". General functions involving lists.
  replaceAll, subsetOf, nubSort, weave,

  -- ** Strings
  toPlainName
) where

import Utils.Drasil.Document
import Utils.Drasil.English
import Utils.Drasil.Lists
import Utils.Drasil.Strings

{-


  -- * Content
  -- | From "Utils.Drasil.Contents".
  enumBullet, enumBulletU, enumSimple, enumSimpleU, mkEnumSimpleD,
  lbldExpr, unlbldExpr,

  -- * Fold-type utilities.
  -- | From "Utils.Drasil.Fold". Defines many general fold functions
  -- for use with Drasil-related types.

  -- ** Folding Options as Types
  EnumType(..), WrapType(..), SepType(..), FoldType(..),

  -- ** Folding functions
  -- *** Expression-related
  foldConstraints,

  -- *** Sentence-related
  foldlEnumList, foldlList, foldlSP, foldlSP_, foldlSPCol, foldlSent,
  foldlSent_,foldlSentCol, foldlsC, foldNums, numList,
  
  -- * Misc. utilities
  -- | From "Utils.Drasil.Misc". General sorting functions, useful combinators,
  -- and various functions to work with Drasil [Chunk](https://github.com/JacquesCarette/Drasil/wiki/Chunks) types.
  
  -- ** Reference-related functions
  -- | Attach a 'Reference' and a 'Sentence' in different ways.
  chgsStart, definedIn, definedIn', definedIn'', definedIn''',
  eqnWSource, fromReplace, fromSource, fromSources, fmtU, follows,
  makeListRef,

  -- ** Sentence-related functions
  -- | See Reference-related functions as well.
  addPercent, displayStrConstrntsAsSet, displayDblConstrntsAsSet,
  eqN, checkValidStr, getTandS, maybeChanged, maybeExpanded,
  maybeWOVerb, showingCxnBw, substitute, typUncr, underConsidertn,
  unwrap, fterms,

  -- ** List-related functions
  bulletFlat, bulletNested, itemRefToSent, makeTMatrix, mkEnumAbbrevList,
  mkTableFromColumns, noRefs, refineChain, sortBySymbol, sortBySymbolTuple,
  tAndDOnly, tAndDWAcc, tAndDWSym,
  weave, zipSentList,
-}
