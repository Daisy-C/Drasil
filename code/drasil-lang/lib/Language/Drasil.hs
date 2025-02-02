-- | The Drasil language, including expressions, chunks, sentences, references,
-- classes, datatypes, and generally useful functions. Re-exports modules to simplify external use.
module Language.Drasil (
  -- * The Drasil Expression Language
  -- | Encodes mathematical and display related expressions.
  -- To see the code-related expressions, look in "Language.Drasil.Code".

  -- ** Base Expression Language
  -- | Defines the expression types and common operators.
  
  -- Language.Drasil.Expr
  Expr
  , ExprC(..) 
  , frac, recip_
  , square, half
  , oneHalf, oneThird
  , apply1, apply2
  , Completeness, Relation

  -- ** Literals Language
  , Literal
  , LiteralC(..)

  -- ** Expression Modelling Language 
  -- | Defines display-related expression functions. Used in models.

  -- Language.Drasil.Expr.ModelExpr
  , ModelExpr
  , DerivType
  , ModelExprC(..)
  -- ** Unicode symbols
  -- | Some expressions need special unicode characters.

  -- Language.Drasil.Unicode
  , Special(..), RenderSpecial(..)
  -- * The Drasil Language (Information Encoding)
  -- | This is the basis of the Drasil language for encoding information.
  -- Every chunk used in Drasil is defined here, along with some classes
  -- that help us to use these chunks.

  -- ** Classes
  -- | Contains many of the classes used in Drasil, along with their methods.

  -- *** Chunk-related
  -- Language.Drasil.Classes.Core
  , HasUID(uid)
  , HasSymbol(symbol)
  -- Language.Drasil.Classes
  , NamedIdea(term)
  , Idea(getA)
  , CommonIdea(abrv)
  , Definition(defn)
  , ConceptDomain(cdom)
  , Concept
  , HasSpace(typ)
  , HasUnitSymbol(usymb)
  , Quantity
  , HasReasVal(reasVal)
  , HasUncertainty(unc)
  , Constrained(constraints)
  , HasAdditionalNotes(getNotes)
  , HasDerivation(derivations)
  , IsUnit(getUnits)
  , DefiningExpr(defnExpr)
  , Express(express)
  -- *** References
  -- Language.Drasil.Classes.Core
  , HasRefAddress(getRefAdd)
  , Referable(..)
  -- Language.Drasil.Classes.Core2
  , HasShortName(shortname)
  -- Language.Drasil.Classes
  , HasReference(getReferences)
  , HasDecRef(getDecRefs)
  -- Language.Drasil.Classes.Document
  , HasCitation(getCitations)
  , HasFields(getFields)
  -- *** Programming-related
  , Callable
  , IsArgumentName
  -- ** Types
  -- | Contains helper functions and smart constructors for each type.
  -- Similar types are grouped together.
  
  -- *** Basic types
  , UID, mkUid
  -- Language.Drasil.Chunk.NamedIdea
  , (+++), (+++.), (+++!)
  , NamedChunk, nc, ncUID, IdeaDict , mkIdea
  , nw -- bad name (historical)
  -- Language.Drasil.Chunk.CommonIdea
  , CI, commonIdea, getAcc, getAccStr, commonIdeaWithDict, prependAbrv
  -- *** Concepts
  -- Language.Drasil.Chunk.Concept.Core
  , ConceptChunk, CommonConcept, ConceptInstance, sDom
  -- Language.Drasil.Chunk.Concept
  , dcc, dcc', dccWDS, dccWDS', cc, cc', ccs, cw, cic
  -- Language.Drasil.Chunk.Relation
  , RelationConcept, makeRC, addRelToCC
  -- *** Quantities and Units
  -- Language.Drasil.Chunk.Quantity
  , QuantityDict, qw, mkQuant, mkQuant', codeVC, implVar, implVar', implVarUID, implVarUID'
  , vc, vc'', vcSt, vcUnit
  -- Language.Drasil.Chunk.NamedArgument
  , NamedArgument, narg
  -- Language.Drasil.Chunk.Eq
  , QDefinition, fromEqn, fromEqn', fromEqnSt, fromEqnSt', fromEqnSt''
  , mkQDefSt, mkQuantDef, mkQuantDef', ec
  , mkFuncDef, mkFuncDef', mkFuncDefByQ
  -- Language.Drasil.Chunk.Unitary
  , Unitary(..), UnitaryChunk, unitary, unitary', mkUnitary, unit_symb
  -- Language.Drasil.Chunk.DefinedQuantity
  , DefinedQuantityDict, dqd, dqd', dqdNoUnit, dqdQd, dqdWr
  -- Language.Drasil.Chunk.Unital
  , UnitalChunk(..), makeUCWDS
  , uc, uc', ucStaged, ucs, ucs', ucsWS, ucuc, ucw
  -- Language.Drasil.Chunk.UnitDefn
  , UnitDefn(..)
  , fromUDefn, unitCon, makeDerU
  , (^:), (/:), (*:), (*$), (/$), (^$), newUnit
  , scale, shift
  , derUC, derUC', derUC''
  , fund, fund', compUnitDefn, derCUC, derCUC', derCUC''
  , unitWrapper, getCu, MayHaveUnit(getUnit)
  -- *** Constrained and Uncertain Values
  -- Language.Drasil.Constraint
  , ConstraintReason(..), Constraint(..), ConstraintE
  , physc, sfwrc, isPhysC, isSfwrC
  -- Language.Drasil.Chunk.Constrained
  , ConstrainedChunk(..), ConstrConcept(..)
  , cuc, cvc, constrained', cuc', cuc'', constrainedNRV'
  , cnstrw, cnstrw'
  -- Language.Drasil.Chunk.UncertainQuantity
  , UncertainChunk(..), UncertQ, uq, uqc, uqcND, uncrtnChunk, uvc
  , uncrtnw
  -- Language.Drasil.Uncertainty.Core
  , Uncertainty, uncty
  -- Language.Drasil.Uncertainty
  , defaultUncrt, uncVal, uncPrec, exact
  -- ** Referencing
  -- Language.Drasil.Label.Type
  , getAdd, prepend
  , LblType(RP, Citation, URI), IRefProg(..)
  -- Language.Drasil.Reference
  , Reference(..), ref, refS, namedRef, complexRef, namedComplexRef
  -- Language.Drasil.Decorated Reference
  , DecRef(refInfo), dRefInfo, dRef
  -- *** Citations
  -- Language.Drasil.Chunk.Citation
  , EntryID, Citation, BibRef
  -- accessors
  , citeID, citeKind
  -- smart constructors
  , cArticle, cBookA, cBookE, cBooklet
  , cInBookACP, cInBookECP, cInBookAC, cInBookEC, cInBookAP, cInBookEP
  , cInCollection, cInProceedings, cManual, cMThesis, cMisc, cPhDThesis
  , cProceedings, cTechReport, cUnpublished
  -- Language.Drasil.Data.Date
  , Month(..)
  -- Language.Drasil.Data.Citation; should be moved to Language.Drasil.Development
  , CiteField(..), HP(..), CitationKind(..)
    -- CiteFields smart constructors
      -- People -> CiteField
  , author, editor
      -- Sentence -> CiteField
  , address, bookTitle, howPublished, howPublishedU, institution, journal, note
  , organization, publisher, school, series, title, typeField
      -- Int -> CiteField
  , chapter, edition, number, volume, year
      -- [Int] -> CiteField
  , pages
      -- Month -> CiteField
  , month
  -- Language.Drasil.People
  , People, Person, person, HasName, name, person', personWM
  , personWM', mononym, nameStr, rendPersLFM, rendPersLFM', rendPersLFM''
  , comparePeople
  -- * Sentences
  -- | Things like expressions and terms are displayed by using 'Sentence's.
  -- We also use 'NounPhrase's to record the proper pluralization and capitalization of terms.

  -- Language.Drasil.Sentence
  , Sentence(..), SentenceStyle(..), TermCapitalization(..), RefInfo(..), (+:+), (+:+.), (+:), (!.), capSent
  , ch, eS, eS', sC, sDash, sParen  
  -- Language.Drasil.Sentence.Extract
  , sdep, shortdep
  -- Language.Drasil.NounPhrase
  , NounPhrase(..), NP, pn, pn', pn'', pn''', pnIrr, cn, cn', cn'', cn''', cnIP
  , cnIrr, cnIES, cnICES, cnIS, cnUM, nounPhrase, nounPhrase'
  , CapitalizationRule(..), atStartNP, atStartNP'
  , PluralRule(..)
  , compoundPhrase, compoundPhrase', compoundPhrase'', compoundPhrase''', compoundPhraseP1
  , titleizeNP, titleizeNP', nounPhrase'', nounPhraseSP, nounPhraseSent
  -- Language.Drasil.Development.Sentence
  , introduceAbb, phrase, plural, phrasePoss, pluralPoss, atStart, atStart'
  , titleize, titleize', short
  -- Language.Drasil.ShortName
  , ShortName, shortname', getSentSN
  -- Language.Drasil.Derivation
  , Derivation(Derivation), mkDeriv, mkDerivName, mkDerivNoHeader
  -- * Basic Document Language
  -- | Holds all the types and helper functions needed especially in @drasil-docLang@

  -- Language.Drasil.Document
  , Document(..), ShowTableOfContents(..), DType(..), Section(..)
  , Contents(..), SecCons(..), ListType(..), ItemType(..), ListTuple
  , LabelledContent(..), UnlabelledContent(..), extractSection
  , mkParagraph, mkRawLC, checkToC
  , llcc, ulcc
  , section, fig, figWithWidth
  , MaxWidthPercent
  , HasContents(accessContents)
  , RawContent(..)
  , mkFig
  , makeTabRef, makeFigRef, makeSecRef, makeEqnRef, makeURI
  , makeTabRef', makeFigRef', makeSecRef', makeEqnRef', makeURI'
  -- * Symbols, Stages, Spaces
  -- | Used for rendering mathematical symbols in Drasil.

  -- Language.Drasil.Space
  , Space(..)
  , RealInterval(..), Inclusive(..)
  , DomainDesc(..), RTopology(..), ContinuousDomainDesc, DiscreteDomainDesc
  , getActorName, getInnerSpace
  -- Language.Drasil.Symbol
  , Decoration, Symbol
  -- Language.Drasil.UnitLang
  , USymb(US)
  -- Language.Drasil.Misc
  , mkTable
  -- Language.Drasil.Stages
  , Stage(Equational,Implementation)
  -- Language.Drasil.Symbol.Helpers
  , eqSymb, codeSymb, hasStageSymbol
  , autoStage, hat, prime, staged, sub, subStr, sup , unicodeConv, upperLeft, vec
  , label, variable

  -- * Type Synonyms
  , ConstQDef, SimpleQDef, ModelQDef
  , PExpr,


  -- TODO: REMOVE ALL OF THE BELOW

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
  zipSentList,
) where

