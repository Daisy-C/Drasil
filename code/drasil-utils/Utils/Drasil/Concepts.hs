module Utils.Drasil.Concepts where

import Language.Drasil
import Utils.Drasil.Phrase
import Utils.Drasil.Sentence

-----------------
-- TO DO -> NOUNPHRASE HAS WRONG TYPE FOR THIS, NEED NOUNPHRASE''
----------------

--Maybe add more generalized versions of these?
-- | Helper function that places a string in between two 'NP's. Plural is defaulted to
-- @phraseNP t1 +:+ S s +:+ pluralNP t2@
insertStringNP :: String -> NP -> NP -> NP 
insertStringNP s t1 t2 = nounPhrase'' (phraseNP t1 +:+ S s +:+ phraseNP t2) (phraseNP t1 +:+ S s +:+ pluralNP t2) CapFirst CapWords
-- | Helper function that prepends a string to a 'NP'
prependStringNP :: String -> NP -> NP
prependStringNP s t1 = nounPhrase'' (S s +:+ phraseNP t1) (S s +:+ pluralNP t1) CapFirst CapWords
-- | Helper function that places a Sentence in between two 'NP's. Plural is defaulted to
-- @phraseNP t1 +:+ s +:+ pluralNP t2@
insertSentNP :: Sentence -> NP -> NP -> NP
insertSentNP s t1 t2 = nounPhrase'' (phraseNP t1 +:+ s +:+ phraseNP t2) (phraseNP t1 +:+ s +:+ pluralNP t2) CapFirst CapWords
-- | Helper function that prepends a 'Sentence' to a 'NP'
prependSentNP :: Sentence -> NP -> NP
prependSentNP s t1 = nounPhrase'' (s +:+ phraseNP t1) (s +:+ pluralNP t1) CapFirst CapWords

-- | Prepends "the" to a 'NP'
theNP :: NP -> NP
theNP t1 = prependStringNP "the" t1
-- | Similar to 'theNP', but accepts a function that determines the plural case
theNP' :: (NP -> Sentence) -> NP -> NP
theNP' f1 t1 = nounPhrase'' (S "the" +:+ phraseNP t1) (S "the" +:+ f1 t1) CapFirst CapWords

-- | Prepends "a" to a 'NP'
aNP :: NP -> NP
aNP t1 = prependStringNP "a" t1
-- | Similar to 'aNP', but accepts a function that determines the plural case
aNP' :: (NP -> Sentence) -> NP -> NP
aNP' f1 t1 = nounPhrase'' (S "a" +:+ phraseNP t1) (S "a" +:+ f1 t1) CapFirst CapWords

-- | Inserts "of the" between two 'NP's
ofTheNP :: NP -> NP -> NP
ofTheNP t1 t2 = insertStringNP "of the" t1 t2
-- | Similar to 'ofTheNP', but the plural case is now @pluralNP t1 `ofThe` phraseNP t2@
ofTheNP' :: NP -> NP -> NP
ofTheNP' t1 t2 = nounPhrase'' (phraseNP t1 `ofThe` phraseNP t2) (pluralNP t1 `ofThe` phraseNP t2) CapFirst CapWords
-- | Similar to 'ofTheNP', but accepts two functions for the plural case
ofTheNP'' :: (NP -> Sentence) -> (NP -> Sentence) -> NP -> NP -> NP
ofTheNP'' f1 f2 t1 t2 = nounPhrase'' (phraseNP t1 `ofThe` phraseNP t2) (f1 t1 `ofThe` f2 t2) CapFirst CapWords

