"""
Applet: Strava Activities
Summary: Displays your YTD or all-time athlete stats recorded on Strava
License: MIT
Author: rgkimball, March 2022
"""

load("http.star", "http")
load("math.star", "math")
load("time.star", "time")
load("cache.star", "cache")
load("render.star", "render")
load("schema.star", "schema")
load("humanize.star", "humanize")
load("encoding/base64.star", "base64")

STRAVA_BASE = "https://www.strava.com/api/v3"
ACCESS_TOKEN = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
DEFAULT_ATHLETE = '51510797'
DEFAULT_UNITS = 'imperial'
DEFAULT_SPORT = 'ride'
DEFAULT_PERIOD = 'all'

PREVIEW_DATA = {
    'count': 108,
    'distance': 56159815,
    'moving_time': 2318919,
    'elapsed_time': 2615958,
    'elevation_gain': 11800,
}

CACHE_PREFIX = 'strava_'
CACHE_TTL = 60 * 60 * 24  # updates once daily

STRAVA_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAACgAAAAICAYAAACLUr1bAAAAAXNSR0IArs4c6QAAAJ9JREFUOE+
VVFsOgCAMg9t6JG+rgVhTl3ab/IDsQdd1zvGs6xwXztjnMaa6X3ZnW/ecB/HRX32vuOXPOXayvy
AygLDFwvGoAqxsL0kMMFbvmOg8rgpn1uI5+gNLyaADowpz7cwkE9lj392NSoMdgF3tKjAOIKTyY
TDTArPTKaqr62oQ7ZRWYo8tzgApfWFaOU4y7NjIfhfVkHDLXVu7AG9xpK01/VJ0qwAAAABJRU5E
rkJggg==
""")

RUN_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAG9JREFUGFd
jZMAO/kOFGWHScAaS+v//LzaAuYz6DagK/////5+RkZHxf1fD/+PzVjB8/PIFrNDzyROwGGNZAy
M2Exm2y8iArebn4WGwunEDrAZD4TENjf/IJmJ1Y9l/5v+dDH8YQM4AsbsY/8INAgB44ioHVKqHv
gAAAABJRU5ErkJggg==
""")

RIDE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAGpJREFUGFd
jZICCkLyq/zD2mkltjCB2Qm03XAwsAAPHNDTgEjAxqxs3GEEawAr//////7imJgNIEMQHabC8fp
0BJAaiGUEApAhEI0uCNCBrBqtBVggyDWYqTBxmI9xqkADIZGQ3gxRDxRkAODJIzA34xRoAAAAAS
UVORK5CYII=
""")

SWIM_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAFpJREFUGFd
jZCASMMLU/f///z+MzcjICBaHiYH4jMgcdEkUhcg2I5vKsuorw99wHriNGFYrTf/C8EiYkUHu7X
+G+2oPGRhcdMBqwITitM//YZJwRVm8cENAagAl0DAHMC2dNAAAAABJRU5ErkJggg==
""")

CLOCK_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAGRJREFUGFdj
ZGBg+M8ABf//w5lgEUZGRpgUA4gFlgUrmgmRSDqZyDDPfD4DQ/p/uGKsCp1XOTHsFX3AwLDiLnaF
SUlJDA8fPmS4f/8+wz0zRtwKGSKU4W4CM7CZCHcnklJkzwAAzHgtAXQJ+34AAAAASUVORK5CYII=
""")

ELEV_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAIBJREFUGFd
jZICCN+8//hcR5GeE8dFpuARIIUgSpvjXr1//2djY4PJgBkzRl4/vwQZJSUkxPHv2jKGkbxbDmk
ltYDVgomLCnP8v3r5ngCkEiakoKYE13bl3D6yYEaQIJABSCAIwxSCFyGKM0nEKYIUw4CqfDVd8/
MMysLClQBQDADOaPH3ku/SjAAAAAElFTkSuQmCC
""")

