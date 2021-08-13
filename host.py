import qsharp
from Program.Quantum.Walk.Test import Fig7QuantumWalk
from Program.Quantum.Grovers import TestGrover
from Tests import TestFig7Shift

import numpy
from matplotlib import pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

# TestFig7Shift.simulate()

# Initialize test
# times = [1, 2, 3, 10, 25, 100]
# times = [3, 4, 5, 6, 7, 8, 9, 10]
times = [1, 2, 3, 4, 8, 10, 25, 100]
# times = [1]
qubits = range(8)
repetitions = 10000
data = {}

# Run test
for t in times:
    data[t] = []
    for i in range(repetitions):
        data[t].append(Fig7QuantumWalk.simulate(time=t))

# Accumulate datapoints into a presentable form
# Create datastructure
dataConverter = {}
for t in times:
    dataConverter[t] = [0 for i in qubits]

# Accumulate datapoints
for key in times:
    for val in data[key]:
        dataConverter[key][val] += 1

# Make frequency relative
for key in times:
    for val in qubits:
        dataConverter[key][val] = dataConverter[key][val]/repetitions

# y = list(qubits)

# plt.plot(y, dataConverter[1])
# plt.title("Grover's på 010001000000010, Rep = " + str(repetitions))
# plt.xlabel("Bit posisjon")
# plt.ylabel("Frekvens")
# plt.show()

x = times # time
y = list(qubits) # position
cols = int(len(times)/2) # Amount of columns used in subplots

def statistics(a, b): # statistics is a function of data
    return dataConverter[a][b]


# Define colors used for subplots
colors = ['firebrick', 'orangered', 'gold', 'limegreen', 'teal', 'mediumblue', 'indigo', 'mediumvioletred', 'crimson']

# Construct subplot figure
fig, ax = plt.subplots(nrows=2, ncols=cols, sharey=True, sharex=True)

# Add data and title to each subfigure
for i in range(len(times)):
    t = times[i]
    if i < cols:
        ax[0, i].plot(y, dataConverter[t], color = colors[i], label='t='+str(t))
        ax[0, i].set_title('t='+str(t))
    else:
        ax[1, i-cols].plot(y, dataConverter[t], color = colors[i], label='t='+str(t))
        ax[1, i-cols].set_title('t='+str(t))

# Set ticks on x-axis
plt.xticks(list(qubits))

# Set titles and lables
fig.suptitle('Figur 7 Kvantevandring; Rep = ' + str(repetitions))
plt.setp(ax[-1, :], xlabel='Posisjon')
plt.setp(ax[:, 0], ylabel='Frekvens')

# Show figure
plt.show()