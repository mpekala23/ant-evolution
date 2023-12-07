import nl4py
import multiprocessing
import random
from schema import SimParams, SimState, RunData


nl4py.initialize("/Applications/NetLogo 6.0.4")
model = "./AntsCompSave.nlogo"


def init(model_path):
    global workspace
    workspace = nl4py.create_headless_workspace()
    workspace.open_model(model_path)


def run_simulation(inp: tuple[dict[str, str], bool]) -> RunData:
    """
    Runs a simulation and returns the results
    """
    global workspace
    raw_params, deterministic = inp
    params = SimParams.from_dict(raw_params)
    seed = (
        random.randint(0, int(1e9))
        if not deterministic
        else params.deterministic_hash()
    )
    workspace.command(f"random-seed {seed}")
    params.set_workspace(workspace)
    workspace.command("setup")
    sim_states = SimState.collect_from_workspace(workspace, range(10, 100, 10))
    return RunData(params, {v.tick: v for v in sim_states})


if __name__ == "__main__":
    sims = [SimParams() for _ in range(4)]
    results = []
    print(
        f"\n Running {len(sims)} simulations on {multiprocessing.cpu_count()} processors"
    )
    results = []
    with multiprocessing.Pool(
        processes=multiprocessing.cpu_count(), initializer=init, initargs=(model,)
    ) as pool:
        for result in pool.map(run_simulation, [(sim.as_dict(), True) for sim in sims]):
            results.append(result)
    print(f"There are {len(results)} runs of results:")
    print(results)
