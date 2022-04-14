load("hash.star", "hash")

def main(*_):
    in_str = "Your string here."
    out_str = hash.sha256(in_str)

    print(in_str, out_str)
