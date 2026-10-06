"""Delete local E3 demo objects through Storage API, then remove fixture rows."""

import os
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path


def main() -> None:
    database = sys.argv[1]
    if database != "postgres" and not database.startswith("e3_demo_dryrun_"):
        raise SystemExit("Refusing nonlocal database name")
    if database == "postgres" and os.environ.get("E3_DEMO_APPROVED") != "1":
        raise SystemExit("Effective local cleanup requires explicit per-run approval")
    local_db_ip = os.environ.get("E3_LOCAL_DB_IP")
    if not local_db_ip:
        raise SystemExit("Run cleanup through tools/demo/e3_local_demo.sh cleanup")
    root = Path(__file__).resolve().parents[2]
    local_url = f"postgresql://postgres:postgres@127.0.0.1:54322/{database}"

    def paths() -> list[str]:
        result = subprocess.run(
            [
                "psql", local_url, "-X", "-v", "ON_ERROR_STOP=1", "-At", "-c",
                "select name from storage.objects where bucket_id='product-images' "
                "and name like 'e3d0/%' order by name;",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        return result.stdout.splitlines()

    objects = paths()
    if objects and database != "postgres":
        raise SystemExit("Clone has E3 object metadata; never use the effective Storage API on a clone")
    if objects:
        key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
        if not key:
            raise SystemExit("Local SUPABASE_SERVICE_ROLE_KEY required to remove Storage objects")
        for path in objects:
            if not path.startswith("e3d0/"):
                raise SystemExit("Unexpected Storage path")
            encoded = urllib.parse.quote(path, safe="/")
            request = urllib.request.Request(
                f"http://127.0.0.1:54321/storage/v1/object/product-images/{encoded}",
                method="DELETE",
                headers={"apikey": key, "Authorization": f"Bearer {key}"},
            )
            with urllib.request.urlopen(request, timeout=20) as response:
                if response.status < 200 or response.status >= 300:
                    raise SystemExit(f"Storage removal failed for {path}")
        if paths():
            raise SystemExit("E3 Storage objects remain after API removal")

    subprocess.run(
        [
            "psql", local_url, "-X", "-v", "ON_ERROR_STOP=1", "-v", f"e3_local_db_ip={local_db_ip}",
            "-f", str(root / "supabase/snippets/step_e3_demo_cleanup.sql"),
        ],
        check=True,
    )


if __name__ == "__main__":
    main()
