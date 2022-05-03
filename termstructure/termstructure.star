"""
Applet: US Yield Curve
Summary: Plots treasury rates
Description: Track changes to the yield curve over different US Treasury maturities.
Author: Rob Kimball
"""

load("re.star", "re")
load("http.star", "http")
load("math.star", "math")
load("time.star", "time")
load("cache.star", "cache")
load("render.star", "render")
load("schema.star", "schema")
load("encoding/json.star", "json")

CME_BASE = "https://www.cmegroup.com/CmeWS/mvc/Quotes/ContractsByNumber"
CBOE_BASE = "https://cdn.cboe.com/api/global/delayed_quotes/term_structure"

SAMPLE_DATA = {
    "price": [
        (8.49 , 4393.00),
        (10.76, 4396.00),
        (11.84, 4407.00),
        (12.55, 4426.00),
        (13.14, 4448.00),
        (13.39, 4473.00),
        (13.64, 4497.00),
        (13.89, 4523.00),
        (14.14, 4545.00),
        (14.64, 4588.00),
        (15.64, 4673.00),
        (16.64, 4753.00),
    ],
    "volume": [
        (8.49, 1708683.0),
        (10.76, 2758.0),
        (11.84, 83.0),
        (12.55, 120.0),
        (13.14, 0.0),
        (13.39, 0.0),
        (13.64, 0.0),
        (13.89, 0.0),
        (14.14, 0.0),
        (14.64, 0.0),
        (15.64, 0.0),
        (16.64, 0.0),
    ],
}

CONTRACT_MONTHS = {
    "January": "F",
    "February": "G",
    "March": "H",
    "April": "J",
    "May": "K",
    "June": "M",
    "July": "N",
    "August": "Q",
    "September": "U",
    "October": "V",
    "November": "X",
    "December": "Z",
}

# RGB Coefficients
COLOR_VECTORS = {
    "Red": (1.0, 0.1, 0.1),
    "Green": (0.1, 1.0, 0.1),
    "Blue": (0.1, 0.1, 1.0),
    "Yellow": (1.0, 1.0, 0.1),
    "Orange": (1.0, 0.66, 0.1),
    "Purple": (0.5, 0.1, 1.0),
    "Pink": (1.0, 0.1, 0.8),
    "Bloomberg": (0.98, 0.545, 0.117),
    "FactSet": (0.0, 0.682, 0.937),
}

