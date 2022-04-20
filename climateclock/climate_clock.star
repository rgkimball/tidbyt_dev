"""
Applet: Climate Clock
Summary: ClimateClock.world
Description: The most important number in the world.
Author: Rob Kimball
"""

load("math.star", "math")
load("time.star", "time")
load("render.star", "render")
load("schema.star", "schema")
load("encoding/base64.star", "base64")

# This is everything we would get from the API if we were to retrieve it over HTTP. In reality, the data here is only
# updated every couple of years so pinging the API isn't really necessary. I've pasted a recent JSON pull below, which
# makes updating the app easier and means fewer code changes if we do decide to start pulling it directly.
# This might be helpful if we add a screen to this app that displays their climate change news feed or the fund AUM.
# Source: https://api.climateclock.world/v1/clock
ALL_DATA = {
    "data": {
        "api_version": "v1.0",
        "config": {
            "device": "generic",
            "display": {
                "deadline": {
                    "color_primary": "#eb1c23",
                    "color_secondary": "#eb1c23",
                },
                "lifeline": {
                    "color_primary": "#4aa1cc",
                    "color_secondary": "#4aa1cc",
                },
                "neutral": {
                    "color_primary": "#ffffff",
                    "color_secondary": "#ffffff",
                },
                "newsfeed": {
                    "separator": " | ",
                },
                "timer": {
                    "unit_labels": {
                        "day": [
                            "DAY",
                            "D",
                        ],
                        "days": [
                            "DAYS",
                            "D",
                        ],
                        "year": [
                            "YEAR",
                            "YR",
                            "Y",
                        ],
                        "years": [
                            "YEARS",
                            "YRS",
                            "Y",
                        ],
                    },
                },
            },
            "modules": [
                "carbon_deadline_1",
                "renewables_1",
                "newsfeed_1",
            ],
        },
        "modules": {
            "carbon_deadline_1": {
                "description": "Time to act before we reach irreversible 1.5°C global temperature rise",
                "flavor": "deadline",
                "labels": [
                    "TIME LEFT TO LIMIT GLOBAL WARMING TO 1.5°C",
                    "TIME LEFT BEFORE 1.5°C GLOBAL WARMING",
                    "TIME TO ACT",
                ],
                "lang": "en",
                "timestamp": "2029-07-23T00:46:03+00:00",
                "type": "timer",
                "update_interval_seconds": 604800,
            },
            "green_climate_fund_1": {
                "description": "USD in the Green Climate Fund",
                "flavor": "lifeline",
                "growth": "linear",
                "initial": 9.52,
                "labels": [
                    "GREEN CLIMATE FUND",
                    "CLIMATE FUND",
                    "GCF",
                ],
                "lang": "en",
                "rate": 0,
                "resolution": 0.01,
                "timestamp": "2021-09-20T00:00:00+00:00",
                "type": "value",
                "unit_labels": [
                    "$B",
                ],
                "update_interval_seconds": 86400,
            },
            "indigenous_land_1": {
                "description": "Despite threats and lack of recognition, indigenous people are protecting this much land.",
                "flavor": "lifeline",
                "growth": "linear",
                "initial": 43.5,
                "labels": [
                    "LAND PROTECTED BY INDIGENOUS PEOPLE",
                    "INDIGENOUS PROTECTED LAND",
                    "INDIGENOUS PROTECTED",
                ],
                "lang": "en",
                "rate": 0,
                "resolution": 0.1,
                "timestamp": "2021-10-01T00:00:00+00:00",
                "type": "value",
                "unit_labels": [
                    "M KM²",
                ],
                "update_interval_seconds": 86400,
            },
            "newsfeed_1": {
                "description": "A newsfeed of hope: good news about climate change.",
                "flavor": "lifeline",
                "lang": "en",
                "newsfeed": [
                    {
                        "date": "2022-02-03T14:48:23+00:00",
                        "headline": "Snoqualmie Tribe Acquires 12,000 Acres of Ancestral Forestland in King County",
                        "headline_original": "Snoqualmie Tribe Acquires 12,000 Acres of Ancestral Forestland in King County ",
                        "link": "https://snoqualmietribe.us/snoqualmie-tribe-acquires-12000-acres-of-ancestral-forestland-in-king-county/?fbclid=IwAR390NwqMLsCso8T0gI1OYcOyxEJjOvCGgHUXEQmDjK78Aq6vW_ehPdJpu4 ",
                        "source": "Snoqualmie Tribe",
                        "summary": "",
                    },
                    {
                        "date": "2022-02-01T14:48:23+00:00",
                        "headline": "Earth has 14% more tree species than previously thought",
                        "headline_original": "Earth has more tree species than we thought ",
                        "link": "https://www.bbc.com/news/science-environment-60198433 ",
                        "source": "BBC",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-28T14:48:23+00:00",
                        "headline": "US federal judge blocks leasing more than 80 million acres for oil and gas production by the US Depa",
                        "headline_original": "In blow to Biden administration, judge halts oil and gas leases in Gulf of Mexico",
                        "link": "https://grist.org/energy/in-blow-to-biden-administration-judge-halts-oil-and-gas-leases-in-gulf-of-mexico/  ",
                        "source": "Grist",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-28T14:48:23+00:00",
                        "headline": "Australia pledges $700 million to protect Great Barrier Reef amid climate change threat",
                        "headline_original": "Australia pledges $700 million to protect Great Barrier Reef amid climate change threat  ",
                        "link": "https://edition.cnn.com/2022/01/27/australia/australia-great-barrier-reef-intl-hnk/index.html ",
                        "source": "CNN",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-27T14:48:23+00:00",
                        "headline": "China’s renewable energy sources may make up 50% of the country’s power capacity in 2022",
                        "headline_original": "Non-fossil fuels forecast to be 50% of China’s power capacity in 2022",
                        "link": "https://www.reuters.com/world/china/non-fossil-fuels-forecast-be-50-chinas-power-capacity-2022-2022-01-28/ ",
                        "source": "Reuters",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-26T14:48:23+00:00",
                        "headline": "Los Angeles City Council will ban new oil and gas wells and phase out existing wells",
                        "headline_original": "In historic vote, Los Angeles will phase out oil drilling",
                        "link": "https://grist.org/energy/in-historic-vote-los-angeles-will-phase-out-oil-drilling/ ",
                        "source": "Grist",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-24T14:48:23+00:00",
                        "headline": "China to cut energy consumption intensity by 13.5% in five years",
                        "headline_original": "China to cut energy consumption intensity by 13.5% pct in five years",
                        "link": "http://www.xinhuanet.com/english/20220124/b53f7dc6f5c246569cb440d87e387d83/c.html ",
                        "source": "Xinhua",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-13T14:48:23+00:00",
                        "headline": "Container shipping giant, Maersk, speeds up decarbonisation target by a decade",
                        "headline_original": "Maersk speeds up decarbonisation target by a decade",
                        "link": "https://www.reuters.com/markets/commodities/maersk-moves-net-zero-target-forward-by-decade-2040-2022-01-12/",
                        "source": "Reuters",
                        "summary": "",
                    },
                    {
                        "date": "2022-01-02T14:48:23+00:00",
                        "headline": "France bans plastic packaging for most fruits and vegetables",
                        "headline_original": "France bans plastic packaging for most fruits and vegetables",
                        "link": "https://www.aljazeera.com/news/2022/1/2/france-bans-plastic-packaging-for-most-fruits-and-vegetables ",
                        "source": "AlJazeera",
                        "summary": "",
                    },
                ],
                "type": "newsfeed",
                "update_interval_seconds": 3600,
            },
            "renewables_1": {
                "description": "The percentage share of global energy consumption currently generated by renewable resources (solar, wind, hydroelectricity, wave and tidal, and bioenergy).",
                "flavor": "lifeline",
                "growth": "linear",
                "initial": 11.4,
                "labels": [
                    "WORLD'S ENERGY FROM RENEWABLES",
                    "GLOBAL RENEWABLE ENERGY",
                    "RENEWABLES",
                ],
                "lang": "en",
                "rate": 2.0428359571070087e-8,
                "resolution": 1e-9,
                "timestamp": "2020-01-01T00:00:00+00:00",
                "type": "value",
                "unit_labels": [
                    "%",
                ],
                "update_interval_seconds": 86400,
            },
        },
        "retrieval_timestamp": "2022-04-05T22:19:55+00:00",
    },
    "status": "success",
}

