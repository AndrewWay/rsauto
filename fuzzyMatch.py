from fuzzywuzzy import fuzz
from fuzzywuzzy import process
import sys

fuzzyString=sys.argv[1]
target=sys.argv[2]

matchvalue=fuzz.partial_ratio(fuzzyString,target)

print "%d" % matchvalue
