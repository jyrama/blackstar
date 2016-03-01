{-# LANGUAGE BangPatterns #-}

module Raytracer where

import Data.Word
import Vision.Primitive
import qualified Vision.Image as I
import Linear hiding (lookAt, mult, trace)
import qualified Linear as L
import Control.Lens
import Data.KdMap.Static

import StarMap

data Scene = Scene { stepSize :: Double
                   , nSteps :: Int
                   , camera :: Camera }

data Camera = Camera { position :: V3 Double
                     , lookAt :: V3 Double
                     , upVec :: V3 Double
                     , fov :: Double
                     , resolution :: (Int, Int) }

-- Generate the sight rays ie. initial conditions for the integration
generateRay :: Scene -> Point -> (V3 Double, V3 Double)
{-# INLINE generateRay #-}
generateRay !scn !(Z :. y' :. x') = (vel, pos)
    where cam = camera scn
          pos = position cam
          xres = fromIntegral . fst $ resolution cam
          yres = fromIntegral . snd $ resolution cam
          matr = L.lookAt pos (lookAt cam) (upVec cam) ^. _m33
          vel  = normalize . (transpose matr !*)
                 $ V3 (fov cam * ((fromIntegral x') / xres - 0.5))
                      (fov cam * ((fromIntegral y') / yres - 0.5) * yres/xres)
                      (-1)

render :: Scene -> KdMap Double (V3 Double) (Int, Word8, Word8) -> I.RGBDelayed
{-# INLINE render #-}
render !scn !startree = I.fromFunction (ix2 yres xres)
                       (colorize startree . traceray scn)
    where cam = camera scn
          (xres, yres) = resolution cam

traceray :: Scene -> Point -> (V3 Double, V3 Double)
{-# INLINE traceray #-}
traceray !scn !pt = last . take (nSteps scn)
                    . takeWhile (\(_, !p) -> sqrnorm p > 1.2 && sqrnorm p < 50**2)
                    . iterate (rk4 (stepSize scn) (fgeodesic h2))
                    $ ray
    where ray@(vel, pos) = generateRay scn pt
          h2 = sqrnorm $ pos `cross` vel

colorize :: KdMap Double (V3 Double) (Int, Word8, Word8)
            -> (V3 Double, V3 Double) -> I.RGBPixel
{-# INLINE colorize #-}
colorize !starmap (!vel, !pos)
    | sqrnorm pos < 2.25 = I.RGBPixel 0 0 0
    | otherwise = starLookup starmap vel

rk4 :: Double -> ((V3 Double, V3 Double) -> (V3 Double, V3 Double))
       -> (V3 Double, V3 Double) -> (V3 Double, V3 Double)
{-# INLINE rk4 #-}
rk4 !h !f !y = y `add`
    ((k1 `add` (k2 `mul` 2) `add` (k3 `mul` 2) `add` k4) `mul` (h/6))
    where k1 = f y
          k2 = f (y `add` (k1 `mul` (h/2)))
          k3 = f (y `add` (k2 `mul` (h/2)))
          k4 = f (y `add` (k3 `mul` h))

          mul (!u, !v) !a = (u ^* a, v ^* a)
          add (!x, !z) (!u, !v) = (x ^+^ u, z ^+^ v)

fgeodesic :: Double -> (V3 Double, V3 Double) -> (V3 Double, V3 Double)
{-# INLINE fgeodesic #-}
fgeodesic h2 (!vel, !pos) = (-1.5*h2 / ((sqrnorm pos)**2.5) *^ pos, vel)
