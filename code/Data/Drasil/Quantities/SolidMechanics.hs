module Data.Drasil.Quantities.SolidMechanics where

import Language.Drasil
import Data.Drasil.Concepts.SolidMechanics as CSM
import Data.Drasil.SI_Units

elastMod, shearRes, stffness :: UnitalChunk

elastMod = uc CSM.elastMod cE pascal
shearRes = uc CSM.shearRes cP newton
stffness = uc CSM.stffness cK stiffnessU