#!/usr/bin/env python3
"""No-follow state, manifest, backup, and restore boundary for shell scripts."""
from __future__ import annotations

import argparse
import datetime
import hashlib
import os
import re
import shutil
import stat
import sys
import tempfile
from pathlib import PurePosixPath

MARKER = b"ai-cli-dotfiles-backup-v1\n"
STAMP = re.compile(r"^\d{8}-\d{6}-\d{9}$")
RID = re.compile(r"^[0-9a-f]{32}$")


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def lst(path: str) -> os.stat_result:
    try:
        return os.lstat(path)
    except OSError as exc:
        fail(f"unsafe or missing path: {path}: {exc.strerror}")


def read_regular(path: str, mode: int) -> bytes:
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
    except OSError as exc:
        fail(f"unsafe metadata file: {path}: {exc.strerror}")
    try:
        s = os.fstat(fd)
        if not stat.S_ISREG(s.st_mode) or stat.S_IMODE(s.st_mode) != mode:
            fail(f"unsafe metadata file: {path}")
        with os.fdopen(fd, "rb", closefd=False) as f:
            return f.read()
    finally:
        os.close(fd)


def directory(path: str, create: bool = False) -> None:
    # Existing path components are checked before any mkdir can traverse them.
    parts = os.path.normpath(path).split(os.sep)
    cur = os.sep if path.startswith(os.sep) else ""
    for part in parts:
        if not part:
            continue
        cur = os.path.join(cur, part)
        if os.path.lexists(cur):
            s = lst(cur)
            if stat.S_ISLNK(s.st_mode) or not stat.S_ISDIR(s.st_mode):
                fail(f"unsafe directory component: {cur}")
            continue
        if not create:
            fail(f"unsafe or missing path: {cur}")
        os.mkdir(cur, 0o700)
        os.chmod(cur, 0o700)
    s = lst(path)
    if not stat.S_ISDIR(s.st_mode) or stat.S_ISLNK(s.st_mode) or stat.S_IMODE(s.st_mode) != 0o700:
        fail(f"unsafe state directory: {path}")


def physical(path: str) -> str:
    if not os.path.isabs(path):
        fail(f"path is not absolute: {path}")
    result = os.path.realpath(path)
    if result != os.path.normpath(path):
        fail(f"path is not normalized physical path: {path}")
    return result


def fsync_dir(path: str) -> None:
    fd = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def mkdirs_no_symlink(path: str) -> None:
    parts = os.path.normpath(path).split(os.sep)
    cur = os.sep if path.startswith(os.sep) else ""
    for part in parts:
        if not part:
            continue
        cur = os.path.join(cur, part)
        if os.path.lexists(cur):
            s = lst(cur)
            if not stat.S_ISDIR(s.st_mode) or stat.S_ISLNK(s.st_mode):
                fail(f"unsafe directory component: {cur}")
        else:
            os.mkdir(cur, 0o700)


def atomic(path: str, data: bytes, mode: int = 0o600) -> None:
    parent = os.path.dirname(path)
    directory(parent)
    fd, temporary = tempfile.mkstemp(prefix=f".{os.path.basename(path)}.", dir=parent)
    try:
        os.fchmod(fd, mode)
        with os.fdopen(fd, "wb", closefd=True) as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.replace(temporary, path)
        fsync_dir(parent)
    finally:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass


def homes(args: argparse.Namespace) -> tuple[str, str, str, str]:
    return tuple(physical(x) for x in (args.home, args.cursor_home, args.codex_home, args.config_root))  # type: ignore[return-value]