-- | Prepends "the" and inserts "of the"
the_ofTheNP :: NP -> NP -> NP
the_ofTheNP t1 t2 = theNP t1 `ofTheNP` t2
-- | Similar to 'the_ofTheNP', but the plural case is now @ S "the" +:+ pluralNP t1 `ofThe` phraseNP t2@
the_ofTheNP' :: NP -> NP -> NP
the_ofTheNP' t1 t2 = theNP t1 `ofTheNP'` t2
-- | Similar to 'the_ofTheNP'', but takes two functions for the plural case
the_ofTheNP'' :: (NP -> Sentence) -> (NP -> Sentence) -> NP -> NP -> NP
the_ofTheNP'' f1 f2 t1 t2 = ofTheNP'' f1 f2 (theNP t1) t2

-- | Inserts "for" between two 'NP's
forNP :: NP -> NP -> NP
forNP t1 t2 = insertStringNP "for" t1 t2 
--FIXME: Change "for" to sFor
-- | Same as 'forNP', but plural case is now @pluralNP t1 `sFor` phraseNP t2@
forNP' :: NP -> NP -> NP
forNP' t1 t2 = nounPhrase'' (phraseNP t1 +:+ S "for" +:+ phraseNP t2) (pluralNP t1 +:+ S "for" +:+ phraseNP t2) CapFirst CapWords
-- | Same as 'forNP'', but takes two functions for the plural case
forNP'' :: (NP -> Sentence) -> (NP -> Sentence) -> NP -> NP -> NP
forNP'' f1 f2 t1 t2 = nounPhrase'' (phraseNP t1 +:+ S "for" +:+ phraseNP t2) (f1 t1 +:+ S "for" +:+ f2 t2) CapFirst CapWords

-- | Inserts "of" between two 'NP's
ofNP :: NP -> NP -> NP
ofNP t1 t2 = insertStringNP "of" t1 t2
-- | Same as 'ofNP', but plural case is now @pluralNP t1 `sOf` phraseNP t2@
ofNP' :: NP -> NP -> NP
ofNP' t1 t2 = nounPhrase'' (phraseNP t1 `sOf` phraseNP t2) (pluralNP t1 `sOf` phraseNP t2) CapFirst CapWords
-- | Same as 'ofNP', but takes two functions for the plural case
ofNP'' :: (NP -> Sentence) -> (NP -> Sentence) -> NP -> NP -> NP
ofNP'' f1 f2 t1 t2 = nounPhrase'' (phraseNP t1 `sOf` phraseNP t2) (f1 t1 `sOf` f2 t2) CapFirst CapWords
-- | Same as 'ofNP', but takes two functions for the singular case and two for the plural case
ofNP''' :: (NP -> Sentence) -> (NP -> Sentence) -> (NP -> Sentence) -> (NP -> Sentence) -> NP -> NP -> NP
ofNP''' f1 f2 p1 p2 t1 t2 = nounPhrase'' (f1 t1 `sOf` f1 t2) (p1 t1 `sOf` p2 t2) CapFirst CapWords

-- | Inserts "with" between two 'NP's
withNP :: NP -> NP -> NP
withNP t1 t2 = insertStringNP "with" t1 t2

-- | Inserts "and" between two 'NP's
andNP :: NP -> NP -> NP
andNP t1 t2 = insertStringNP "and" t1 t2
-- | Same as 'andNP', but plural case is now @pluralNP t1 `sAnd` phraseNP t2@
andNP' :: NP -> NP -> NP
andNP' t1 t2 = nounPhrase'' (phraseNP t1 `sAnd` phraseNP t2) (pluralNP t1 `sAnd` phraseNP t2) CapFirst CapWords
-- | Same as 'andNP', but takes two functions for the plural case
andNP'' :: (NP -> Sentence) -> (NP -> Sentence) -> NP -> NP -> NP
andNP'' f1 f2 t1 t2 = nounPhrase'' (phraseNP t1 `sAnd` phraseNP t2) (f1 t1 `sAnd` f2 t2) CapFirst CapWords
-- | Same as 'andNP', but takes two functions for the singular case and two for the plural case
andNP''' :: (NP -> Sentence) -> (NP -> Sentence) -> (NP -> Sentence) -> (NP -> Sentence) -> NP -> NP -> NP
andNP''' f1 f2 p1 p2 t1 t2 = nounPhrase'' (f1 t1 `sAnd` f1 t2) (p1 t1 `sAnd` p2 t2) CapFirst CapWords