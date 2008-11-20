def read_repo_list(name):
    return [x.strip() for x in open(name).readlines() if not x.strip().startswith("#")]

all_repos = read_repo_list("subprojects")
excluded_repos = read_repo_list("excluded-subprojects")

for x in excluded_repos:
    all_repos.remove(x)

for x in all_repos:
    print x
