

def xorshift(n):
	n ^= n<<2
	n &= 0xff
	n ^= n>>5
	n &= 0xff
	n ^= n<<3
	n &= 0xff
	return n

my_set = set()
for j in range(256):
	my_set = set()
	seed = j
	for i in range(1000):
		my_set.add(seed)
		seed = xorshift(seed)
	if(len(my_set) < 30):
		print(j)
		print(my_set)