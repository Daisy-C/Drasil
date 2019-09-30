{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE PostfixOperators #-}

-- | The logic to render C# code is contained in this module
module GOOL.Drasil.LanguageRenderer.CSharpRenderer (
  -- * C# Code Configuration -- defines syntax of all C# code
  CSharpCode(..)
) where

import Utils.Drasil (indent)

import GOOL.Drasil.CodeType (CodeType(..), isObject)
import GOOL.Drasil.Symantics (Label,
  ProgramSym(..), RenderSym(..), InternalFile(..),
  KeywordSym(..), PermanenceSym(..), BodySym(..), BlockSym(..), 
  ControlBlockSym(..), TypeSym(..), UnaryOpSym(..), BinaryOpSym(..), 
  VariableSym(..), ValueSym(..), NumericExpression(..), BooleanExpression(..), 
  ValueExpression(..), InternalValue(..), Selector(..), FunctionSym(..), 
  SelectorFunction(..), InternalFunction(..), InternalStatement(..), 
  StatementSym(..), ControlStatementSym(..), ScopeSym(..), MethodTypeSym(..), 
  ParameterSym(..), MethodSym(..), InternalMethod(..), StateVarSym(..), 
  ClassSym(..), ModuleSym(..), BlockCommentSym(..))
import GOOL.Drasil.LanguageRenderer (addExt, fileDoc', moduleDocD, classDocD, 
  enumDocD, enumElementsDocD, multiStateDocD, blockDocD, bodyDocD, oneLinerD, 
  printDoc, outDoc, printFileDocD, boolTypeDocD, intTypeDocD, charTypeDocD, 
  stringTypeDocD, typeDocD, enumTypeDocD, listTypeDocD, listInnerTypeD, 
  voidDocD, constructDocD, paramDocD, paramListDocD, mkParam, methodDocD, 
  methodListDocD, stateVarDocD, stateVarDefDocD, stateVarListDocD, ifCondDocD, 
  switchDocD, forDocD, forEachDocD, whileDocD, runStrategyD, listSliceD, 
  assignDocD, plusEqualsDocD, plusPlusDocD, varDecDocD, varDecDefDocD, 
  listDecDocD, listDecDefDocD, objDecDefDocD, constDecDefDocD, statementDocD, 
  returnDocD, mkSt, mkStNoEnd, stringListVals', stringListLists', commentDocD, 
  unOpPrec, notOpDocD, negateOpDocD, unExpr, unExpr', typeUnExpr, powerPrec, 
  equalOpDocD, notEqualOpDocD, greaterOpDocD, greaterEqualOpDocD, lessOpDocD, 
  lessEqualOpDocD, plusOpDocD, minusOpDocD, multOpDocD, divideOpDocD, 
  moduloOpDocD, andOpDocD, orOpDocD, binExpr, binExpr', typeBinExpr, mkVal, 
  mkVar, litTrueD, litFalseD, litCharD, litFloatD, litIntD, litStringD, 
  classVarD, classVarDocD, objVarDocD, inlineIfD, newObjDocD, varD, staticVarD, 
  extVarD, selfD, enumVarD, classVarD, objVarSelfD, listVarD, listOfD, iterVarD,
  valueOfD, argD, enumElementD, argsListD, objAccessD, objMethodCallD, 
  objMethodCallNoParamsD, selfAccessD, listIndexExistsD, indexOfD, funcAppD, 
  extFuncAppD, newObjD,notNullD, funcDocD, castDocD, listSetFuncDocD, 
  castObjDocD, funcD, getD, setD, listSizeD, listAddD, listAppendD, iterBeginD, 
  iterEndD, listAccessD, listSetD, getFuncD, setFuncD, listAddFuncD, 
  listAppendFuncD, iterBeginError, iterEndError, listAccessFuncD, listSetFuncD, 
  breakDocD, continueDocD, staticDocD, dynamicDocD, privateDocD, publicDocD, 
  dot, new, blockCmtStart, blockCmtEnd, docCmtStart, observerListName, 
  doubleSlash, elseIfLabel, inLabel, blockCmtDoc, docCmtDoc, commentedItem, 
  addCommentsDocD, functionDox, classDoc, moduleDoc, commentedModD, docFuncRepr,
  appendToBody, surroundBody, getterName, setterName, setMainMethod, setEmpty, 
  filterOutObjs)
import GOOL.Drasil.Data (Terminator(..), FileData(..), file, FuncData(..), fd, 
  ModData(..), md, updateModDoc, MethodData(..), mthd, OpData(..), 
  ParamData(..), pd, updateParamDoc, ProgData(..), progD, TypeData(..), td, 
  ValData(..), vd, updateValDoc, Binding(..), VarData(..), vard)
import GOOL.Drasil.Helpers (emptyIfEmpty, liftA4, 
  liftA5, liftA6, liftA7, liftList, lift1List, lift3Pair, lift4Pair,
  liftPair, liftPairFst, checkParams)

import Prelude hiding (break,print,(<>),sin,cos,tan,floor)
import Data.Maybe (maybeToList)
import Control.Applicative (Applicative, liftA2, liftA3)
import Text.PrettyPrint.HughesPJ (Doc, text, (<>), (<+>), parens, comma, empty,
  semi, vcat, lbrace, rbrace, colon)

csExt :: String
csExt = "cs"

newtype CSharpCode a = CSC {unCSC :: a} deriving Eq

instance Functor CSharpCode where
  fmap f (CSC x) = CSC (f x)

instance Applicative CSharpCode where
  pure = CSC
  (CSC f) <*> (CSC x) = CSC (f x)

instance Monad CSharpCode where
  return = CSC
  CSC x >>= f = f x

instance ProgramSym CSharpCode where
  type Program CSharpCode = ProgData
  prog n = liftList (progD n)

instance RenderSym CSharpCode where
  type RenderFile CSharpCode = FileData
  fileDoc code = liftA2 file (fmap (addExt csExt . name) code) (liftA2 
    updateModDoc (liftA2 emptyIfEmpty (fmap modDoc code) $ liftA3 fileDoc' 
    (top code) (fmap modDoc code) bottom) code)

  docMod d a dt m = commentedMod (docComment $ moduleDoc d a dt $ filePath 
    (unCSC m)) m

  commentedMod = liftA2 commentedModD

instance InternalFile CSharpCode where
  top _ = liftA2 cstop endStatement (include "")
  bottom = return empty

instance KeywordSym CSharpCode where
  type Keyword CSharpCode = Doc
  endStatement = return semi
  endStatementLoop = return empty

  include _ = return $ text "using"
  inherit = return colon

  list _ = return $ text "List"

  blockStart = return lbrace
  blockEnd = return rbrace

  ifBodyStart = blockStart
  elseIf = return elseIfLabel
  
  iterForEachLabel = return $ text "foreach"
  iterInLabel = return inLabel

  commentStart = return doubleSlash
  blockCommentStart = return blockCmtStart
  blockCommentEnd = return blockCmtEnd
  docCommentStart = return docCmtStart
  docCommentEnd = blockCommentEnd

instance PermanenceSym CSharpCode where
  type Permanence CSharpCode = Doc
  static_ = return staticDocD
  dynamic_ = return dynamicDocD

instance BodySym CSharpCode where
  type Body CSharpCode = Doc
  body = liftList bodyDocD
  bodyStatements = block
  oneLiner = oneLinerD

  addComments s = liftA2 (addCommentsDocD s) commentStart

  bodyDoc = unCSC

instance BlockSym CSharpCode where
  type Block CSharpCode = Doc
  block sts = lift1List blockDocD endStatement (map (fmap fst . state) sts)

  docBlock = return

instance TypeSym CSharpCode where
  type Type CSharpCode = TypeData
  bool = return boolTypeDocD
  int = return intTypeDocD
  float = return csFloatTypeDoc
  char = return charTypeDocD
  string = return stringTypeDocD
  infile = return csInfileTypeDoc
  outfile = return csOutfileTypeDoc
  listType p st = liftA2 listTypeDocD st (list p)
  listInnerType = listInnerTypeD
  obj t = return $ typeDocD t
  enumType t = return $ enumTypeDocD t
  iterator t = t
  void = return voidDocD

  getType = cType . unCSC
  getTypeString = typeString . unCSC
  getTypeDoc = typeDoc . unCSC

instance ControlBlockSym CSharpCode where
  runStrategy = runStrategyD

  listSlice = listSliceD

instance UnaryOpSym CSharpCode where
  type UnaryOp CSharpCode = OpData
  notOp = return notOpDocD
  negateOp = return negateOpDocD
  sqrtOp = return $ unOpPrec "Math.Sqrt"
  absOp = return $ unOpPrec "Math.Abs"
  logOp = return $ unOpPrec "Math.Log10"
  lnOp = return $ unOpPrec "Math.Log"
  expOp = return $ unOpPrec "Math.Exp"
  sinOp = return $ unOpPrec "Math.Sin"
  cosOp = return $ unOpPrec "Math.Cos"
  tanOp = return $ unOpPrec "Math.Tan"
  asinOp = return $ unOpPrec "Math.Asin"
  acosOp = return $ unOpPrec "Math.Acos"
  atanOp = return $ unOpPrec "Math.Atan"
  floorOp = return $ unOpPrec "Math.Floor"
  ceilOp = return $ unOpPrec "Math.Ceiling"

instance BinaryOpSym CSharpCode where
  type BinaryOp CSharpCode = OpData
  equalOp = return equalOpDocD
  notEqualOp = return notEqualOpDocD
  greaterOp = return greaterOpDocD
  greaterEqualOp = return greaterEqualOpDocD
  lessOp = return lessOpDocD
  lessEqualOp = return lessEqualOpDocD
  plusOp = return plusOpDocD
  minusOp = return minusOpDocD
  multOp = return multOpDocD
  divideOp = return divideOpDocD
  powerOp = return $ powerPrec "Math.Pow"
  moduloOp = return moduloOpDocD
  andOp = return andOpDocD
  orOp = return orOpDocD

instance VariableSym CSharpCode where
  type Variable CSharpCode = VarData
  var = varD
  staticVar = staticVarD
  const = var
  extVar = extVarD
  self = selfD
  enumVar = enumVarD
  classVar = classVarD classVarDocD
  objVar = liftA2 csObjVar
  objVarSelf = objVarSelfD
  listVar  = listVarD
  listOf = listOfD 
  iterVar = iterVarD

  ($->) = objVar

  variableBind = varBind . unCSC
  variableName = varName . unCSC
  variableType = fmap varType
  variableDoc = varDoc . unCSC
  
  varFromData b n t d = liftA2 (vard b n) t (return d)

instance ValueSym CSharpCode where
  type Value CSharpCode = ValData
  litTrue = litTrueD
  litFalse = litFalseD
  litChar = litCharD
  litFloat = litFloatD
  litInt = litIntD
  litString = litStringD

  ($:) = enumElement

  valueOf = valueOfD
  arg n = argD (litInt n) argsList
  enumElement = enumElementD
  
  argsList = argsListD "args"

  valueType = fmap valType
  valueDoc = valDoc . unCSC

instance NumericExpression CSharpCode where
  (#~) = liftA2 unExpr' negateOp
  (#/^) = liftA2 unExpr sqrtOp
  (#|) = liftA2 unExpr absOp
  (#+) = liftA3 binExpr plusOp
  (#-) = liftA3 binExpr minusOp
  (#*) = liftA3 binExpr multOp
  (#/) = liftA3 binExpr divideOp
  (#%) = liftA3 binExpr moduloOp
  (#^) = liftA3 binExpr' powerOp

  log = liftA2 unExpr logOp
  ln = liftA2 unExpr lnOp
  exp = liftA2 unExpr expOp
  sin = liftA2 unExpr sinOp
  cos = liftA2 unExpr cosOp
  tan = liftA2 unExpr tanOp
  csc v = litFloat 1.0 #/ sin v
  sec v = litFloat 1.0 #/ cos v
  cot v = litFloat 1.0 #/ tan v
  arcsin = liftA2 unExpr asinOp
  arccos = liftA2 unExpr acosOp
  arctan = liftA2 unExpr atanOp
  floor = liftA2 unExpr floorOp
  ceil = liftA2 unExpr ceilOp

instance BooleanExpression CSharpCode where
  (?!) = liftA3 typeUnExpr notOp bool
  (?&&) = liftA4 typeBinExpr andOp bool
  (?||) = liftA4 typeBinExpr orOp bool

  (?<) = liftA4 typeBinExpr lessOp bool
  (?<=) = liftA4 typeBinExpr lessEqualOp bool
  (?>) = liftA4 typeBinExpr greaterOp bool
  (?>=) = liftA4 typeBinExpr greaterEqualOp bool
  (?==) = liftA4 typeBinExpr equalOp bool
  (?!=) = liftA4 typeBinExpr notEqualOp bool
  
instance ValueExpression CSharpCode where
  inlineIf = liftA3 inlineIfD
  funcApp = funcAppD
  selfFuncApp = funcApp
  extFuncApp = extFuncAppD
  newObj = newObjD newObjDocD
  extNewObj _ = newObj

  exists = notNull
  notNull = notNullD

instance InternalValue CSharpCode where
  inputFunc = liftA2 mkVal string (return $ text "Console.ReadLine()")
  printFunc = liftA2 mkVal void (return $ text "Console.Write")
  printLnFunc = liftA2 mkVal void (return $ text "Console.WriteLine")
  printFileFunc f = liftA2 mkVal void (fmap (printFileDocD "Write") f)
  printFileLnFunc f = liftA2 mkVal void (fmap (printFileDocD "WriteLine") f)
  
  cast = csCast
  
  valFromData p t d = liftA2 (vd p) t (return d)

instance Selector CSharpCode where
  objAccess = objAccessD
  ($.) = objAccess

  objMethodCall = objMethodCallD
  objMethodCallNoParams = objMethodCallNoParamsD

  selfAccess = selfAccessD

  listIndexExists = listIndexExistsD
  argExists i = listAccess argsList (litInt $ fromIntegral i)
  
  indexOf = indexOfD "IndexOf"

instance FunctionSym CSharpCode where
  type Function CSharpCode = FuncData
  func = funcD

  get = getD
  set = setD

  listSize = listSizeD
  listAdd = listAddD
  listAppend = listAppendD

  iterBegin = iterBeginD
  iterEnd = iterEndD

instance SelectorFunction CSharpCode where
  listAccess = listAccessD
  listSet = listSetD
  at = listAccess

instance InternalFunction CSharpCode where
  getFunc = getFuncD
  setFunc = setFuncD

  listSizeFunc = liftA2 fd int (return $ funcDocD (text "Count"))
  listAddFunc _ = listAddFuncD "Insert"
  listAppendFunc = listAppendFuncD "Add"

  iterBeginFunc _ = error $ iterBeginError csName
  iterEndFunc _ = error $ iterEndError csName

  listAccessFunc = listAccessFuncD
  listSetFunc = listSetFuncD listSetFuncDocD 
    
  functionType = fmap funcType
  functionDoc = funcDoc . unCSC

  funcFromData t d = liftA2 fd t (return d)

instance InternalStatement CSharpCode where
  printSt _ p v _ = mkSt <$> liftA2 printDoc p v
  
  state = fmap statementDocD
  loopState = fmap (statementDocD . setEmpty)

  emptyState = return $ mkStNoEnd empty
  statementDoc = fst . unCSC

instance StatementSym CSharpCode where
  type Statement CSharpCode = (Doc, Terminator)
  assign vr vl = mkSt <$> liftA2 assignDocD vr vl
  assignToListIndex lst index v = valState $ listSet (valueOf lst) index v
  multiAssign _ _ = error "No multiple assignment statements in C#"
  (&=) = assign
  (&-=) vr vl = vr &= (valueOf vr #- vl)
  (&+=) vr vl = mkSt <$> liftA2 plusEqualsDocD vr vl
  (&++) v = mkSt <$> fmap plusPlusDocD v
  (&~-) v = v &= (valueOf v #- litInt 1)

  varDec v = csVarDec (variableBind v) $ mkSt <$> liftA3 varDecDocD v static_ 
    dynamic_ 
  varDecDef v def = csVarDec (variableBind v) $mkSt <$> liftA4 varDecDefDocD v 
    def static_ dynamic_ 
  listDec n v = csVarDec (variableBind v) $ mkSt <$> liftA4 listDecDocD v 
    (litInt n) static_ dynamic_
  listDecDef v vs = csVarDec (variableBind v) $ mkSt <$> liftA4 listDecDefDocD 
    v (sequence vs) static_ dynamic_ 
  objDecDef v def = csVarDec (variableBind v) $ mkSt <$> liftA4 objDecDefDocD v 
    def static_ dynamic_ 
  objDecNew v vs = csVarDec (variableBind v) $ mkSt <$> liftA4 objDecDefDocD v 
    (newObj (variableType v) vs) static_ dynamic_ 
  extObjDecNew _ = objDecNew
  objDecNewNoParams v = csVarDec (variableBind v) $ mkSt <$> liftA4 objDecDefDocD v 
    (newObj (variableType v) []) static_ dynamic_ 
  extObjDecNewNoParams _ = objDecNewNoParams
  constDecDef v def = mkSt <$> liftA2 constDecDefDocD v def

  print v = outDoc False printFunc v Nothing
  printLn v = outDoc True printLnFunc v Nothing
  printStr s = outDoc False printFunc (litString s) Nothing
  printStrLn s = outDoc True printLnFunc (litString s) Nothing

  printFile f v = outDoc False (printFileFunc f) v (Just f)
  printFileLn f v = outDoc True (printFileLnFunc f) v (Just f)
  printFileStr f s = outDoc False (printFileFunc f) (litString s) (Just f)
  printFileStrLn f s = outDoc True (printFileLnFunc f) (litString s) (Just f)

  getInput v = v &= liftA2 csInput (variableType v) inputFunc
  discardInput = mkSt <$> fmap csDiscardInput inputFunc
  getFileInput f v = v &= liftA2 csInput (variableType v) (fmap csFileInput f)
  discardFileInput f = valState $ fmap csFileInput f

  openFileR f n = f &= liftA2 csOpenFileR n infile
  openFileW f n = f &= liftA3 csOpenFileWorA n outfile litFalse
  openFileA f n = f &= liftA3 csOpenFileWorA n outfile litTrue
  closeFile f = valState $ objMethodCall void f "Close" []

  getFileInputLine = getFileInput
  discardFileLine f = valState $ fmap csFileInput f
  stringSplit d vnew s = assign vnew $ newObj (listType dynamic_ string) 
    [s $. func "Split" (listType static_ string) [litChar d]]

  stringListVals = stringListVals'
  stringListLists = stringListLists'

  break = return (mkSt breakDocD)
  continue = return (mkSt continueDocD)

  returnState v = mkSt <$> liftList returnDocD [v]
  multiReturn _ = error "Cannot return multiple values in C#"

  valState v = mkSt <$> fmap valDoc v

  comment cmt = mkStNoEnd <$> fmap (commentDocD cmt) commentStart

  free _ = error "Cannot free variables in C#" -- could set variable to null? Might be misleading.

  throw errMsg = mkSt <$> fmap csThrowDoc (litString errMsg)

  initState fsmName initialState = varDecDef (var fsmName string) (litString initialState)
  changeState fsmName toState = var fsmName string &= litString toState

  initObserverList t = listDecDef (var observerListName t)
  addObserver o = valState $ listAdd obsList lastelem o
    where obsList = valueOf $ observerListName `listOf` valueType o
          lastelem = listSize obsList

  inOutCall = csInOutCall funcApp
  extInOutCall m = csInOutCall (extFuncApp m)

  multi = lift1List multiStateDocD endStatement

instance ControlStatementSym CSharpCode where
  ifCond bs b = mkStNoEnd <$> lift4Pair ifCondDocD ifBodyStart elseIf blockEnd b
    bs
  ifNoElse bs = ifCond bs $ body []
  switch v cs c = mkStNoEnd <$> lift3Pair switchDocD (state break) v c cs
  switchAsIf v cs = ifCond cases
    where cases = map (\(l, b) -> (v ?== l, b)) cs

  ifExists v ifBody = ifCond [(notNull v, ifBody)]

  for sInit vGuard sUpdate b = mkStNoEnd <$> liftA6 forDocD blockStart blockEnd 
    (loopState sInit) vGuard (loopState sUpdate) b
  forRange i initv finalv stepv = for (varDecDef i initv) 
    (valueOf i ?< finalv) (i &+= stepv)
  forEach e v b = mkStNoEnd <$> liftA7 forEachDocD e blockStart blockEnd 
    iterForEachLabel iterInLabel v b
  while v b = mkStNoEnd <$> liftA4 whileDocD blockStart blockEnd v b

  tryCatch tb cb = mkStNoEnd <$> liftA2 csTryCatch tb cb

  checkState l = switch (valueOf $ var l string)
  notifyObservers f t = for initv (v_index ?< listSize obsList) 
    (var_index &++) notify
    where obsList = valueOf $ observerListName `listOf` t
          var_index = var "observerIndex" int
          v_index = valueOf var_index
          initv = varDecDef var_index $ litInt 0
          notify = oneLiner $ valState $ at obsList v_index $. f

  getFileInputAll f v = while ((f $. liftA2 fd bool (return $ text 
    ".EndOfStream")) ?!) (oneLiner $ valState $ listAppend (valueOf v) (fmap 
    csFileInput f))

instance ScopeSym CSharpCode where
  type Scope CSharpCode = Doc
  private = return privateDocD
  public = return publicDocD

instance MethodTypeSym CSharpCode where
  type MethodType CSharpCode = TypeData
  mType t = t
  construct n = return $ td (Object n) n (constructDocD n)

instance ParameterSym CSharpCode where
  type Parameter CSharpCode = ParamData
  param = fmap (mkParam paramDocD)
  pointerParam = param

  parameterName = variableName . fmap paramVar
  parameterType = variableType . fmap paramVar

instance MethodSym CSharpCode where
  type Method CSharpCode = MethodData
  method n _ s p t ps b = liftA2 (mthd False) (checkParams n <$> sequence ps) 
    (liftA5 (methodDocD n) s p (mType t) (liftList paramListDocD ps) b)
  getMethod c v = method (getterName $ variableName v) c public dynamic_ 
    (variableType v) [] getBody
    where getBody = oneLiner $ returnState (valueOf $ self c $-> v)
  setMethod c v = method (setterName $ variableName v) c public dynamic_ void 
    [param v] setBody
    where setBody = oneLiner $ (self c $-> v) &= valueOf v
  privMethod n c = method n c private dynamic_
  pubMethod n c = method n c public dynamic_
  constructor n = intMethod n n public dynamic_ (construct n)
  destructor _ _ = error "Destructors not allowed in C#"

  docMain b = commentedFunc (docComment $ functionDox 
    "Controls the flow of the program" 
    [("args", "List of command-line arguments")] []) (mainFunction b)
 
  function n s p t = intFunc n s p (mType t)
  mainFunction b = setMainMethod <$> function "Main" public static_ void 
    [liftA2 pd (var "args" (listType static_ string)) 
    (return $ text "string[] args")] b

  docFunc desc pComms rComm = docFuncRepr desc pComms (maybeToList rComm)

  inOutFunc n s p ins [v] [] b = function n s p (variableType v) (map param ins)
   (liftA3 surroundBody (varDec v) b (returnState $ valueOf v))
  inOutFunc n s p ins [] [v] b = function n s p (if null (filterOutObjs [v]) 
    then void else variableType v) (map param $ v : ins) 
    (if null (filterOutObjs [v]) then b else liftA2 appendToBody b 
    (returnState $ valueOf v))
  inOutFunc n s p ins outs both b = function n s p void (map (fmap 
    (updateParamDoc csRef) . param) both ++ map param ins ++ 
    map (fmap (updateParamDoc csOut) . param) outs) b

  docInOutFunc n s p desc is [o] [] b = docFuncRepr desc (map fst is) [fst o] 
    (inOutFunc n s p (map snd is) [snd o] [] b)
  docInOutFunc n s p desc is [] [both] b = docFuncRepr desc (map fst (both : 
    is)) [fst both | not ((isObject . getType . variableType . snd) both)] 
    (inOutFunc n s p (map snd is) [] [snd both] b)
  docInOutFunc n s p desc is os bs b = docFuncRepr desc (map fst (is ++ os ++ 
    bs)) [] (inOutFunc n s p (map snd is) (map snd os) (map snd bs) b)
  
  parameters m = map return $ (mthdParams . unCSC) m

instance InternalMethod CSharpCode where
  intMethod n _ s p t ps b = liftA2 (mthd False) (checkParams n <$> sequence ps)
    (liftA5 (methodDocD n) s p t (liftList paramListDocD ps) b)
  intFunc n = intMethod n ""
  commentedFunc cmt fn = liftA3 mthd (fmap isMainMthd fn) (fmap mthdParams fn)
    (liftA2 commentedItem cmt (fmap mthdDoc fn))

instance StateVarSym CSharpCode where
  type StateVar CSharpCode = Doc
  stateVar _ s p v = liftA4 stateVarDocD s p v endStatement
  stateVarDef _ _ s p vr vl = liftA3 stateVarDefDocD s p (fst <$>
    state (varDecDef vr vl))
  constVar _ _ s vr vl = liftA3 stateVarDefDocD s (return empty) 
    (fst <$> state (constDecDef vr vl))
  privMVar del = stateVar del private dynamic_
  pubMVar del = stateVar del public dynamic_
  pubGVar del = stateVar del public static_

instance ClassSym CSharpCode where
  -- Bool is True if the method is a main method, False otherwise
  type Class CSharpCode = (Doc, Bool)
  buildClass n p s vs fs = liftPairFst (liftA4 (classDocD n p) inherit s 
    (liftList stateVarListDocD vs) (liftList methodListDocD (map (fmap mthdDoc) 
    fs)), any (isMainMthd . unCSC) fs)
  enum n es s = liftPairFst (liftA2 (enumDocD n) (return $ 
    enumElementsDocD es False) s, False)
  privClass n p = buildClass n p private
  pubClass n p = buildClass n p public

  docClass d = commentedClass (docComment $ classDoc d)

  commentedClass cmt cs = liftPair (liftA2 commentedItem cmt (fmap fst cs), 
    fmap snd cs)

instance ModuleSym CSharpCode where
  type Module CSharpCode = ModData
  buildModule n _ ms cs = fmap (md n (any (isMainMthd . unCSC) ms || 
    any (snd . unCSC) cs)) (liftList moduleDocD (if null ms then cs 
    else pubClass n Nothing [] ms : cs))
    
  moduleName m = name (unCSC m)

instance BlockCommentSym CSharpCode where
  type BlockComment CSharpCode = Doc
  blockComment lns = liftA2 (blockCmtDoc lns) blockCommentStart blockCommentEnd
  docComment lns = liftA2 (docCmtDoc lns) docCommentStart docCommentEnd

csName :: String
csName = "C#"

cstop :: Doc -> Doc -> Doc
cstop end inc = vcat [
  inc <+> text "System" <> end,
  inc <+> text "System.IO" <> end,
  inc <+> text "System.Collections" <> end,
  inc <+> text "System.Collections.Generic" <> end]

csFloatTypeDoc :: TypeData
csFloatTypeDoc = td Float "double" (text "double") -- Same as Java, maybe make a common function

csInfileTypeDoc :: TypeData
csInfileTypeDoc = td File "StreamReader" (text "StreamReader")

csOutfileTypeDoc :: TypeData
csOutfileTypeDoc = td File "StreamWriter" (text "StreamWriter")

csCast :: CSharpCode (Type CSharpCode) -> CSharpCode (Value CSharpCode) -> 
  CSharpCode (Value CSharpCode)
csCast t v = csCast' (getType t) (getType $ valueType v)
  where csCast' Float String = funcApp "Double.Parse" float [v]
        csCast' _ _ = liftA2 mkVal t $ liftA2 castObjDocD (fmap castDocD t) v

csThrowDoc :: ValData -> Doc
csThrowDoc errMsg = text "throw new" <+> text "Exception" <> 
  parens (valDoc errMsg)

csTryCatch :: Doc -> Doc -> Doc
csTryCatch tb cb= vcat [
  text "try" <+> lbrace,
  indent tb,
  rbrace <+> text "catch" <+> 
    lbrace,
  indent cb,
  rbrace]

csDiscardInput :: ValData -> Doc
csDiscardInput = valDoc

csInput :: TypeData -> ValData -> ValData
csInput t inFn = mkVal t $ text (csInput' (cType t)) <> 
  parens (valDoc inFn)
  where csInput' Integer = "Int32.Parse"
        csInput' Float = "Double.Parse"
        csInput' Boolean = "Boolean.Parse"
        csInput' String = ""
        csInput' Char = "Char.Parse"
        csInput' _ = error "Attempt to read value of unreadable type"

csFileInput :: ValData -> ValData
csFileInput f = mkVal (valType f) (valDoc f <> dot <> text "ReadLine()")

csOpenFileR :: ValData -> TypeData -> ValData
csOpenFileR n r = mkVal r $ new <+> typeDoc r <> 
  parens (valDoc n)

csOpenFileWorA :: ValData -> TypeData -> ValData -> ValData
csOpenFileWorA n w a = mkVal w $ new <+> typeDoc w <> 
  parens (valDoc n <> comma <+> valDoc a)

csRef :: Doc -> Doc
csRef p = text "ref" <+> p

csOut :: Doc -> Doc
csOut p = text "out" <+> p

csInOutCall :: (Label -> CSharpCode (Type CSharpCode) -> 
  [CSharpCode (Value CSharpCode)] -> CSharpCode (Value CSharpCode)) -> Label -> 
  [CSharpCode (Value CSharpCode)] -> [CSharpCode (Variable CSharpCode)] -> 
  [CSharpCode (Variable CSharpCode)] -> CSharpCode (Statement CSharpCode)
csInOutCall f n ins [out] [] = assign out $ f n (variableType out) ins
csInOutCall f n ins [] [out] = if null (filterOutObjs [out])
  then valState $ f n void (valueOf out : ins) 
  else assign out $ f n (variableType out) (valueOf out : ins)
csInOutCall f n ins outs both = valState $ f n void (map (fmap (updateValDoc 
  csRef) . valueOf) both ++ ins ++ map (fmap (updateValDoc csOut) . valueOf) 
  outs)

csVarDec :: Binding -> CSharpCode (Statement CSharpCode) -> 
  CSharpCode (Statement CSharpCode)
csVarDec Static _ = error "Static variables can't be declared locally to a function in C#. Use stateVar to make a static state variable instead."
csVarDec Dynamic d = d

csObjVar :: VarData -> VarData -> VarData
csObjVar o v = csObjVar' (varBind v)
  where csObjVar' Static = error 
          "Cannot use objVar to access static variables through an object in C#"
        csObjVar' Dynamic = mkVar (varName o ++ "." ++ varName v) 
          (varType v) (objVarDocD (varDoc o) (varDoc v))