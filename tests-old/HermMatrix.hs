
module HermMatrix
    where

import Driver
import Monadic

import Data.Matrix.Herm
import Data.Matrix.Dense
import Data.Matrix.Dense.ST
import Data.Vector.Dense
import Data.Vector.Dense.ST

import Test.Matrix.Herm.Dense
import qualified Test.QuickCheck.BLAS as Test

type V  = Vector E
type M  = Matrix E
type HM = Herm Matrix E

prop_herm_col (Index n j) =
    forAll (Test.hermMatrix n) $ \(a :: HM) ->
        col a j ~== a <*> basisVector n j

prop_herm_row (Index m i) =
    forAll (Test.hermMatrix m) $ \(a :: HM) ->
        row a i ~== conj (herm a <*> basisVector m i)

prop_herm_apply (HermMatrixMV (h :: HM) a x) =
    h <*> x ~== a <*> x

prop_herm_sapply k (HermMatrixMV (h :: HM) a x) =
    sapplyVector k h x ~== sapplyVector k a x

prop_herm_herm_apply (HermMatrixMV (h :: HM) a x) =
    herm h <*> x ~== h <*> x

prop_doSapplyAddVector alpha beta (HermMatrixMV (a :: HM) _ x) = monadicST $ do
    forAllM (Test.vector (numRows a)) $ \y -> do
        y'  <- run $ (unsafeThawVector y :: ST s (STVector s E))
        y'' <- run $ freezeVector y'
        run $ doSApplyAddVector alpha a x beta y'
        assert $ y ~== a <*> (alpha *> x) + (beta *> y'')

prop_herm_applyMatrix (HermMatrixMM (h :: HM) a b) =
    h <**> b ~== a <**> b

prop_herm_sapplyMatrix k (HermMatrixMM (h :: HM) a b) =
    sapplyMatrix k h b ~== sapplyMatrix k a b

prop_herm_herm_applyMatrix (HermMatrixMM (h :: HM) _ b) =
    herm h <**> b ~== h <**> b

prop_doSapplyAddMatrix alpha beta (HermMatrixMM (a :: HM) _ b) = monadicST $ do
    forAllM (Test.matrix (numRows a, numCols b)) $ \c -> do
        c'  <- run $ unsafeThawMatrix c
        c'' <- run $ freezeMatrix c'
        run $ doSApplyAddMatrix alpha a b beta c'
        assert $ c ~== a <**> (alpha *> b) + (beta *> c'')


tests_HermMatrix =
    [ testProperty "herm col" prop_herm_col
    , testProperty "herm row" prop_herm_row
    , testProperty "herm apply" prop_herm_apply
    , testProperty "herm sapply" prop_herm_sapply
    , testProperty "herm herm apply" prop_herm_herm_apply
    , testProperty "doSApplyAddVector" prop_doSapplyAddVector

    , testProperty "herm applyMatrix" prop_herm_applyMatrix
    , testProperty "herm sapplyMatrix" prop_herm_sapplyMatrix
    , testProperty "herm herm applyMatrix" prop_herm_herm_applyMatrix
    , testProperty "doSApplyAddMatrix" prop_doSapplyAddMatrix        
    ]