def active_assets(args: argparse.Namespace) -> dict[str, str]:
    home, cursor, codex, config = homes(args)
    result = {
        "bin/cursor-st": f"{home}/.local/bin/cursor-st",
        "shell/ai-cli-aliases.sh": f"{config}/ai-cli-aliases.sh",
        "cursor/hooks.json": f"{cursor}/hooks.json",
        "cursor/hooks/cursor-st-command-guard.py": f"{cursor}/hooks/cursor-st-command-guard.py",
        "cursor/hooks/prompt-timing.py": f"{cursor}/hooks/prompt-timing.py",
        "cursor/statusline.py": f"{cursor}/statusline.py",
        "cursor/cli-config.json": f"{cursor}/cli-config.json",
        "bin/codex-st": f"{home}/.local/bin/codex-st",
        "codex/config/config.toml": f"{codex}/config.toml",
        "codex/config/sol-terra-luna.config.toml": f"{codex}/sol-terra-luna.config.toml",
        "codex/AGENTS.md": f"{codex}/AGENTS.md",
        "codex/rules/default.rules": f"{codex}/rules/default.rules",
    }
    root = physical(args.repo_root)
    for folder, target_root in (("cursor/agents", f"{cursor}/agents"), ("cursor/rules", f"{cursor}/rules"), ("codex/agents", f"{codex}/agents")):
        try:
            names = os.listdir(f"{root}/{folder}")
        except OSError:
            continue
        for name in names:
            source = f"{root}/{folder}/{name}"
            if os.path.isfile(source):
                result[f"{folder}/{name}"] = f"{target_root}/{name}"
    return result


def retired_manifest_assets(args: argparse.Namespace) -> dict[str, str]:
    home, cursor, codex, _ = homes(args)
    return {
        "cursor/agents/sol-reviewer.md": f"{cursor}/agents/sol-reviewer.md",
        "cursor/agents/luna-log-analyst.md": f"{cursor}/agents/luna-log-analyst.md",
        "cursor/agents/grok-advisor.md": f"{cursor}/agents/grok-advisor.md",
        "cursor/agents/grok-architect.md": f"{cursor}/agents/grok-architect.md",
        "cursor/rules/sol-plan-terra-build.mdc": f"{cursor}/rules/sol-plan-terra-build.mdc",
        "cursor/rules/delegation-budget.mdc": f"{cursor}/rules/delegation-budget.mdc",
        "codex/rules/default.rules": f"{codex}/rules/default.rules",
    }


def manifest_assets(args: argparse.Namespace) -> dict[str, str]:
    active = active_assets(args)
    retired = retired_manifest_assets(args)
    for asset, target in retired.items():
        if asset in active and active[asset] != target:
            fail("conflicting active and retired manifest asset")
    return active | retired


def backup_allowlist(args: argparse.Namespace) -> set[str]:
    home, cursor, codex, config = homes(args)
    values = set(active_assets(args).values())
    values.update(retired_manifest_assets(args).values())
    values.update({
        f"{home}/.bashrc", f"{cursor}/hooks.json",
    })
    return values


def root_id(root: str) -> str:
    return hashlib.sha256(root.encode()).hexdigest()[:32]


def state_paths(args: argparse.Namespace) -> tuple[str, str, str]:
    state = args.state_root
    return state, f"{state}/source-roots.tsv", f"{state}/install-manifest.tsv"


def read_roots(path: str) -> dict[str, str]:
    data = read_regular(path, 0o600)
    rows: dict[str, str] = {}
    paths: set[str] = set()
    for line in data.decode("utf-8").splitlines():
            fields = line.split("\t")
            if len(fields) != 3 or fields[0] != "v1" or not RID.fullmatch(fields[1]):
                fail("malformed source registry")
            root = physical(fields[2])
            if fields[1] in rows or root in paths or root_id(root) != fields[1]:
                fail("duplicate or invalid source registry")
            rows[fields[1]] = root
            paths.add(root)
    return rows


