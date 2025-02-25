# What is in R14
## Differences to R13
- 64bit only, built on Windows 10
- UI entirely QML -> HTML-like markup with javascript meaning easier to modify for others
	- Less compact UI (default themes are spacious)
- No containers anymore
- Action are able to be copied and referenced
- Intermediate output system allows for arbitrary amounts of synthetic internal axes, buttons, and hats
- No special vJoy tab
- Mode switching is a bit smarter (maybe)
- Virtual button setup is now at the top of every action sequence making it easier to know about
- No convoluted tabs on actions anymore
	- Virtual buttons are at the top of a sequence
	- Conditions are now an action
- Calibration similar but a bit more refined
- Everything processing input is an action, no special things such as merge tool anymore
- Response curve has a new piece-wise linear curve option
## Goodbye Containers
R13 had actions (doing something) and containers (managing actions) but that meant some desirable usage scenarios were impossible. For example, no Tempo behavior together with a Hat to Buttons container. R14 does away with containers and now just has actions. Actions can contain child actions (tempo, chain, condition) and decide how and when they do their action (Map to X, Macro, Mode change). This means you can nest actions as deep as you want but you'll bear the consequences of it.
Gremlin still has the notion of an action having multiple independent sets of actions, in R13 this was represented by containers. In R14 Each input can have multiple action sequences that are completely independent of each other.
![Complex action sequence|600](images/action_sequence_complex.png)
![Multiple action sequences|600](images/action_sequence_multiple.png)

## Drag & Drop and other usability things
Within an action sequence you can drag & drop actions around to reorder them. This should work mostly but likely still has bugs here and there. In addition to this each action can also be folded/unfolded to only show the action's heading taking up less space.
⚠️ Drag and drop may still fail or do weird things at times from corner cases as it hasn't been super thoroughly debugged.
## Custom Actions Location
Gremlin now additionally loads actions from a user specified folder in addition to actions shipped with Gremlin by default. This means that actions that may not be of general use can easily be loaded in Gremlin without having to modify the code and allow people to curate their own set of actions they need.
## Condition
In R13 conditions were a separate tab on the container that allowed adding conditions at either the container or action level. The design of the condition dialog also led to various confusing behaviors. In R14 conditions are simply an action that evaluates a condition and based on the outcome one of the two branches (true / false) containing child actions is executed. This makes the control flow easier to see and with drag&drop rearranging things should be less painful to rearrange as well.
![Condition action|600](images/condition_action.png)

## Virtual Button
In R13 a virtual button tab would appear when certain actions were selected on an axis or a hat. This made it hard to discover that feature and also a bit cumbersome to setup. In R14 each action sequences added to an axis or hat has the option to configured to act as a button, which then displays the virtual button configuration and also changes the actions that can be added to that action sequence.
⚠️ There is likely some quirks with going back and forth between virtual button and natural behavior as I haven't decided yet how to deal with that fully.
![Virtual button|600](images/virtual_button.png)

## Merge Axis
In R13 merging two axes was done via a custom dialog as the design of the profile structure didn't permit for actions to be associated with two physical inputs. The changes in R14's profile structure mean that now merge axis can be a regular action. The action needs to be assigned to two different axes which can associate themselves with one of the two axis slots.
There are a variety of things that are commonly desired in a merge axis scenario which were not possible nicely or at all in R13, including:
- Apply a response curve to an axis before merging
	- utilize intermediate outputs for this
- Response curve on the merged output
	- was doable with vJoy tabs but had odd side effects
	![Merge action|600](images/merge_action.png)
