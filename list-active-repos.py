def read_repo_list(name):
    try:
        return [x.strip() for x in open(name).readlines() if not x.strip().startswith("#")]
    except IOError:
        return ""

all_repos = read_repo_list("subprojects")
excluded_repos = read_repo_list("excluded-subprojects")

for x in excluded_repos:
    all_repos.remove(x)

for x in all_repos:
    print x