def read_manifest(args: argparse.Namespace, allow_legacy: bool = False) -> list[tuple[str, str, str, str, str]]:
    state, registry, manifest = state_paths(args)
    directory(state)
    manifest_data = read_regular(manifest, 0o600)
    expected = manifest_assets(args)
    rows: list[tuple[str, str, str, str, str]] = []
    seen_assets: set[str] = set()
    seen_targets: set[str] = set()
    text = manifest_data.decode("utf-8").splitlines()
    legacy = bool(text and text[0].split("\t")[0] != "v2")
    if legacy:
        if not allow_legacy:
            fail("legacy manifest is not trusted")
        current = physical(args.repo_root)
        for line in text:
            fields = line.split("\t")
            if len(fields) != 3 or fields[0] not in {"symlink", "copy"}:
                fail("malformed legacy manifest")
            mode, source, target = fields
            source = os.path.normpath(source)
            if not source.startswith(current + "/"):
                fail("legacy source is not under current repository")
            asset = source[len(current) + 1:]
            if expected.get(asset) != target:
                fail("legacy source-target mapping is invalid")
            if asset in seen_assets or target in seen_targets:
                fail("duplicate legacy manifest row")
            seen_assets.add(asset); seen_targets.add(target)
            rows.append((mode, root_id(current), asset, target, source))
        return rows
    roots = read_roots(registry)
    for line in text:
        fields = line.split("\t")
        if len(fields) != 5 or fields[0] != "v2" or fields[1] not in {"symlink", "copy"}:
            fail("malformed manifest")
        _, mode, ident, asset, target = fields
        if ident not in roots or not asset or asset.startswith("/") or ".." in PurePosixPath(asset).parts:
            fail("untrusted manifest provenance")
        if expected.get(asset) != target or asset in seen_assets or target in seen_targets:
            fail("invalid manifest asset mapping")
        source = f"{roots[ident]}/{asset}"
        seen_assets.add(asset); seen_targets.add(target)
        rows.append((mode, ident, asset, target, source))
    return rows


def cmd_manifest(args: argparse.Namespace) -> None:
    try:
        rows = read_manifest(args, allow_legacy=args.migrate_legacy)
    except SystemExit:
        raise
    if args.migrate_legacy:
        # The caller publishes these v2 rows only after all install mutations succeed.
        manifest = state_paths(args)[2]
        if read_regular(manifest, 0o600)[:3] != b"v2\t":
            print("warning: migrating verified current-root legacy install manifest", file=sys.stderr)
    for row in rows:
        print("\t".join(row))


def cmd_preflight(args: argparse.Namespace) -> None:
    state, registry, manifest = state_paths(args)
    if not os.path.lexists(state):
        return
    directory(state)
    registry_exists = os.path.lexists(registry)
    manifest_exists = os.path.lexists(manifest)
    if registry_exists:
        read_roots(registry)
    if manifest_exists:
        read_manifest(args, allow_legacy=True)


def cmd_publish(args: argparse.Namespace) -> None:
    state, registry, manifest = state_paths(args)
    directory(state, create=True)
    current = physical(args.repo_root)
    expected = active_assets(args)
    wanted: list[tuple[str, str, str]] = []
    seen: set[str] = set()
    with open(args.records, encoding="utf-8") as f:
        for line in f.read().splitlines():
            fields = line.split("\t")
            if len(fields) != 3 or fields[0] not in {"symlink", "copy"} or expected.get(fields[1]) != fields[2]:
                fail("invalid publish record")
            if fields[1] in seen:
                fail("duplicate publish record")
            seen.add(fields[1]); wanted.append(tuple(fields))
    old: list[tuple[str, str, str, str, str]] = []
    if (args.retain_codex or args.retain_cursor) and os.path.lexists(manifest):
        old = read_manifest(args, allow_legacy=True)
    retained = [
        (mode, ident, asset, target)
        for mode, ident, asset, target, _ in old
        if asset not in seen and (
            (args.retain_codex and (asset.startswith("codex/") or asset == "bin/codex-st"))
            or (args.retain_cursor and asset != "shell/ai-cli-aliases.sh" and not (asset.startswith("codex/") or asset == "bin/codex-st"))
        )
    ]
    roots = {root_id(current): current}
    if retained:
        prior_roots = read_roots(registry)
        roots.update({ident: prior_roots[ident] for _, ident, _, _ in retained})
    registry_data = b"".join(f"v1\t{i}\t{p}\n".encode() for i, p in sorted(roots.items()))
    atomic(registry, registry_data)
    lines = []
    for mode, asset, target in wanted:
        ident = root_id(current)
        lines.append(f"v2\t{mode}\t{ident}\t{asset}\t{target}\n")
    for mode, ident, asset, target in retained:
        lines.append(f"v2\t{mode}\t{ident}\t{asset}\t{target}\n")
    atomic(manifest, "".join(lines).encode())


