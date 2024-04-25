This is a repository for the deterministic sandpile model. It can run simulations up to 1000 without any real issue (the real bottleneck is the display, which, is still rather fast!).

If you want to play around with it, you can change the initialization to be values of 0,1,2,3 as you want. The results are quite different, and interesting (the environment which the 'circle' expands into).

In order to run and build the script, please ensure you have zig installed, and run the following command in your zig environment / directory.

$ zig build run -Dcpu=<<your_cpu_architecture_here>> -Doptimize=ReleaseFast

Note, that if you do not know your cpu architecture, you can just delete the -flag (I personally use a tigerlake).

![Model](https://github.com/mengsig/zig-forest-fire/blob/main/fig.png?raw=true)

Please enjoy, and share!

By: Marcus Engsig
