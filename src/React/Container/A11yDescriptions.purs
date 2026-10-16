-- | `<A11yDescriptions />` — emits hidden description divs and an
-- | `aria-live` region that screen readers announce. Mirrors
-- | `xyflow/packages/react/src/components/A11yDescriptions/index.tsx`.
-- |
-- | **Selector slice strategy.** `state.ariaLabelConfig` includes a
-- | function field (`nodeA11yDescriptionAriaLiveMessage`), which means
-- | the record as a whole has no `Eq` instance. The selector projects
-- | only the three `String` description fields we actually render, so
-- | the `useStore` subscription compares strings and re-renders only
-- | when one of them changes. `ariaLiveMessage` is selected separately
-- | (it changes more often — every keyboard nudge).
module React.Container.A11yDescriptions
  ( a11yDescriptions
  , ariaNodeDescKey
  , ariaEdgeDescKey
  , ariaLiveMessageKey
  ) where

import Prelude

import Effect.Unsafe (unsafePerformEffect)
import Foreign (Foreign)
import React.Basic (JSX, ReactComponent, fragment)
import React.Basic.Hooks (reactComponent)
import React.Basic.Hooks as React
import React.FFI.DOM (div_, textContent)
import React.Hook.Store (useStore)
import React.Types.Component (A11yDescriptionsProps)
import React.Types.Store (ReactFlowState)
import Unsafe.Coerce (unsafeCoerce)

-- | TS `ARIA_NODE_DESC_KEY`. `<NodeWrapper />` points `aria-describedby` at
-- | `<key>-<rfId>`, the id of the node description rendered here.
ariaNodeDescKey :: String
ariaNodeDescKey = "react-flow__node-desc"

-- | TS `ARIA_EDGE_DESC_KEY`, which `<EdgeWrapper />` points at the same way.
ariaEdgeDescKey :: String
ariaEdgeDescKey = "react-flow__edge-desc"

-- | TS `ARIA_LIVE_MESSAGE`.
ariaLiveMessageKey :: String
ariaLiveMessageKey = "react-flow__aria-live"

type DescriptionsSlice =
  { nodeDefault :: String
  , nodeKeyboardDisabled :: String
  , edgeDefault :: String
  }

selectDescriptions :: forall n e. ReactFlowState n e -> DescriptionsSlice
selectDescriptions s =
  { nodeDefault: s.ariaLabelConfig.nodeA11yDescriptionDefault
  , nodeKeyboardDisabled: s.ariaLabelConfig.nodeA11yDescriptionKeyboardDisabled
  , edgeDefault: s.ariaLabelConfig.edgeA11yDescriptionDefault
  }

-- `useStore`'s `Eq` constraint is satisfied by the structural Eq instance
-- for records (all fields here are `String`, themselves `Eq`).

selectAriaLiveMessage :: forall n e. ReactFlowState n e -> String
selectAriaLiveMessage = _.ariaLiveMessage

toForeignStyle :: forall r. Record r -> Foreign
toForeignStyle = unsafeCoerce

-- | `display: none` for the description divs.
hiddenStyle :: Foreign
hiddenStyle = toForeignStyle { display: "none" }

-- | Visually-hidden but screen-reader-accessible style for the
-- | aria-live region. Mirrors the inline style in the TS source.
ariaLiveStyle :: Foreign
ariaLiveStyle = toForeignStyle
  { position: "absolute"
  , width: 1
  , height: 1
  , margin: -1
  , border: 0
  , padding: 0
  , overflow: "hidden"
  , clip: "rect(0px, 0px, 0px, 0px)"
  , clipPath: "inset(100%)"
  }

a11yDescriptions :: ReactComponent A11yDescriptionsProps
a11yDescriptions =
  unsafePerformEffect $ reactComponent "A11yDescriptions"
    \(props :: A11yDescriptionsProps) -> React.do
      descs <- useStore selectDescriptions
      ariaLiveMessage <- useStore selectAriaLiveMessage
      let
        -- Upstream's key names read backwards against their strings, and
        -- this picks them backwards as upstream does: `keyboardDisabled`
        -- holds the arrow-key sentence, shown while the keyboard is on. A
        -- consumer's override of each key lands where upstream shows it.
        nodeDescText =
          if props.disableKeyboardA11y then descs.nodeDefault
          else descs.nodeKeyboardDisabled
        nodeDescId = ariaNodeDescKey <> "-" <> props.rfId
        edgeDescId = ariaEdgeDescKey <> "-" <> props.rfId
        ariaLiveId = ariaLiveMessageKey <> "-" <> props.rfId
        descChildren :: Array JSX
        descChildren =
          [ div_
              { id: nodeDescId, style: hiddenStyle }
              [ textContent nodeDescText ]
          , div_
              { id: edgeDescId, style: hiddenStyle }
              [ textContent descs.edgeDefault ]
          ]
        liveChildren :: Array JSX
        liveChildren =
          if props.disableKeyboardA11y then []
          else
            [ div_
                { id: ariaLiveId
                , "aria-live": "assertive"
                , "aria-atomic": "true"
                , style: ariaLiveStyle
                }
                [ textContent ariaLiveMessage ]
            ]
      pure $ fragment (descChildren <> liveChildren)
