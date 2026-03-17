x = 2+2
print(x^2)
using Plots
x = range(0, 10, length=100)
y = sin.(x)
plot(x, y)