# If the value has an integer ID, we can find it in the CME data. Otherwise, we'll override each special case.
FUTURES = {
    "Equity": {
        "US": {
            "ES": ("S&P 500 Index E-mini", 133),  # ; SPX E-mini
            "NQ": ("NDX E-mini", 146),
            "RTY": ("Russell 2000 E-mini", 8314),
            "YM": ("Dow $5 E-mini", 318),
            "MES": ("SPX Micro E-mini", 8667),
            "MNQ": ("NDX Micro E-mini", 8668),
            "M2K": ("RTY Micro E-mini", 8669),
            "MYM": ("Dow Micro E-mini", 8670),
            "ESG": ("SPX ESG E-mini", 8847),
            "EMD": ("SMID E-mini", 166),
            # 132,  # didn't return anything?
            "RX": ("Dow Jones Real Estate", 335),
            "VIX": ("S&P 500 Volatility Index", "VIX"),
        },
        "International": {
            "NIY": ("Nikkei (Yen)", 167),
            "NKD": ("Nikkei (USD)", 168),
            "TPY": ("TOPIX (Yen)", 8491),
        },
    },
    "Crypto": {
        "BTC": ("Bitcoin", 8478),
        "MBT": ("Micro Bitcoin", 9024),
        "ETH": ("Ethereum", 8995),
        "MET": ("Micro ETH", 10065),
    },
    "Commodities": {
        "GD": ("S&P GSCI", 33),
        "AW": ("Bloomberg Commodity Index", 333),
        "Metals": {
            "Precious": {
                "GC": ("Gold", 437),
                "MGC": ("Micro Gold", 5224),
                "SI": ("Silver", 458),
                "QO": ("Gold E-mini", 454),
                "QI": ("Silver E-mini", 450),
                "PL": ("Platinum", 446),
                "PA": ("Palladium", 445),
            },
            "Base": {
                "ALI": ("Aluminum", 7440),
                "HG": ("Copper", 438),
            },
            "Ferrous": {
                "HRC": ("Steel", 2508),
            },
        },
        "Energy": {
            "Crude": {
                "CL": ("Crude Oil", 425),
                "MCL": ("Micro Crude Oil", 10037),
                "BZ": ("Brent", 424),
            },
            "Natural": {
                "NG": ("Nat Gas", 444),
            },
            "Refined": {
                "RB": ("Gasoline", 429),
            },
        },
        "Agriculture": {
            "Grain": {
                "ZC": ("Corn", 300),
                "ZW": ("Wheat", 323),
                "ZS": ("Soybeans", 320),
                "ZO": ("Oats", 331),
                "ZR": ("Rice", 336),
            },
            "Livestock": {
                "LE": ("Live Cattle", 22),
                "HE": ("Lean Hog", 19),
                "GF": ("Feeder Cattle", 34),
            },
            "Dairy": {
                "DC": ("Milk", 27),
                "CSC": ("Cheese", 5201),
            },
            "Forest": {
                "LB": ("Lumber", 2498),
            },
            "Softs": {
                "CJ": ("Cocoa", 423),
                "KT": ("Coffee", 440),
                "TT": ("Cotton", 460),
                "YO": ("Sugar", 470),
            },
        },
    },
}

def is_numeric(s):
    if type(s) in ("int", "float"):
        return True
    else:
        return len(re.match(r"^[\d,\.]+$", str(s))) > 0

def walk_tree(d, subtree = None):
    flat = {}
    for key, value in d.items():
        if subtree:
            if key.lower() == subtree.lower():
                if type(value) == "dict":
                    flat.update(walk_tree(value))
                else:
                    flat[key] = value
        else:
            if type(value) == "dict":
                flat.update(walk_tree(value))
            else:
                flat[key] = value
    return flat

def tree_labels(d):
    labels = []
    for key, value in d.items():
        if type(value) == "dict":
            labels.append(key)
            labels.extend(tree_labels(value))
    return labels

def contract_search(search_text):
    contracts = walk_tree(FUTURES)
    labels = tree_labels(FUTURES)
    if search_text.upper() in contracts.keys():
        results = [
            schema.Option(
                display = "%s (%s)" % (contracts[search_text.upper()][0], search_text.upper()),
                value = str(contracts[search_text.upper()][1]),
            ),
        ]
    elif search_text.lower() in labels:
        subset = walk_tree(FUTURES, search_text.lower())
        results = [
            schema.Option(
                display = "%s (%s)" % (name, k),
                value = str(cme_id),
            )
            for k, (name, cme_id) in subset.items()
        ]
    else:
        results = [
            schema.Option(
                display = "%s (%s)" % (name, k),
                value = str(cme_id),
            )
            for k, (name, cme_id) in contracts.items()
        ]

    return results

