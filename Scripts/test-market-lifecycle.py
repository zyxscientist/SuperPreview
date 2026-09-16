#!/usr/bin/env python3
"""Run one real-device market stress session and preserve failure evidence.

No test retries, target-process kills, or automatic relaunch after an observed exit.
Runtime outputs live outside the repository by default.
"""

import argparse
import datetime as dt
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
BUNDLE = "com.peterz.SuperPreview"
TEST = "SuperPreviewUITests/MarketLifecycleStressUITests/testContinuousMarketBackgroundForeground"


def timestamp():
    return dt.datetime.now(dt.timezone.utc).isoformat()


def arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", required=True, help="Connected physical iPhone UDID")
    parser.add_argument("--cycles", type=int, default=100)
    parser.add_argument("--background-durations", default="0.5,2,10,30")
    parser.add_argument("--configuration", choices=["Debug", "Release"], default="Release")
    parser.add_argument("--no-diagnostics", action="store_true", help="Run the uninstrumented baseline")
    parser.add_argument("--output", type=Path, help="New, empty output directory")
    parser.add_argument("--skip-build", action="store_true", help="Reuse this configuration's built test products")
    options = parser.parse_args()
    try:
        durations = [float(value) for value in options.background_durations.split(",")]
        if not 1 <= options.cycles <= 10000 or not durations or any(not 0 <= value <= 300 for value in durations):
            raise ValueError()
    except ValueError:
        parser.error("cycles must be 1...10000; background durations must be comma-separated seconds in 0...300")
    return options


