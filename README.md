# Blackstar
A black hole ray tracer written in Haskell. There's [an article](https://flannelhead.github.io/projects/blackstar.html) about this on my homepage. I've also written a [theoretical writeup](https://flannelhead.github.io/posts/2016-03-06-photons-and-black-holes.html) on Schwarzschild geodesics.

![An example image](https://raw.githubusercontent.com/flannelhead/blackstar/master/example.png)

## Features
* Fast, parallel ray tracing
* Rendering [Schwarzschild](https://en.wikipedia.org/wiki/Schwarzschild_metric) black holes
* Rendering accretion disks
* Drawing the celestial sphere using a star catalogue
* Bloom effect
* Antialiasing by 4x supersampling for smoother images
* Easy, YAML based configuration
* A simple CLI
* Batch mode and sequence generator for creating animations

## What about the name?
It is a tribute to David Bowie, referring to his last album.

## Building
Use [`stack`](http://docs.haskellstack.org/en/stable/README/) to build this. First clone the repo, then run `stack build` and follow the instructions given by `stack`. You should be able to build `blackstar` on any platform where you can install `stack`.

Alternatively, one can use plain `cabal` to build `blackstar` (although this is not recommended due to the various advantages `stack` gives over `cabal`). After cloning this repo, proceed with these commands in the root folder of the project:
```
cabal update
cabal sandbox init
cabal install --dependencies-only
cabal build
```
It will take a while to build all the dependencies. Currently, the package is meant to be built with `ghc-8.0.1`.

This repository includes a star lookup tree (`stars.kdt`), which has been generated from the [PPM star catalog](http://tdc-www.harvard.edu/software/catalogs/ppm.html). The prebuilt tree in binary form is included for convenience, but you can also build it yourself. First, remove `stars.kdt`. Download [this archive](http://tdc-www.harvard.edu/software/catalogs/ppm.tar.gz) and extract the file `PPM` to the root folder of this project. Then run `stack exec generate-tree PPM stars.kdt` and the tree will be generated and saved.

### Speeding it up with LLVM
When doing large or batch renders, it is recommended to build `blackstar` using GHC's LLVM backend. GHC produces LLVM bytecode and LLVM produces fast native code from GHC's output. In my tests I've noticed ~1.5x speedups.

The LLVM backend isn't used by default since one needs to install (and usually build) a specific version of LLVM separately. Moreover, the build time is significantly higher with LLVM, so one doesn't definitely want to use it while hacking on the code.

To successfully build with LLVM, you need to:

* Download and [build](http://llvm.org/docs/GettingStarted.html#getting-started-quickly-a-summary) [LLVM 3.7.1](http://llvm.org/releases/download.html#3.7.1). You can skip the Clang parts. After the build, you should make sure the tools `llc` and `opt` are found in your `PATH`. Notice that these aren't included in the prebuilt LLVM binaries, that's why you'll need to build it.
* Build `blackstar` with `stack build --ghc-options -fllvm`. (If you've just built it, run `stack clean` first to ensure it really gets rebuilt with LLVM.)
* Wait patiently
* Enjoy the result!

## Usage
When `blackstar` has been built with `stack`, you can run it with
```
stack exec blackstar -- [-p|--preview] [-f|--force] [-o|--output=PATH] [-s|--starmap=PATH] SCENENAME
```
Notice the two dashes (`--`) which are required to terminate `stack`'s argument list.


`cabal` users can run `blackstar` by executing
```
cabal run -- [OPTIONS] SCENENAME
```
in the root folder of the project.

Scenes are defined using YAML config files. Look in the `scenes` folder for examples. To render the `default` scene to the directory `output`, run
```
stack exec blackstar -- scenes/default.yaml --output output
```
in the root directory of the project. The `--output` flag specifies the output directory. By default, `blackstar` searches for a starmap in the path `./stars.kdt`, but a different path can be specified using the `--starmap` flag.

The rendered files are named `scenename.png` and `scenename-bloomed.png`. The `--preview` flag can be used to render small-sized previews of the scene while adjusting the parameters. The `--force` flag will cause `blackstar` to overwrite output images without a prompt.

If a directory is given as the input scene path, `blackstar` searches non-recursively for YAML files in that directory and tries to render them. The scenes are placed in the specified output directory.

There's also a help text which can be seen by running
```
stack exec blackstar -- --help
OR
cabal run -- --help
```

Better images can be achieved by rendering larger than the target size and then scaling down (some antialiasing is achieved). This is called supersampling and is implemented in `blackstar`. It can be enabled by setting `supersampling` to true in the YAML config file &mdash; see `scenes/default-aa.yaml` for an example.

## Profiling
Thanks to `stack`, profiling is incredibly easy. Rebuild `blackstar` by running
```
stack build --profile
```
and then run it with
```
stack exec blackstar -- scenes/default.yaml -o output +RTS -p
```
The profile will be generated to `blackstar.prof`.

## TODO
As always, there's a plenty of room for improvement. For example:

* Document the animator
* Overall better documentation (wiki pages?)
* Binary releases?
* Preview GUI for planning scenes
* GPU acceleration?
* Arbitrary textures for accretion disk?
* Redshifting of the accretion disk?

Pull requests are welcome! If you find some cool scenes, I'd appreciate if you contributed them to this repository.
