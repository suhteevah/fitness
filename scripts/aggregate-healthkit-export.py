"""
Aggregate the Apple Health "Export All Health Data" CSV bundle into compact
daily / weekly / monthly JSON rollups for PerformanceTracker.

Input:  J:\\fitness\\data\\healthkit-export\\csv\\*.csv  (~650 MB, 2.5M records, 8.5 yrs)
Output: J:\\fitness\\data\\healthkit-aggregates\\{daily,weekly,monthly}.json

Streams each CSV; never loads a whole file into memory.
"""

import csv
import json
import sys
import os
from collections import defaultdict
from datetime import datetime, date, timedelta
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8', errors='replace')
csv.field_size_limit(10_000_000)

EXPORT_DIR = Path(r"J:\fitness\data\healthkit-export\csv")
OUT_DIR = Path(r"J:\fitness\data\healthkit-aggregates")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# ----- helpers ---------------------------------------------------------------

def parse_local(ts: str) -> datetime | None:
    # "2019-03-04 12:39:35 -0700"
    if not ts:
        return None
    try:
        return datetime.strptime(ts, "%Y-%m-%d %H:%M:%S %z")
    except ValueError:
        return None

def day_of(dt: datetime) -> str:
    return dt.date().isoformat()

# ----- accumulators ----------------------------------------------------------

class Acc:
    """Mean accumulator with min/max/count."""
    __slots__ = ("sum", "n", "mn", "mx")
    def __init__(self):
        self.sum = 0.0
        self.n = 0
        self.mn = float("inf")
        self.mx = float("-inf")
    def add(self, v: float):
        self.sum += v
        self.n += 1
        if v < self.mn: self.mn = v
        if v > self.mx: self.mx = v
    def out(self):
        if self.n == 0:
            return None
        return {"avg": round(self.sum / self.n, 3), "min": round(self.mn, 3),
                "max": round(self.mx, 3), "n": self.n}

# day -> dict[metric -> Acc | running totals]
days: dict[str, dict] = defaultdict(lambda: defaultdict(Acc))
day_sums: dict[str, dict] = defaultdict(lambda: defaultdict(float))
day_counts: dict[str, dict] = defaultdict(lambda: defaultdict(int))
day_workouts: dict[str, list] = defaultdict(list)
day_sleep: dict[str, dict] = defaultdict(lambda: defaultdict(float))  # state -> minutes

# ----- per-CSV streamers -----------------------------------------------------

def stream_value(filename: str, metric_key: str, agg_kind: str = "avg",
                 value_cast=float):
    """agg_kind: 'avg' (use Acc) | 'sum' (sum into day_sums)"""
    path = EXPORT_DIR / filename
    if not path.exists():
        print(f"  [skip] {filename} not found")
        return
    n = 0
    with path.open("r", encoding="utf-8", newline="") as fh:
        rdr = csv.DictReader(fh)
        for row in rdr:
            dt = parse_local(row.get("start_local", ""))
            if not dt: continue
            try:
                v = value_cast(row["value"])
            except (KeyError, ValueError, TypeError):
                continue
            d = day_of(dt)
            if agg_kind == "avg":
                days[d][metric_key].add(v)
            else:
                day_sums[d][metric_key] += v
                day_counts[d][metric_key] += 1
            n += 1
    print(f"  {filename}: {n:,} rows -> {metric_key}")

def stream_workouts():
    path = EXPORT_DIR / "Workout.csv"
    if not path.exists(): return
    n = 0
    with path.open("r", encoding="utf-8", newline="") as fh:
        rdr = csv.DictReader(fh)
        for row in rdr:
            dt = parse_local(row.get("start_local", ""))
            if not dt: continue
            d = day_of(dt)
            try:
                duration = float(row.get("duration") or 0)
            except ValueError:
                duration = 0.0
            try:
                kcal = float(row.get("totalEnergyBurned") or 0)
            except ValueError:
                kcal = 0.0
            try:
                dist = float(row.get("totalDistance") or 0)
            except ValueError:
                dist = 0.0
            day_workouts[d].append({
                "type": row.get("activityType", ""),
                "min": round(duration, 1),
                "kcal": round(kcal, 1),
                "dist": round(dist, 3),
                "distUnit": row.get("totalDistanceUnit", ""),
            })
            n += 1
    print(f"  Workout.csv: {n:,} rows -> workouts")

