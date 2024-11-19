
import sys

tests = sys.argv[1:]

def fail(std, out):
    print(f'Expected: {std}')
    print(f'Got: {out}')
    exit(1)

for test in tests:
    with open(test + '.std', 'r') as s, open(test + '.out', 'r') as o:
        std = int(s.readline())
        out = int(o.readline())

        if int(std) != int(out):
            fail(std, out)
        
        for i, (line1, line2) in enumerate(zip(s, o)):
            std = [int(x) for x in line1.strip().split()]
            out = [int(x) for x in line2.strip().split()]
            if std[0] != out[0] or std[0] != len(std) - 1 or set(std[1:]) != set(out[1:]):
                fail(std, out)
            
    print(f'{test} passed')
    