module XYFlow.FFI.D3Zoom
  ( ZoomTransform(..)
  ) where

import Foreign (Foreign)

newtype ZoomTransform = ZoomTransform Foreign
