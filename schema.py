import nl4py
from typing import Any, NamedTuple


class SimParams(NamedTuple):
    """
    Datatype for all of the variables defining our simulation.

    NOTE: The below are defaults. In the provided (from NamedTuple) construtor,
    you can choose which of these to set, and the rest receive the default values below.
    """

    food_evaporation: int = 3
    proportion_workers: int = 75
    initial_ants: int = 240
    initial_queens: int = 2
    scout_lifespan: int = 575
    worker_lifespan: int = 575
    intitial_nest_energy: float = 1000.0
    food_val: float = 1.5
    birth_threshold: float = 800.0
    birth_cost: float = 4.0
    split_threshold: float = 1600.0
    split_distance: float = 65.0
    fight_win_bonus: float = 2.0
    max_colony_lifespan: float = 3000.0
    coop_both_bonus: float = 2.5
    coop_one_cost: float = 1.0
    chunk_refresh_threshold: int = 125
    chunk_refresh_time: int = 2000
    chunk_size: int = 25

    def as_dict(self) -> dict[str, str]:
        fields = self._fields
        return {field: str(getattr(self, field)) for field in fields}

    @staticmethod
    def from_dict(data: dict[str, str]):
        return SimParams(
            food_evaporation=int(data.get("food_evaporation", 3)),
            proportion_workers=int(data.get("proportion_workers", 75)),
            initial_ants=int(data.get("initial_ants", 240)),
            scout_lifespan=int(data.get("scout_lifespan", 575)),
            worker_lifespan=int(data.get("worker_lifespan", 575)),
            intitial_nest_energy=float(data.get("intitial_nest_energy", 1000.0)),
            food_val=float(data.get("food_val", 1.5)),
            birth_threshold=float(data.get("birth_threshold", 800.0)),
            birth_cost=float(data.get("birth_cost", 4.0)),
            split_threshold=float(data.get("split_threshold", 1600.0)),
            split_distance=float(data.get("split_distance", 65.0)),
            fight_win_bonus=float(data.get("fight_win_bonus", 2.0)),
            max_colony_lifespan=float(data.get("max_colony_lifespan", 3000.0)),
            coop_both_bonus=float(data.get("coop_both_bonus", 2.5)),
            coop_one_cost=float(data.get("coop_one_cost", 1.0)),
            chunk_refresh_threshold=int(data.get("chunk_refresh_threshold", 125)),
            chunk_refresh_time=int(data.get("chunk_refresh_time", 2000)),
            chunk_size=int(data.get("chunk_size", 25)),
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
    agg_min: float
    agg_avg: float
    agg_max: float
    coop_min: float
    coop_avg: float
    coop_max: float
    num_colonies: int
    num_ants: int
    num_food: int

    @staticmethod
    def from_tuple(data: Any) -> "SimState":
        return SimState(
            data[0],
            data[1],
            data[2],
            data[3],
            data[4],
            data[5],
            data[6],
            int(data[7]),
            int(data[8]),
            int(data[9]),
        )

    @staticmethod
    def collect_from_workspace(
        workspace: nl4py.NetLogoHeadlessWorkspace, tick_range: range
    ) -> list["SimState"]:
        """
        Adds reporters to a workspace and then runs, returning the data from the ticks
        """
        measures = [
            "min-aggresiveness",
            "average-aggresiveness",
            "max-aggresiveness",
            "min-cooperation",
            "average-cooperation",
            "max-cooperation",
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
        min_aggs = results[0]
        avg_aggs = results[1]
        max_aggs = results[2]
        min_coop = results[3]
        avg_coop = results[4]
        max_coop = results[5]
        num_queens = results[6]
        num_ants = results[7]
        num_food = results[8]

        clean_results = []
        for data in zip(
            tick_range,
            min_aggs,
            avg_aggs,
            max_aggs,
            min_coop,
            avg_coop,
            max_coop,
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
