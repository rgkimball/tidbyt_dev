import os
from time import sleep

iter_seconds = 60 * 3
apps = [
    # ("usyieldcurve", "us_yield_curve"),
    ("finevent", "finevent"),
]
pixlet_exe = r"C:\Users\kimba\Code\tidbyt\pixlet.exe"
token = os.environ.get("TIDBYT_API_KEY", None)
device = os.environ.get("TIDBYT_DEVICE_ID", None)

if __name__ == '__main__':

    pardir = os.getcwd()

    while True:
        for direc, app in apps:
            os.chdir(os.path.join(pardir, direc))
            render = f"{pixlet_exe} render {app}.star"
            push = f"{pixlet_exe} push --api-token {token} {device} --installation-id {direc} {app}.webp"
            os.system(render)
            os.system(push)
        print(f"sleeping for {iter_seconds:,}")
        sleep(iter_seconds)
