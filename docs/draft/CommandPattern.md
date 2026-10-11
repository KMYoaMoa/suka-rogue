Command Pattern and Time System

实现命令模式，是基于以下需求做出的设计决定。
- 将一个操作对应到一个命令，使得定义这个操作的“副作用”和连锁反应更加容易，将多个主体的行为打包到一个命令中。
  - 例如玩家的移动命令执行后，可以检查是否触发陷阱，然后将陷阱触发的命令加入Schedule等。这可以使得许多丰富的行为成为可能。类似于将Command同时作为一个Event处理。
  - 这为我们实现的时间和调度系统做好了准备。它会决定在哪一个Tick有哪些Invoker可以发出命令。

时间系统的实现可以参考下面这篇文章

```
Introduction
I have been looking at time systems for roguelike games. I have found really simple systems that are not powerful enough and powerful systems that are very complicated. I decided to try to put something together that would be simple and powerful (enough). This system is a simple schedule of turns based on the monster's speed. I provide Python code for the scheduling system--the system is a good match for use in Python.

Algorithm
Define a quantum of time, call it a tick. Time is kept in a variable called ticks. A monster's speed is defined by the number of ticks between turns. For example, the pc might have a speed of 10; a faster monster might have a speed of 8, and really fast monster might have a speed of 2.

A schedule is kept of future moves, specifically a list of moves that are scheduled for future values of ticks. Implementing a schedule as a Python dict might look like this at ticks = 100:

sched = { 101: [mon1, mon2], 105: [mon3, pc], 109: [mon4, mon5] }
In that example, mon1 gets the next move followed by mon2. Then the ticks would get incremented to 105 and mon3 and the pc get to move.

When an actor makes a move it schedules its next move, so if mon1 and mon2 have speeds of 7 and 10, then the schedule in the above example would look like this at ticks = 102:

sched = { 105: [mon3, pc], 107: [mon1], 109: [mon4, mon5], 111: [mon2] }
Code
Here is a simple implementation in Python:

#!/usr/bin/env python
# -*- coding: utf-8-*-

import random  # only needed for the fake monster

class Ticker(object):
    """Simple timer for roguelike games."""

    def __init__(self):
        self.ticks = 0  # current ticks--sys.maxint is 2147483647
        self.schedule = {}  # this is the dict of things to do {ticks: [obj1, obj2, ...], ticks+1: [...], ...}

    def schedule_turn(self, interval, obj):
        self.schedule.setdefault(self.ticks + interval, []).append(obj)

    def next_turn(self):
        things_to_do = self.schedule.pop(self.ticks, [])
        for obj in things_to_do:
            obj.do_turn()

###################################################################
#    Example main program

if __name__== "__main__":
    class Monster(object):
        """Fake monster for demo."""
        def __init__(self, ticker):
            self.ticker = ticker
            self.speed = 6 + random.randrange(1, 6)  # random speed in 7 - 12
            self.ticker.schedule_turn(self.speed, self) # schedule monsters 1st move

        def do_turn(self):
            print self, "gets a turn at", self.ticker.ticks # just print a message
            self.ticker.schedule_turn(self.speed, self)     # and schedule the next turn

    ticker = Ticker()  #  create our ticker
    print ticker.schedule

    monsters = []  #  create some monsters for the demo
    while len(monsters) < 5:
        monsters.append(Monster(ticker))
    print ticker.schedule

    while ticker.ticks < 51:  #  our main program loop
        if ticker.ticks in [10, 20, 30, 40, 50]:
            print ticker.schedule
        ticker.ticks += 1
        ticker.next_turn()
Class Ticker has three methods (in this minimal implementation): __init__, which initializes the empty schedule and the ticks variable; schedule turn, which is called by the monster to insert its next turn into the schedule; and next_turn, which finds the next tick with scheduled items and runs them.

The main loop just increments the ticks and calls next_turn to make the next moves.

Some sample output looks like this:

{}
{8: [<__main__.Monster instance at 0xb8056dcc>], 
 9: [<__main__.Monster instance at 0xb8056e0c>], 
11: [<__main__.Monster instance at 0xb8056dec>], 
 7: [<__main__.Monster instance at 0xb8056d8c>, <__main__.Monster instance at 0xb8056e2c>]}
<__main__.Monster instance at 0xb8056d8c> gets a turn at 7
<__main__.Monster instance at 0xb8056e2c> gets a turn at 7
<__main__.Monster instance at 0xb8056dcc> gets a turn at 8
<__main__.Monster instance at 0xb8056e0c> gets a turn at 9
{11: [<__main__.Monster instance at 0xb8056dec>], 
 14: [<__main__.Monster instance at 0xb8056d8c>, <__main__.Monster instance at 0xb8056e2c>],
 16: [<__main__.Monster instance at 0xb8056dcc>],
 18: [<__main__.Monster instance at 0xb8056e0c>]}
<__main__.Monster instance at 0xb8056dec> gets a turn at 11
<__main__.Monster instance at 0xb8056d8c> gets a turn at 14
<__main__.Monster instance at 0xb8056e2c> gets a turn at 14
<__main__.Monster instance at 0xb8056dcc> gets a turn at 16
<__main__.Monster instance at 0xb8056e0c> gets a turn at 18
{21: [<__main__.Monster instance at 0xb8056d8c>, <__main__.Monster instance at 0xb8056e2c>],
 22: [<__main__.Monster instance at 0xb8056dec>],
 24: [<__main__.Monster instance at 0xb8056dcc>],
 27: [<__main__.Monster instance at 0xb8056e0c>]}
<__main__.Monster instance at 0xb8056d8c> gets a turn at 21
<__main__.Monster instance at 0xb8056e2c> gets a turn at 21
<__main__.Monster instance at 0xb8056dec> gets a turn at 22
...
Scheduling non-monster actions
So far all discussion has been about scheduling of the moves of dungeon monsters (and the pc). Most roguelikes will have other actions that need to be scheduled. In this system any object (in the OO programming sense) that implements a do_turn method and calls the ticker's schedule_turn method can be timed. This should be general enough for all timing considerations.

For example, here is example code for a class that would control a protection spell that degraded over time.

    class Protection(object):

        def __init__(self, ticker, ac, monster):
            self.ticker = ticker
            self.ac = ac # the amount of ac enhancement
            self.monster = monster
            self.decay_speed = 250  # protection decrements by 1 every 250 ticks
            self.monster.increment_ac(self.ac)  # this would increment the monster's ac
            self.ticker.schedule_turn(self.decay_speed, self) # schedule 1st ac decay

        def do_turn(self):
            self.ac += -1
            self.monster.increment_ac(-1) # so decrement the ac
            if self.ac > 0:   # if the ac is back to normal, don't reschedule
                self.ticker.schedule_turn(self.decay_speed, self)
Other Considerations
We have a variable that keeps track of the number of ticks since the beginning of the game:

        self.ticks = 0
Some may complain that ticking through the future schedule until we find scheduled actions is inelegant and wastes resources. In a real roguelike, with lots of monsters and other actions to be scheduled, I would expect that the percentage of ticks with no actions will not be large. Therefore, the overhead of iterating through the schedule will insignificant. Other time systems have to search through the schedule to insert actions or have to touch every monster every tick to update energy, or etc. I think the efficiency of this system will compare favorably with those.

It is inevitable that more than one turn will be scheduled for some ticks. Within a tick, the turns are taken in the same order as they were scheduled (i.e., FIFO). I think this is the correct implementation; if not, it can be easily modified.

The example is quite simplified in that the monster's speed is static. In a game it should be calculated from health, enchantments, weight carried, etc. This can be calculated on the fly for every call to schedule_turn, or it could be calculated when something changes, that would require storing both the base speed and current speed.

Some game actions might take more (reading a spellbook) or less (reloading a shotgun) time than a full turn. That is also easily handled by calculating a pseudo speed for those operations before calling schedule_turn. One problem is when a long turn is interrupted (e.g., "you stop digging" in NetHack). In that case the currently scheduled action would have to be canceled and a new action scheduled. Canceling the scheduled action is a small problem. One approach would be to store the ticks of the next action in the monster, so that the monster can ask the ticker to cancel the now unneeded action.
```

我希望实现的效果：Scheduler实现上面提到的 ticknum: {actor list} 的字典。每次取出一个actor,然后生成对应的Command放进一个独立的Commands队列中。然后依次执行队列中的Command,直到队列中的Command全部执行完毕，该actor结算完成。

例如，该tick轮到玩家，等待输入，玩家进行移动操作，将移动命令放入队列，开始执行。移动命令触发陷阱，将陷阱命令加入队列，执行完成。队列为空，轮到该tick下一个actor怪物，怪物根据AI生成命令，开始执行结算……该tick全部actor结算完成后，内容设为nil，然后计数器增加直到调度器中下一个需要结算的tick。

由于这一逻辑相对复杂，你可以：
- 在experiments/ 中添加 Command-Pattern/ 目录，并在其中写好代码，确认可行。
- 撰写Suggestion文档，描述如何将实验代码与src整合。

你只能在 experiments/ 中撰写代码，不要修改任何src中的代码。
