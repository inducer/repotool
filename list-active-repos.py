def read_repo_list(name):
    try:
        return [x.strip() for x in open(name).readlines() if not x.strip().startswith("#")]
    except IOError:
        return []

import sys
my_dir = sys.argv[1]

from os.path import join

all_repos = (read_repo_list(join(my_dir, "subprojects"))
		+ read_repo_list(join(my_dir, "extra-subprojects")))
excluded_repos = read_repo_list(join(my_dir, "excluded-subprojects"))

for x in excluded_repos:
    try:
        all_repos.remove(x)
    except ValueError:
        print>>sys.stderr, "----------------------------------------------------------------------------------"
        print>>sys.stderr, "*** ERROR: %s in excluded-subprojects isn't a valid subproject to start with" % x
        print>>sys.stderr, "----------------------------------------------------------------------------------"

for x in all_repos:
    print join(my_dir, x)
