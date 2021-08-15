module Drasil.NBSections.Introduction (introductionSection, purposeOfDoc) where

import Language.Drasil
import qualified Drasil.DocLang.Notebook as NB (intro, prpsOfDoc)

-- | Constructor for the Notebook introduction section
-- problemIntroduction - Sentence introducing the specific example problem
-- programDefinition  - Sentence definition of the specific example
-- **** programDefinition : maybe just topic 
introductionSection :: [Contents] -> Section
introductionSection = NB.intro 0

-- | Constructor for purpose of document subsection
-- purposeOfProgramParagraph - a sentence explaining the purpose of the document
purposeOfDoc :: [Sentence] -> Section
purposeOfDoc [purposeOfProgram] = NB.prpsOfDoc 1 [mkParagraph purposeOfProgram]
purposeOfDoc _ = NB.prpsOfDoc 1 []