def allowed(args: argparse.Namespace) -> set[str]:
    return backup_allowlist(args)


def backup_file(backup: str, target: str) -> str:
    return backup + target


def cmd_backup_init(args: argparse.Namespace) -> None:
    directory(args.backup_root, create=True)
    if not STAMP.fullmatch(os.path.basename(args.backup_dir)) or os.path.dirname(args.backup_dir) != args.backup_root:
        fail("invalid backup directory name")
    directory(args.backup_dir, create=True)
    inventory = f"{args.backup_dir}/.inventory.tsv"
    marker = f"{args.backup_dir}/.complete"
    if not os.path.lexists(inventory):
        atomic(inventory, b"")
    else:
        read_regular(inventory, 0o600)
    if os.path.lexists(marker):
        if read_regular(marker, 0o600) != MARKER:
            fail("invalid backup marker")


def cmd_backup_complete(args: argparse.Namespace) -> None:
    cmd_backup_init(args)
    read_regular(f"{args.backup_dir}/.inventory.tsv", 0o600)
    marker = f"{args.backup_dir}/.complete"
    if not os.path.lexists(marker):
        atomic(marker, MARKER)


def cmd_backup_add(args: argparse.Namespace) -> None:
    cmd_backup_init(args)
    if args.target not in allowed(args):
        fail("backup target is not allowlisted")
    inventory = f"{args.backup_dir}/.inventory.tsv"
    lines = read_regular(inventory, 0o600).decode("utf-8").splitlines()
    recorded = set()
    for line in lines:
        f = line.split("\t")
        if len(f) != 3 or f[0] != "v1" or f[1] not in {"file", "symlink"} or f[2] not in allowed(args) or f[2] in recorded:
            fail("invalid backup inventory")
        recorded.add(f[2])
    if args.target in recorded or not os.path.lexists(args.target):
        return
    payload = backup_file(args.backup_dir, args.target)
    parent = os.path.dirname(payload)
    mkdirs_no_symlink(parent)
    # backup root is private; refuse a substituted path component nevertheless.
    cur = args.backup_dir
    for component in os.path.relpath(parent, args.backup_dir).split(os.sep):
        if component != ".":
            cur = os.path.join(cur, component)
            s = lst(cur)
            if not stat.S_ISDIR(s.st_mode) or stat.S_ISLNK(s.st_mode):
                fail("unsafe backup payload parent")
    s = lst(args.target)
    if stat.S_ISREG(s.st_mode):
        fd = os.open(args.target, os.O_RDONLY | os.O_NOFOLLOW)
        temp: str | None = None
        try:
            source_stat = os.fstat(fd)
            if not stat.S_ISREG(source_stat.st_mode):
                fail("backup source is not a regular file")
            out, temp = tempfile.mkstemp(prefix=".payload.", dir=parent)
            with os.fdopen(fd, "rb") as src, os.fdopen(out, "wb") as dst:
                fd = -1
                shutil.copyfileobj(src, dst); dst.flush(); os.fsync(dst.fileno())
                os.fchmod(dst.fileno(), stat.S_IMODE(source_stat.st_mode))
            os.replace(temp, payload); fsync_dir(parent)
        finally:
            if fd >= 0:
                os.close(fd)
            if temp is not None:
                try: os.unlink(temp)
                except FileNotFoundError: pass
    elif stat.S_ISLNK(s.st_mode):
        os.symlink(os.readlink(args.target), payload)
        fsync_dir(parent)
    else:
        fail("backup source is not a regular file or symlink")
    kind = "symlink" if stat.S_ISLNK(s.st_mode) else "file"
    atomic(inventory, ("\n".join(lines + [f"v1\t{kind}\t{args.target}"]) + "\n").encode())


