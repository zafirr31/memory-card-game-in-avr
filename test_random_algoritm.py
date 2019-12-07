

def random(seed, a, b):
	res = (((a*seed) & 0xff) + b) & 0xff
	return res

my_set = []
seed = 4
while(True):
	my_set.append(seed)
	seed = random(seed, 71, 67)
	if seed in my_set:
		break

print len(my_set)
print my_set