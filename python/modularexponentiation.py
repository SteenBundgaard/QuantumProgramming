import numpy as np
import matplotlib.pyplot as plt

# Definition of the function and parameters
a = 19  # Du kan ændre 'a' til enhver værdi, du ønsker
x_values = np.arange(1, 21)  # x fra 1 til 20
modulus = 91

# Evaluering af funktionen a^x mod 91
y_values = [pow(a, int(x), modulus) for x in x_values]

# Plot af resultaterne
plt.figure(figsize=(10, 60))
plt.plot(x_values, y_values, marker='o', label=f'{a}^x mod {modulus}')
plt.title(f'Evaluering af {a}^x mod {modulus} for x = 1..20')
plt.xlabel('x')
plt.ylabel(f'{a}^x mod {modulus}')
plt.xticks(x_values)  # Sikrer, at alle x-værdier vises
plt.grid(True)
plt.legend()
plt.show()
