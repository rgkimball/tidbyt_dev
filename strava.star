load("http.star", "http")
load("math.star", "math")
load("time.star", "time")
load("cache.star", "cache")
load("render.star", "render")
load("schema.star", "schema")
load("humanize.star", "humanize")
load("encoding/base64.star", "base64")

STRAVA_BASE = "https://www.strava.com/api/v3/"
ACCESS_TOKEN = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
DEFAULT_ATHLETE = '51510797'
DEFAULT_UNITS = 'imperial'

CACHE_PREFIX = 'strava_'
CACHE_TTL = 60 * 15

STRAVA_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACgAAAAICAYAAACLUr1bAAAAAXNSR0IArs4c6QAAAJ9JREFUOE+
VVFsOgCAMg9t6JG+rgVhTl3ab/IDsQdd1zvGs6xwXztjnMaa6X3ZnW/ecB/HRX32vuOXPOXayvy
AygLDFwvGoAqxsL0kMMFbvmOg8rgpn1uI5+gNLyaADowpz7cwkE9lj392NSoMdgF3tKjAOIKTyY
TDTArPTKaqr62oQ7ZRWYo8tzgApfWFaOU4y7NjIfhfVkHDLXVu7AG9xpK01/VJ0qwAAAABJRU5E
rkJggg==
""")

RIDE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAGpJREFUGFdjZICCkLyq/zD2mkltjCB2Qm03XAwsAAPHNDTgEjAxqxs3GEEawAr//////7imJgNIEMQHabC8fp0BJAaiGUEApAhEI0uCNCBrBqtBVggyDWYqTBxmI9xqkADIZGQ3gxRDxRkAODJIzA34xRoAAAAASUVORK5CYII=
""")

ELEV_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAIBJREFUGFdjZICCN+8//hcR5GeE8dFpuARIIUgSpvjXr1//2djY4PJgBkzRl4/vwQZJSUkxPHv2jKGkbxbDmkltYDVgomLCnP8v3r5ngCkEiakoKYE13bl3D6yYEaQIJABSCAIwxSCFyGKM0nEKYIUw4CqfDVd8/MMysLClQBQDADOaPH3ku/SjAAAAAElFTkSuQmCC
""")

DISTANCE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAEtJREFUGFdjZCAAeN0X/v+8M56REZ86kKJPO+IY+DwWMYAV/g9X+g+iGVfeQ9EIUggziBGkCKYAnQ1SxPehngGr1eimwzTjdSOy+wFaLiTvmqj9hwAAAABJRU5ErkJggg==
""")

headers = {
    'Authorization': 'Bearer %s' % ACCESS_TOKEN
}


def main(config):
    timezone = config.get("timezone") or "America/New_York"
    year = time.now().in_location(timezone).year
    sport = config.get('sport', 'ride')
    athlete = config.get('athlete_id', DEFAULT_ATHLETE)
    units = config.get('units', DEFAULT_UNITS)

    stats = ['count', 'distance', 'moving_time', 'elapsed_time', 'elevation_gain']
    stats = {k: cache.get(CACHE_PREFIX + k) for k in stats}

    if False:
        print("Hit! Displaying cached data.")
    else:
        print("Miss! Calling Strava API.")
        url = "https://www.strava.com/api/v3/athletes/%s/stats" % athlete
        response = http.get(url, headers=headers)
        if response.status_code != 200:
            fail('Strava API call failed with status %d' % response.status_code)
        data = response.json()

        for item in stats.keys():
            stats[item] = data['ytd_ride_totals'][item]
            cache.set(CACHE_PREFIX + item, str(stats[item]), ttl_seconds=CACHE_TTL)
            print('saved item %s "%s" in the cache for %d seconds' % (item, str(stats[item]), CACHE_TTL))

    #################################################
    # Configure the display to the user's preferences
    #################################################

    if units.lower() == 'imperial':
        stats['distance'] = round(meters_to_mi(float(stats['distance'])), 2)
        stats['elevation_gain'] = round(meters_to_ft(float(stats['elevation_gain'])), 1)
        distu = 'mi'
        elevu = 'ft'
    else:
        stats['distance'] = round(meters_to_km(float(stats['distance'])), 1)
        distu = 'km'
        elevu = 'm'

    if sport == 'all':
        if stats['count'] > 1:
            actu = 'activities'
        else:
            actu = 'activity'
    else:
        actu = sport
        if stats['count'] > 1:
            actu += 's'

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = STRAVA_ICON),
                        render.Text(" %d" % year, font="tb-8"),
                    ],
                ),
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = RIDE_ICON),
                        render.Text(" %s " % humanize.comma(stats.get('count', 0))),
                        render.Text(actu, font="tb-8"),
                    ],
                ),
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = DISTANCE_ICON),
                        render.Text(" %s " % humanize.comma(stats.get('distance', 0))),
                        render.Text(distu, font="tb-8"),
                    ],
                ),
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = ELEV_ICON),
                        render.Text(
                            " %s %s" % (humanize.comma(stats.get('elevation_gain', 0)), elevu),
                        ),
                    ],
                ),
            ],
        ),
    )


def meters_to_mi(m):
    return m * 0.00062137

def meters_to_km(m):
    return m / 1000

def meters_to_ft(m):
    return m * 3.280839895

def round(num, precision):
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "athlete_id",
                name = "Strava Athlete ID",
                desc = "As found in your profile URL: https://strava.com/athletes/99999999",
                icon = "number",
                default = DEFAULT_ATHLETE,
            ),
            schema.Text(
                id = "sport",
                name = "What activity types do you want to display?",
                desc = "Can be All, Run, Ride or Swim.",
                icon = "number",
                default = 'All',
            ),
            schema.Text(
                id = "units",
                name = "Which units do you want to display?",
                desc = "Default will be imperial (miles and feet).",
                icon = "number",
                default = DEFAULT_UNITS,
            ),
        ],
    )
