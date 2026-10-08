# BSP Dungeon Generation

First step: do the partitioning
Second step: find neighbours for each cell
Third Step: Shrink cells into rooms
Fourth Step: add corridors
Extra Steps: assign types, etc.

## Data Structures

Each room/cell can be a class, so that we can assign different types to the rooms.
To represent the whole dungeon, we need a map class of rooms.
A hallway can also be a class. Making the coding easier, and make it easier to be added

By doing the BSP, we are actually building a **binary tree**.
