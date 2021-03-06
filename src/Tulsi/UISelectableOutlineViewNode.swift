// Copyright 2016 The Tulsi Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Cocoa


protocol Selectable: class {
  var selected: Bool { get set }
}

/// Models a UIRuleEntry as a node suitable for an outline view controller.
class UISelectableOutlineViewNode: NSObject {

  /// The display name for this node.
  let name: String

  /// The object contained by this node (only valid for leaf nodes).
  var entry: Selectable? {
    didSet {
      if let entry = entry {
        state = entry.selected ? NSOnState : NSOffState
      }
    }
  }

  /// This node's children.
  var children: [UISelectableOutlineViewNode] {
    return _children
  }
  private var _children = [UISelectableOutlineViewNode]()

  /// This node's parent.
  weak var parent: UISelectableOutlineViewNode?

  /// This node's checkbox state in the UI (NSOnState/NSOffState/NSMixedState)
  dynamic var state: Int {
    get {
      if children.isEmpty {
        return (entry?.selected ?? false) ? NSOnState : NSOffState
      }

      var stateIsValid = false
      var state = NSOffState
      for node in children {
        if !stateIsValid {
          state = node.state
          stateIsValid = true
          continue
        }
        if state != node.state {
          return NSMixedState
        }
      }
      return state
    }

    set {
      let newSelectionState = (newValue == NSOnState)
      let selected = entry?.selected
      if selected == newSelectionState {
        return
      }

      willChangeValue(forKey: "state")
      if let entry = entry {
        entry.selected = newSelectionState
      }

      for node in children {
        node.state = newValue
      }
      didChangeValue(forKey: "state")

      // Notify KVO that this node's ancestors have also changed state.
      var ancestor = parent
      while ancestor != nil {
        ancestor!.willChangeValue(forKey: "state")
        ancestor!.didChangeValue(forKey: "state")
        ancestor = ancestor!.parent
      }
    }
  }

  init(name: String) {
    self.name = name
    super.init()
  }

  func addChild(_ child: UISelectableOutlineViewNode) {
    _children.append(child)
    child.parent = self
  }

  // TODO(abaire): Use a custom control to override nextState: such that it's never set to mixed via user interaction.
  func validateState(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
    if let value = ioValue.pointee as? NSNumber {
      if value.intValue == NSMixedState {
        ioValue.pointee = NSNumber(value: NSOnState as Int)
      }
    }
  }
}