def validate_backup(args: argparse.Namespace, candidate: str) -> list[tuple[str, str, str]]:
    directory(args.backup_root)
    name = os.path.basename(candidate)
    if os.path.dirname(candidate) != args.backup_root or not STAMP.fullmatch(name):
        fail("invalid backup candidate")
    try:
        datetime.datetime.strptime(name[:15], "%Y%m%d-%H%M%S")
    except ValueError:
        fail("invalid backup timestamp")
    directory(candidate)
    marker, inventory = f"{candidate}/.complete", f"{candidate}/.inventory.tsv"
    if read_regular(marker, 0o600) != MARKER:
        fail("invalid backup marker")
    rows, seen = [], set()
    for line in read_regular(inventory, 0o600).decode("utf-8").splitlines():
        f = line.split("\t")
        if len(f) != 3 or f[0] != "v1" or f[1] not in {"file", "symlink"} or f[2] not in allowed(args) or f[2] in seen:
            fail("invalid backup inventory")
        payload = backup_file(candidate, f[2])
        # No symlink traversal from backup root to payload.
        cur = candidate
        for part in os.path.relpath(os.path.dirname(payload), candidate).split(os.sep):
            if part != ".":
                cur = os.path.join(cur, part); s = lst(cur)
                if not stat.S_ISDIR(s.st_mode) or stat.S_ISLNK(s.st_mode): fail("unsafe payload parent")
        s = lst(payload)
        if (f[1] == "file" and not stat.S_ISREG(s.st_mode)) or (f[1] == "symlink" and not stat.S_ISLNK(s.st_mode)):
            fail("invalid backup payload")
        seen.add(f[2]); rows.append((f[1], f[2], payload))
    return rows


def destination_parent_safe(target: str, args: argparse.Namespace) -> None:
    home, cursor, codex, config = homes(args)
    anchors = [home, cursor, codex, config]
    anchor = max((x for x in anchors if target == x or target.startswith(x + "/")), key=len, default=None)
    if not anchor: fail("restore target is outside configured roots")
    cur = anchor
    for part in os.path.relpath(os.path.dirname(target), anchor).split(os.sep):
        if part != ".":
            cur = os.path.join(cur, part)
            if os.path.lexists(cur):
                s = lst(cur)
                if not stat.S_ISDIR(s.st_mode) or stat.S_ISLNK(s.st_mode): fail("unsafe restore destination parent")


