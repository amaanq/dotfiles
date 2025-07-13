import hashlib
import json
import os
import datetime

now = datetime.datetime.now(datetime.timezone.utc)
user = "ilfak@hex-rays.com"

license = {
    "payload": {
        "name": user,
        "email": user,
        "licenses": [
            {
                "id": "96-2137-ACAB-99",
                "owner": user,
                "product_id": "IDAPRO",
                "edition_id": "ida-pro",
                "description": "IDA Pro",
                "start_date": now.strftime("%Y-%m-%d"),
                "end_date": now.replace(year=now.year + 3).strftime("%Y-%m-%d"),
                "issued_on": now.strftime("%Y-%m-%d %H:%M:%S"),
                "license_type": "named",
                "seats": 999,
                "add_ons": [],
                #               'features': [] This is for floating license
            }
        ],
    },
    "header": {"version": 1},
}


def add_every_addon(license):
    addons = [
        "HEXX86",
        "HEXX64",
        "HEXARM",
        "HEXARM64",
        "HEXMIPS",
        "HEXMIPS64",
        "HEXPPC",
        "HEXPPC64",
        "HEXRV",
        "HEXRV64",
        "HEXARC",
        "HEXARC64",
        "TEAMS",
        "LUMINA",
    ]
    for count, addon in enumerate(addons):
        license["payload"]["licenses"][0]["add_ons"].append(
            {
                "id": f"97-1337-DEAD-{count:02}",
                "code": addon,
                "owner": license["payload"]["licenses"][0]["id"],
                "start_date": now.strftime("%Y-%m-%d"),
                "end_date": now.replace(year=now.year + 10).strftime("%Y-%m-%d"),
            }
        )


add_every_addon(license)


def json_stringify_alphabetical(obj) -> str:
    return json.dumps(obj, sort_keys=True, separators=(",", ":"))


def buf_to_bigint(buf: bytes) -> int:
    return int.from_bytes(buf, byteorder="little")


def bigint_to_buf(i):
    return i.to_bytes((i.bit_length() + 7) // 8, byteorder="little")


pub_modulus_hexrays: int = buf_to_bigint(
    bytes.fromhex(
        "edfd425cf978546e8911225884436c57140525650bcf6ebfe80edbc5fb1de68f4c66c29cb22eb668788afcb0abbb718044584b810f8970cddf227385f75d5dddd91d4f18937a08aa83b28c49d12dc92e7505bb38809e91bd0fbd2f2e6ab1d2e33c0c55d5bddd478ee8bf845fcef3c82b9d2929ecb71f4d1b3db96e3a8e7aaf93"
    )
)
pub_modulus_patched: int = buf_to_bigint(
    bytes.fromhex(
        "edfd42cbf978546e8911225884436c57140525650bcf6ebfe80edbc5fb1de68f4c66c29cb22eb668788afcb0abbb718044584b810f8970cddf227385f75d5dddd91d4f18937a08aa83b28c49d12dc92e7505bb38809e91bd0fbd2f2e6ab1d2e33c0c55d5bddd478ee8bf845fcef3c82b9d2929ecb71f4d1b3db96e3a8e7aaf93"
    )
)
private_key: int = buf_to_bigint(
    bytes.fromhex(
        "77c86abbb7f3bb134436797b68ff47beb1a5457816608dbfb72641814dd464dd640d711d5732d3017a1c4e63d835822f00a4eab619a2c4791cf33f9f57f9c2ae4d9eed9981e79ac9b8f8a411f68f25b9f0c05d04d11e22a3a0d8d4672b56a61f1532282ff4e4e74759e832b70e98b9d102d07e9fb9ba8d15810b144970029874"
    )
)


def decrypt(message) -> bytes:
    bdecrypted = pow(buf_to_bigint(message), exponent, pub_modulus_patched)
    decrypted = bigint_to_buf(bdecrypted)
    return decrypted[::-1]


def encrypt(message) -> bytes:
    encrypted = pow(buf_to_bigint(message[::-1]), private_key, pub_modulus_patched)
    encrypted = bigint_to_buf(encrypted)
    return encrypted


exponent = 0x13


def sign_hexlic(payload: dict) -> str:
    data = {"payload": payload}
    data_str = json_stringify_alphabetical(data)
    buffer = bytearray(128)
    seed = os.urandom(32)
    for i in range(32):
        buffer[1 + i] = seed[i]
    sha256 = hashlib.sha256()
    sha256.update(data_str.encode())
    digest = sha256.digest()
    for i in range(32):
        buffer[33 + i] = digest[i]
        continue
    encrypted = encrypt(buffer)
    return encrypted.hex().upper()


def patch_dll(filename) -> None:
    if not os.path.exists(filename):
        print(f"Didn't find {filename}, skipping patch generation")
        return
    with open(filename, "rb") as f:
        data = f.read()
        if data.find(bytes.fromhex("EDFD42CBF978")) != -1:
            print(f"{filename} looks to be already patched :)")
            return
        else:
            if data.find(bytes.fromhex("EDFD425CF978")) == -1:
                print(f"{filename} doesn't contain the original modulus.")
                return
            data = data.replace(
                bytes.fromhex("EDFD425CF978"), bytes.fromhex("EDFD42CBF978")
            )
            # patched_filename = f'{filename}.patched'
            patched_filename = f"{filename}"
            with open(patched_filename, "wb") as f:
                f.write(data)
            print(f"File {patched_filename} patched!")


license["signature"] = sign_hexlic(license["payload"])

message = bytes.fromhex(license["signature"])

print(decrypt(message).hex().upper().zfill(2 * 128))

print(encrypt(decrypt(message)).hex().upper().zfill(2 * 128))

serialized = json.dumps(license, indent=2)
filename = "idapro_" + license["payload"]["licenses"][0]["id"] + ".hexlic"

with open(filename, "w", encoding="utf-8", newline="\n") as f:
    f.write(serialized)
print("cwd:", os.getcwd())

print(f"Saved new license to {os.path.abspath(filename)}!")

patch_dll("ida32.dll")
patch_dll("ida.dll")
patch_dll("libida32.so")
patch_dll("libida.so")
patch_dll("libida32.dylib")
patch_dll("libida.dylib")