## Intermediate Output
R14 adds a system that permits the creation of an arbitrary number of named axes, buttons, and hats. These are only internal to Gremlin but can be used as intermediary outputs for a variety of tasks, such as :
- pre-process inputs as described in the merge axis case
- storing state similar to how people use vJoy buttons in R13
- mapping multiple physical axes to one axis to share output and response curve without duplication
These intermediate outputs (IO) work and behave exactly like any other physical device but can be named and their numbers are not limited. Under the hood though the same signaling mechanism used by other inputs also is used on the IO system.
![Intermediate output|600](images/intermediate_output.png)
## Profile structure
R13 had a very direct profile structure, where for each device all inputs were listed and the actions associated with an input were nested within that input's entry. R14 decouples inputs and actions entirely. The profile is made up of a library containing actions and inputs that refer to entries in the library. The figure below shows this difference.
Actions are stored in a library and have an associated unique identifier that makes it possible to uniquely refer to them. If an action contains other actions, such as a tempo action, then only the referred "child" actions' identifiers are stored in the "parent" action but not the actions' contents itself.
Of the physical devices only those inputs that have an action associated with them is stored. Each entry specifies the input as well as the mode and the set of root actions associated with that particular input.
What this split enables is that the same action can be used with multiple physical inputs or be contained in several action sequences. Examples of this are:
- Having a shared response curve for several axes that map to different vJoy outputs
- Bind the same action, such as a macro, to two different physical inputs
There are two aspects the library system allows that I haven't gotten around to implementing yet but want to as soon as possible:
- Assigning library actions (likely via drag&drop) from a searchable library interface onto physical inputs. This would allow quickly putting together a profile from a library of actions someone else made, or to rebind actions quickly and easily. The reference action permits this on a technical level but is a bit clunky to use.
- Updating library entries. As every action has a unique identifier it is possible to load entries from another library and overwrite existing entries to update them. A typical use case for this would be that a game changes the default bindings for an action and now, instead of one having to change these settings everywhere, one person can update the shared action library and everyone loads that library and has the "fixed" bindings.

| R14 Profile Structure                         | R13 Profile Structure                         |
| --------------------------------------------- | --------------------------------------------- |
| ![R14\|400](images/r14_profile_structure.png) | ![R13\|200](images/r13_profile_structure.png) |
| Some things to consider here                  |                                               |
- R14 looks much messier and also is more tricky to read from an XML point of view
- R14 allows the reuse of actions, thus sharing of settings such as curves
- R14 allows arbitrary nesting of containers
- R13 needs to duplicate actions
- R13 doesn't support nesting there are two levels, containers which contain actions, as such the input 3 scenario is impossible
- R14 actions are uniquely identifiable with an ID as such the library repos consisting of "game mappings" can be made and updated and will then automatically update when loaded (needs to be implemented but that's part of the design idea)
- R13 always lists all available physical inputs even if nothing is assigned to them, making profiles long especially on setups with tons of devices, R14 only lists inputs that have an associated action
# What is still missing
- [ ] Input repeater and make it works with complex action sequences
- [ ] Automatically assign remaps to inputs, i.e. the old 1:1 Mapping tool but more flexible, likely a dialog where you configure what behavior you want
- [ ] Profile auto load system including support to say whether or not to turn profiles off on focus loss
- [ ] System to enable/disable and reorder actions in the drop down list
- [ ] Add the user plugin system back and fix some of its bugs
- [ ] Profile conversion from R13 (unclear when/if that happens)
- [ ] TTS action, looking into if Qt's TTS system should be used instead
- [ ] Configuration options missing
	- [ ] Ability to designate vJoy devices as inputs
	- [ ] Macro default action delay
	- [ ] vJoy device default initialization values
	- [ ] Mode to use when activating Gremlin
- [ ] Prettify device information dialog
- [ ] Cheatsheet generation (way down the line maybe)
- [ ] Profile creator but via library things so very different
- [ ] Log viewing tools
- [ ] Reworked and renamed swap devices tool that doesn't omit information (should be significantly easier with R14's profile layout)
- [ ] Support for command line options
- [ ] Build the sphinx documentation
- [ ] Properly integrate dark mode and make sure it is readable
- [ ] Action summaries on inputs