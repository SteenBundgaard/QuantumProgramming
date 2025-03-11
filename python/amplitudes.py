import numpy as np
import matplotlib.pyplot as plt

# Konstantværdier
r = 6
n = 7
Q = round(2**n / r) #16384

# Interval for y-værdier
y_values = np.arange(1, 500)

# Funktion P(y)
def P(y):
    summation = np.sum([np.exp(2j * np.pi * k * r * y / (2**n)) for k in range(Q-1)])
    return (1 / (2**n * Q)) * np.abs(summation)**2

# Beregn P(y) for alle y-værdier
P_values = [P(y) for y in y_values]

# Plot resultatet
plt.figure(figsize=(10, 6))
plt.plot(y_values, P_values, marker='o', label=r'$P(y)$')
plt.title(r'Evaluering af $P(y)$ for $y = 1..20$')
plt.xlabel(r'$y$')
plt.ylabel(r'$P(y)$')
plt.grid(True)
plt.xticks(y_values)
plt.legend()
plt.show()