import Utils.Drasil.Contents
import Utils.Drasil.Fold
import Utils.Drasil.Misc

import Prelude hiding (log, sin, cos, tan, sqrt, id, return, print, break, exp, product)
import Language.Drasil.Expr.Class (ExprC(..),
  frac, recip_, square, half, oneHalf, oneThird, apply1, apply2)
import Language.Drasil.Expr.Lang (Expr, Completeness, Relation)
import Language.Drasil.Literal.Class (LiteralC(..))
import Language.Drasil.Literal.Lang (Literal)
import Language.Drasil.ModelExpr.Class (ModelExprC(..))
import Language.Drasil.ModelExpr.Lang (ModelExpr, DerivType)
import Language.Drasil.Document (section, fig, figWithWidth
  , Section(..), SecCons(..) , llcc, ulcc, Document(..)
  , mkParagraph, mkFig, mkRawLC, ShowTableOfContents(..), checkToC, extractSection
  , makeTabRef, makeFigRef, makeSecRef, makeEqnRef, makeURI
  , makeTabRef', makeFigRef', makeSecRef', makeEqnRef', makeURI')
import Language.Drasil.Document.Core (Contents(..), ListType(..), ItemType(..), DType(..)
  , RawContent(..), ListTuple, MaxWidthPercent
  , HasContents(accessContents)
  , LabelledContent(..), UnlabelledContent(..) )
import Language.Drasil.Unicode (RenderSpecial(..), Special(..))
import Language.Drasil.UID
    (UID, HasUID(..), (+++), (+++.), (+++!), mkUid)
import Language.Drasil.Classes.Core (HasSymbol(symbol),
  HasRefAddress(getRefAdd), Referable(refAdd, renderRef))
import Language.Drasil.Classes.Core2 (HasShortName(shortname))
import Language.Drasil.Classes (NamedIdea(term), Idea(getA),
  Definition(defn), ConceptDomain(cdom), Concept, HasUnitSymbol(usymb),
  IsUnit(getUnits), CommonIdea(abrv), HasAdditionalNotes(getNotes), Constrained(constraints), 
  HasReasVal(reasVal), HasDerivation(derivations), 
  HasReference(getReferences), HasDecRef(getDecRefs), HasSpace(typ),
  DefiningExpr(defnExpr), Quantity, HasUncertainty(unc), Callable, 
  IsArgumentName, Express(..))
import Language.Drasil.Classes.Citations (HasFields(getFields))
import Language.Drasil.Classes.Document (HasCitation(getCitations))
import Language.Drasil.Derivation (Derivation(Derivation), mkDeriv, mkDerivName, mkDerivNoHeader)
import Language.Drasil.Data.Date (Month(..))
import Language.Drasil.Chunk.Citation (
  -- Types
    Citation, EntryID, BibRef
    -- Accessors
  , citeID, citeKind
    -- CiteFields smart constructors
      -- People -> CiteField
    -- Citation smart constructors
  , cArticle, cBookA, cBookE, cBooklet
  , cInBookACP, cInBookECP, cInBookAC, cInBookEC, cInBookAP, cInBookEP
  , cInCollection, cInProceedings, cManual, cMThesis, cMisc, cPhDThesis
  , cProceedings, cTechReport, cUnpublished)
import Language.Drasil.Chunk.CommonIdea
import Language.Drasil.Chunk.Concept
import Language.Drasil.Chunk.Concept.Core (sDom) -- exported for drasil-database FIXME: move to development package?
import Language.Drasil.Chunk.Constrained
import Language.Drasil.Constraint (physc, sfwrc, isPhysC, isSfwrC,
  Constraint(..), ConstraintE, ConstraintReason(..))
import Language.Drasil.Chunk.DefinedQuantity
import Language.Drasil.Chunk.Eq (QDefinition, fromEqn, fromEqn', fromEqnSt, 
  fromEqnSt', fromEqnSt'', mkQDefSt, mkQuantDef, mkQuantDef', ec,
  mkFuncDef, mkFuncDef', mkFuncDefByQ)
import Language.Drasil.Chunk.NamedArgument (NamedArgument, narg)
import Language.Drasil.Chunk.NamedIdea
import Language.Drasil.Chunk.Quantity
import Language.Drasil.Chunk.Relation(RelationConcept, makeRC, addRelToCC)
import Language.Drasil.Chunk.UncertainQuantity
import Language.Drasil.Chunk.Unital(UnitalChunk(..), makeUCWDS, uc, uc', 
  ucStaged, ucs, ucs', ucsWS, ucuc, ucw)
import Language.Drasil.Chunk.Unitary
import Language.Drasil.Data.Citation(CiteField(..), HP(..), CitationKind(..) -- for Printing
  , author, editor
      -- Sentence -> CiteField
  , address, bookTitle, howPublished, howPublishedU, institution, journal, note
  , organization, publisher, school, series, title, typeField
      -- Int -> CiteField
  , chapter, edition, number, volume, year
      -- [Int] -> CiteField
  , pages
      -- Month -> CiteField
  , month)
import Language.Drasil.NounPhrase
import Language.Drasil.ShortName (ShortName, shortname', getSentSN)
import Language.Drasil.Space (Space(..), RealInterval(..), Inclusive(..), 
  RTopology(..), DomainDesc(..), ContinuousDomainDesc, DiscreteDomainDesc,
  getActorName, getInnerSpace)
import Language.Drasil.Sentence (Sentence(..), SentenceStyle(..), TermCapitalization(..), RefInfo(..), (+:+),
  (+:+.), (+:), (!.), capSent, ch, eS, eS', sC, sDash, sParen)
import Language.Drasil.Sentence.Extract (sdep, shortdep) -- exported for drasil-database FIXME: move to development package?
import Language.Drasil.Reference (Reference(..), namedRef, complexRef, namedComplexRef, ref, refS)
import Language.Drasil.DecoratedReference(DecRef(refInfo), dRefInfo, dRef)
import Language.Drasil.Symbol (Decoration, Symbol)
import Language.Drasil.Symbol.Helpers (eqSymb, codeSymb, hasStageSymbol, 
  autoStage, hat, prime, staged, sub, subStr, sup, unicodeConv, upperLeft, vec,
  label, variable)
import Language.Drasil.Synonyms (ConstQDef, SimpleQDef, ModelQDef, PExpr)
import Language.Drasil.Stages (Stage(..))
import Language.Drasil.Misc (mkTable)
import Language.Drasil.People (People, Person, person, HasName(..),
  person', personWM, personWM', mononym, name, nameStr, rendPersLFM, 
  rendPersLFM', rendPersLFM'', comparePeople)
import Language.Drasil.Label.Type (getAdd, LblType(RP, Citation, URI), IRefProg(..), prepend)

import Language.Drasil.UnitLang (USymb(US))
import Language.Drasil.Uncertainty.Core(Uncertainty, uncty)
import Language.Drasil.Uncertainty(defaultUncrt, uncVal, uncPrec, exact)

import Language.Drasil.Development.Sentence -- are these really development?
import Language.Drasil.Chunk.UnitDefn (UnitDefn(..)
  , fromUDefn, unitCon, makeDerU
  , (^:), (/:), (*:), (*$), (/$),(^$), newUnit
  , scale, shift
  , derUC, derUC', derUC''
  , fund, fund', compUnitDefn, derCUC, derCUC', derCUC''
  , unitWrapper, getCu, MayHaveUnit(getUnit))
