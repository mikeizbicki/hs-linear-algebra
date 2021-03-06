{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
{-# OPTIONS_HADDOCK hide #-}
-----------------------------------------------------------------------------
-- |
-- Module     : Data.Matrix.Class.ISolveBase
-- Copyright  : Copyright (c) , Patrick Perry <patperry@stanford.edu>
-- License    : BSD3
-- Maintainer : Patrick Perry <patperry@stanford.edu>
-- Stability  : experimental
--
-- An overloaded interface for solving immutable matrix systems.  The
-- matrices can operate via inverse multiplication on immutable dense
-- vectors and matrices.
--

module Data.Matrix.Class.ISolveBase (
    -- * The IMatrix type class
    ISolve(..),
    
    -- * Operators
    (<\>),
    (<\\>),
    
    -- * Solving linear systems
    solveVector,
    solveMatrix,
    ssolveVector,
    ssolveMatrix,
    
    ) where

import Data.Elem.BLAS
import BLAS.Internal ( checkMatVecSolv, checkMatMatSolv )
import Data.Matrix.Class
import Data.Matrix.Class.MSolveBase

import Data.Tensor.Class.ITensor( (*>) )
import Data.Vector.Dense ( Vector, dim )
import Data.Vector.Dense.ST ( runSTVector )
import Data.Matrix.Dense ( Matrix, shape )
import Data.Matrix.Dense.ST ( runSTMatrix )
import Data.Matrix.TriBase

infixr 7 <\>, <\\>


-- | A type class for immutable matrices with inverses.  The member
-- functions of the type class do not perform any checks on the validity
-- of shapes or indices, so in general their safe counterparts should be
-- preferred.
class (MatrixShaped a) => ISolve a where
    unsafeSolveVector :: (BLAS2 e) 
                   => a e -> Vector e -> Vector e
    unsafeSolveVector = unsafeSSolveVector 1
    {-# INLINE unsafeSolveVector #-}
    
    unsafeSolveMatrix :: (BLAS3 e) 
                   => a e -> Matrix e -> Matrix e
    unsafeSolveMatrix = unsafeSSolveMatrix 1
    {-# INLINE unsafeSolveMatrix #-}

    unsafeSSolveVector :: (BLAS2 e)
                    => e -> a e -> Vector e -> Vector e
    
    unsafeSSolveMatrix :: (BLAS3 e)
                    => e -> a e -> Matrix e -> Matrix e

-- | Solve for a vector.
solveVector :: (ISolve a, BLAS2 e) => a e -> Vector e -> Vector e
solveVector a y =
    checkMatVecSolv (shape a) (dim y) $
        unsafeSolveVector a y
{-# INLINE solveVector #-}

-- | Solve for a matrix.
solveMatrix :: (ISolve a, BLAS3 e) => a e -> Matrix e -> Matrix e
solveMatrix a b =
    checkMatMatSolv (shape a) (shape b) $
        unsafeSolveMatrix a b
{-# INLINE solveMatrix #-}

-- | Solve for a vector and scale.
-- @ssolveVector k a y@ is equal to @a `solveVector` (k *> y)@ but is often faster.
ssolveVector :: (ISolve a, BLAS2 e) => e -> a e -> Vector e -> Vector e
ssolveVector alpha a y =
    checkMatVecSolv (shape a) (dim y) $
        unsafeSSolveVector alpha a y
{-# INLINE ssolveVector #-}

-- | Solve for a matrix and scale.
-- @ssolveMatrix k a c@ is equal to @a `solveMatrix` (k *> c)@ but is often faster.
ssolveMatrix :: (ISolve a, BLAS3 e) => e -> a e -> Matrix e -> Matrix e
ssolveMatrix alpha a b =
    checkMatMatSolv (shape a) (shape b) $
        unsafeSSolveMatrix alpha a b
{-# INLINE ssolveMatrix #-}

instance ISolve (Tri Matrix) where
    unsafeSSolveVector alpha a y = runSTVector $ unsafeGetSSolveVector alpha a y
    {-# INLINE unsafeSSolveVector #-}
    unsafeSSolveMatrix alpha a c = runSTMatrix $ unsafeGetSSolveMatrix alpha a c
    {-# INLINE unsafeSSolveMatrix #-}

-- | Operator form of solving for a vector.
(<\>) :: (ISolve a, BLAS2 e) => a e -> Vector e -> Vector e
(<\>) = solveVector
{-# INLINE (<\>) #-}

-- | Operator form of solving for a matrix.
(<\\>) :: (ISolve a, BLAS3 e) => a e -> Matrix e -> Matrix e
(<\\>) = solveMatrix
{-# INLINE (<\\>) #-}

{-# RULES
"scale.solve/ssolveVector"       forall k a y. a <\>  (k *> y) = ssolveVector k a y
"scale.solveMatrix/ssolveMatrix" forall k a c. a <\\> (k *> c) = ssolveMatrix k a c
 #-}