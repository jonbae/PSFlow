-- | Comparison helpers shared by the parity property modules. The central
-- | problem these solve: PSFlow renders SVG `d` strings with
-- | `Data.Number.Format.toString` while XYFlow uses JS `${n}` interpolation.
-- | Although both ultimately call the same ECMAScript number-to-string
-- | algorithm, edge cases (`-0`, exponential notation, trailing precision)
-- | mean a raw string compare is the wrong contract. Instead we **tokenize**
-- | each path into its command letters + numeric operands, assert the letter
-- | sequence matches exactly, and compare each number within an epsilon.
module Test.Parity.Util
  ( epsilon
  , approxEq
  , tokenizePath
  , pathsMatch
  , edgeResultsMatch
  , edgeCenterMatch
  , xyMatch
  , rectMatch
  , boxMatch
  , numMatch
  , transformMatch
  , strMatch
  , strArrayMatch
  ) where

import Prelude

import Data.Array (all, catMaybes, foldl, length, snoc, sort, zipWith) as Array
import Data.Array.NonEmpty (toArray) as NEA
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Data.Number (abs, fromString) as Number
import Data.String.Regex (Regex, match, regex) as Re
import Data.String.Regex.Flags (global) as ReFlags
import Partial.Unsafe (unsafeCrashWith)
import System.Types.Geometry (Box, Rect, XYPosition)
import System.Utils.Edges.General (EdgeCenter, EdgePathResult)
import Test.QuickCheck (Result, (<?>))

-- | Numbers in path strings and label coordinates are compared up to this
-- | tolerance. Both libraries run the *same* IEEE-754 ops on the same inputs,
-- | so genuine results are bit-identical; the tolerance only absorbs
-- | formatting round-trips. Mixed absolute+relative so it holds across
-- | magnitudes.
epsilon :: Number
epsilon = 1.0e-9

approxEq :: Number -> Number -> Boolean
approxEq a b =
  a == b
    || Number.abs (a - b) <= epsilon * (1.0 + max (Number.abs a) (Number.abs b))

-- | Matches a single SVG command letter OR one numeric literal (incl. an
-- | optional sign and exponent). Command letters and number characters never
-- | overlap, and the number alternative greedily consumes any exponent `e`,
-- | so a single global scan classifies every token unambiguously.
tokenRegex :: Re.Regex
tokenRegex =
  case Re.regex "[A-Za-z]|-?[0-9]*\\.?[0-9]+(?:[eE][+-]?[0-9]+)?" ReFlags.global of
    Right r -> r
    Left err -> unsafeCrashWith ("Test.Parity.Util: bad tokenizer regex: " <> err)

type PathTokens = { letters :: Array String, numbers :: Array Number }

-- | Split a path `d` string into its ordered command letters and numeric
-- | operands. A token parses as a `Number` (→ operand) or it doesn't (→
-- | command letter).
tokenizePath :: String -> PathTokens
tokenizePath s =
  let
    toks = case Re.match tokenRegex s of
      Just matches -> Array.catMaybes (NEA.toArray matches)
      Nothing -> []
    classify acc t = case Number.fromString t of
      Just n -> acc { numbers = Array.snoc acc.numbers n }
      Nothing -> acc { letters = Array.snoc acc.letters t }
  in
    Array.foldl classify { letters: [], numbers: [] } toks

-- | Two path strings agree iff their command-letter sequences are identical
-- | and their numeric operands match positionally within `epsilon`.
pathsMatch :: String -> String -> Boolean
pathsMatch a b =
  let
    ta = tokenizePath a
    tb = tokenizePath b
  in
    ta.letters == tb.letters
      && Array.length ta.numbers == Array.length tb.numbers
      && Array.all identity (Array.zipWith approxEq ta.numbers tb.numbers)

-- ─── Result builders (carry the failing PSFlow-vs-XYFlow values) ──────────

edgeResultsMatch :: String -> EdgePathResult -> EdgePathResult -> Result
edgeResultsMatch ctx ps xy =
  ( pathsMatch ps.path xy.path
      && approxEq ps.labelX xy.labelX
      && approxEq ps.labelY xy.labelY
      && approxEq ps.offsetX xy.offsetX
      && approxEq ps.offsetY xy.offsetY
  ) <?>
    ( ctx
        <> "\n  PSFlow: path=" <> ps.path
        <> " label=(" <> show ps.labelX <> "," <> show ps.labelY <> ")"
        <> " offset=(" <> show ps.offsetX <> "," <> show ps.offsetY <> ")"
        <> "\n  XYFlow: path=" <> xy.path
        <> " label=(" <> show xy.labelX <> "," <> show xy.labelY <> ")"
        <> " offset=(" <> show xy.offsetX <> "," <> show xy.offsetY <> ")"
    )

