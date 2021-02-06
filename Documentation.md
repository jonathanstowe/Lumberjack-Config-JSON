NAME
====

Lumberjack::Config::JSON - configure Lumberjack from JSON

SYNOPSIS
========

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
             ],
             "args" : {
                "colour" : true
             }
          }
       ],
       "levels" : [
          {
             "class" : "My::Class",
             "level" : "Error"
          }
       ]
    }
    EOJ

DESCRIPTION
===========

This configures [Lumberjack](https://github.com/jonathanstowe/Lumberjack) from a JSON description. The configuration is somewhat simplified compared to what is possible working directly with the `Lumberjack` and the dispatchers, loggers and so forth.

The configuration is applied immediately after the JSON is parsed to an object and before the object is returned, the intent of doing this is so that it can be embedded within a larger JSON configuration that is managed by `JSON::Class` without any need for further processing. You can do something like:

    class My::Class does Lumberjack::Logger {

    }

    class InnerLJ does JSON::Class {
        has Str                         $.something;
        has Lumberjack::Config::JSON    $.logger-config;
    }

    my $config =InnerLJ.from-json(q:to/EOJ/);
    {
        "something" : "thing",
        "logger-config" : {
                           "dispatchers" : [
                              {
                                 "dispatcher" : "Lumberjack::Dispatcher::Console",
                                 "levels": [
                                    "Debug", "Info", "Warn", "Error"
                                 ],
                                 "classes" : [
                                    "My::Class"
                                 ],
                                 "args": {
                                     "colour" : true
                                 }
                              }
                           ],
                           "levels" : [
                              {
                                 "class" : "My::Class",
                                 "level" : "Error"
                              }
                           ]
                        }
    }
    EOJ

And the `Lumberjack` will be configured by the time `from-json` returns, and you will be able to use the returned object as normal, though you can ignore the `Lumberjack::Config::JSON` object in `logger-config` if you wish.

CONFIG LAYOUT
-------------

The JSON config is a JSON object with two Array properties `dispatchers` and `levels` each comprising a list of objects:

### dispatchers

The `dispatchers` represents objects that do the `Lumberjack::Dispatcher` role that will be pushed on the [Lumberjack](Lumberjack) instance. `dispatcher` must be the name of a loaded or loadable class that does the `Lumberjack::Dispatcher` role, and is required, an exception will be thrown if the class cannot be resolved. `levels` is a list of the names of the `Lumberjack::Level` that the dispatcher will handle, this can be empty or omitted in which case the dispatcher will handle all levels. `classes` is a list of the names of classes that do the `Lumberjack::Logger` role that the dispatcher will handle, they must be resolvable (either defined or requirable,) or an exception will be thrown. The `args` object is an optional set of additional dispatcher specific arguments ( such as the `colour` argument to the Console dispatcher, or the `file` argument to [Lumberjack::Dispatcher::File](https://github.com/jonathanstowe/Lumberjack/blob/master/Documentation.md#lumberjackdispatcherfile).) These can only be things that can be completely represented in JSON, so if your dispatcher requires, say, an object argument you may need to provide an alternative constructor which will take strings, numbers, booleans or a list or hash thereof.

### levels

The `levels` represents the initial `log-level` of the named classes. The `class` must be the name of a type that does the `Lumberjack::Logger` role and which is either already loaded or can be required; if it can't be resolved an exception will be thrown, if it isn't a [Lumberjack::Logger](Lumberjack::Logger) it will be ignored. The `level` must be the name of a value of the [Lumberjack::Level](https://github.com/jonathanstowe/Lumberjack/blob/master/Documentation.md#lumberjacklevel) enumeration, if the name isn't recognised an exception will be thrown.

