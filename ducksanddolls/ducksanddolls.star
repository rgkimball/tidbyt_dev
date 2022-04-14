"""
Applet: US Yield Curve
Summary: Plots treasury rates
Description: Track changes to the yield curve over different US Treasury maturities.
Author: rs7q5, rgkimball
"""

load("http.star", "http")
load("cache.star", "cache")
load("render.star", "render")

URL_PRS = "https://github.com/tidbyt/community/pulls"
URL_ISSUES = "https://github.com/tidbyt/community/issues"
URL_APPS = "https://github.com/tidbyt/community/tree/main/apps"

PR_PASSING = "color-fg-success"
PR_FAILING = "color-fg-danger"
PASSING_MULTIPLIER = 1.0
FAILING_MULTIPLIER = 1.5
ISSUE_COUNT = "octicon-issue-opened"
APP_COUNT = "octicon-file-directory-fill"

CACHE_LIFE = 60 * 60 * 24  # we don't need this intraday...

def main(config):

    cache_id = "ducksanddolls/exchange_rate"
    exchange_rate = cache.get(cache_id)

    base_prs = 10
    base_issues = 1
    base_apps = 70
    base_ex_rate = 900

    if not exchange_rate:
        prs = http.get(URL_PRS).body()
        apps = http.get(URL_APPS).body()
        issues = http.get(URL_ISSUES).body()

        passing_prs = prs.count(PR_PASSING)
        failing_prs = prs.count(PR_FAILING)
        num_issues = issues.count(ISSUE_COUNT)
        num_apps = apps.count(APP_COUNT)

        print("passing_prs", passing_prs)
        print("failing_prs", failing_prs)
        print("issues", num_issues)
        print("num_apps", num_apps)

        duck_total = (num_issues + passing_prs * PASSING_MULTIPLIER + failing_prs * FAILING_MULTIPLIER) / (base_prs +
                                                                                                           base_issues)
        doll_hair_total = num_apps / base_apps

        exchange_rate = str((doll_hair_total / duck_total) * base_ex_rate)

        print("duck total", duck_total)
        print("doll total", doll_hair_total)
        print("exchange rate", exchange_rate)

        cache.set(cache_id, exchange_rate)

    return render.Root(
        child = render.Text(exchange_rate)
    )
