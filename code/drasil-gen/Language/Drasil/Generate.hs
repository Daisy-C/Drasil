module Language.Drasil.Generate (gen, genDot, genCode, DocType(..), DocSpec(DocSpec), Format(TeX, HTML), DocChoices(DC), DebugOption(..), docChoices) where

import System.IO (hClose, hPutStrLn, openFile, IOMode(WriteMode))
import Text.PrettyPrint.HughesPJ (Doc, render)
import Prelude hiding (id)
import System.Directory (createDirectoryIfMissing, getCurrentDirectory,
  setCurrentDirectory)
import Data.Time.Clock (getCurrentTime, utctDay)
import Data.Time.Calendar (showGregorian)

import Build.Drasil (genMake)
import Language.Drasil
import Drasil.DocLang (mkGraphInfo)
import Database.Drasil (SystemInformation)
import Language.Drasil.Printers (Format(TeX, HTML, JSON), 
 makeCSS, genHTML, genTeX, genJSON, PrintingInformation, outputDot)
import Language.Drasil.Code (generator, generateCode, Choices(..), CodeSpec(..),
  Lang(..), getSampleData, readWithDataDesc, sampleInputDD, 
  unPP, unJP, unCSP, unCPPP, unSP)
import Language.Drasil.Output.Formats(DocType(SRS, Website, Jupyter), Filename, DocSpec(DocSpec), DocChoices(DC), DebugOption(..))

import GOOL.Drasil (unJC, unPC, unCSC, unCPPC, unSC)

-- | Generate a number of artifacts based on a list of recipes.
gen :: DocSpec -> Document -> PrintingInformation -> IO ()
gen ds fn sm = prnt sm ds fn

-- TODO: Include Jupyter into the SRS setup.
-- | Generate the output artifacts (TeX+Makefile or HTML).
prnt :: PrintingInformation -> DocSpec -> Document -> IO ()
prnt sm (DocSpec (DC Jupyter _ _) fn) body =
  do prntDoc body sm fn Jupyter JSON
prnt sm (DocSpec (DC dtype fmts dbugOp) fn) body =
  do prntDebug dbugOp body sm
     mapM_ (prntDoc body sm fn dtype) fmts

-- | Helper for writing the documents (TeX / HTML) to file.
prntDoc :: Document -> PrintingInformation -> String -> DocType -> Format -> IO ()
prntDoc d pinfo fn Jupyter _ = prntDoc' "Jupyter" fn JSON d pinfo
prntDoc d pinfo fn dtype fmt =
  case fmt of
    HTML -> do prntDoc' (show dtype ++ "/HTML") fn HTML d pinfo
               prntCSS dtype fn d
    TeX -> do prntDoc' (show dtype ++ "/PDF") fn TeX d pinfo
              prntMake $ DocSpec (DC dtype [] NoDebug) fn
    _ -> mempty

-- | Helper that takes the directory name, document name, format of documents,
-- document information and printing information. Then generates the document file.
prntDoc' :: String -> String -> Format -> Document -> PrintingInformation -> IO ()
prntDoc' dt' fn format body' sm = do
  createDirectoryIfMissing True dt'
  outh <- openFile (dt' ++ "/" ++ fn ++ getExt format) WriteMode
  hPutStrLn outh $ render $ writeDoc sm format fn body'
  hClose outh
  where getExt TeX  = ".tex"
        getExt HTML = ".html"
        getExt JSON = ".ipynb"
        getExt _    = error "We can only write in TeX, HTML and in Python Notebooks (for now)."

-- | Helper for writing the Makefile(s).
prntMake :: DocSpec -> IO ()
prntMake ds@(DocSpec (DC dt _ _) _) =
  do outh <- openFile (show dt ++ "/PDF/Makefile") WriteMode
     hPutStrLn outh $ render $ genMake [ds]
     hClose outh

-- | Helper that creates a CSS file to accompany an HTML file.
-- Takes in the folder name, generated file name, and the document.
prntCSS :: DocType -> String -> Document -> IO ()
prntCSS docType fn body = do
  outh2 <- openFile (getFD docType ++ fn ++ ".css") WriteMode
  hPutStrLn outh2 $ render (makeCSS body)
  hClose outh2
  where
    getFD dtype = show dtype ++ "/HTML/"

-- | Renders the documents.
writeDoc :: PrintingInformation -> Format -> Filename -> Document -> Doc
writeDoc s TeX  _  doc = genTeX doc s
writeDoc s HTML fn doc = genHTML s fn doc
writeDoc s JSON _ doc  = genJSON s doc
writeDoc _    _  _   _ = error "we can only write TeX/HTML (for now)"

-- | Generates traceability graphs as .dot files.
genDot :: SystemInformation -> IO ()
genDot si = do
    let gi = mkGraphInfo si
    outputDot "TraceyGraph" gi
    return mempty

-- | Currently does nothing. Sets up option for creating a log as per #2759.
prntDebug :: DebugOption -> Document -> PrintingInformation -> IO ()
prntDebug _ _ _ = mempty

-- | Calls the code generator.
genCode :: Choices -> CodeSpec -> IO ()
genCode chs spec = do 
  workingDir <- getCurrentDirectory
  time <- getCurrentTime
  sampData <- maybe (return []) (\sd -> readWithDataDesc sd $ sampleInputDD 
    (extInputs spec)) (getSampleData chs)
  createDirectoryIfMissing False "src"
  setCurrentDirectory "src"
  let genLangCode Java = genCall Java unJC unJP
      genLangCode Python = genCall Python unPC unPP
      genLangCode CSharp = genCall CSharp unCSC unCSP
      genLangCode Cpp = genCall Cpp unCPPC unCPPP
      genLangCode Swift = genCall Swift unSC unSP
      genCall lng unProgRepr unPackRepr = generateCode lng unProgRepr 
        unPackRepr $ generator lng (showGregorian $ utctDay time) sampData chs spec
  mapM_ genLangCode (lang chs)
  setCurrentDirectory workingDir

-- | Constructor for users to choose their document options
docChoices :: DocType -> [Format] -> DebugOption -> DocChoices
docChoices = DC