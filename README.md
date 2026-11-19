# Omni Style Guide

Howdy!

This repo contains the Omni style guide as a [Vale](https://vale.sh) package. Vale checks your writing against the style guide and shows the problems that it finds.

The package includes:

- The Omni rules, in `styles/omni`
- The [ai-tells](https://github.com/tbhb/vale-ai-tells) package, which finds patterns that are typical of AI-generated text

## Install

You must have a Mac with [Homebrew](https://brew.sh).

Run this command in Terminal:

```shell
curl -fsSL https://raw.githubusercontent.com/exploreomni/vale-style-guide/main/install.sh | bash
```

The script:

1. Installs Vale, if you do not have it
2. Writes a global Vale config. Vale uses this config in all folders on your Mac. If you already have a global config, the script saves a backup copy first.
3. Downloads the style guide
4. Asks if you want automatic updates

## Check a file

```shell
vale path/to/file.md
```

The global config checks `.md`, `.mdx`, and `.txt` files.

## Get updates

If you selected automatic updates, Vale downloads the latest style guide every Monday at 10:00.

To get updates manually, run:

```shell
vale --config "$HOME/Library/Application Support/vale/.vale.ini" sync
```

To change your update setting, run the install command again with an option:

```shell
# Turn on automatic updates
curl -fsSL https://raw.githubusercontent.com/exploreomni/vale-style-guide/main/install.sh | bash -s -- --auto-update

# Turn off automatic updates
curl -fsSL https://raw.githubusercontent.com/exploreomni/vale-style-guide/main/install.sh | bash -s -- --no-auto-update
```

## Use the style guide in a project

To use the style guide in a repo, for example in CI:

1. Add a `.vale.ini` file to the root of the repo. For examples, refer to `config-templates/`. The file must include these lines before the first section header (`[...]`):

   ```ini
   StylesPath = styles
   Packages = https://github.com/exploreomni/vale-style-guide/releases/latest/download/omni.zip
   ```

2. Add `omni` and `ai-tells` to `BasedOnStyles`:

   ```ini
   [*.md]
   BasedOnStyles = omni, ai-tells
   ```

3. Add `styles/` to `.gitignore`. `vale sync` fills this folder.
4. Run `vale sync`. In CI, run `vale sync` before you run Vale.

## Change the style guide

- **Rules:** Add or change the `.yml` files in `styles/omni`.
- **Vocabulary:** Add words to `styles/config/vocabularies/Omni`.
- **Default rule settings:** Add them to `package.vale.ini`. Vale merges this file into the config of each project that uses the package. Use it, for example, to turn off a noisy ai-tells rule for everyone.

To release a change, publish a new release in GitHub. The release workflow builds `omni.zip` and adds it to the release. Users get the change at their next sync.
