{-# OPTIONS -Wall #-}
{-# LANGUAGE FlexibleContexts #-} 
module Drasil.SWHS.TModel1 where

import Drasil.SWHS.Unitals
import Drasil.SWHS.Concepts

import Language.Drasil
import Prelude hiding (id)
import Data.Drasil.Concepts.Thermodynamics
import Data.Drasil.Quantities.Math (gradient)

import Control.Lens ((^.))

s4_2_2_T1 :: Contents
s4_2_2_T1 = Definition (Theory t1ConsThermE)

t1ConsThermE :: RelationChunk
t1ConsThermE = makeRC "Conservation of thermal energy" t1descr consThermERel

consThermERel :: Relation
consThermERel = (Neg (C gradient)) :. (C thFluxVect) + (C vol_ht_gen) :=
                (C density) * (C htCap) * (Deriv Part (C temp) (C time))

t1descr :: Sentence
t1descr = (S "The above equation gives the " :+: (sLower
          (law_cons_energy ^. term)) :+: S " for " :+: (sLower
          ((transient ^. term))) :+: S " " :+: (sLower (heat_trans ^. term)) :+:
          S " in a material of " :+: (htCap ^. defn) :+: S " " :+: 
          P (htCap ^. symbol) :+: S " (" :+: Sy (htCap ^. unit) :+: S ") " :+:
          S "and " :+: (density ^. defn) :+: S ", " :+: 
          P (density ^. symbol) :+: S " (" :+: Sy (density ^. unit) :+: 
          S "), where " :+: P (thFluxVect ^. symbol) :+: S " is the " :+: 
          (thFluxVect ^. defn) :+: S " (" :+: Sy (thFluxVect ^. unit) :+:
          S "), " :+: P (vol_ht_gen ^. symbol) :+: S " is the " :+: 
          (vol_ht_gen ^. defn) :+: S " (" :+: Sy (vol_ht_gen ^. unit) :+: 
          S "), " :+: P (temp ^. symbol) :+: S " is the " :+: 
          (temp ^. defn) :+: S " (" :+: Sy (temp ^. unit) :+: S "), " :+: 
          P (time ^. symbol) :+: S " is " :+: (time ^. defn) :+: S " (" :+: 
          Sy (time ^. unit) :+: S "), and " :+: P (gradient ^. symbol) :+: 
          S " is the " :+: (gradient ^. defn) :+: S ". For this equation " :+: 
          S "to apply, " :+: S "other forms of energy, such as " :+:
          (sLower(mech_energy ^. term)) :+: 
          S ", are assumed to be negligible in the system (A1).")

--referencing within a simple list is not yet implemented.
--Forgot many "S" and ":+:" typing out above description
---- lost a lot of time fixing