def stream_sleep():
    """SleepAnalysis: value is HKCategoryValueSleepAnalysis* string.
    Bucket minutes by night-of (start date - 12h shift so 2am counts as prior day)."""
    path = EXPORT_DIR / "SleepAnalysis.csv"
    if not path.exists(): return
    n = 0
    with path.open("r", encoding="utf-8", newline="") as fh:
        rdr = csv.DictReader(fh)
        for row in rdr:
            dt0 = parse_local(row.get("start_local", ""))
            dt1 = parse_local(row.get("end_local", ""))
            if not dt0 or not dt1: continue
            mins = (dt1 - dt0).total_seconds() / 60.0
            if mins <= 0 or mins > 24 * 60: continue
            # night-of = the date the sleep "belongs" to: shift by -12h so a
            # 2am wake counts to the prior date.
            night = (dt0 - timedelta(hours=12)).date().isoformat()
            state = (row.get("value") or "").replace("HKCategoryValueSleepAnalysis", "")
            day_sleep[night][state] += mins
            n += 1
    print(f"  SleepAnalysis.csv: {n:,} rows -> sleep")

def stream_activity_summary():
    """ActivitySummary: one row per day, ring totals."""
    path = EXPORT_DIR / "ActivitySummary.csv"
    if not path.exists(): return
    n = 0
    with path.open("r", encoding="utf-8", newline="") as fh:
        rdr = csv.DictReader(fh)
        for row in rdr:
            d = row.get("date", "")
            if not d or d.startswith("1969") or d.startswith("1970"): continue
            try:
                day_sums[d]["activeKcalRing"] = float(row.get("activeEnergyBurned") or 0)
                day_sums[d]["exerciseMinRing"] = float(row.get("appleExerciseTime") or 0)
                day_sums[d]["standHoursRing"] = float(row.get("appleStandHours") or 0)
                day_sums[d]["moveTimeRing"] = float(row.get("appleMoveTime") or 0)
                n += 1
            except ValueError:
                continue
    print(f"  ActivitySummary.csv: {n:,} rows -> ring totals")

# ----- ingest ----------------------------------------------------------------

print("Ingesting CSVs (streaming)…")
stream_value("HeartRate.csv",                 "hr")
stream_value("RestingHeartRate.csv",          "rhr")
stream_value("HeartRateVariabilitySDNN.csv",  "hrv")
stream_value("WalkingHeartRateAverage.csv",   "walkHR")
stream_value("RespiratoryRate.csv",           "rr")
stream_value("OxygenSaturation.csv",          "spo2")
stream_value("VO2Max.csv",                    "vo2max")
stream_value("AppleSleepingWristTemperature.csv", "wristTemp")
stream_value("BodyMass.csv",                  "bodyMass")

stream_value("StepCount.csv",                 "steps", agg_kind="sum")
stream_value("DistanceWalkingRunning.csv",    "distWalkRun", agg_kind="sum")
stream_value("DistanceCycling.csv",           "distCycle", agg_kind="sum")
stream_value("ActiveEnergyBurned.csv",        "activeKcal", agg_kind="sum")
stream_value("BasalEnergyBurned.csv",         "basalKcal", agg_kind="sum")
stream_value("AppleExerciseTime.csv",         "exerciseMin", agg_kind="sum")
stream_value("AppleStandTime.csv",            "standMin", agg_kind="sum")
stream_value("FlightsClimbed.csv",            "flights", agg_kind="sum")
stream_value("MindfulSession.csv",            "mindfulMin", agg_kind="sum",
             value_cast=lambda s: float(s) if s else 0.0)

stream_workouts()
stream_sleep()
stream_activity_summary()

# ----- write daily.json ------------------------------------------------------

