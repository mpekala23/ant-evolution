# Data Plan

## PROBLEMS

- It's not entirely clear what we are trying to show. There are a couple parameters in the model that I think would be interesting to fool around with, but what we care about will kind of depend on the results we observe (shoddy science).
- I'm not confident that the model is stable. It may be the case that as we try to tweak parameters, we end up in blow-up or insta-death, which are not interesting results.
- The model is slow, but noisy. I.e., to say anything good we probably need to run it a bunch of times, but this will take a long time.

## TAKEAWAYS

_Get all the data we could ever be interested in_

Even if it's not parsed in the best possible way, get everything. This includes:

- All the parameters (not just the ones that we think we are going to change now)
- Average aggression
- Average cooperation
- Max/min aggression
- Max/min cooperation
- Number of colonies (FIX 0 BUG)
- Number of ants
- Amount of food (i.e. num blue patches)
- Total number of patches (this may change)

_Make it easy to vary a parameter in parallel and synthesize results_

We want a good pipeline to:

- Specify which parameters to vary
- Grid search and write results to sql table
- Easily make graphs across this grid search to understand the high level effects

_Make it easy to bash a specific range of parameters for data quantity_

TODO LAST: Once ^ the above has given us a good idea of the flavor of the data, would be nice to make a script to just get a shit ton of data so that we can play around with it.
