import qsharp
from Walks import Test

import numpy
from matplotlib import pyplot as plt

data = []

for i in range(1000):
    data.append(Test.simulate())

dict = {}
for i in range(16):
    dict[i] = 0

for val in data:
    dict[val] += 1

x = list(range(15))
y = [dict[i] for i in range(15)]

plt.bar(x,y, align='center')
plt.title('Test')
plt.xlabel('n')
plt.ylabel('Frekvens')
plt.show()

# print(data)

