# Suka Rogue - 終末なにしてますか？

本作为基于末日三问世界观设计的 Roguelike 同人游戏。

本作将尝试在能力范围内尽可能还原原作中的设定。但出于改编需要，本作将不得不拓展延伸出一些不存在的设定，或者与采用原作设定存在一定出入的处理。

## Implementation Plan

Scheduled Oct. 2026

- [x] BSP Dungeon Generation
    - Experiment: DONE
    - Integration: DONE
- [ ] Biome/Room-Type System
- [ ] Tile System
- [ ] Message System
- [ ] Construct Spawn System
- [ ] Item Spawn System
- [ ] Inventory System
- [ ] Mob Spawn System

Experiments

- [ ] Apply Cellular Automata After BSP

Improvements

- [ ] Improve Appearance for Dungeon
- [ ] Improve UI Layout
- [ ] Make sure all rooms are connected

## Player and Race

玩家将扮演“打捞者”，在“十三兽”和各类魔物出没的地下人类遗迹招募队伍、探索、战斗、逃脱危险的“梦境”。

玩家可以选择自己的种族，不同的种族有不同的“特征”，但这些特征都可以通过后天锻炼来提升。但不同种族之间的文化差异和友好度很难通过努力克服，并且会影响玩家与 NPC 的交互以及队伍成员的表现。

“黄金妖精”是一种十分特殊的种族。玩家可以扮演这一种族，从而获得显著更强的魔力。但与此同时，这一种族在悬浮大陆群长期被“武器化”。详情在“Weapon and Combat”章节介绍。

“艾尔佩斯商国”

## Game Mechanicsb

### Weapon and Combat

常规武器无法杀死兽，只能使兽暂时无法行动。

能对兽造成大量伤害并将兽杀死的武器有且只有两种：“遗迹兵器”即“圣剑”、“机兵”。

圣剑基于蓝图，由“护符”构造而成。蓝图决定了其基本性质和必须的护符、材料、技术。而武器的最终效果由实际组成的护符以及“参数调整”决定。既然人族已经灭绝，只有黄金妖精可以装备圣剑。使用圣剑的妖精会发生“侵蚀”，侵蚀后的妖精性格会发生变化，因此圣剑的适配度也会发生变化，并且可能选择离开队伍。

机兵同样只有黄金妖精可以装备，但不如说机兵是以黄金妖精作为燃料运作的。燃料耗尽后，机兵会发生自毁，造成大范围的破坏并杀死范围内所有的兽。你也可以选择让机兵提前自毁。自毁前，你有时间逃离破坏范围。如果没能逃离，则游戏结束。
