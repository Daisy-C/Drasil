module Language.Drasil.TeX.Import where

import Control.Lens ((^.))
import Prelude hiding (id)
import Language.Drasil.Expr (Expr(..), Oper(..), BinOp(..),
    DerivType(..), EOperator(..), ($=), RealRange(..), DomainDesc(..))
import Language.Drasil.Chunk.AssumpChunk
import Language.Drasil.Expr.Extract
import Language.Drasil.Chunk.Change (chng, chngType, ChngType(..))
import Language.Drasil.Chunk.Concept (defn)
import Language.Drasil.Spec
import qualified Language.Drasil.TeX.AST as T
import qualified Language.Drasil.Printing.AST as P
import Language.Drasil.Unicode (Special(Partial))
import Language.Drasil.Chunk.Eq
import Language.Drasil.Chunk.ExprRelat (relat)
import Language.Drasil.Chunk.NamedIdea (term)
import Language.Drasil.Chunk.Quantity (Quantity(..))
import Language.Drasil.Chunk.SymbolForm (eqSymb)
import Language.Drasil.Chunk.ReqChunk (requires)
import Language.Drasil.ChunkDB (getUnitLup, symbLookup, HasSymbolTable(..))
import Language.Drasil.Chunk.Citation ( Citation, CiteField(..), HP(..)
                                      , citeID, externRefT, fields)
