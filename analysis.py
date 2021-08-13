import numpy as np
import quantum_decomp as qd
import scipy as sp
from scipy.optimize import minimize

# Analysis of stagggered quantum walk, Figure 10

H_1 = (1/3)*np.matrix([[-1, 2, 2, 0, 0, 0, 0, 0],
                    [2, -1, 2, 0, 0, 0, 0, 0],
                    [2, 2, -1, 0, 0, 0, 0, 0],
                    [0, 0, 0, 3, 0, 0, 0, 0],
                    [0, 0, 0, 0, -1, 2, 2, 0],
                    [0, 0, 0, 0, 2, -1, 2, 0],
                    [0, 0, 0, 0, 2, 2, -1, 0],
                    [0, 0, 0, 0, 0, 0+0j, 0, 3]])

H_2 = (1/3)*np.matrix([[-1, 0, 0, 0, 0, 0, 2, 2],
                    [0, 3, 0, 0, 0, 0, 0, 0],
                    [0, 0, -1, 2, 2, 0, 0, 0],
                    [0, 0, 2, -1, 2, 0, 0, 0],
                    [0, 0, 2, 2, -1, 0, 0, 0],
                    [0, 0, 0, 0, 0, 3, 0, 0],
                    [2, 0, 0, 0, 0, 0, -1, 2],
                    [2, 0, 0, 0, 0, 0, 2, -1]])

H_3 = (1/2)*np.matrix([[-1, 0, 1, 0, 1, 0, 1, 0],
                    [0, 2, 0, 0, 0, 0, 0, 0],
                    [1, 0, -1, 0, 1, 0, 1, 0],
                    [0, 0, 0, 2, 0, 0, 0, 0],
                    [1, 0, 1, 0, -1, 0, 1, 0],
                    [0, 0, 0, 0, 0, 2, 0, 0],
                    [1, 0, 1, 0, 1, 0, -1, 0],
                    [0, 0, 0, 0, 0, 0, 0, 2]])

# The evolution operator is:
u = H_3*H_1*H_2

# Marking matrix
r = np.matrix([[1, 0, 0, 0, 0, 0, 0, 0],
                [0, 1, 0, 0, 0, 0, 0, 0],
                [0, 0, 1, 0, 0, 0, 0, 0],
                [0, 0, 0, 1, 0, 0, 0, 0],
                [0, 0, 0, 0, -1, 0, 0, 0],
                [0, 0, 0, 0, 0, 1, 0, 0],
                [0, 0, 0, 0, 0, 0, 1, 0],
                [0, 0, 0, 0, 0, 0, 0, 1]])

# Numeric analysis of spectral decomposition 
ur = u @ r
w, v = np.linalg.eig(ur)

# Vertex 5 is marked 
marked = np.matrix([[0],[0],[0],[0],[1],[0],[0],[0]])

# Start position is normalized uniform
initial = np.matrix([[1],[1],[1],[1],[1],[1],[1],[1]])
initial = initial/np.linalg.norm(initial)

dotMark = []
dotInit = []



for i in range(8):
    dotMark.append(v[:,i].conjugate().T @ marked)
    dotInit.append(initial.conjugate().T @ v[:,i])

organize = list(zip(w, dotMark, dotInit))
# print(len(organize))

print((H_1 @ initial) - initial)

def prob(t):
    return np.abs(marked.T @ u @ u @ initial)**2

print(prob(0))

# print(marked.T)
# print(v[:,0])
# print(marked.T @ v[:,0])

# output4 = np.matrix([[0.1],[0.22],[0.1],[0.1],[0],[0.38],[0],[0.1]])
# output4 = output4/np.linalg.norm(output4)
# specialMatrix = ((2*output4 @ output4.T) - np.identity(8)) @ r

# top = minimize(lambda x: -1*prob(x), 6, method = 'Nelder-Mead')
# print(top)
# print(prob(5))

# print(valU)
# print(vecU)

# print(U)
# print(qd.quantum_decomp_main.matrix_to_qsharp(u, op_name='U'))