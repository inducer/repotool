def read_repo_list(name):
    try:
        return [x.strip() for x in open(name).readlines() if not x.strip().startswith("#")]
    except IOError:
        return ""

import sys
my_dir = sys.argv[1]

from os.path import join

all_repos = read_repo_list(join(my_dir, "subprojects"))
excluded_repos = read_repo_list(join(my_dir, "excluded-subprojects"))

for x in excluded_repos:
    all_repos.remove(x)

for x in all_repos:
    print join(my_dir, x)
