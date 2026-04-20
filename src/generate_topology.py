import os
from datetime import datetime
from pathlib import Path

import yaml


def get_repo_root() -> Path:
    candidates = []

    repo_root_from_env = os.getenv("SENTINEL_REPO_ROOT")
    if repo_root_from_env:
        candidates.append(Path(repo_root_from_env))

    candidates.extend([
        Path.cwd(),
        Path(__file__).resolve().parents[1],
    ])

    for candidate in candidates:
        if (candidate / "infra" / "docker" / "core.yml").exists():
            return candidate

    raise FileNotFoundError("Could not locate infra/docker/core.yml from the current environment")


def sync_map() -> None:
    repo_root = get_repo_root()
    compose_file_path = repo_root / "infra" / "docker" / "core.yml"
    output_file_path = repo_root / "topology_map.md"

    with compose_file_path.open("r", encoding="utf-8") as compose_file:
        data = yaml.safe_load(compose_file) or {}

    services = sorted((data.get("services") or {}).keys())
    lines = [
        "# Sentinel Topology Map",
        f"**Snapshot:** {datetime.now().isoformat()}",
        "",
        "## Active Services",
        *[f"- {service}" for service in services],
    ]

    output_file_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Topology map generated successfully at {output_file_path}")


if __name__ == "__main__":
    sync_map()