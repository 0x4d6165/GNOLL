# Dice Tower
[![Build + Test](https://github.com/ianfhunter/DiceTower/actions/workflows/c-cpp.yml/badge.svg)](https://github.com/ianfhunter/DiceTower/actions/workflows/c-cpp.yml) [![GitHub license](https://img.shields.io/github/license/ianfhunter/dice-tower.svg)](https://github.com/ianfhunter/dice-tower/blob/master/LICENSE)
![GitHub last commit](https://img.shields.io/github/last-commit/ianfhunter/dice-tower.svg)  [![Donate](https://img.shields.io/badge/Donate-Paypal-yellow.svg)](https://paypal.me/ianfhunter)

<p align="center">
<img src="media/logo.png" height="200">
</p>

A comprehensive grammar-based library for rolling dice. DiceTower parses [Dice Notation](https://en.wikipedia.org/wiki/Dice_notation) for your project, so that you don't have to. Ideal for software or researchers of tabletop gaming.

Here's an example of how you might use DiceTower:
```markdown
   Gridon The Brave: I want to steal from the goblin sitting at the bar.
   Dungeon Master: Okay, give me a stealth check!
   Gridon The Brave: Okay, that's a <1d20+5>
   [DiceTower]: 21
   Dungeon Master: Hurrah! You successfully pickpocket the goblin! However, all he had in there were some crummy dice...
```

[You can follow Grindon's adventure through the world of dice notation in our Wiki](https://github.com/ianfhunter/dice-tower/wiki/Dice-Roll-Syntaxes)

## Current Status

### Dice Notation
DiceTower supports a lot of different notations. Too many to explain here so [we've got a seperate section in our wiki](https://github.com/ianfhunter/dice-tower/wiki/Dice-Roll-Syntaxes).

### Language Support

We wrote DiceTower to be the definitive solution to dice notation. We've written all the code in C, but fear not! We will be adding wrappers for you to access DiceTower's functionality in the near future.

#### Currently
- C
- Python

**Note:** There is no Windows/POSIX support yet.

#### Backlog
Want to show your interest in a particular language? [Vote on FeatHub](https://feathub.com/ianfhunter/dice).

 - Javascript
 - PHP
 - Ruby

## Getting Started

Setup for the various languages can be found on [the Wiki](https://github.com/ianfhunter/dice-tower/wiki)

### Prerequisites

Some languages may have other prerequsites, but these will be common throughout:

- Linux Support (We have an open issue with support on POSIX systems e.g. Cygwin, WSL)

Apt:
```
sudo apt-get install bison flex make python3-pip -y
```

### Build and Test

Simply run the following to build the application:
```bash
   make all
```

You can run our tests too:
```bash
   make test
```


(Note: The following is currently not live. As of now, you can pipe a file containing the roll into the script)
You should be able to try out rolling some dice now!
```
$ dice 1d20
20
```

### Use it in your application
Again, please see the wiki for the various languages instructions [the Wiki](https://github.com/ianfhunter/dice-tower/wiki)

#### Python

```bash
pip install dicetower
```

Then
```python
exit_code, result = roll("1d4")
```


## Built With

* [Lex & Yacc](http://dinosaur.compilertools.net/) - Grammar Lexing & Parsing
* [Hatchful](https://hatchful.shopify.com/onboarding/select-logo) - Logo Creation Tool
* [uthash](https://troydhanson.github.io/uthash/userguide.html) - C hashtable lib
* Love! 💖

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/ianfhunter/dice-tower/tags).

## Authors / Contributers / Attributions

* **Ian Hunter** - *Main Developer* - [Ianfhunter](https://github.com/ianfhunter/)

See also the list of [contributors](https://github.com/ianfhunter/dice-tower/contributors) who participated in this project.

## Issues / Bugs / FAQs / Feature Requests

We are currently building a Wiki to help you in building on top of Dice Tower.
In the meantime, if you encounter any issues, please file them in our [Issue Tracker](https://github.com/ianfhunter/dice-tower/issues).
You can vote on prospective new features on [FeatHub](https://feathub.com/ianfhunter/dice)

Please bear with us as we build a project charter to define the scope of the project.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details.

Individiual licensing arrangements can be made if this is an issue for your project - Contact Me at [LinkedIn](https://www.linkedin.com/in/ianfhunter) to discuss.

## Acknowledgments

* **Billie Thompson** - *README & Contribution Templates* - [PurpleBooth](https://github.com/PurpleBooth)

## Donate

[Keep this project alive](https://paypal.me/ianfhunter)