print("\nWriting daily.json…")
all_dates = set(days) | set(day_sums) | set(day_workouts) | set(day_sleep)
daily_out = {}
for d in sorted(all_dates):
    rec = {}
    for k, acc in days[d].items():
        rec[k] = acc.out()
    for k, v in day_sums[d].items():
        rec[k] = round(v, 3)
    if d in day_workouts:
        ws = day_workouts[d]
        rec["workouts"] = ws
        rec["workoutCount"] = len(ws)
        rec["workoutMin"] = round(sum(w["min"] for w in ws), 1)
    if d in day_sleep:
        sleep = day_sleep[d]
        asleep = sum(v for k, v in sleep.items()
                     if k in ("AsleepUnspecified", "AsleepCore", "AsleepDeep",
                              "AsleepREM", "Asleep"))
        rec["sleep"] = {
            "asleepMin": round(asleep, 1),
            "inBedMin": round(sleep.get("InBed", 0), 1),
            "awakeMin": round(sleep.get("Awake", 0), 1),
            "stages": {k: round(v, 1) for k, v in sleep.items()},
        }
    daily_out[d] = rec

with (OUT_DIR / "daily.json").open("w", encoding="utf-8") as fh:
    json.dump(daily_out, fh, separators=(",", ":"), ensure_ascii=False)
print(f"  {len(daily_out):,} days -> {OUT_DIR / 'daily.json'}")

# ----- weekly + monthly rollups ---------------------------------------------

def iso_week(d: str) -> str:
    y, m, day = map(int, d.split("-"))
    iso = date(y, m, day).isocalendar()
    return f"{iso.year}-W{iso.week:02d}"

def month_of(d: str) -> str:
    return d[:7]  # YYYY-MM

def rollup(period_fn, label: str):
    buckets: dict[str, dict] = defaultdict(lambda: {
        "days": 0,
        "avgFields": defaultdict(lambda: {"sum": 0.0, "n": 0}),
        "sumFields": defaultdict(float),
        "workoutCount": 0,
        "workoutMin": 0.0,
        "sleepAsleepMinSum": 0.0,
        "sleepDays": 0,
    })
    AVG_FIELDS = {"hr", "rhr", "hrv", "walkHR", "rr", "spo2", "vo2max",
                  "wristTemp", "bodyMass"}
    SUM_FIELDS = {"steps", "distWalkRun", "distCycle", "activeKcal",
                  "basalKcal", "exerciseMin", "standMin", "flights",
                  "mindfulMin", "activeKcalRing", "exerciseMinRing"}
    for d, rec in daily_out.items():
        b = buckets[period_fn(d)]
        b["days"] += 1
        for f in AVG_FIELDS:
            v = rec.get(f)
            if isinstance(v, dict) and v.get("avg") is not None:
                b["avgFields"][f]["sum"] += v["avg"]
                b["avgFields"][f]["n"] += 1
        for f in SUM_FIELDS:
            v = rec.get(f)
            if isinstance(v, (int, float)):
                b["sumFields"][f] += v
        if "workouts" in rec:
            b["workoutCount"] += rec["workoutCount"]
            b["workoutMin"] += rec["workoutMin"]
        if "sleep" in rec:
            b["sleepAsleepMinSum"] += rec["sleep"]["asleepMin"]
            b["sleepDays"] += 1

    out = {}
    for period, b in sorted(buckets.items()):
        rec = {"days": b["days"]}
        for f, agg in b["avgFields"].items():
            if agg["n"]:
                rec[f] = round(agg["sum"] / agg["n"], 3)
        for f, total in b["sumFields"].items():
            rec[f] = round(total, 3)
        if b["workoutCount"]:
            rec["workoutCount"] = b["workoutCount"]
            rec["workoutMin"] = round(b["workoutMin"], 1)
        if b["sleepDays"]:
            rec["sleepAvgMin"] = round(b["sleepAsleepMinSum"] / b["sleepDays"], 1)
            rec["sleepAvgHr"] = round(b["sleepAsleepMinSum"] / b["sleepDays"] / 60, 2)
        out[period] = rec
    path = OUT_DIR / f"{label}.json"
    with path.open("w", encoding="utf-8") as fh:
        json.dump(out, fh, separators=(",", ":"), ensure_ascii=False)
    print(f"  {len(out):,} {label} buckets -> {path}")
    return out

print("\nRolling up weekly + monthly…")
rollup(iso_week, "weekly")
rollup(month_of, "monthly")

# ----- summary ---------------------------------------------------------------

print("\nDone.")
sizes = {p.name: p.stat().st_size for p in OUT_DIR.glob("*.json")}
for k, v in sizes.items():
    print(f"  {k}: {v / 1024:.1f} KB")
