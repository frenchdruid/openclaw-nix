import os
import re

start_all()

machine.wait_until_succeeds(
    "systemctl show -p Result home-manager-alice.service | grep -q 'Result=success'"
)

machine.wait_until_succeeds("test -f /home/alice/.openclaw/openclaw.json")

uid = machine.succeed("id -u alice").strip()
machine.succeed("loginctl enable-linger alice")
machine.succeed(f"systemctl start user@{uid}.service")
machine.wait_for_unit(f"user@{uid}.service")

machine.wait_until_succeeds("test -S /run/user/1000/bus")

user_env = "XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
machine.succeed(f"su - alice -c '{user_env} systemctl --user daemon-reload'")

exec_start = machine.succeed(
    f"su - alice -c '{user_env} systemctl --user show openclaw-gateway.service -p ExecStart --value'"
).strip()
exec_match = re.search(r"path=([^ ;]+)", exec_start)
if not exec_match:
    raise Exception(f"failed to parse openclaw ExecStart: {exec_start}")

gateway_wrapper = exec_match.group(1)
openclaw_bin = machine.succeed(
    f"grep -o '/nix/store/[^\" ]*/bin/openclaw' {gateway_wrapper} | head -n 1"
).strip()
if not openclaw_bin:
    raise Exception(f"failed to locate openclaw binary from wrapper: {gateway_wrapper}")

openclaw_bin_real = machine.succeed(
    f"readlink -f {openclaw_bin} || readlink {openclaw_bin}"
).strip()
if not openclaw_bin_real:
    raise Exception(f"failed to resolve openclaw binary: {openclaw_bin}")

node_bin = machine.succeed(
    f"grep -o '/nix/store/[^\" ]*/bin/node' {openclaw_bin_real} | head -n 1"
).strip()
if not node_bin:
    raise Exception(f"failed to locate node binary from wrapper: {openclaw_bin_real}")

openclaw_root = os.path.dirname(os.path.dirname(openclaw_bin_real))
openclaw_lib = os.path.join(openclaw_root, "lib", "openclaw")
openclaw_node_modules = os.path.join(openclaw_lib, "node_modules")
probe_env = f"{user_env} NODE_PATH={openclaw_node_modules}"

pi_pkg = machine.succeed(
    f"find {openclaw_node_modules}/.pnpm -path '*/node_modules/@mariozechner/pi-coding-agent' -print | head -n 1"
).strip()
if not pi_pkg:
    raise Exception("failed to find pi-coding-agent path")

pi_pkg_dir = pi_pkg


def run_probe(label, command):
    try:
        machine.succeed(command)
    except Exception:
        machine.succeed(f"echo 'fail-fast probe: {label}'")
        machine.succeed(f"echo 'openclaw_bin: {openclaw_bin}'")
        machine.succeed(f"echo 'openclaw_bin_real: {openclaw_bin_real}'")
        machine.succeed(f"echo 'pi_pkg: {pi_pkg}'")
        machine.succeed(f"echo 'pi_pkg_dir: {pi_pkg_dir}'")
        machine.succeed(f"ls -la {openclaw_lib} || true")
        machine.succeed(f"ls -la {openclaw_node_modules}/@mariozechner || true")
        machine.succeed(
            "command -v find >/dev/null && "
            f"find {openclaw_node_modules}/.pnpm -maxdepth 6 -path '*@mariozechner+clipboard*' -print || true"
        )
        machine.succeed(
            "command -v find >/dev/null && "
            f"find {openclaw_node_modules} -maxdepth 5 -name 'clipboard*.node' -print || true"
        )
        machine.succeed(
            "command -v find >/dev/null && "
            f"find {openclaw_node_modules} -maxdepth 5 -name 'clipboard*.node' "
            "-exec sh -c 'echo --- $1; ldd \"$1\" || true' _ {} \\; || true"
        )
        machine.succeed(
            f"su - alice -c '{probe_env} PI_PKG_DIR={pi_pkg_dir} {node_bin} -e \"const target=require.resolve(\\\"@mariozechner/clipboard\\\", {{ paths: [process.env.PI_PKG_DIR] }}); console.log(target);\"' || true"
        )
        raise


run_probe(
    "require-clipboard",
    f"su - alice -c '{probe_env} PI_PKG_DIR={pi_pkg_dir} {node_bin} -e \"const target=require.resolve(\\\"@mariozechner/clipboard\\\", {{ paths: [process.env.PI_PKG_DIR] }}); console.log(target); require(target);\"'",
)
run_probe(
    "clipboard-hasText",
    f"su - alice -c '{probe_env} PI_PKG_DIR={pi_pkg_dir} {node_bin} -e \"const target=require.resolve(\\\"@mariozechner/clipboard\\\", {{ paths: [process.env.PI_PKG_DIR] }}); const c=require(target); console.log(c.hasText());\"'",
)

machine.succeed(f"su - alice -c '{user_env} systemctl --user start openclaw-gateway.service'")
machine.wait_for_unit("openclaw-gateway.service", user="alice")

try:
    machine.wait_for_open_port(18999)
except Exception:
    machine.succeed(
        f"su - alice -c '{user_env} systemctl --user status openclaw-gateway.service --no-pager -n 200 2>&1' || true"
    )
    machine.succeed(
        f"su - alice -c '{user_env} systemctl --user show openclaw-gateway.service -p ActiveState -p SubState -p ExecMainCode -p ExecMainStatus -p MainPID --no-pager 2>&1' || true"
    )
    machine.succeed(
        f"su - alice -c '{user_env} systemctl --user cat openclaw-gateway.service --no-pager 2>&1' || true"
    )
    machine.succeed(
        "journalctl --user -u openclaw-gateway.service --no-pager -n 200 2>&1 || true"
    )
    machine.succeed("ls -la /tmp/openclaw/openclaw-gateway.log || true")
    machine.succeed("tail -n 200 /tmp/openclaw/openclaw-gateway.log || true")
    machine.succeed("tail -n 200 /tmp/openclaw/openclaw.log || true")
    machine.succeed("ls -la /tmp/openclaw || true")
    machine.succeed("ps -eo pid,ppid,cmd | grep -E '[o]penclaw|[n]ode' || true")
    machine.succeed("ls -la /tmp/openclaw/node-report* || true")
    machine.succeed("tail -n 200 /tmp/openclaw/node-report* || true")
    machine.succeed("coredumpctl info --no-pager | tail -n 200 || true")
    raise
