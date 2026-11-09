import json
import os

with open(".github/build.json") as f:
    config = json.load(f)

    jobs = []

    for name, data in config["platforms"].items():
        if data.get("include") is not True:
            continue

        settings = data.get("settings", {})

        jobs.append({
            "name": name,
            "version": config.get("version", "0.0.0"),
            "platform": data["platform"],
            "variant": settings.get("variant", "debug"),
            "architectures": ",".join(
            settings.get("architectures", [])
            ),
            "bundle_format": ",".join(
            settings.get("bundle_format", [])
            ),
            "texture_compression":
                settings.get("texture_compression") == "enabled",
            "with_symbols":
                settings.get("with_symbols", False),
            "build_report":
                settings.get("build_report", False),
            "runner": (
                "macos-latest"
                if name.startswith("ios")
                    else "ubuntu-latest"
                  ),
            "keystore": settings.get("keystore", ""),
            "keystore_password": settings.get("keystore_password", ""),
            "key_pass": settings.get("key_pass", ""),
              })

        if not jobs:
            raise ValueError("No platforms selected")

        matrix = json.dumps({"include": jobs})

        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
              f.write("matrix=" + matrix + "\n")