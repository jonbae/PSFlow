-- | `useNodesEdgesState` — prototyping helper that wraps two
-- | `useState`s (one for nodes, one for edges) and pre-bakes the
-- | `onNodesChange` / `onEdgesChange` callbacks that funnel `NodeChange`
-- | / `EdgeChange` arrays back into the state via `applyNodeChanges` /
-- | `applyEdgeChanges`. Mirrors
-- | `xyflow-main/packages/react/src/hooks/useNodesEdgesState.ts`.
-- |
-- | **PS divergence.** TS exports two separate hooks (`useNodesState`,
-- | `useEdgesState`) each returning a 3-tuple. PS combines into one
-- | record-returning hook for symmetry — ticket 049 re-exports two
-- | helpers `useNodesState` / `useEdgesState` that destructure this
-- | record so the public contract is preserved.
module React.Hook.NodesEdgesState
  ( UseNodesEdgesState(..)
  , NodesEdgesState
  , NodesStateBundle
  , EdgesStateBundle
  , useNodesEdgesState
  , useNodesState
  , useEdgesState
  ) where

import Prelude

import Data.Newtype (class Newtype)
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import React.Basic.Hooks (Hook, UseState, coerceHook, useState)
import React.Basic.Hooks as React
import React.Store.Changes (applyEdgeChanges, applyNodeChanges)
import React.Types.Edges (Edge)
import React.Types.Nodes (Node)
import System.Types.Edge (EdgeChange)
import System.Types.Node (NodeChange)

-- | The bundle this hook returns. Field names match upstream so the
-- | public API ticket can re-export `useNodesState` / `useEdgesState`
-- | by destructuring without renaming.
type NodesEdgesState n e =
  { nodes :: Array (Node n)
  , setNodes :: (Array (Node n) -> Array (Node n)) -> Effect Unit
  , edges :: Array (Edge e)
  , setEdges :: (Array (Edge e) -> Array (Edge e)) -> Effect Unit
  , onNodesChange :: Array (NodeChange n) -> Effect Unit
  , onEdgesChange :: Array (EdgeChange e) -> Effect Unit
  }

newtype UseNodesEdgesState n e hooks =
  UseNodesEdgesState
    ( UseState (Array (Edge e))
        (UseState (Array (Node n)) hooks)
    )

derive instance newtypeUseNodesEdgesState ::
  Newtype (UseNodesEdgesState n e hooks) _

useNodesEdgesState
  :: forall n e
   . Array (Node n)
  -> Array (Edge e)
  -> Hook (UseNodesEdgesState n e) (NodesEdgesState n e)
useNodesEdgesState initialNodes initialEdges = coerceHook React.do
  nodes /\ setNodesState <- useState initialNodes
  edges /\ setEdgesState <- useState initialEdges
  pure
    { nodes
    , setNodes: setNodesState
    , edges
    , setEdges: setEdgesState
    , onNodesChange: \changes -> setNodesState (applyNodeChanges changes)
    , onEdgesChange: \changes -> setEdgesState (applyEdgeChanges changes)
    }

-- | Subset of `NodesEdgesState` returned by `useNodesState`. Mirrors the
-- | TS 3-tuple `[nodes, setNodes, onNodesChange]` as a PS record.
type NodesStateBundle n =
  { nodes :: Array (Node n)
  , setNodes :: (Array (Node n) -> Array (Node n)) -> Effect Unit
  , onNodesChange :: Array (NodeChange n) -> Effect Unit
  }

-- | Subset of `NodesEdgesState` returned by `useEdgesState`. Mirrors the
-- | TS 3-tuple `[edges, setEdges, onEdgesChange]` as a PS record.
type EdgesStateBundle e =
  { edges :: Array (Edge e)
  , setEdges :: (Array (Edge e) -> Array (Edge e)) -> Effect Unit
  , onEdgesChange :: Array (EdgeChange e) -> Effect Unit
  }

-- | TS public-API helper. Mirrors the TS `useNodesState` signature.
-- | Allocates the edges-side `useState` slot with an empty array so the
-- | hook-effect tag matches `useNodesEdgesState` and the two helpers
-- | nest predictably under `coerceHook` from the same chain.
useNodesState
  :: forall n
   . Array (Node n)
  -> Hook (UseNodesEdgesState n Unit) (NodesStateBundle n)
useNodesState initialNodes = coerceHook React.do
  nodes /\ setNodesState <- useState initialNodes
  _ <- (useState ([] :: Array (Edge Unit)) :: React.Hook (UseState (Array (Edge Unit))) _)
  pure
    { nodes
    , setNodes: setNodesState
    , onNodesChange: \changes -> setNodesState (applyNodeChanges changes)
    }

-- | TS public-API helper. Symmetric counterpart of `useNodesState` — see
-- | the note there on the unused nodes slot.
useEdgesState
  :: forall e
   . Array (Edge e)
  -> Hook (UseNodesEdgesState Unit e) (EdgesStateBundle e)
useEdgesState initialEdges = coerceHook React.do
  _ <- (useState ([] :: Array (Node Unit)) :: React.Hook (UseState (Array (Node Unit))) _)
  edges /\ setEdgesState <- useState initialEdges
  pure
    { edges
    , setEdges: setEdgesState
    , onEdgesChange: \changes -> setEdgesState (applyEdgeChanges changes)
    }
