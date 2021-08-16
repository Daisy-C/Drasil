module Drasil.Sections.GeneralSystDesc where

import Language.Drasil
import Utils.Drasil
import Utils.Drasil.Sentence

import Data.Drasil.Concepts.Documentation (interface, system, environment,
  userCharacteristic, systemConstraint, information, section_)
import qualified Drasil.DocLang.SRS as SRS (sysCon, sysCont, userChar)

-- | Default General System Description introduction.
genSysIntro :: Contents
genSysIntro = foldlSP [S "This", phrase section_, S "provides general",
  phrase information, S "about the" +:+. phrase system, S "It identifies the",
  plural interface, S "between the", phrase system `andIts` phrase environment `sC`
  S "describes the", plural userCharacteristic `sC` S "and lists the", plural systemConstraint]

-- | User Characeristics.
usrCharsF :: [Contents] -> Section
usrCharsF = SRS.userChar 1

-- | System Constraints.
-- Generalized if no constraints, but if there are, they can be passed through.
-- subsec is removed ([Contents] -> [Sections] -> Section before), add if needed.  
systCon :: [Contents] -> Section
systCon [] = SRS.sysCon 1 [systCon_none] 
            where systCon_none = mkParagraph (S "There are no" +:+. plural systemConstraint)
systCon a  = SRS.sysCon 1 a 

-- | System Context.
sysContxt :: [Contents] -> Section
sysContxt = SRS.sysCont 1
