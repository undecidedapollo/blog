+++
title = "Rust on the Game Boy Advance"
date = "2026-05-14T15:00:00Z"
description = "A guide on how to setup a rust project that builds a rom which runs on the GBA"
[taxonomies]
tags = ["rust", "code", "gba", "gaming"]
+++

## Background {#background}

This is the part where I tell you my life story before giving you the recipe to make "Chocolate Chip Cookies". Click here to skip ahead. 

Last year around this time I wanted to work on a low-level project with Rust. Most of my day job I spent building API's in TypeScript but Rust had interested me in its ability to model program execution in a safe, performant way allowing developers to write code that performs at native speeds while still having the conveniences of a modern language.

I started out buying a couple {{ link(label="Arduino ESP32", url="https://store-usa.arduino.cc/products/nano-esp32") }} boards and did the basics, blinking lights, ESPNow Ping and Pong, etc. While fun, you also need to be good with electronics to do any useful "work" with an ESP32 and that isn't my strong suit. 

After spending some time searching, I landed on the Game Boy Advance as a fun platform to try and develop for. It has a 32-bit Arm processor, input buttons on the device, has output like a screen and speakers, MMIO (Memory Mapped Input / Output), and is standardized in the sense that what runs on one Game Boy Advance will run on any other. With all of these it also had restrictions such as limited memory, limited rom space, VRAM limitations, sprite limitations. 

On my mind at the time was the quote by Orson Welles:

> "The enemy of art is the absence of limitations"
> \- Orson Welles

I started out on this journey figuring out what existed in the space already, two crates with different goals in mind.

The first I saw was the crate {{ link(label="gba", url="https://docs.rs/gba/latest/gba/") }} which posits itself as a crate that does just enough to make a rust safe API to work with the hardware from the language.

In the docs it pointed me to a separate crate:

> This crate provides an API to interact with the GBA that is safe, but with
> minimal restrictions on what components can be changed when. If you’d like
> an API where the borrow checker provides stronger control over component
> access then the {{ link(label="agb", url="https://docs.rs/agb/latest/agb/") }} crate might be what you want.

That statement sold me as I wanted low-level rust with as little hand holding as possible so I dove in to the `gba` crate.

From there I read the repo, setup a project, and followed some great tutorials from other developers on how to get started with GBA developers.

The first tutorial I followed was {{ link(label=`Shane's dev blog - "Building GBA Games in Rust"`, url="https://shanesnover.com/2024/02/07/intro-to-rust-on-gba.html") }} which covered Shane's learning process on getting started with GBA development on Rust and pointed me to some of the other tutorials I mentioned below. Best of all was a link to his {{ link(label=`"Conway's Game of Life" repository`, url="https://github.com/ssnover/game-of-life") }} which became the building block for my gba game (and we will pull some features and code from it also). It is worth reading as it covers GBA development at a high level.

The main tutorial that I followed was {{ link(label=`Kyle Halladay - "GBA Tutorial"`, url="https://kylehalladay.com/gba.html") }} set of blog posts which covered how to get started with GBA development in C++. From drawing on the screen to drawing a sprite, drawing background layers, user input, it was a great resource and I highly recommend you read it if you haven't already.

Another great resource which dove deep into the hardware and explained how the Game Boy Advance actually worked under the hood was {{ link(label="Tonc", url="https://www.coranac.com/tonc/text/toc.htm") }}. This was a bit harder to read as it was very technical but it contained a trove of information such as info on the underlying hardware, memory layout, quirks, tips, pointers, code examples, etc. When it came time to understanding a new system like sprites or background modes, I enjoyed reading the info on each of the modes, what you can do with them, and code examples on how to best leverage them that Tonc provided. I would recommend bookmarking that site as it has a wealth of information that will come in handy later.

