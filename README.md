# This is the repository for the self-organized-critical model of the forest-fire created by Drossel and Schwabl (1992), that can simulate up to a system of 2000x2000 in real-time (30fps) on a single thread!

# The parameters to play with are p and f, which represent the probability of a burnt cell to become green (vegetated) and the probability of a green (vegetated) cell to sporadically go on fire (become burning). 

# In order to run and build the script, please ensure you have zig installed, and run the following command in your zig environment / directory.

$ zig build run -Dcpu=<<your_cpu_architecture_here>> -Doptimize=ReleaseFast

# Note, that if you do not know your cpu architecture, you can just delete the -flag (I personally use a tigerlake).

# Please enjoy, and share!

# By: Marcus Engsig & Mikkel Petersen.