def round(num, precision):
    """Round a float to the specified number of significant digits"""
    return math.round(num * math.pow(10, precision)) / math.pow(10, precision)

def duration_to_string(sec):
    """
    Builds a prettier duration display from the total seconds than what is natively available in Go.
    This function was adapted from LukiLeu's Google Traffic app.

    :param sec: numeric type, total seconds of the trip duration
    :return: tuple of strings, years, days and a HH:MM:SS timestamp
    """
    seconds_in_year = 60 * 60 * 24 * 365
    seconds_in_day = 60 * 60 * 24
    seconds_in_hour = 60 * 60
    seconds_in_minute = 60

    years = sec // seconds_in_year
    days = (sec - (years * seconds_in_year)) // seconds_in_day
    hours = (sec - (years * seconds_in_year) - (days * seconds_in_day)) // seconds_in_hour
    minutes = (sec - (years * seconds_in_year) - (days * seconds_in_day) - (hours * seconds_in_hour)) // seconds_in_minute
    seconds = (sec - (years * seconds_in_year) - (days * seconds_in_day) - (hours * seconds_in_hour) - (minutes * seconds_in_minute))

    str_years, str_days, timestamp = "", "", ""
    for part in (hours, minutes, seconds):
        if part < 10:
            timestamp = timestamp + "0%i:" % part
        else:
            timestamp = timestamp + "%i:" % part
    timestamp = timestamp[:-1]  # final colon

    if years > 0:
        str_years = "%i Years" % years
    if days > 0:
        str_days = "%i Days" % days

    return str_years, str_days, timestamp

