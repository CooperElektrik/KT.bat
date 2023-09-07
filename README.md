# KT.bat
A collection of Windows batchfile scripts to automate the process of setting up and running Kohya LoRA trainer.

Supports SD 1.5 and 2.X training. Working on SDXL.

# How to use
The main script (`trainer-prep.bat`) assumes the existence of an already set up clone of Kohya's repo, a checkpoint model it can use, and .png/jpg images with their accompanying .txt tag files. Also paths shouldn't have spaces in them.

On the first time running, specify trainer settings and the location of Kohya's trainer repo and the model location (specify full paths). These will be written to a file called `path` in the same directory as the batch script.

After that, tell it what the name of the concept is and how many epochs to train for. The rest is fully automated.

# Todo
- [x] Let the user specify what settings to use. They should be able to edit those later.
- [ ] Fix bug if there is any.