import Language.Drasil.Config (verboseDDDescription, numberedDDEquations, numberedTMEquations)
import Language.Drasil.Document
import Language.Drasil.Misc (unit'2Contents)
import Language.Drasil.NounPhrase (phrase, titleize)
import Language.Drasil.Reference
import Language.Drasil.Symbol
import Language.Drasil.SymbolAlphabet
import Language.Drasil.Unit (usymb)

expr :: HasSymbolTable ctx => Expr -> ctx -> P.Expr
expr (Dbl d)            _ = P.Dbl  d
expr (Int i)            _ = P.Int  i
expr (Str s)            _ = P.Str  s
expr (Assoc op l)      sm = P.Assoc op $ map (\x -> expr x sm) l
expr (C c)             sm = -- FIXME: Add Stage for Context
  P.Sym  (eqSymb (symbLookup c (sm ^. symbolTable)))
expr (Deriv Part a b)  sm = P.BOp Frac (P.Assoc Mul [P.Sym (Special Partial), expr a sm])
                           (P.Assoc Mul [P.Sym (Special Partial), expr (C b) sm])
expr (Deriv Total a b) sm = P.BOp Frac (P.Assoc Mul [P.Sym lD, expr a sm])
                           (P.Assoc Mul [P.Sym lD, expr (C b) sm])
expr (FCall f x)       sm = P.Call (expr f sm) (map (flip expr sm) x)
expr (Case ps)         sm = if length ps < 2 then
        error "Attempting to use multi-case expr incorrectly"
        else P.Case (zip (map (flip expr sm . fst) ps) (map (flip expr sm . snd) ps))
expr (Matrix a)        sm = P.Mtx $ map (map (flip expr sm)) a
expr (UnaryOp o u)     sm = P.UOp o $ expr u sm
expr (EOp o)           sm = eop o sm
expr (Grouping e)      sm = P.Grouping (expr e sm)
expr (BinaryOp Div a b) sm = P.BOp Frac (replace_divs sm a) (replace_divs sm b)
expr (BinaryOp o a b)  sm = P.BOp o (expr a sm) (expr b sm)
expr (IsIn  a b)       sm = P.IsIn  (expr a sm) b

eop :: HasSymbolTable ctx => EOperator -> ctx -> P.Expr
eop (Summation (IntegerDD v (BoundedR l h)) e) sm =
  P.Funct (P.Summation (Just ((v, expr l sm), expr h sm))) (expr e sm)
eop (Summation (All _) e) sm = P.Funct (P.Summation Nothing) (expr e sm)
eop (Summation(RealDD _ _) _) _ = error "TeX/Import.hs Summation cannot be over Real"
eop (Product (IntegerDD v (BoundedR l h)) e) sm =
  P.Funct (P.Product (Just ((v, expr l sm), expr h sm))) (expr e sm)
eop (Product (All _) e) sm = P.Funct (P.Product Nothing) (expr e sm)
eop (Product (RealDD _ _) _) _ = error "TeX/Import.hs Product cannot be over Real"
eop (Integral (RealDD v (BoundedR l h)) e) sm =
  P.Funct (P.Integral (Just (expr l sm), Just (expr h sm)) v) (expr e sm)
eop (Integral (All v) e) sm =
  P.Funct (P.Integral (Just (P.Sym v), Nothing) v) (expr e sm)
eop (Integral (IntegerDD _ _) _) _ =
  error "TeX/Import.hs Integral cannot be over Integers"

int_wrt :: Symbol -> P.Expr
int_wrt wrtc = P.Assoc Mul [P.Sym lD, P.Sym wrtc]

replace_divs :: HasSymbolTable ctx => ctx -> Expr -> P.Expr
replace_divs sm (BinaryOp Div a b) = P.BOp Div (replace_divs sm a) (replace_divs sm b)
replace_divs sm (Assoc op l) = P.Assoc op $ map (replace_divs sm) l
replace_divs sm (BinaryOp Pow a b) = P.BOp Pow (replace_divs sm a) (replace_divs sm b)
replace_divs sm (BinaryOp Subt a b) = P.BOp Subt (replace_divs sm a) (replace_divs sm b)
replace_divs sm a            = expr a sm

spec :: HasSymbolTable ctx => ctx -> Sentence -> T.Spec
spec _  (S s)          = T.S s
spec _  (Sy s)         = T.Sy s
spec sm (EmptyS :+: b) = spec sm b
spec sm (a :+: EmptyS) = spec sm a
spec sm (a :+: b)      = spec sm a T.:+: spec sm b
spec _  (G g)          = T.G g
spec _  (Sp s)         = T.Sp s
spec sm (F f s)        = spec sm (accent f s)
spec _  (P s)          = T.N s
spec sm (Ref t r n)    = T.Ref t (T.S r) (spec sm n)
spec sm (Quote q)      = T.S "``" T.:+: spec sm q T.:+: T.S "\""
spec _  EmptyS         = T.EmptyS
spec sm (E e)          = T.E $ expr e sm

decorate :: Decoration -> Sentence -> Sentence
decorate Hat    s = S "\\hat{" :+: s :+: S "}"
decorate Vector s = S "\\bf{" :+: s :+: S "}"
decorate Prime  s = s :+: S "'"

accent :: Accent -> Char -> Sentence
accent Grave  s = S $ "\\`{" ++ (s : "}")
accent Acute  s = S $ "\\'{" ++ (s : "}")

makeDocument :: HasSymbolTable ctx => ctx -> Document -> T.Document
makeDocument sm (Document title author sections) =
  T.Document (spec sm title) (spec sm author) (createLayout sm sections)

layout :: HasSymbolTable ctx => ctx -> Int -> SecCons -> T.LayoutObj
layout sm currDepth (Sub s) = sec sm (currDepth+1) s
layout sm _         (Con c) = lay sm c

createLayout :: HasSymbolTable ctx => ctx -> Sections -> [T.LayoutObj]
createLayout sm = map (sec sm 0)

sec :: HasSymbolTable ctx => ctx -> Int -> Section -> T.LayoutObj
sec sm depth x@(Section title contents _) =
  T.Section depth (spec sm title) (map (layout sm depth) contents) (T.S (refAdd x))

lay :: HasSymbolTable ctx => ctx -> Contents -> T.LayoutObj
lay sm x@(Table hdr lls t b _)
  | null lls || length hdr == length (head lls) = T.Table ((map (spec sm) hdr) :
      (map (map (spec sm)) lls)) (T.S (refAdd x)) b (spec sm t)
  | otherwise = error $ "Attempting to make table with " ++ show (length hdr) ++
                        " headers, but data contains " ++
                        show (length (head lls)) ++ " columns."
lay sm (Paragraph c)          = T.Paragraph (spec sm c)
lay sm (EqnBlock c _)         = T.EqnBlock (T.E (expr c sm))
--lay (CodeBlock c)         = T.CodeBlock c
lay sm x@(Definition c)       = T.Definition (makePairs sm c) (T.S (refAdd x))
lay sm (Enumeration cs)       = T.List $ makeL sm cs
lay sm x@(Figure c f wp _)    = T.Figure (T.S (refAdd x)) (spec sm c) f wp
lay sm x@(Requirement r)      =
  T.Requirement (spec sm (requires r)) (T.S (refAdd x))
lay sm x@(Assumption a)       =
  T.Assumption (spec sm (assuming a)) (T.S (refAdd x))
lay sm x@(Change lc)    = (if (chngType lc) == Likely then 
  T.LikelyChange else T.UnlikelyChange) (spec sm (chng lc)) (T.S (refAdd x))
lay sm x@(Graph ps w h t _)   = T.Graph (map (\(y,z) -> (spec sm y, spec sm z)) ps)
                               w h (spec sm t) (T.S (refAdd x))
lay sm (Defnt dtyp pairs rn)  = T.Defnt dtyp (layPairs pairs) (T.S rn)
  where layPairs = map (\(x,y) -> (x, map (lay sm) y))
lay sm (Bib bib)          = T.Bib $ map (layCite sm) bib

-- | For importing bibliography
layCite :: HasSymbolTable ctx => ctx -> Citation -> T.Citation
layCite sm c = T.Cite (citeID c) (externRefT c) (map (layField sm) (fields c))

layField :: HasSymbolTable ctx => ctx -> CiteField -> T.CiteField
layField sm (Address      s) = T.Address      $ spec sm s
layField  _ (Author       p) = T.Author       p
layField sm (BookTitle    b) = T.BookTitle    $ spec sm b
layField  _ (Chapter      c) = T.Chapter      c
layField  _ (Edition      e) = T.Edition      e
layField  _ (Editor       e) = T.Editor       e
layField sm (Institution  i) = T.Institution  $ spec sm i
layField sm (Journal      j) = T.Journal      $ spec sm j
layField  _ (Month        m) = T.Month        m
layField sm (Note         n) = T.Note         $ spec sm n
layField  _ (Number       n) = T.Number       n
layField sm (Organization o) = T.Organization $ spec sm o
layField  _ (Pages        p) = T.Pages        p
layField sm (Publisher    p) = T.Publisher    $ spec sm p
layField sm (School       s) = T.School       $ spec sm s
layField sm (Series       s) = T.Series       $ spec sm s
layField sm (Title        t) = T.Title        $ spec sm t
layField sm (Type         t) = T.Type         $ spec sm t
layField  _ (Volume       v) = T.Volume       v
layField  _ (Year         y) = T.Year         y
layField sm (HowPublished (URL  u)) = T.HowPublished (T.URL  $ spec sm u)
layField sm (HowPublished (Verb v)) = T.HowPublished (T.Verb $ spec sm v)

makeL :: HasSymbolTable ctx => ctx -> ListType -> T.ListType
makeL sm (Bullet bs)      = T.Enum        $ map (item sm) bs
makeL sm (Numeric ns)      = T.Item       $ map (item sm) ns
makeL sm (Simple ps)      = T.Simple      $ map (\(x,y) -> (spec sm x, item sm y)) ps
makeL sm (Desc ps)        = T.Desc        $ map (\(x,y) -> (spec sm x, item sm y)) ps
makeL sm (Definitions ps) = T.Definitions $ map (\(x,y) -> (spec sm x, item sm y)) ps

item :: HasSymbolTable ctx => ctx -> ItemType -> T.ItemType
item sm (Flat i)     = T.Flat   (spec sm i)
item sm (Nested t s) = T.Nested (spec sm t) (makeL sm s)

makePairs :: HasSymbolTable ctx => ctx -> DType -> [(String,[T.LayoutObj])]
makePairs m (Data c) = [
  ("Label",       [T.Paragraph $ spec m (titleize $ c ^. term)]),
  ("Units",       [T.Paragraph $ spec m (unit'2Contents c)]),
  ("Equation",    [eqnStyleDD  $ buildEqn m c]),
  ("Description", [T.Paragraph $ buildDDDescription m c])
  ]
makePairs m (Theory c) = [
  ("Label",       [T.Paragraph $ spec m (titleize $ c ^. term)]),
  ("Equation",    [eqnStyleTM $ T.E (expr (c ^. relat) m)]),
  ("Description", [T.Paragraph (spec m (c ^. defn))])
  ]
makePairs _ General  = error "Not yet implemented"
makePairs _ Instance = error "Not yet implemented"
makePairs _ TM       = error "Not yet implemented"
makePairs _ DD       = error "Not yet implemented"


-- Toggle equation style
eqnStyleDD :: T.Contents -> T.LayoutObj
eqnStyleDD = if numberedDDEquations then T.EqnBlock else T.Paragraph

eqnStyleTM :: T.Contents -> T.LayoutObj
eqnStyleTM = if numberedTMEquations then T.EqnBlock else T.Paragraph

buildEqn :: HasSymbolTable ctx => ctx -> QDefinition -> T.Spec
buildEqn sm c = T.N (eqSymb c) T.:+: T.S " = " T.:+:
  T.E (expr (c^.equat) sm)

-- Build descriptions in data defs based on required verbosity
buildDDDescription :: HasSymbolTable ctx => ctx -> QDefinition -> T.Spec
buildDDDescription m c = descLines m
  (if verboseDDDescription then vars (C c $= c^.equat) m else [])

descLines :: (HasSymbolTable ctx, Quantity q) => ctx -> [q] -> T.Spec
descLines _ []      = error "No chunks to describe"
descLines m (vc:[]) = (T.N (eqSymb vc) T.:+:
  (T.S " is the " T.:+: (spec m (phrase $ vc ^. term)) T.:+:
   maybe (T.S "") (\a -> T.S " (" T.:+: T.Sy (a ^. usymb) T.:+: T.S ")") (getUnitLup vc m)))
descLines m (vc:vcs) = descLines m (vc:[]) T.:+: T.HARDNL T.:+: descLines m vcs
