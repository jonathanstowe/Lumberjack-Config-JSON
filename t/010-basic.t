#!/usr/bin/env raku

use Test;
use Lumberjack::Config::JSON;

use Lumberjack;

class My::Class does Lumberjack::Logger {

}

lives-ok {
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
    EOJ

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
