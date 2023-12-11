import nl4py
from typing import Any, NamedTuple


class SimParams(NamedTuple):
    """
    Datatype for all of the variables defining our simulation.

    NOTE: The below are defaults. In the provided (from NamedTuple) construtor,
    you can choose which of these to set, and the rest receive the default values below.
    """

    food_evaporation: int = 3
    home_dist_threshold: float = 5.0
    proportion_workers: int = 75
    initial_ants: int = 120
    initial_queens: int = 6
    scout_lifespan: int = 575
    worker_lifespan: int = 575
    intitial_nest_energy: float = 1000.0
    food_val: float = 1.0
    birth_threshold: float = 700.0
    birth_cost: float = 2.7
    split_threshold: float = 1400.0
    split_distance: float = 40.0
    max_colony_lifespan: float = 1500.0
    fight_mult: float = 1.0
    coop_mult: float = 0.05
    coop_amt: float = 0.5
    chunk_refresh_threshold: int = 40
    chunk_refresh_time: int = 500
    chunk_size: int = 12

    def as_dict(self) -> dict[str, str]:
        fields = self._fields
        return {field: str(getattr(self, field)) for field in fields}

    @staticmethod
    def from_dict(data: dict[str, str]):
        return SimParams(
            food_evaporation=int(data.get("food_evaporation", 3)),
            home_dist_threshold=float(data.get("home_dist_threshold", 5.0)),
            proportion_workers=int(data.get("proportion_workers", 75)),
            initial_ants=int(data.get("initial_ants", 120)),
            initial_queens=int(data.get("initial_queens", 6)),
            scout_lifespan=int(data.get("scout_lifespan", 575)),
            worker_lifespan=int(data.get("worker_lifespan", 575)),
            intitial_nest_energy=float(data.get("intitial_nest_energy", 1000.0)),
            food_val=float(data.get("food_val", 2.0)),
            birth_threshold=float(data.get("birth_threshold", 700.0)),
            birth_cost=float(data.get("birth_cost", 2.7)),
            split_threshold=float(data.get("split_threshold", 1400.0)),
            split_distance=float(data.get("split_distance", 30.0)),
            max_colony_lifespan=float(data.get("max_colony_lifespan", 1500.0)),
            fight_mult=float(data.get("fight_mult", 1.0)),
            coop_mult=float(data.get("coop_mult", 0.05)),
            coop_amt=float(data.get("coop_amt", 0.5)),
            chunk_refresh_threshold=int(data.get("chunk_refresh_threshold", 40)),
            chunk_refresh_time=int(data.get("chunk_refresh_time", 900)),
            chunk_size=int(data.get("chunk_size", 12)),
        )

    def set_workspace(self, workspace: nl4py.NetLogoHeadlessWorkspace):
        """
        Given our sim params data type, set the workspace accordingly
        """
        raw_fields = SimParams()._fields
        nl_fields = [term.replace("_", "-") for term in raw_fields]
        for raw, nl_safe in zip(raw_fields, nl_fields):
            print(f"set {nl_safe} {getattr(self, raw)}")
            workspace.command(f"set {nl_safe} {getattr(self, raw)}")

    def deterministic_hash(self) -> int:
        """
        If we want results to be repeatable, we seed using hash of sim params
        """
        as_str = ""
        for field in self._fields:
            as_str += str(getattr(self, field))
        return hash(as_str)


class SimState(NamedTuple):
    """
    The state we care about from a simuation.
    """

    tick: int
    num_kills: int
    num_coop: int
    num_colonies: int
    num_ants: int
    num_food: int

    @staticmethod
    def from_tuple(data: Any) -> "SimState":
        return SimState(
            int(data[0]),
            int(data[1]),
            int(data[2]),
            int(data[3]),
            int(data[4]),
            int(data[5]),
        )

    @staticmethod
    def collect_from_workspace(
        workspace: nl4py.NetLogoHeadlessWorkspace, tick_range: range
    ) -> list["SimState"]:
        """
        Adds reporters to a workspace and then runs, returning the data from the ticks
        """
        measures = [
            "num-kills",
            "num-coop",
            "num-queens",
            "num-ants",
            "num-food",
        ]
        results = workspace.schedule_reporters(
            measures,
            start_at_tick=tick_range.start,
            stop_at_tick=tick_range.stop,
            interval_ticks=tick_range.step,
        )
        num_kills = results[0]
        num_coop = results[1]
        num_queens = results[2]
        num_ants = results[3]
        num_food = results[4]

        clean_results = []
        for data in zip(
            tick_range,
            num_kills,
            num_coop,
            num_queens,
            num_ants,
            num_food,
        ):
            sim_state = SimState.from_tuple(data)
            clean_results.append(sim_state)

        return clean_results


class RunData(NamedTuple):
    params: SimParams
    data: dict[int, SimState]
