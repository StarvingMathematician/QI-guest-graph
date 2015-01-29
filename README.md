# QI-guest-graph
The British quiz show [QI (Quite Interesting)](https://en.wikipedia.org/wiki/QI) has been running for 12 years, and amassed over 170 episodes. Each episode is comprised of 4 contestants, 3 of whom vary from episode to episode (the 4th is always comedian Alan Davies). As any frequent watcher of the show will know, many of the guest contestants appear in multiple episodes (most notably Bill Bailey, Jo Brand, and Phill Jupitus, each of whom appear in over 30 episodes). This simple repetitive format makes the show a prime target for network analysis and visualization, which is what this Repo attempts to do.

The files "prepping_data.R" and "visualizing_data.R" perform the data processing and visualization, respectively. The resulting graph networks are shown (with varied formatting) in "graph_plot_1.png" and "graph_plot_2.png".

The graph is formatted as follows:

1. Each vertex represents a unique contestant. The vertices are sized according to the number of episodes that the contestant appeared in. (Only contestants appearing in more than 4 episodes are shown.)
2. There exists an edge between two vertices if those two contestants ever starred in the same episode. The width of the edge is given by the number of episodes that the contestants co-starred in.
3. The color of an edge is determined by the expectation that such an extreme number of episode co-occurrences would happen by chance (see below). Unusually high co-occurence rates are colored red, and unusually low co-occurence rates are colored blue. Darker hues indicate more extreme values.

---------

The co-occurrence probability is computed by enumerating all possible scenarios in which that number of co-occurences could happen given the total number of episodes and the number of times each of the two guests appeared on the show. This (extremely large) number is then divided by the total number of ways that the two guests' appearances could have been distributed among the episodes.

We can enumerate the number of ways in which a specific co-occurrence count can happen using the following combinatorial formula:

![eq1](https://github.com/StarvingMathematician/QI-guest-graph/blob/master/eq1.gif)

which can be simplified to:

![eq2](https://github.com/StarvingMathematician/QI-guest-graph/blob/master/eq2.gif)

This expression can then be summed over to obtain the total number of possible arrangements of guest1 and guest2, yielding the following the formula for the co-occurrence probability:

![eq3](https://github.com/StarvingMathematician/QI-guest-graph/blob/master/eq3.gif)

where n_t:=total_num_episodes, n_c:=num_cooccurrences, g_1:=num_guest1_appearances, g_2:=num_guest2_appearances

---------

Further plans include:

1. Generating separate graphs colored by left-tail expectation and right-tail expectation.
2. Examining the complement graph for pairs of frequent contestants who *never* starred in the same episode.
3. Amending our probability mass function to account for the fact that contestants often appear on the show in multi-episode runs, rather than completely at random. This could be modeled as overlapping contiguous subsequences.