edgeCenterMatch :: String -> EdgeCenter -> EdgeCenter -> Result
edgeCenterMatch ctx ps xy =
  ( approxEq ps.centerX xy.centerX
      && approxEq ps.centerY xy.centerY
      && approxEq ps.offsetX xy.offsetX
      && approxEq ps.offsetY xy.offsetY
  ) <?>
    ( ctx
        <> "\n  PSFlow: center=(" <> show ps.centerX <> "," <> show ps.centerY <> ")"
        <> " offset=(" <> show ps.offsetX <> "," <> show ps.offsetY <> ")"
        <> "\n  XYFlow: center=(" <> show xy.centerX <> "," <> show xy.centerY <> ")"
        <> " offset=(" <> show xy.offsetX <> "," <> show xy.offsetY <> ")"
    )

xyMatch :: String -> XYPosition -> XYPosition -> Result
xyMatch ctx a b =
  (approxEq a.x b.x && approxEq a.y b.y) <?>
    ( ctx
        <> "\n  PSFlow=(" <> show a.x <> "," <> show a.y <> ")"
        <> "  XYFlow=(" <> show b.x <> "," <> show b.y <> ")"
    )

rectMatch :: String -> Rect -> Rect -> Result
rectMatch ctx a b =
  ( approxEq a.x b.x && approxEq a.y b.y
      && approxEq a.width b.width
      && approxEq a.height b.height
  ) <?>
    ( ctx
        <> "\n  PSFlow=" <> show a.x <> "," <> show a.y <> " " <> show a.width <> "x" <> show a.height
        <> "\n  XYFlow=" <> show b.x <> "," <> show b.y <> " " <> show b.width <> "x" <> show b.height
    )

boxMatch :: String -> Box -> Box -> Result
boxMatch ctx a b =
  ( approxEq a.x b.x && approxEq a.y b.y
      && approxEq a.x2 b.x2
      && approxEq a.y2 b.y2
  ) <?>
    ( ctx
        <> "\n  PSFlow=(" <> show a.x <> "," <> show a.y <> ")-(" <> show a.x2 <> "," <> show a.y2 <> ")"
        <> "\n  XYFlow=(" <> show b.x <> "," <> show b.y <> ")-(" <> show b.x2 <> "," <> show b.y2 <> ")"
    )

numMatch :: String -> Number -> Number -> Result
numMatch ctx a b =
  approxEq a b <?>
    (ctx <> "\n  PSFlow=" <> show a <> "  XYFlow=" <> show b)

-- | CSS-transform strings (`translate(60px, 15px) translate(-50%, -100%)`) are
-- | compared with the same tokenize-then-epsilon contract as SVG paths: the
-- | literal tokens (`translate`, `px`, `scale`, …) must match exactly and the
-- | numeric operands within `epsilon`. This absorbs `Number.toString` vs `${n}`
-- | formatting drift just like `pathsMatch`.
transformMatch :: String -> String -> String -> Result
transformMatch ctx ps xy =
  pathsMatch ps xy <?>
    (ctx <> "\n  PSFlow=" <> ps <> "\n  XYFlow=" <> xy)

-- | Exact string equality, for outputs that carry no formatted floats (e.g.
-- | marker ids whose numeric fields are integer-valued by construction).
strMatch :: String -> String -> String -> Result
strMatch ctx a b =
  (a == b) <?>
    (ctx <> "\n  PSFlow=" <> a <> "\n  XYFlow=" <> b)

-- | Order-insensitive equality of two id sets (e.g. the node/edge ids returned
-- | by graph traversal). Both sides are sorted before comparison.
strArrayMatch :: String -> Array String -> Array String -> Result
strArrayMatch ctx a b =
  (Array.sort a == Array.sort b) <?>
    (ctx <> "\n  PSFlow=" <> show (Array.sort a) <> "\n  XYFlow=" <> show (Array.sort b))
