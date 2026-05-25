-- | Identifier newtypes. Wrapping the bare `String` ids that flow
-- | through the codebase as `NodeId`, `EdgeId`, `HandleId`, `ParentId`
-- | lets the type system catch the "wrong kind of id passed here"
-- | class of bug at compile time — `Map.lookup edge.target nodeLookup`
-- | only typechecks if both arguments agree on what kind of id is
-- | involved.
-- |
-- | These are erased at runtime — newtypes have no representational
-- | overhead. `unwrap` / `wrap` (via `Data.Newtype`) is the bridge at
-- | DOM-attribute, string-concat, and JSON boundaries.
module System.Types.Ids
  ( NodeId(..)
  , EdgeId(..)
  , HandleId(..)
  , ParentId(..)
  , parentToNode
  , nodeToParent
  ) where

import Prelude

import Data.Newtype (class Newtype)

newtype NodeId = NodeId String

derive instance newtypeNodeId :: Newtype NodeId _
derive newtype instance eqNodeId :: Eq NodeId
derive newtype instance ordNodeId :: Ord NodeId
derive newtype instance showNodeId :: Show NodeId

newtype EdgeId = EdgeId String

derive instance newtypeEdgeId :: Newtype EdgeId _
derive newtype instance eqEdgeId :: Eq EdgeId
derive newtype instance ordEdgeId :: Ord EdgeId
derive newtype instance showEdgeId :: Show EdgeId

newtype HandleId = HandleId String

derive instance newtypeHandleId :: Newtype HandleId _
derive newtype instance eqHandleId :: Eq HandleId
derive newtype instance ordHandleId :: Ord HandleId
derive newtype instance showHandleId :: Show HandleId

-- | A `ParentId` is just a `NodeId` viewed in a parent-child role.
-- | Kept as its own newtype so that signatures like `parentId :: Maybe
-- | ParentId` cannot be accidentally satisfied by a child's `NodeId`,
-- | even though both wrap `String`. Convert with `wrap <<< unwrap`
-- | (or via `ParentId <<< unwrap <<< (id :: NodeId -> _)`) at the
-- | adoption boundary.
newtype ParentId = ParentId String

derive instance newtypeParentId :: Newtype ParentId _
derive newtype instance eqParentId :: Eq ParentId
derive newtype instance ordParentId :: Ord ParentId
derive newtype instance showParentId :: Show ParentId

-- | Convert a `ParentId` to the `NodeId` of the same node — needed
-- | when looking the parent up in `NodeLookup`. Same underlying
-- | string; the conversion is just changing the type tag.
parentToNode :: ParentId -> NodeId
parentToNode (ParentId s) = NodeId s

-- | The other direction: tag a `NodeId` as a `ParentId` when assigning
-- | it to a child's `parentId` field or using it as a `ParentLookup`
-- | key.
nodeToParent :: NodeId -> ParentId
nodeToParent (NodeId s) = ParentId s