DISTANCE_ICON = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAGCAYAAAD68A/GAAAAAXNSR0IArs4c6QAAAEtJREFUGFd
jZCAAeN0X/v+8M56REZ86kKJPO+IY+DwWMYAV/g9X+g+iGVfeQ9EIUggziBGkCKYAnQ1SxPehng
Gr1eimwzTjdSOy+wFaLiTvmqj9hwAAAABJRU5ErkJggg==
""")

headers = {
    'Authorization': 'Bearer %s' % ACCESS_TOKEN
}


def main(config):
    timezone = config.get("timezone") or "America/New_York"
    year = time.now().in_location(timezone).year
    sport = config.get('sport', DEFAULT_SPORT)
    athlete = config.get('athlete_id', DEFAULT_ATHLETE)
    units = config.get('units', DEFAULT_UNITS)
    period = config.get('period', DEFAULT_PERIOD)

    stats = ['count', 'distance', 'moving_time', 'elapsed_time', 'elevation_gain']

    # Optionally we can display dummy data if we need to test without the API
    # stats = {k: PREVIEW_DATA[k] for k in stats}

    stats = {k: cache.get(CACHE_PREFIX + k) for k in stats}

    if None not in stats.values():
        print("Displaying cached data.")
    else:
        print("Calling Strava API.")
        url = "%s/athletes/%s/stats" % (STRAVA_BASE, athlete)
        response = http.get(url, headers=headers)
        if response.status_code != 200:
            fail('Strava API call failed with status %d' % response.status_code)
        data = response.json()
        print(data)

        for item in stats.keys():
            stats[item] = data['%s_%s_totals' % (period, sport)][item]
            cache.set(CACHE_PREFIX + item, str(stats[item]), ttl_seconds=CACHE_TTL)
            print('saved item %s "%s" in the cache for %d seconds' % (item, str(stats[item]), CACHE_TTL))

    #################################################
    # Configure the display to the user's preferences
    #################################################

    if units.lower() == 'imperial':
        if sport == 'swim':
            stats['distance'] = round(meters_to_ft(float(stats['distance'])), 0)
            distu = 'ft'
        else:
            stats['distance'] = round(meters_to_mi(float(stats['distance'])), 1)
            distu = 'mi'
            elevu = 'ft'
        stats['elevation_gain'] = round(meters_to_ft(float(stats['elevation_gain'])), 0)
    else:
        if sport != 'swim':
            stats['distance'] = round(meters_to_km(float(stats['distance'])), 0)
            distu = 'km'
        else:
            distu = 'm'
        elevu = 'm'

    if sport == 'all':
        if stats['count'] != 1:
            actu = 'activities'
        else:
            actu = 'activity'
    else:
        actu = sport
        if stats['count'] != 1:
            actu += 's'

    print(stats)

    display_header = [
         render.Image(src = STRAVA_ICON),
    ]
    if period == 'ytd':
        display_header.append(
           render.Text(" %d" % year, font="tb-8")
        )

    SPORT_ICON = {
        'run': RUN_ICON,
        'ride': RIDE_ICON,
        'swim': SWIM_ICON,
    }[sport]

    # The number of activites and distance traveled is universal, but for cycling the elevation gain is a
    # more interesting statistic than speed so we'll vary the third item:
    if sport == 'ride':
        third_stat = [
             render.Image(src = ELEV_ICON),
             render.Text(
                 " %s %s" % (humanize.comma(stats.get('elevation_gain', 0)), elevu),
             ),
         ]
    else:
        if stats.get('distance', 0) > 0:
            split = stats.get('moving_time', 0) / stats.get('distance', 0)
            split = time.parse_duration(str(split) + 's')
            split = format_duration(split)
        else:
            split = 'N/A'

        third_stat = [
             render.Image(src = CLOCK_ICON),
             render.Text(
                 " %s%s" % (split, '/' + distu),
             ),
         ]

    return render.Root(
        child = render.Column(
            children = [
                render.Row(
                    cross_align = "center",
                    children = display_header,
                ),
                render.Row(
                    cross_align = "center",
                    children = [
                        render.Image(src = SPORT_ICON),
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
                    children = third_stat,
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

def format_duration(d):
    m = int(d.minutes)
    s = str(int((d.minutes - m) * 60))
    m = str(m)
    if len(m) == 1:
        m = '0' + m
    if len(s) == 1:
        s = '0' + s
    return '%s:%s' % (m, s)


def get_schema():

    units_options = [
        schema.Option(value='imperial', display='Imperial (US)'),
        schema.Option(value='metric', display='Metric'),
    ]

    period_options = [
        schema.Option(value='ytd', display='YTD'),
        schema.Option(value='all', display='All-time'),
    ]

    sport_options = [
        schema.Option(value='run', display='Running'),
        schema.Option(value='ride', display='Cycling'),
        schema.Option(value='swim', display='Swimming'),
    ]

    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "athlete_id",
                name = "Strava Athlete ID",
                desc = "As found in your profile URL: https://strava.com/athletes/99999999",
                icon = "user",
                default = DEFAULT_ATHLETE,
            ),
            schema.Dropdown(
                id = "sport",
                name = "What activity types do you want to display?",
                desc = "Can choose between Run, Ride or Swim.",
                icon = "rectangleList",
                options = sport_options,
                default = 'ride',
            ),
            schema.Dropdown(
                id = "units",
                name = "Which units do you want to display?",
                desc = "Imperial displays miles and feet, metric displays kilometers and meters.",
                icon = "quoteRight",
                options = units_options,
                default = DEFAULT_UNITS,
            ),
            schema.Dropdown(
                id = "period",
                name = "Display your all-time stats or YTD?",
                desc = "YTD will also display the current year in the corner",
                icon = "clock",
                options = period_options,
                default = DEFAULT_PERIOD,
            ),
        ],
    )
