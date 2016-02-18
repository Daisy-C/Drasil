{-# OPTIONS -Wall #-} 
{-# LANGUAGE GADTs, Rank2Types #-}
module UnitalChunk (UnitalChunk(..), makeUC) where

import Chunk (Chunk(..), Concept(..), Quantity(..), VarChunk(..))
import Unit (Unit(..), UnitDefn(..))
import Symbol
import Control.Lens (Simple, Lens, (^.), set)

--BEGIN HELPER FUNCTIONS--
makeUC :: Unit u => String -> String -> Symbol -> u -> UnitalChunk
makeUC nam desc sym un = UC (VC nam desc sym) un

qlens :: (forall c. Quantity c => Simple Lens c a) -> Simple Lens Q a
qlens l f (Q a) = fmap (\x -> Q (set l x a)) (f (a ^. l))

-- these don't get exported
q :: Simple Lens UnitalChunk Q
q f (UC a b) = fmap (\(Q x) -> UC x b) (f (Q a))

u :: Simple Lens UnitalChunk UnitDefn
u f (UC a b) = fmap (\(UU x) -> UC a x) (f (UU b))
--END HELPER FUNCTIONS----

-------- BEGIN DATATYPES/INSTANCES --------

-- BEGIN Q --
data Q where
  Q :: Quantity c => c -> Q

instance Chunk Q where 
  name = qlens name

instance Concept Q where 
  descr = qlens descr

instance Quantity Q where
  symbol = qlens symbol
-- END Q ----

-- BEGIN UNITALCHUNK --
data UnitalChunk where
  UC :: (Quantity c, Unit u) => c -> u -> UnitalChunk

instance Chunk UnitalChunk where
  name = q . name

instance Concept UnitalChunk where
  descr = q . descr

instance Quantity UnitalChunk where
  symbol = q . symbol

instance Unit UnitalChunk where
  unit = u . unit
-- END UNITALCHUNK ----