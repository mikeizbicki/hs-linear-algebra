-----------------------------------------------------------------------------
-- |
-- Module     : Data.Matrix.Dense
-- Copyright  : Copyright (c) , Patrick Perry <patperry@stanford.edu>
-- License    : BSD3
-- Maintainer : Patrick Perry <patperry@stanford.edu>
-- Stability  : experimental
--

module Data.Matrix.Dense (
    module Data.Matrix.Dense.Internal,
    
    -- * Matrix and vector multiplication
    module BLAS.Matrix.Immutable,
    
    -- * Converting between mutable and immutable matrices
    UnsafeFreezeMatrix(..),
    UnsafeThawMatrix(..),
    freezeMatrix,
    thawMatrix,
    ) where

import BLAS.Elem
import Data.Matrix.Dense.Internal hiding ( M )
import qualified Data.Matrix.Dense.Internal as I
import Data.Matrix.Dense.ST
import Data.Matrix.Dense.IO
import BLAS.Matrix.Immutable

class UnsafeFreezeMatrix a where
    unsafeFreezeMatrix :: a mn e -> Matrix mn e
instance UnsafeFreezeMatrix IOMatrix where
    unsafeFreezeMatrix = I.M
instance UnsafeFreezeMatrix (STMatrix s) where
    unsafeFreezeMatrix = unsafeFreezeMatrix . unsafeSTMatrixToIOMatrix    
    
class UnsafeThawMatrix a where
    unsafeThawMatrix :: Matrix mn e -> a mn e
instance UnsafeThawMatrix IOMatrix where
    unsafeThawMatrix (I.M a) = a
instance UnsafeThawMatrix (STMatrix s) where
    unsafeThawMatrix = unsafeIOMatrixToSTMatrix . unsafeThawMatrix
    
freezeMatrix :: (ReadMatrix a x e m, WriteMatrix b y e m, UnsafeFreezeMatrix b, BLAS1 e) =>
    a mn e -> m (Matrix mn e)
freezeMatrix x = do
    x' <- newCopyMatrix x
    return (unsafeFreezeMatrix x')

thawMatrix :: (WriteMatrix a y e m, BLAS1 e) =>
    Matrix mn e -> m (a mn e)
thawMatrix = newCopyMatrix
