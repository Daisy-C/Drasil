module Language.Drasil.Reference where

import Language.Drasil.Chunk (Chunk, uid)
import Language.Drasil.Chunk.AssumpChunk
import Language.Drasil.Chunk.Change
import Language.Drasil.Chunk.ReqChunk
import Language.Drasil.Chunk.Citation
import Language.Drasil.Document
import Language.Drasil.Spec
import Control.Lens ((^.), Simple, Lens)

import Data.List (partition, sortBy)
import qualified Data.Map as Map
import Data.Function (on)

-- | Create References to a given 'LayoutObj'
-- This should not be exported to the end-user, but should be usable
-- within the recipe (we want to force reference creation to check if the given
-- item exists in our database of referable objects.
makeRef :: (Referable l) => l -> Sentence
makeRef r = customRef r (refName r)

-- | Create a reference with a custom 'RefName'
customRef :: (Referable l) => l -> Sentence -> Sentence
customRef r n = Ref (rType r) (refAdd r) n

-- | Database for internal references.
data ReferenceDB = RDB
  { assumpDB :: AssumpMap
  , reqDB :: ReqMap
  , changeDB :: ChangeMap
  , citationDB :: BibMap
  }
  
data RefBy = ByName
           | ByNum -- If applicable

rdb :: [AssumpChunk] -> [ReqChunk] -> [Change] -> BibRef ->
  ReferenceDB
rdb assumps reqs changes citations = RDB
  (assumpMap assumps)
  (reqMap reqs)
  (changeMap changes)
  (bibMap citations)

-- | Map for maintaining assumption references.
-- The Int is that reference's number.
-- Maintains access to both num and chunk for easy reference swapping
-- between number and shortname when necessary (or use of number
-- if no shortname exists)
type AssumpMap = Map.Map String (AssumpChunk, Int)

assumpMap :: [AssumpChunk] -> AssumpMap
assumpMap a = Map.fromList $ zip (map (^. uid) a) (zip a [1..])

assumpLookup :: Chunk c => c -> AssumpMap -> (AssumpChunk, Int)
assumpLookup a m = let lookC = Map.lookup (a ^. uid) m in
                   getS lookC
  where getS (Just x) = x
        getS Nothing = error $ "Assumption: " ++ (a ^. uid) ++
          " referencing information not found in Assumption Map"

-- | Map for maintaining requirement references.
-- Similar to AssumpMap
type ReqMap = Map.Map String (ReqChunk, Int)

reqMap :: [ReqChunk] -> ReqMap
reqMap rs = Map.fromList $ zip (map (^. uid) (frs ++ nfrs)) ((zip frs [1..]) ++
  (zip nfrs [1..]))
  where (frs, nfrs)  = partition (isFuncRec . reqType) rs
        isFuncRec FR = True
        isFuncRec _  = False

reqLookup :: Chunk c => c -> ReqMap -> (ReqChunk, Int)
reqLookup r m = let lookC = Map.lookup (r ^. uid) m in
                   getS lookC
  where getS (Just x) = x
        getS Nothing = error $ "Requirement: " ++ (r ^. uid) ++
          " referencing information not found in Requirement Map"

-- | Map for maintaining change references.
-- Similar to AssumpMap
type ChangeMap = Map.Map String (Change, Int)

changeMap :: [Change] -> ChangeMap
changeMap cs = Map.fromList $ zip (map (^. uid) (lcs ++ ulcs))
  ((zip lcs [1..]) ++ (zip ulcs [1..]))
  where (lcs, ulcs) = partition (isLikely . chngType) cs
        isLikely Likely = True
        isLikely _ = False

changeLookup :: Chunk c => c -> ChangeMap -> (Change, Int)
changeLookup c m = let lookC = Map.lookup (c ^. uid) m in
                   getS lookC
  where getS (Just x) = x
        getS Nothing = error $ "Change: " ++ (c ^. uid) ++
          " referencing information not found in Change Map"

-- | Map for maintaining citation references.
-- Similar to AssumpMap.
type BibMap = Map.Map String (Citation, Int)

bibMap :: [Citation] -> BibMap
bibMap cs = Map.fromList $ zip (map (^. uid) scs) (zip scs [1..])
  where scs :: [Citation]
        scs = sortBy citeSort cs
        -- Sorting is necessary if using elems to pull all the citations
        -- (as it sorts them and would change the order).
        -- We can always change the sorting to whatever makes most sense
        
citeLookup :: Chunk c => c -> BibMap -> (Citation, Int)
citeLookup c m = let lookC = Map.lookup (c ^. uid) m in
                   getS lookC
  where getS (Just x) = x
        getS Nothing = error $ "Change: " ++ (c ^. uid) ++
          " referencing information not found in Change Map"

-- Classes and instances --
class HasAssumpRefs s where
  assumpRefTable :: Simple Lens s AssumpMap

instance HasAssumpRefs ReferenceDB where
  assumpRefTable f (RDB a b c d) = fmap (\x -> RDB x b c d) (f a)

class HasReqRefs s where
  reqRefTable :: Simple Lens s ReqMap

instance HasReqRefs ReferenceDB where
  reqRefTable f (RDB a b c d) = fmap (\x -> RDB a x c d) (f b)

class HasChangeRefs s where
  changeRefTable :: Simple Lens s ChangeMap

instance HasChangeRefs ReferenceDB where
  changeRefTable f (RDB a b c d) = fmap (\x -> RDB a b x d) (f c)

class HasCitationRefs s where
  citationRefTable :: Simple Lens s BibMap

instance HasCitationRefs ReferenceDB where
  citationRefTable f (RDB a b c d) = fmap (\x -> RDB a b c x) (f d)

class Referable s where
  refName :: s -> RefName -- Sentence; The text to be displayed for the link.
  refAdd  :: s -> String  -- The reference address (what we're linking to).
                          -- Should be string with no spaces/special chars.
  rType   :: s -> RefType -- The reference type (referencing namespace?)

instance Referable AssumpChunk where
  refName (AC _ _ sn _) = sn
  refAdd  x             = "A:" ++ concatMap repUnd (x ^. uid)
  rType   _             = Assump

instance Referable ReqChunk where
  refName (RC _ _ _ sn _)   = sn
  refAdd  r@(RC _ rt _ _ _) = show rt ++ ":" ++ concatMap repUnd (r ^. uid)
  rType   _                 = Req

instance Referable Change where
  refName (ChC _ _ _ sn _)     = sn
  refAdd r@(ChC _ rt _ _ _)    = show rt ++ ":" ++ concatMap repUnd (r ^. uid)
  rType (ChC _ Likely _ _ _)   = LC
  rType (ChC _ Unlikely _ _ _) = UC

instance Referable Section where
  refName (Section t _ _) = t
  refAdd  (Section _ _ r) = "Sec:" ++ r
  rType   _               = Sect

instance Referable Citation where
  refName c = S $ citeID c
  refAdd c = concatMap repUnd $ citeID c -- citeID should be unique.
  rType _ = Cite

instance Referable Contents where
  refName (Table _ _ _ _ r)     = S "Table:" :+: S r
  refName (Figure _ _ _ r)      = S "Figure:" :+: S r
  refName (Graph _ _ _ _ r)     = S "Figure:" :+: S r
  refName (EqnBlock _ r)        = S "Equation:" :+: S r
  refName (Definition d)        = S $ getDefName d
  refName (Defnt dt _ r)        = S (getDefName dt) :+: S r
  refName (Requirement rc)      = refName rc
  refName (Assumption ca)       = refName ca
  refName (Change lcc)          = refName lcc
  refName (Enumeration _)       = error "Can't reference lists"
  refName (Paragraph _)         = error "Can't reference paragraphs"
  refName (Bib _)               = error $
    "Bibliography list of references cannot be referenced. " ++
    "You must reference the Section or an individual citation."
  rType (Table _ _ _ _ _)       = Tab
  rType (Figure _ _ _ _)        = Fig
  rType (Definition (Data _))   = Def
  rType (Definition (Theory _)) = Def
  rType (Definition _)          = Def
  rType (Defnt _ _ _)           = Def
  rType (Requirement r)         = rType r
  rType (Assumption a)          = rType a
  rType (Change l)              = rType l --rType lc
  rType (Graph _ _ _ _ _)       = Fig
  rType (EqnBlock _ _)          = EqnB
  rType _                       =
    error "Attempting to reference unimplemented reference type"
  refAdd (Table _ _ _ _ r)      = "Table:" ++ r
  refAdd (Figure _ _ _ r)       = "Figure:" ++ r
  refAdd (Graph _ _ _ _ r)      = "Figure:" ++ r
  refAdd (EqnBlock _ r)         = "Equation:" ++ r
  refAdd (Definition d)         = getDefName d
  refAdd (Defnt dt _ r)         = getDefName dt ++ r
  refAdd (Requirement rc)       = refAdd rc
  refAdd (Assumption ca)        = refAdd ca
  refAdd (Change lcc)           = refAdd lcc
  refAdd (Enumeration _)        = error "Can't reference lists"
  refAdd (Paragraph _)          = error "Can't reference paragraphs"
  refAdd (Bib _)                = error $
    "Bibliography list of references cannot be referenced. " ++
    "You must reference the Section or an individual citation."

-- | Automatically create the label for a definition
getDefName :: DType -> String
getDefName (Data c)   = "DD:" ++ concatMap repUnd (c ^. uid) -- FIXME: To be removed
getDefName (Theory c) = "T:" ++ concatMap repUnd (c ^. uid) -- FIXME: To be removed
getDefName TM         = "T:"
getDefName DD         = "DD:"
getDefName Instance   = "IM:"
getDefName General    = "GD:"

citeSort :: Citation -> Citation -> Ordering
citeSort = compare `on` (^. uid)

citationsFromBibMap :: BibMap -> [Citation]
citationsFromBibMap bm = sortBy citeSort citations
  where citations :: [Citation]
        citations = map (\(x,_) -> x) (Map.elems bm)

assumptionsFromDB :: AssumpMap -> [AssumpChunk]
assumptionsFromDB am = dropNums $ sortBy (compare `on` snd) assumptions
  where assumptions = Map.elems am
        dropNums = map fst

repUnd :: Char -> String
repUnd '_' = "."
repUnd c = c : []

-- This works for passing the correct id to the reference generator for Assumptions,
-- Requirements and Likely Changes but I question whether we should use it.
-- Pass it the item to be referenced and the enumerated list of the respective
-- contents for that file. Change rType values to implement.

acroTest :: Contents -> [Contents] -> Sentence
acroTest ref reflst = makeRef $ find ref reflst

find :: Contents -> [Contents] -> Contents
find _ [] = error "This object does not match any of the enumerated objects provided by the list."
find itm@(Assumption comp1) (frst@(Assumption comp2):lst)
  | (comp1 ^. uid) == (comp2 ^. uid) = frst
  | otherwise = find itm lst
find itm@(Definition (Data comp1)) (frst@(Definition (Data comp2)):lst)
  | (comp1 ^. uid) == (comp2 ^. uid) = frst
  | otherwise = find itm lst
find itm@(Definition (Theory comp1)) (frst@(Definition (Theory comp2)):lst)
  | (comp1 ^. uid) == (comp2 ^. uid) = frst
  | otherwise = find itm lst
find itm@(Requirement comp1) (frst@(Requirement comp2):lst)
  | (comp1 ^. uid) == (comp2 ^. uid) = frst
  | otherwise = find itm lst
find itm@(Change comp1) (frst@(Change comp2):lst)
  | (comp1 ^. uid) == (comp2 ^. uid) = frst
  | otherwise = find itm lst
find _ _ = error "Error: Attempting to find unimplemented type"