class Session:
    def __init__(self, options):
        self.options = options
        if options.output:
            self.output = options.output.expanduser().resolve()
            self.output.mkdir(parents=True, exist_ok=True)
            if any(self.output.iterdir()):
                raise ValueError("Output directory must be empty; existing evidence is never overwritten")
        else:
            parent = Path.home() / "Library/Logs/SuperPreview/MarketLifecycle"
            parent.mkdir(parents=True, exist_ok=True)
            self.output = Path(tempfile.mkdtemp(prefix=dt.datetime.now().strftime("%Y%m%d-%H%M%S-"), dir=parent))
        self.derived = Path.home() / "Library/Developer/Xcode/DerivedData" / ("SuperPreviewMarketStress-" + options.configuration)
        self.state = {"phase": "preparing", "runnerPID": os.getpid(), "startedAt": timestamp(),
                      "device": options.device, "cycles": options.cycles, "configuration": options.configuration,
                      "backgroundDurations": options.background_durations, "diagnostics": not options.no_diagnostics,
                      "artifacts": str(self.output)}
        self.target_pid = None
        self.observed_exits = []
        self.seen_crashes = set()
        self.save_state()
        print(f"Evidence directory: {self.output}", flush=True)

    def save_state(self):
        temporary = self.output / "status.tmp"
        temporary.write_text(json.dumps(self.state, indent=2) + "\n")
        temporary.replace(self.output / "status.json")

    def event(self, name, **details):
        entry = {"timestamp": timestamp(), "event": name, **details}
        with (self.output / "host-timeline.jsonl").open("a") as stream:
            stream.write(json.dumps(entry) + "\n")
        print(json.dumps(entry), flush=True)

    def device_json(self, command, label):
        path = self.output / (label + ".json")
        result = subprocess.run(["xcrun", "devicectl", "device", *command, "--device", self.options.device,
                                 "--timeout", "10", "--json-output", str(path)], capture_output=True, text=True, timeout=15)
        if result.returncode:
            with (self.output / "collection-errors.log").open("a") as stream:
                stream.write(f"{timestamp()} {label}: {result.stderr}{result.stdout}\n")
            return None
        return json.loads(path.read_text()).get("result", {})

    def processes(self):
        result = self.device_json(["info", "processes", "--search", "SuperPreview"], "latest-processes")
        if result is None:
            return None  # Connection failure is not evidence that the app exited.
        processes = result.get("runningProcesses", [])
        pids = [item["processIdentifier"] for item in processes
                if item.get("executable", "").endswith("/SuperPreview.app/SuperPreview")]
        with (self.output / "process-history.jsonl").open("a") as stream:
            stream.write(json.dumps({"timestamp": timestamp(), "appPIDs": pids}) + "\n")
        return pids

    def crash_files(self, label):
        result = self.device_json(["info", "files", "--domain-type", "systemCrashLogs", "--no-recurse"], label)
        if result is None:
            return None
        return [item for item in result.get("files", []) if not item.get("resources", {}).get("isDirectory")
                and ("superpreview" in item.get("name", "").lower() or item.get("name", "").startswith("JetsamEvent"))]

    def copy(self, source, destination, domain, identifier=None):
        destination.parent.mkdir(parents=True, exist_ok=True)
        command = ["xcrun", "devicectl", "device", "copy", "from", "--device", self.options.device,
                   "--source", source, "--destination", str(destination), "--domain-type", domain, "--timeout", "20"]
        if identifier:
            command += ["--domain-identifier", identifier]
        result = subprocess.run(command, capture_output=True, text=True, timeout=25)
        if result.returncode:
            with (self.output / "collection-errors.log").open("a") as stream:
                stream.write(f"{timestamp()} copy {source}: {result.stderr}{result.stdout}\n")
        return result.returncode == 0

    def collect_crashes(self):
        files = self.crash_files("latest-crash-files")
        if files is None:
            return
        for item in files:
            source = item.get("relativePath", item["name"])
            if source in self.seen_crashes:
                continue
            destination = self.output / "system-reports" / Path(source).name
            if self.copy(source, destination, "systemCrashLogs"):
                self.seen_crashes.add(source)
                self.event("system-report-collected", file=str(destination))

    def snapshot(self):
        if self.options.no_diagnostics:
            return
        destination = self.output / "app-snapshots" / str(time.time_ns())
        if self.copy("Documents/MarketLifecycleDiagnostics", destination, "appDataContainer", BUNDLE):
            self.event("app-diagnostics-collected", directory=str(destination))

    def build(self):
        self.state["phase"] = "building"
        self.save_state()
        command = ["xcodebuild", "-project", str(ROOT / "SuperPreview.xcodeproj"), "-scheme", "SuperPreview",
                   "-testPlan", "SuperPreviewMarketLifecycle", "-configuration", self.options.configuration,
                   "-destination", f"platform=iOS,id={self.options.device}", "-derivedDataPath", str(self.derived),
                   "-allowProvisioningUpdates", "build-for-testing"]
        with (self.output / "build.log").open("w") as stream:
            result = subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
        if result.returncode:
            raise RuntimeError(f"Build failed; see {self.output / 'build.log'}")

    def prepare_test_run(self):
        candidates = sorted((path for path in (self.derived / "Build/Products").glob("*.xctestrun")
                             if not path.name.startswith("MarketLifecycle-")), key=lambda path: path.stat().st_mtime)
        if not candidates:
            raise RuntimeError("No built .xctestrun products found; remove --skip-build")
        source = candidates[-1]
        with source.open("rb") as stream:
            data = plistlib.load(stream)
        count = 0
        for configuration in data.get("TestConfigurations", []):
            for target in configuration.get("TestTargets", []):
                if target.get("BlueprintName") != "SuperPreviewUITests":
                    continue
                count += 1
                target.setdefault("EnvironmentVariables", {}).update({
                    "MARKET_STRESS_CYCLES": str(self.options.cycles),
                    "MARKET_STRESS_BACKGROUNDS": self.options.background_durations,
                    "MARKET_STRESS_DIAGNOSTICS": "0" if self.options.no_diagnostics else "1"
                })
        if count == 0:
            raise RuntimeError("Unsupported .xctestrun structure or missing UI test target")
        # Keep beside the original so __TESTROOT__ still resolves built products.
        destination = source.with_name("MarketLifecycle-" + self.output.name + ".xctestrun")
        with destination.open("wb") as stream:
            plistlib.dump(data, stream)
        with (self.output / "test-run.xctestrun").open("wb") as stream:
            plistlib.dump(data, stream)
        return destination

    def analyze(self):
        analysis = {"testExitCode": self.state.get("testExitCode"), "reports": [], "gpuErrors": [],
                    "delayedMainHeartbeats": [], "limitations": [
                        "Process disappearance alone may be XCTest cleanup.",
                        "A passing run does not prove an intermittent failure is fixed.",
                        "These signatures classify evidence; they do not establish a root cause."]}
        decoder = json.JSONDecoder()
        for path in sorted((self.output / "system-reports").glob("*")):
            try:
                text = path.read_text(errors="replace").lstrip()
                objects = []
                while text:
                    value, end = decoder.raw_decode(text)
                    objects.append(value)
                    text = text[end:].lstrip()
                for report in objects:
                    if not isinstance(report, dict):
                        continue
                    if report.get("procName") == "SuperPreview":
                        termination = report.get("termination", {})
                        code = termination.get("code")
                        kind = "watchdog" if code == 0x8BADF00D else "app-termination"
                        analysis["reports"].append({"file": str(path), "kind": kind,
                                                    "captureTime": report.get("captureTime"),
                                                    "pid": report.get("pid"), "termination": termination,
                                                    "exception": report.get("exception")})
                    for process in report.get("processes", []):
                        if process.get("name") == "SuperPreview" and process.get("reason"):
                            analysis["reports"].append({"file": str(path), "kind": "jetsam",
                                                        "reason": process["reason"], "process": process})
            except (ValueError, OSError) as error:
                analysis.setdefault("parseErrors", []).append({"file": str(path), "error": str(error)})
        # Filter by this host session's start, avoiding older app sessions and duplicate snapshots.
        started = dt.datetime.fromisoformat(self.state["startedAt"]).timestamp()
        seen = set()
        for path in sorted((self.output / "app-snapshots").rglob("*.jsonl")):
            with path.open(errors="replace") as stream:
                for line in stream:
                    try:
                        entry = json.loads(line)
                        event = entry.get("event")
                        identity = (entry.get("timestamp"), event, entry.get("frame"))
                        if float(entry.get("timestamp", 0)) < started or identity in seen:
                            continue
                        seen.add(identity)
                        if event == "gpu-error":
                            analysis["gpuErrors"].append(entry)
                        elif event == "main-heartbeat-delayed":
                            analysis["delayedMainHeartbeats"].append(entry)
                    except (ValueError, TypeError):
                        continue  # A live snapshot may contain a partially written final line.
        analysis["systemTerminationRecorded"] = bool(analysis["reports"])
        (self.output / "analysis.json").write_text(json.dumps(analysis, indent=2) + "\n")
        lines = ["Market lifecycle evidence summary", "",
                 f"XCTest exit code: {analysis['testExitCode']}",
                 f"SuperPreview system termination reports: {len(analysis['reports'])}",
                 f"Recorded GPU errors: {len(analysis['gpuErrors'])}",
                 f"Delayed main-thread heartbeats: {len(analysis['delayedMainHeartbeats'])}", ""]
        for report in analysis["reports"]:
            lines.append(f"- {report['kind']}: {report['file']}")
        if not analysis["reports"]:
            lines.append("No new SuperPreview termination report was collected. A UI test failure alone is not a confirmed crash.")
        lines += ["", *analysis["limitations"]]
        (self.output / "analysis.txt").write_text("\n".join(lines) + "\n")

    def run(self):
        details = self.device_json(["info", "details"], "device-details")
        if details is None:
            raise RuntimeError("Physical device is unavailable; see collection-errors.log")
        if details.get("hardwareProperties", {}).get("reality") == "simulated":
            raise RuntimeError("This runner requires a physical iPhone")
        self.state["gitCommit"] = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
        (self.output / "source.diff").write_bytes(subprocess.check_output(["git", "diff", "HEAD"], cwd=ROOT))
        # Archive newly added diagnostic/test source as well as tracked changes.
        for path in [ROOT / "SuperPreview/Utilities/MarketLifecycleDiagnostics.swift",
                     ROOT / "SuperPreviewUITests/MarketLifecycleStressUITests.swift", Path(__file__).resolve()]:
            (self.output / path.name).write_bytes(path.read_bytes())
        files = self.crash_files("crash-baseline")
        if files is None:
            raise RuntimeError("Cannot access system crash logs; refusing to start without crash collection")
        self.seen_crashes = {item.get("relativePath", item["name"]) for item in files}
        if not self.options.skip_build:
            self.build()
        test_run = self.prepare_test_run()
        self.state["derivedData"] = str(self.derived)
        for symbols in (self.derived / "Build/Products").glob("*-iphoneos/SuperPreview.app.dSYM"):
            destination = self.output / "symbols" / symbols.name
            shutil.copytree(symbols, destination)
            with (self.output / "symbol-uuids.txt").open("w") as stream:
                subprocess.run(["xcrun", "dwarfdump", "--uuid", str(destination)], stdout=stream, stderr=subprocess.STDOUT)
        baseline_pids = self.processes()
        if baseline_pids is None:
            raise RuntimeError("Cannot query device process state")
        self.state["phase"] = "testing"
        self.save_state()
        self.event("stress-start", cycles=self.options.cycles)
        command = ["xcodebuild", "test-without-building", "-xctestrun", str(test_run),
                   "-destination", f"platform=iOS,id={self.options.device}", "-parallel-testing-enabled", "NO",
                   "-only-testing:" + TEST, "-resultBundlePath", str(self.output / "stress.xcresult"),
                   "-test-timeouts-enabled", "YES", "-default-test-execution-time-allowance", "14400",
                   "-maximum-test-execution-time-allowance", "14400", "-collect-test-diagnostics", "on-failure"]
        with (self.output / "test.log").open("w") as stream:
            process = subprocess.Popen(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT)
            self.state["xcodebuildPID"] = process.pid
            self.save_state()
            last_snapshot = time.monotonic()
            try:
                while process.poll() is None:
                    try:
                        pids = self.processes()
                        if pids is not None:
                            if self.target_pid is None:
                                new = [pid for pid in pids if pid not in baseline_pids]
                                if new:
                                    self.target_pid = new[0]
                                    self.event("target-process-observed", pid=self.target_pid)
                            elif self.target_pid not in pids and not self.observed_exits:
                                self.observed_exits.append({"timestamp": timestamp(), "pid": self.target_pid})
                                self.event("target-process-disappeared", pid=self.target_pid,
                                           note="May also be normal XCTest cleanup; correlate with report and result")
                                self.snapshot()
                            elif any(pid != self.target_pid for pid in pids):
                                self.event("unexpected-target-process-replacement", originalPID=self.target_pid, currentPIDs=pids)
                        self.collect_crashes()
                        if time.monotonic() - last_snapshot >= 60:
                            self.snapshot()
                            last_snapshot = time.monotonic()
                    except (subprocess.TimeoutExpired, OSError, ValueError) as error:
                        self.event("collector-observation-error", error=str(error))
                    time.sleep(5)
            except KeyboardInterrupt:
                self.event("operator-interrupted")
                process.send_signal(2)
                try:
                    process.wait(timeout=30)
                except subprocess.TimeoutExpired:
                    # Cancel only the xcodebuild child owned by this session.
                    process.terminate()
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
            returncode = process.wait()
        self.state.update(phase="collecting", testExitCode=returncode, observedProcessExits=self.observed_exits)
        self.save_state()
        try:
            self.snapshot()
        except (subprocess.TimeoutExpired, OSError) as error:
            self.event("collector-observation-error", error=str(error))
        # Diagnostic generation can lag behind the actual OS termination.
        if returncode:
            for _ in range(6):
                try:
                    self.collect_crashes()
                except (subprocess.TimeoutExpired, OSError, ValueError) as error:
                    self.event("collector-observation-error", error=str(error))
                time.sleep(5)
        try:
            self.collect_crashes()
        except (subprocess.TimeoutExpired, OSError, ValueError) as error:
            self.event("collector-observation-error", error=str(error))
        for arguments, filename in [(["get", "test-results", "summary"], "test-summary.json"),
                                    (["export", "diagnostics", "--output-path", str(self.output / "xcresult-diagnostics")], "diagnostic-export.log")]:
            with (self.output / filename).open("w") as stream:
                try:
                    subprocess.run(["xcrun", "xcresulttool", *arguments, "--path", str(self.output / "stress.xcresult")],
                                   stdout=stream, stderr=subprocess.STDOUT, timeout=60)
                except (subprocess.TimeoutExpired, OSError) as error:
                    self.event("xcresult-export-error", error=str(error))
        self.analyze()
        self.state.update(phase="passed" if returncode == 0 else "failed", finishedAt=timestamp())
        self.save_state()
        self.event("stress-finished", outcome=self.state["phase"], artifacts=str(self.output))
        return returncode


def main():
    session = Session(arguments())
    try:
        return session.run()
    except Exception as error:
        session.state.update(phase="infrastructure-error", error=str(error), finishedAt=timestamp())
        session.save_state()
        session.event("infrastructure-error", error=str(error))
        return 2


if __name__ == "__main__":
    sys.exit(main())