def get_cme_data(cme_id):
    timestamp = time.now()
    cache_id = "termstructure/cme/%i" % cme_id

    data = cache.get(cache_id)
    # expired = True
    # if data:
    #     updated = data[]

    if not data:
        url = "%s?productIds=%i&contractsNumber=18&venue=G&type=VOLUME&isProtected&_t=%i" % (
            CME_BASE,
            cme_id,
            timestamp.unix,
        )
        print("Getting fresh data from %s" % url)

        headers = {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
            "Accept-Encoding": "json",
            "Accept-Language": "en-US,en;q=0.9",
            "Cache-Control": "max-age=0",
            "Connection": "keep-alive",
            "Host": "www.cmegroup.com",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "Upgrade-Insecure-Requests": "1",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.88 Safari/537.36",
            "sec-ch-ua": "\"Not A;Brand\";v=\"99\", \"Chromium\";v=\"100\", \"Google Chrome\";v=\"100\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "Windows",
        }

        response = http.get(url, headers = headers)
        if response.status_code != 200:
            # We only print the error and then display whatever was cached if we can. Invalidation is manual.
            print(response.body())
        else:
            data = response.json()
            print("Cached data to %s" % cache_id)
            cache.set(cache_id, json.encode(data))
    else:
        print("Returning cached data from %s" % cache_id)
        data = json.decode(data)

    result = []
    for row in data:
        formatted = {
            "code": row.get("productCode"),
            "expiry": row.get("expirationCode"),
            "exp_date": time.parse_time(row.get("expirationDate"), "20060102"),
            "last": row.get("last"),
            "settle": row.get("priorSettle", "-"),
            "volume": row.get("volume"),
        }
        result.append(formatted)

    print(result)
    return {timestamp: result}

def get_cboe_data(contract = "VIX"):
    timestamp = time.now()
    cache_id = "termstructure/cboe/%s" % contract

    data = cache.get(cache_id)
    if not data:
        url = "%s/%s/%s_%s.json" % (
            CBOE_BASE,
            timestamp.year,
            contract,
            timestamp.format("2006-01-02"),
        )
        print("Getting fresh data from %s" % url)

        headers = {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9",
            "Accept-Encoding": "json",
            "Accept-Language": "en-US,en;q=0.9",
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "Host": "www.cboe.com",
            "sec-ch-ua": "\"Not A;Brand\";v=\"99\", \"Chromium\";v=\"100\", \"Google Chrome\";v=\"100\"",
            "Sec-Fetch-Dest": "document",
            "Sec-Fetch-Mode": "navigate",
            "Sec-Fetch-Site": "none",
            "Sec-Fetch-User": "?1",
            "Upgrade-Insecure-Requests": "1",
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.88 Safari/537.36",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "Windows",
        }
        response = http.get(url, headers = headers)
        print("Reply from CBOE", response, response.status_code)
        if response.status_code != 200:
            # We only print the error and then display whatever was cached if we can. Invalidation is manual.
            print(response.body())
        else:
            data = response.json()
            print("Cached data to %s" % cache_id)
            cache.set(cache_id, json.encode(data))
    else:
        print("Returning cached data from %s" % cache_id)
        data = json.decode(data)

    expirations = {
        exp["symbol"]: time.parse_time(exp["expirationDate"], "02-Jan-2006")
        for exp in data["data"]["expirations"]
    }
    prices = data["data"]["prices"]

    time_series = {}
    for price in prices:
        exp = expirations[price["index_symbol"]]
        item = {
            "price_time": price["price_time"],
            "code": contract,
            "expiry": price["index_symbol"].replace(contract, ""),
            "exp_date": exp,
            "last": price["price"],
        }
        time_series.setdefault(price["price_time"], []).append(item)

    return time_series

