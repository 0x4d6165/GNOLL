import os
import matplotlib.pyplot as plt
import time
from gnoll.parser import roll as gnoll_roll
from rpg_dice import roll as rpgdice_roll
from dice import roll as dice_roll
from python_dice import PythonDiceInterpreter
from d20 import roll as d20_roll

def pythondice_roll(s):
    interpreter = PythonDiceInterpreter()
    program = [s]
    return interpreter.roll(s)

# X axis = Roll
# Y axis = Time

shared_x = [0,1,2,3,4,5,6]

configurations = {
    "GNOLL": {
        "roll_fn": gnoll_roll,
        "color": "b"
    },
    "RPG Dice": {
        "roll_fn": rpgdice_roll,
        "color": "g"
    },
    "Dice": {
        "roll_fn": dice_roll,
        "color": "r"
    },
    "PythonDice":{
        "roll_fn": pythondice_roll,
        "color": "c"
    },
    "d20":{
        "roll_fn": d20_roll,
        "color": "y"
    }
}


# Data gather
for key in configurations:
    print("Rolling: ", key)
    c = configurations[key]
    y = []
    dx = []

    for x in shared_x:
        n = 10**x
        r = f"{n}d{n}"
        time1 = time.time()
        try:
            result = c["roll_fn"](r)
            time2 = time.time()
            y.append((time2 - time1)*1000)
            dx.append(x)
        except Exception as e:
            print(f"Err: {key}:{r}")
            print("\t", e)
  

    if len(dx):
        plt.plot(
            dx, y, 
            color=c["color"]
        )
    
# Configuration and Output
plt.xlabel("Dice Roll (10^N)d(10^N)")
plt.ylabel("Time (ms)")
plt.title('Python Library comparison')

plt.yscale('log')
plt.legend(configurations.keys())

this_folder = os.path.dirname(__file__)
output_file = os.path.join(this_folder, "../../doc/JOSS/py.PNG")
plt.savefig(output_file)
