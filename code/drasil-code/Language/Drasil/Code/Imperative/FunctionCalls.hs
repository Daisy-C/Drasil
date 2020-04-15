module Language.Drasil.Code.Imperative.FunctionCalls (
  getAllInputCalls, getInputCall, getDerivedCall, getConstraintCall, 
  getCalcCall, getOutputCall
) where

import Language.Drasil.Code.Imperative.GenerateGOOL (fApp, fAppInOut)
import Language.Drasil.Code.Imperative.Import (codeType, mkVal, mkVar)
import Language.Drasil.Code.Imperative.Logging (maybeLog)
import Language.Drasil.Code.Imperative.Parameters (getCalcParams, 
  getConstraintParams, getDerivedIns, getDerivedOuts, getInputFormatIns, 
  getInputFormatOuts, getOutputParams)
import Language.Drasil.Code.Imperative.DrasilState (DrasilState(..))
import Language.Drasil.Chunk.Code (CodeIdea(codeName), CodeVarChunk, quantvar)
import Language.Drasil.Chunk.CodeDefinition (CodeDefinition)

import GOOL.Drasil (VSType, SValue, MSStatement, ProgramSym, TypeSym(..), 
  VariableValue(..), StatementSym(..), DeclStatement(..), convType)

import Data.List ((\\), intersect)
import qualified Data.Map as Map (lookup)
import Data.Maybe (catMaybes)
import Control.Applicative ((<|>))
import Control.Monad.Reader (Reader, ask)

getAllInputCalls :: (ProgramSym r) => Reader DrasilState [MSStatement r]
getAllInputCalls = do
  gi <- getInputCall
  dv <- getDerivedCall
  ic <- getConstraintCall
  return $ catMaybes [gi, dv, ic]

getInputCall :: (ProgramSym r) => Reader DrasilState 
  (Maybe (MSStatement r))
getInputCall = getInOutCall "get_input" getInputFormatIns getInputFormatOuts

getDerivedCall :: (ProgramSym r) => Reader DrasilState 
  (Maybe (MSStatement r))
getDerivedCall = getInOutCall "derived_values" getDerivedIns getDerivedOuts

getConstraintCall :: (ProgramSym r) => Reader DrasilState 
  (Maybe (MSStatement r))
getConstraintCall = do
  val <- getFuncCall "input_constraints" void getConstraintParams
  return $ fmap valState val

getCalcCall :: (ProgramSym r) => CodeDefinition -> Reader DrasilState 
  (Maybe (MSStatement r))
getCalcCall c = do
  t <- codeType c
  val <- getFuncCall (codeName c) (convType t) (getCalcParams c)
  v <- mkVar $ quantvar c
  l <- maybeLog v
  return $ fmap (multi . (: l) . varDecDef v) val

getOutputCall :: (ProgramSym r) => Reader DrasilState 
  (Maybe (MSStatement r))
getOutputCall = do
  val <- getFuncCall "write_output" void getOutputParams
  return $ fmap valState val

getFuncCall :: (ProgramSym r) => String -> VSType r -> 
  Reader DrasilState [CodeVarChunk] -> Reader DrasilState (Maybe (SValue r))
getFuncCall n t funcPs = do
  mm <- getCall n
  let getFuncCall' Nothing = return Nothing
      getFuncCall' (Just m) = do
        cs <- funcPs
        pvals <- mapM mkVal cs
        val <- fApp m n t pvals []
        return $ Just val
  getFuncCall' mm

getInOutCall :: (ProgramSym r) => String -> 
  Reader DrasilState [CodeVarChunk] -> Reader DrasilState [CodeVarChunk] ->
  Reader DrasilState (Maybe (MSStatement r))
getInOutCall n inFunc outFunc = do
  mm <- getCall n
  let getInOutCall' Nothing = return Nothing
      getInOutCall' (Just m) = do
        ins' <- inFunc
        outs' <- outFunc
        ins <- mapM mkVar (ins' \\ outs')
        outs <- mapM mkVar (outs' \\ ins')
        both <- mapM mkVar (ins' `intersect` outs')
        stmt <- fAppInOut m n (map valueOf ins) outs both
        return $ Just stmt
  getInOutCall' mm
  
-- Gets the name of the module containing the function being called
-- If the function is not in either module export map or class definition map, 
--   return Nothing
-- If the function is not in module export map but is in class definition map, 
-- that means it is a private function, so return Nothing unless it is in the 
-- current class
getCall :: String -> Reader DrasilState (Maybe String)
getCall n = do
  g <- ask
  let currc = currentClass g
      getCallExported Nothing = getCallInClass (Map.lookup n $ clsMap g)
      getCallExported m = return m
      getCallInClass Nothing = return Nothing
      getCallInClass (Just c) = if c == currc then return $ Map.lookup c (eMap 
        g) <|> error (c ++ " class missing from export map")
        else return Nothing
  getCallExported $ Map.lookup n (eMap g)