def plot_current_data(config, data):
    COLOR_VOLUME = "#7189aa"
    COLOR_FILL = "#042a50"
    COLOR_LINE = "#FFFFFF"
    NO_COLOR = "#0000"

    if len(data):
        price_time = list(data.keys())[0]
        data = data[price_time]
        for row in data:
            row["display_price"] = 0.0
            row["display_volume"] = 0.0
            for price in ["settle", "last"]:
                if is_numeric(row[price]) and row[price] != "-":
                    row["display_price"] = float(row[price])
            for vol in ["volume"]:
                if is_numeric(row[vol]) and row[vol] != "-":
                    row["display_volume"] = float(row[vol].replace(",", ""))
        chrono_sorted = sorted(data, key = lambda r: r["exp_date"])

        plot_data = [
            (
                scale_time_axis(row["exp_date"]),
                row["display_price"],
            )
            for row in chrono_sorted if row["display_price"] > 0
        ]

        volume_data = [
            (
                scale_time_axis(row["exp_date"]),
                row["display_volume"],
            )
            for row in chrono_sorted if row["display_price"] > 0
        ]
    else:
        contract = "XX"
        expiry = CONTRACT_MONTHS[time.now().format("January")] + time.now().format("6")
        plot_data = SAMPLE_DATA["price"]
        volume_data = SAMPLE_DATA["volume"]

    height = 32
    width = 64

    bar_plots = []
    if config.bool("volume_bars", True):
        if config.bool("log_volume", False):
            log_volume = [(l, math.log(v)) for l, v in volume_data]
        else:
            log_volume = volume_data

        max_volume = max(max([v for _, v in log_volume]), 1)
        min_loc = min([l for l, _ in log_volume])
        max_loc = max([l for l, _ in log_volume])

        bar_width = int(width / (len(log_volume) * 2))
        rescaled = [
            (
                ((loc - min_loc) / (max_loc - min_loc)) * width,
                (value / max_volume) * height,
            )
            for loc, value in log_volume
        ]

        bar_plots = [
            render.Box(
                width = 1,
                height = height,
                color = NO_COLOR,
            ),
        ]
        pos, spacer = 0, 0

        for i, (location, volume) in enumerate(rescaled):
            pos = bar_width + spacer
            spacer = int(location + 1)

            if (spacer - pos) > 0:
                # print(spacer - pos, spacer, pos)
                # Add spacer from the last data point
                bar_plots.append(
                    render.Box(
                        width = spacer - pos - 1,
                        height = 0,
                        color = NO_COLOR,
                    ),
                )

            color = COLOR_VOLUME
            # Calculate the bar height in pixels
            if volume > 0:
                volume = int(volume)
                if volume == 0:
                    volume = 1
            # Make this bar transparent if the data is zero
            elif volume == float("-inf"):
                volume = 0
                color = color + "00"
            else:
                volume = 0
                color = color + "00"

            bar_plots.append(
                render.Box(
                    width = bar_width,
                    height = volume,
                    color = color,
                ),
            )

    return [
        render.Plot(
            data = plot_data,
            width = width,
            height = height,
            color = COLOR_FILL,
            y_lim = (min([v for _, v in plot_data]) * 0.98, max([v for _, v in plot_data]) * 1.05),
            fill = True,
        ),
        render.Row(
            expanded = True,
            cross_align = "end",
            children = bar_plots,
        ),
        render.Plot(
            data = plot_data,
            width = width,
            height = height,
            color = COLOR_LINE,
            y_lim = (min([v for _, v in plot_data]) * 0.98, max([v for _, v in plot_data]) * 1.05),
            fill = False,
        ),
    ]

def plot_timeseries_data(config, data):
    color_choice = config.get("graph_color", "FactSet")
    color_vector = COLOR_VECTORS[color_choice]
    dates = list(sorted(data.keys()))

    max_len = max([len(data[d]) for d in dates])
    # all_prices = []
    # for d in dates:
    #     for p in data[d]:
    #         all_prices.append(p["last"])
    min_price = min([p["last"] for d in dates for p in data[d]])
    max_price = max([p["last"] for d in dates for p in data[d]])
    dates = [d for d in dates if len(data[d]) == max_len]

    plots = []
    min_color = 15
    for i, entry in enumerate(dates):
        points = sorted(data[entry], key = lambda x: x["exp_date"])
        c = 255 * (math.pow(1.01, i) / math.pow(1.01, len(dates)))
        c_r, c_g, c_b = color_vector
        rgb = (
            max(min_color, int(c * c_r)),
            max(min_color, int(c * c_g)),
            max(min_color, int(c * c_b)),
        )
        color = rgb_to_hex(*rgb)
        if i == len(dates) - 1:
            color = "999"

        curve = [(p["exp_date"].unix, p.get("last", 0.0)) for p in points]
        print(i, entry, color, curve)
        plots.append(render.Plot(
            data = curve,
            width = 64,
            height = 32,
            color = "#" + color,
            y_lim = (min_price, max_price + 3),
            fill = False,
        ))

    return plots

