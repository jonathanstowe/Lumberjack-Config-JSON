#!/usr/bin/env raku

use Test;
use Lumberjack::Config::JSON;
use JSON::Class;

use Lumberjack;

class My::Class does Lumberjack::Logger {

}

class InnerLJ does JSON::Class {
    has Str                         $.something;
    has Lumberjack::Config::JSON    $.logger-config;
}

lives-ok {
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

    isa-ok $config.logger-config, Lumberjack::Config::JSON;
    ok my $dispatcher = Lumberjack.dispatchers.first, "got the dispatcher";
    isa-ok $dispatcher, Lumberjack::Dispatcher::Console, "got the right dispatcher";
    ok $dispatcher.colour, "got the arg we set";

    for ( Lumberjack::Debug, Lumberjack::Info, Lumberjack::Warn, Lumberjack::Error ) -> $l {
        ok $l ~~ $dispatcher.levels, "Dispatcher handles $l OK";
    }
    ok My::Class ~~ $dispatcher.classes, "class matches";
    ok My::Class.log-level == Lumberjack::Error, "My::Class has the right log-level";


}, "Ingest the configuration";



done-testing;
# vim: ft=raku
