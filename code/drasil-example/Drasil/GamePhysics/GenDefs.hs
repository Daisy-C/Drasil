module Drasil.GamePhysics.GenDefs (generalDefns, accelGravityGD, impulseGD,
 ) where

import Language.Drasil
import Utils.Drasil
--import Data.Drasil.Concepts.Physics as CP (rigidBody, time)
import Theory.Drasil (GenDefn, gd)
import qualified Data.Drasil.Quantities.Physics as QP (acceleration,
 gravitationalAccel, gravitationalConst, restitutionCoef, impulseS)
import Drasil.GamePhysics.Unitals (mLarger, dispNorm, dispUnit, massA, massB,
  momtInertA, momtInertB, normalLen, normalVect, perpLenA, perpLenB, initRelVel)
import Drasil.GamePhysics.DataDefs (collisionAssump, rightHandAssump,
  rigidTwoDAssump)

----- General Models -----

generalDefns :: [GenDefn]
generalDefns = [accelGravityGD, impulseGD]


{-conservationOfMomentGDef :: RelationConcept
conservationOfMomentGDef = makeRC "conservOfMoment" (nounPhraseSP "Conservation of Momentum") 
  conservationOfMomentDesc conservationOfMomentRel

conservationOfMomentRel :: Relation
conservationOfMomentRel = UnaryOp $ Summation Nothing
  C massI

conservationOfMomentDesc :: Sentence
conservationOfMomentDesc = foldlSent [S "In an isolated system,",
  S "where the sum of external", phrase impulseS, S "acting on the system is zero,",
  S "the total momentum of the bodies is constant (conserved)"
  ]

--[mass, initialVelocity, finalVelocity]

conservationOfMomentDeriv :: Sentence
conservationOfMomentDeriv = foldlSent [S "When bodies collide, they exert",
  S "an equal (force) on each other in opposite directions" +:+.
  S "This is Newton's third law:",
  S "(expr1)",
  S "The objects collide with each other for the exact same amount of", 
  phrase time, getS time,
  S "The above equation is equal to the", phrase impulseS, 
  S "(GD1 ref)",
  S "(expr2)",
  S "The", phrase impulseS, S "is equal to the change in momentum:",
  S "(expr3)",
  S "Substituting 2*ref to 2* into 1*ref to 1* yields:",
  S "(expr4)",
  S "Expanding and rearranging the above formula gives",
  S "(expr5)",
  S "Generalizing for multiple (k) colliding objects:",
  S "(expr6)"
  ]
-}


--------------------------Acceleration due to gravity----------------------------
accelGravityGD :: GenDefn
accelGravityGD = gd accelGravityRC (getUnit QP.acceleration) (Just accelGravityDeriv)
   [accelGravitySrc] "accelGravity" [{-Notes-}]
  

accelGravityRC :: RelationConcept
accelGravityRC = makeRC "accelGravityRC" (nounPhraseSP "Acceleration due to gravity") 
  accelGravityDesc accelGravityRel

accelGravityRel :: Relation
accelGravityRel = sy QP.gravitationalAccel $=  sy QP.gravitationalConst * sy mLarger/
                  (sy dispNorm $^ 2) * sy dispUnit

accelGravitySrc :: Reference
accelGravitySrc = makeURI "accelGravitySrc" "https://en.wikipedia.org/wiki/Gravitational_acceleration" $
  shortname' "Definition of Gravitational Acceleration"

accelGravityDesc :: Sentence
accelGravityDesc = foldlSent [S "Acceleration due to gravity"]

accelGravityDeriv :: Derivation
accelGravityDeriv = mkDerivName (phrase QP. gravitationalAccel)
                      (weave [accelGravityDerivSentences, map E accelGravityDerivEqns])

accelGravityDerivSentences :: [Sentence]
accelGravityDerivSentences = map foldlSentCol [accelGravityDerivSentence1, 
 accelGravityDerivSentence2, accelGravityDerivSentence3] 

accelGravityDerivSentence1 :: Sentence
accelGravityDerivSentence1 = [S "From Newton's law of universal gravitation", ]
              S "The above equation governs the gravitational attraction between two bodies",
              S "Suppose that one of the bodies is significantly more massive than the other" `Sc`
              S "so that we concern ourselves with the" phrase force , S "the massive body",
              S "exerts on the lighter body" +:+. S "Further suppose that the", phrase cartesian `sIs`
              S "is chosen such that this", phrase force, S "acts on a", phrase line, 
              S "which lies along one of the principal axes", sParen (makeRef2S rigidTwoDAssump), 
              S "Then our", phrase dispunit, 

              --   S "light body, respectively" +:+. S "Using 3 **ref to 3** and equating this",
--   S "with Newton's second law (T1 ref) for the force experienced by the light",
--   S "body, we get:",
--   S "(expr3)",
--   S "where", getS gravitationalConst, S "is", phrase gravitationalAccel,
--   S "Dividing 4 **ref to 4**",
--   S "by m, and resolving this into separate x and y components:",
--   S "(expr4)",
--   S "(expr5)",
--   S "Thus:",
--   S "(expr6)"
--   ]

----------------------------Impulse for Collision--------------------------------------------

impulseGD :: GenDefn
impulseGD = gd impulseRC (getUnit QP.impulseS) Nothing 
  [impulseSrc] "impulse" [rigidTwoDAssump, rightHandAssump, collisionAssump]

impulseRC :: RelationConcept
impulseRC = makeRC "impulseRC" (nounPhraseSP "Impulse for Collision") 
  impulseDesc impulseRel

impulseRel :: Relation
impulseRel = sy QP.impulseS $= (negate (1 + sy QP.restitutionCoef) * sy initRelVel $.
  sy normalVect) / (((1 / sy massA) + (1 / sy massB)) *
  (sy normalLen $^ 2) +
  ((sy perpLenA $^ 2) / sy momtInertA) +
  ((sy perpLenB $^ 2) / sy momtInertB))

impulseSrc :: Reference
impulseSrc = makeURI "impulseSrc" "http://www.chrishecker.com/images/e/e7/Gdmphys3.pdf" $
  shortname' "Impulse for Collision Ref"

impulseDesc :: Sentence
impulseDesc = foldlSent [S "Impulse for Collision"]
