from functools import reduce

print(reduce(lambda x,y: x*y, range(2, 500000)))