def renewables(DATA):
    fps = 80

    data = DATA["data"]["modules"]["renewables_1"]
    initial = data["initial"]  # 11.4
    units = data["unit_labels"][0]
    rate = data["rate"]
    start = time.parse_time(data["timestamp"])
    resolution = int(str(data["rate"])[-1]) + 1

    end = time.now()
    elapsed = end - start
    current = elapsed.seconds * rate + initial

    def generate_data(x):
        # Decimal; generate {speed} values per second to animate over
        d = current + ((x * rate) / fps)

        # String; convert each one to a string, rounded to {resolution} digits
        s = "%s" % round(d, resolution)

        # Formatted; pad each string if it isn't at least {resolution + 3} long, so the animation doesn't jump
        f = s + "0" * (resolution - len(s) + 3) + units

        return render.Box(
            # expanded=True,
            # main_align="center",
            child = render.Text(f, color = "#050"),
            height = 16,
            width = 64,
        )

    # Generate enough frames to fill 15 seconds
    frames = [generate_data(x) for x in range(15 * (1000 // fps))]

    return render.Root(
        delay = 1000 // fps,
        child = render.Stack(
            children = [
                render.Image(BG_RENEWABLES),
                # render.Box(width = 64, height = 32, color = "#0006"),
                render.Column(
                    expanded = True,
                    main_align = "top",
                    cross_align = "center",
                    children = [render.Animation(children = frames)],
                ),
            ],
        ),
    )

def global_warming(DATA):
    fps = 1

    data = DATA["data"]["modules"]["carbon_deadline_1"]
    deadline = time.parse_time(data["timestamp"])
    rate = -1

    start = time.now()
    if deadline <= start:
        frames = [
            render.Row(
                expanded = True,
                main_align = "center",
                children = [
                    render.Text("FIN", color = "#00094d"),
                ],
            ),
        ]
    else:
        remaining = int((deadline - start).seconds)

        frames = []

        for i in range(1, 15 * fps):
            years, days, stamp = duration_to_string(remaining + (rate * i))
            childs = []
            for element in (years, days, stamp):
                if len(element):
                    childs.append(
                        render.Row(
                            expanded = True,
                            main_align = "center",
                            children = [
                                render.Text(element, color = "#003"),
                            ],
                        ),
                    )
            frames.append(
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = childs,
                ),
            )

    return render.Root(
        delay = 1000 // fps,
        child = render.Stack(
            children = [
                render.Image(BG_WARMING),
                # render.Box(width = 64, height = 32, color = "#0008"),
                render.Column(
                    expanded = True,
                    main_align = "center",
                    cross_align = "center",
                    children = [render.Animation(children = frames)],
                ),
            ],
        ),
    )

SCREENS = {
    # "Renewable Energy": renewables,
    "Global Warming": global_warming,
}

def main(config):
    display = config.get("display", list(SCREENS.keys())[0])
    print(display)
    return SCREENS.get(display)(ALL_DATA)

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Dropdown(
                id = "display",
                name = "Display type",
                desc = "",
                icon = "chartPie",
                options = [
                    schema.Option(value = k, display = k)
                    for k, v in SCREENS.items()
                ],
                default = list(SCREENS.keys())[0],
            ),
        ],
    )