def rgb_to_hex(r, g, b):
    """Return 6-character hexadecimal color code from R/G/B values given as integers"""
    ret = ""
    for i in (r, g, b):
        this = "%X" % i
        if len(this) == 1:
            this = "0" + this
        ret = ret + this
    return ret

def scale_time_axis(expiry):
    current = time.now()
    difference = (expiry - current).hours / 24
    # print(current, expiry, difference)
    if difference > 365:
        return difference / 365 + 25
    elif difference < 0:
        return 0.0
    else:
        return math.log(difference) * 4

def main(config):
    # contract = config.get("contract", "133")  # Default = ES
    contract = config.get("contract", "VIX")
    NO_COLOR = "#0000"
    source = "Lookup"
    print(contract, type(contract))
    if re.match(r"^{.*}$", str(contract)):
        contract = re.match(r"\"value\":\"(\w+)\"}", str(contract))
        if len(contract):
            contract = contract[0][1]  # this gives us the extracted value
    if is_numeric(contract):
        source = "CME"
        contract = int(contract)
    if contract == "VIX":
        source = "CBOE"
    print("Displaying %s from %s" % (contract, source))

    data = {}
    if source == "CME":
        data = get_cme_data(contract)
    elif source == "CBOE":
        data = get_cboe_data(contract)

    last_price = 22.24
    expiry = ""
    if len(data.keys()) > 1:
        plots = plot_timeseries_data(config, data)
        dates = list(sorted(data.keys()))

        data[dates[-1]]
    elif len(data.keys()) == 1:
        plots = plot_current_data(config, data)
        price_time = list(data.keys())[0]
        contract = data[price_time][0]["code"]
        last_price = data[price_time][0]["display_price"]
        expiry = ":" + sorted(data[price_time], key = lambda r: r["display_volume"], reverse = True)[0]["expiry"]
    else:
        plots = [
            render.Box(width = 1, height = 1)
        ]

    legend = []
    if config.bool("legend", True):
        legend_width = (len(contract) + len(expiry) + len(str(last_price)) + 2) * 4 - 1
        legend = [
            render.Box(
                color = NO_COLOR,
                width = legend_width,
                height = 9,
                padding = 1,
                child = render.Box(
                    color = "#ccc5",
                    width = legend_width - 2,
                    height = 7,
                    padding = 1,
                    child = render.Row(
                        children = [
                            render.Text("%s%s " % (contract, expiry), font = "CG-pixel-3x5-mono"),
                            render.Text(str(last_price), color = "#fb8b1e", font = "CG-pixel-3x5-mono"),
                        ]
                    ),
                ),
            ),
        ]

    return render.Root(
        delay = 1000,
        child = render.Stack(
            children = plots + [
                render.Row(
                    expanded = True,
                    main_align = "end",
                    children = legend,
                )
            ]
        )
    )


def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Typeahead(
                id = "contract",
                name = "Contract",
                desc = "Choose which contract to display.",
                icon = "chartLine",
                handler = contract_search,
            ),
            schema.Toggle(
                id = "volume_bars",
                name = "Show volume bars",
                desc = "Show or hide bars that indicate daily contract volume. Data only available for certain contracts.",
                icon = "chartColumn",
                default = True,
            ),
            schema.Toggle(
                id = "log_volume",
                name = "Log-scale volume",
                desc = "Rescale the contract volume by the natural log.",
                icon = "bezierCurve",
                default = False,
            ),
            schema.Toggle(
                id = "legend",
                name = "Show legend",
                desc = "Show or hide the contract code, expiry and last price.",
                icon = "tag",
                default = True,
            ),
        ],
    )
