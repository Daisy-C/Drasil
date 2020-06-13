-- | Defines the underlying data types used in the package extension.
module Language.Drasil.Code.Imperative.GOOL.Data (AuxData(auxFilePath, auxDoc), 
  ad, PackData(packProg, packAux), packD
) where

import GOOL.Drasil (ProgData)

import Text.PrettyPrint.HughesPJ (Doc)

-- The underlying data type for auxiliary files in all renderers
data AuxData = AD {auxFilePath :: FilePath, auxDoc :: Doc}

ad :: FilePath -> Doc -> AuxData
ad = AD

-- The underlying data type for packages in all renderers
data PackData = PackD {packProg :: ProgData, packAux :: [AuxData]}

packD :: ProgData -> [AuxData] -> PackData
packD = PackD