BG_RENEWABLES = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAMAAACVQ462AAADAFBMVEUAAAD////U0cHC0W84LkkyKUI5Mzu9uMORjpW1sbstJTuuq7MyKkM0LEU0LUIyKkRBOlJTTWKloq1bVmkyLEU6NE1LR1ttaXxPTGBhX3KAfo41PlY5RV9ATWo7R2FAS2RGUWmOlKE8SWJSXHHw8/lOWGvN2OvM1+rV3u7Z4fDe5fLj6fTo7fbm6/Tt8fjs8Pc/UG3K1unL1+rP2uzO2evT3e7T3e3X4O/W3+7d5fLc5PHf5vLe5fHh6PTg5/Lh6PPq7/fp7vbo7fXy9frQ2+zP2uvR3OzU3u3Z4vDY4e/b5PHa4/DZ4u/j6vTi6fPn7fbm7PXl6/Tu8vhOZIHe5vHr8Pfj6vPx9frw9PlYeJxEW3VMaog+WXFxjadxhpc9XHNEZoBahqg7VmtCXG9keopAZHtYdYdDbYRNdItOcIPg5ehEcolJb4NXgJbh5+rk6Ork5udGeI9JfJNGdYvf6OxHfpU5ZXhAcYZHfZNAcYVCc4d3s8y+4O7a6e/b5+zh6Ovx9vjb6O3f5+rZ6e7c6Ozf6Ovy9fbk5+jj5ufM7fbd6OvY6e3q9vnu9vjx9fbi5+jW7PDg6+3h5+jW6+7d6uzu9fba6uze6+ze6+vi6Ojz9fX09fVYeE1gfkxqilJ5nlJ6n1N3l1eFp2KWs3eeuYJyjVN9mliHqFh7lVZrgkhleUWFnlqYsmCivmGjv2KlwGSdt2CQp1qlv2KqxWeqw2uWqWatxWarw2Wvx2mlu2iyyGewx2atxGWswWW6zWymt2C2yWqgsGC4yH26zWu9zmy5ymu2x2m+z26tvmW9zmvA0W3B0W7C0W6/0G21xGe9zW27y2zD0nK4x2zF03W/znTH1Xq4xGWst2zM14TI03nDyH7O0YvW2ZSTlErIx7rW1cy+vK3X1cfq6eGsqp3OzMHl49jv7ujW08PV0sLY1cbw7d3U0sjh39Xy8ezCv7Lc2czl2KbMwJ339vP/xUX/v0P/wkT/u0Lv27X/t0D/sT764MX29fSjloy1p5yxraz////IYjU7AAABAHRSTlP///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////8AU/cHJQAAAAlwSFlzAAALEwAACxMBAJqcGAAABRZpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDYuMC1jMDAyIDc5LjE2NDQ2MCwgMjAyMC8wNS8xMi0xNjowNDoxNyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczpkYz0iaHR0cDovL3B1cmwub3JnL2RjL2VsZW1lbnRzLzEuMS8iIHhtbG5zOnBob3Rvc2hvcD0iaHR0cDovL25zLmFkb2JlLmNvbS9waG90b3Nob3AvMS4wLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIDIxLjIgKFdpbmRvd3MpIiB4bXA6Q3JlYXRlRGF0ZT0iMjAyMi0wNC0xMVQxNzozMjozOC0wNDowMCIgeG1wOk1vZGlmeURhdGU9IjIwMjItMDQtMTFUMjI6MDM6MzktMDQ6MDAiIHhtcDpNZXRhZGF0YURhdGU9IjIwMjItMDQt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
""")

BG_WARMING = base64.decode("""
iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAYAAACinX6EAAAAAXNSR0IArs4c6QAABMJJREFUaEPlWd1vG0UQn7X6UCGkQlXxQv1URPiohBCExAnn89mJ0zbky+RCJV56f9mhAqJgSBOnJa1T++y4UQMtoEDcJIU39wlVrSqhigeUQbMfd+uzLwZRkUt6L3ezMz7N77e/md09s5NHAUFe9/9UTwAnjwbPrV/OBAYPZ4GNCMA0+4D4jYE6x8B0AjSU/uMrzwH89qSbB6CdmO4xcRs1B67zlBqPRGacAAJJlw5UjfUC4H2nq6NX9P77rYFrPInaQ0lA5nhQAt3T0+VNEX7F8PA4EmD2lyGR2O1Qrl7imeMaAd1AWFIqPCyRANjdlfwIAuIIXE0gzXJU2aoYRQbDe2fap3T/VfqfM7AGhczDZa3G9L7GcGssmgBS/170xMxvpCoc45HEXz1JVAph2BxDvqqp1e0Q3M3hFYDELiQkDap4ExIo2crH8OdR5Ou4Ws8PwX18cB2urg+K/UkPPAw3RjWRhzV9+G2GP4484wTc0QnYu3dY+Rt8eWndHOnZZA5KAKONkLeck7uCUNcPVUDSFF22Vf9n8X5zVWzEsKIY3sqhNV4RM1vLRa4G1jkZ4+XEWegArxZJS0wkXQzXsmhNVP2dU6uS7VBvL3+c5M6Gq4BrnRj0HJO5qlByJQsMG1neBK0pQUJrpQsB0kc7KG9x75fvJxnMEMCw0T1HwkgXHYTouE/bYYa1DB3owSp4goBrGXneFxqPGo9jDbBMDbDWnr/Kk3DoW2OaTCKCYVUSMCsJ+DZEQMR4HAnYqzlZs55/BFYnQUHAisl3gtZcTShgyZRfeBCsuXrQG66YkPxAfEVpXSGSZBf0vwjF105OiLxJ8gTe+yoDbKQmm2DZFD3gvADbKplaGTOwztfAu2RCclK8hBPgx8RrXWP5OmA5yJ9yVic/dfyl2lfyx3IGGC6nBQEfrwoCLqfb+hiNq9ohX3JmtSNmPxtfW3fXclN41Mwr4ISRN/PPBU6GVwUBUZezPgHu4BKoe/LDVfGCT9uJigMJlFvrm/a8aExdet729fehOHYTGJYMnwDn9iS4/SX/B/YNA54/9iIf4773Su3fB+JVAWBdaID3icHzz1/qg2MnXuL50/XH40fw+MHv/PnlU33cLo42gOGC4X8PsKsGFLMN3kydO5P+j8of7XDbfbcEdsWAYq4Ry0XA+WES3HdK/mJAeMIElOd2uF/hYDg/zPcBdi0NxUwgF+enqYCA2W0g2317sSMuYCKqCEL/I3SEPT2/yjmMQylAjetxDL+WBKymoZgmAkRCzoZGQGGb2+5bi2CH4uIkBWdjWkg7hMMnQBtXOBh+OYTO5gy4py+DvZbhdVKe2gJnU7xMt9WLSFbkU/JyTy/E4nREODgBw7Rky4ncnPZ7gBrX4xh+MYTO3Rke5L6xAPml16E8sQXOXY0AaZPfvmVCMVUX96E6OM1p/ruuSlCfpKKOj0/ZTzg4ASlJAGM8P18BapxKXubP8LMUOjsFcPvmwf7eEjM+3gRnuxAoQNqRCnhtPhaVQDg4AQMez4fwdDTBc03Q4xheTKHzawHcV+fBvi0JONsE555GgLRVTLHf436y1d3vbeGe9j/aKmfKL7/8ZuQyWD7b5Fgpjp144cih+2Pk32zKnnkC/gamm/tRuDLkTAAAAABJRU5ErkJggg==
""")