def cmd_restore(args: argparse.Namespace) -> None:
    rows = validate_backup(args, args.backup)
    for _, target, _ in rows: destination_parent_safe(target, args)
    for kind, target, payload in rows:
        if os.path.lexists(target):
            s = lst(target)
            if stat.S_ISDIR(s.st_mode): fail("refusing to replace directory restore target")
            if not args.force: continue
        if args.dry_run: continue
        parent = os.path.dirname(target); mkdirs_no_symlink(parent)
        if kind == "symlink":
            fd, temp = tempfile.mkstemp(prefix=f".{os.path.basename(target)}.restore-", dir=parent)
            os.close(fd); os.unlink(temp)
            try:
                os.symlink(os.readlink(payload), temp)
                os.replace(temp, target); fsync_dir(parent)
            finally:
                try: os.unlink(temp)
                except FileNotFoundError: pass
        else:
            fd = os.open(payload, os.O_RDONLY | os.O_NOFOLLOW)
            temp: str | None = None
            try:
                payload_stat = os.fstat(fd)
                if not stat.S_ISREG(payload_stat.st_mode):
                    fail("invalid backup payload")
                out, temp = tempfile.mkstemp(prefix=f".{os.path.basename(target)}.restore-", dir=parent)
                with os.fdopen(fd, "rb") as src, os.fdopen(out, "wb") as dst:
                    fd = -1
                    shutil.copyfileobj(src, dst); dst.flush(); os.fsync(dst.fileno())
                    os.fchmod(dst.fileno(), stat.S_IMODE(payload_stat.st_mode))
                os.replace(temp, target); fsync_dir(parent)
            finally:
                if fd >= 0:
                    os.close(fd)
                if temp is not None:
                    try: os.unlink(temp)
                    except FileNotFoundError: pass


def cmd_latest(args: argparse.Namespace) -> None:
    try:
        candidates = sorted(x.path for x in os.scandir(args.backup_root) if STAMP.fullmatch(x.name))
    except OSError:
        return
    for candidate in reversed(candidates):
        marker = f"{candidate}/.complete"
        if not os.path.lexists(marker):
            continue
        validate_backup(args, candidate)
        print(candidate)
        return


def cmd_lock(args: argparse.Namespace) -> None:
    state, _, _ = state_paths(args)
    directory(state, create=True)
    path = f"{state}/operation.lock"
    try:
        os.mkdir(path, 0o700)
    except FileExistsError:
        fail("another or stale operation lock exists")
    fsync_dir(state)


def cmd_unlock(args: argparse.Namespace) -> None:
    path = f"{args.state_root}/operation.lock"
    try:
        s = lst(path)
        if stat.S_ISDIR(s.st_mode) and not stat.S_ISLNK(s.st_mode):
            os.rmdir(path); fsync_dir(args.state_root)
    except OSError:
        pass


def parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser()
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--state-root", required=True); common.add_argument("--repo-root", required=True)
    common.add_argument("--home", required=True); common.add_argument("--cursor-home", required=True)
    common.add_argument("--codex-home", required=True); common.add_argument("--config-root", required=True)
    sub = p.add_subparsers(dest="command", required=True)
    q = sub.add_parser("manifest", parents=[common]); q.add_argument("--migrate-legacy", action="store_true"); q.set_defaults(func=cmd_manifest)
    q = sub.add_parser("preflight", parents=[common]); q.set_defaults(func=cmd_preflight)
    q = sub.add_parser("publish", parents=[common]); q.add_argument("--records", required=True); q.add_argument("--retain-codex", action="store_true"); q.add_argument("--retain-cursor", action="store_true"); q.set_defaults(func=cmd_publish)
    for name, fn in (("backup-init", cmd_backup_init), ("backup-add", cmd_backup_add), ("backup-complete", cmd_backup_complete)):
        q = sub.add_parser(name, parents=[common]); q.add_argument("--backup-root", required=True); q.add_argument("--backup-dir", required=True)
        if name == "backup-add": q.add_argument("--target", required=True)
        q.set_defaults(func=fn)
    q = sub.add_parser("restore", parents=[common]); q.add_argument("--backup-root", required=True); q.add_argument("--backup", required=True); q.add_argument("--force", action="store_true"); q.add_argument("--dry-run", action="store_true"); q.set_defaults(func=cmd_restore)
    q = sub.add_parser("latest", parents=[common]); q.add_argument("--backup-root", required=True); q.set_defaults(func=cmd_latest)
    q = sub.add_parser("lock", parents=[common]); q.set_defaults(func=cmd_lock)
    q = sub.add_parser("unlock", parents=[common]); q.set_defaults(func=cmd_unlock)
    return p


if __name__ == "__main__":
    args = parser().parse_args()
    args.func(args)
