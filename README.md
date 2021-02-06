# Lumberjack::Config::JSON

Configure the Lumberjack logging framework from JSON

![Build Status](https://github.com/jonathanstowe/Lumberjack-Config-JSON/workflows/CI/badge.svg)

## Synopsis

```raku

use Lumberjack::Config::JSON;

my $config = Lumberjack::Config::JSON.from-json(q:to/EOJ/);
{
   "dispatchers" : [
      {
         "dispatcher" : "Lumberjack::Dispatcher::Console",
         "levels": [
            "Debug", "Info", "Warn", "Error"
         ],
         "classes" : [
            "My::Class"
         ]
      }
   ],
   "levels" : [
      {
         "class" : "My::Class",
         "level" : "All"
      }
   ]
}
EOJ

```

## Description

This provides a mechanism to configure [Lumberjack](https://github.com/jonathanstowe/Lumberjack)
from a description in `JSON`.

This is a fairly simple generic configuration, if you want more sophistication you may want to
compose your configuration in code.

Somewhat more detail can be found in the [Documentation](Documentation.md).

## Installation

Assuming you have a working Rakudo installation you should be able to install this with *zef* :

   zef install Lumberjack::Config::JSON

## Support

## Licence and Copyright

This is free software, please see the [LICENCE](LICENCE) for details.

© Jonathan Stowe 2021-