This tutorial will rehash many of the things Kyle covered in his tutorials but will be focused solely on Rust and specifically the [gba](https://docs.rs/gba/latest/gba/) crate. Since we are working on an embedded system, we will only have access to `core` (you can use `alloc` also technically but we won't for this project) and will not have access to the traditional, expansive rust standard library.

This tutorial will cover the basics to get you up and running and future tutorials may be created that cover more advanced topics.

## Setting Up Your Dev Environment

#### Rust

There are a few prerequisites before we get started. You will need to have Rust / Cargo installed on your machine, we will be using a nightly version of the compiler. If you have a recent version of Rust / Cargo installed it should download the nightly version you need when we configure the project later on.

If you don't have Rust installed, you can use {{ link(label="RustUp", url="https://rustup.rs/") }} to get your machine setup.

#### Other Software

Next we will follow the instructions from the {{ link(label="gba", url="https://docs.rs/gba/latest/gba/#how-to-make-your-own-gba-project-using-this-crate") }} crate on how to setup our own gba project. There are a few things we need to download and setup here but it is just a one time setup.

##### ARM Binutils

First we will need to download the {{ link(label="ARM Binutils", url="https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain") }}.

> You'll need the ARM version of the GNU binutils in your path, specifically the linker (`arm-none-eabi-ld`).
> Linux folks can use the package manager. Mac and Windows folks can use the [ARM Website](https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain)

##### GBA Emulator

Lastly we will need an emulator to run our game. According to the `gba` crate, the roms created by the crate can be run on devices directly but require extra steps and won't be covered in this tutorial.

We will be using the {{ link(label="mGBA emulator", url="https://mgba.io/downloads.html") }} as it is the recommended emulator by the crate authors. You can download the emulator from that [link](https://mgba.io/downloads.html).

## Project Creation

With everything installed we can use `cargo` to create a new `binary` project which we will use as the foundation for building our GBA game.

```shell
cargo new --bin gba-tutorial
```

We can now `cd gba-tutorial` into our project and begin setting it up for GBA development.

#### Nightly Rust

GBA development with rust requires us to use the nightly compiler. To tell rust to always use the nightly compiler for our project we start by setting up a `rust-toolchain.toml` file in the root of our project.


```toml
[toolchain]
channel = "nightly"
components = ["rust-src"]
```

If you are like me and like to pin your versions, you can specify a specific nightly version here instead like so:

```toml
[toolchain]
channel = "nightly-2026-05-09"
components = ["rust-src"]
```


#### Cargo Config

First, we need to tell cargo more about this project and how to build it. We start by creating a directory called `.cargo` and creating a file inside of it called `config.toml` (full path: `.cargo/config.toml`). Inside of the file we set a few options:

```toml
[build]
target = "thumbv4t-none-eabi" # Specify the cpu / system architecture we are targeting

[unstable]
build-std = ["core"] # Specify we only want core

[target.thumbv4t-none-eabi]

# TODO: you may need to update this for your own operating system
runner = "mgba-qt" # sets the emulator to run bins/examples with
# Mac:
# runner = "/Applications/mGBA.app/Contents/MacOS/mGBA"

rustflags = [
  "-Clinker=arm-none-eabi-ld", # uses the ARM linker
  "-Clink-arg=-Tlinker.ld", # sets the link script
]
```

#### Download Linker Script

We need a link script to tell the linker how to properly structure our executable. Thankfully the `gba` crate authors provide us with one.

{{ link(label="Linker File", url="https://github.com/rust-console/gba/blob/main/linker_scripts/mono_boot.ld") }}

Download or copy the file and save it to `linker.ld` inside of your project.

#### Add the GBA Crate

Add the gba crate to the project, we will use version 0.15 which is the latest at the time this tutorial was written.

You can use cargo to add the crate:

```shell
cargo add gba@0.15
```

At the end, your `Cargo.toml` should look like the following:

```toml
[package]
name = "gba-tutorial"
version = "0.1.0"
edition = "2024"

[dependencies]
gba = "0.15"
```

#### Create Our First Executable

Lastly, we can copy the starter function definition from the `gba` crate documentation which sets up a `no-std` compatible executable file. It is barebones and won't do anything, but we will be able to run it.

Update your existing `src/main.rs` file (created above with `cargo new`) to have the following contents:

```rust
#![no_std]
#![no_main]

use gba::prelude::*;

#[panic_handler]
fn panic_handler(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

#[unsafe(no_mangle)]
extern "C" fn main() -> ! {
    loop {}
}

```

#### (Optional) VSCode Configuration

If you are using rust-analyzer inside VSCode, you may notice it giving you warnings from the above code changes. Since we are building a rom that doesn't use std and uses a custom architecture we need to tell VSCode about it. To do so, create a folder called `.vscode` and create a file named `settings.json` and put the following:

```json
{
    "rust-analyzer.cargo.target": "thumbv4t-none-eabi",
    "rust-analyzer.cargo.buildScripts.overrideCommand": [
        "cargo", "check", "--target", "thumbv4t-none-eabi",
        "-Z", "build-std=core,alloc",
        "--message-format=json"
    ],
    "rust-analyzer.check.overrideCommand": [
        "cargo", "check", "--target", "thumbv4t-none-eabi",
        "-Z", "build-std=core,alloc",
        "--message-format=json"
    ],
    "rust-analyzer.check.allTargets": false,
    "rust-analyzer.cargo.extraEnv": {
        "RUSTFLAGS": "-Clink-arg=-Tlinker.ld"
    }
}
```


#### Run our ROM (first time)

At this point we can run our rom!

```shell
cargo run --release
```

It doesn't do anything at all but display a white screen but it shows that we can build a rust program into a Game Boy Advanced ROM.

## Doing Something

