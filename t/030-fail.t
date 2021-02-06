#!/usr/bin/env raku

use Test;
use Lumberjack::Config::JSON;

use Lumberjack;

class My::Class does Lumberjack::Logger {

}

class NotALogger {
}

class NotADispatcher {
}

throws-like {
    my $config = Lumberjack::Config::JSON.from-json(q:to/EOJ/);
    {
       "dispatchers" : [
          {
             "dispatcher" : "Goatfish::Beelzebub",
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

}, X::Lumberjack::Config::JSON::NoClass, message => 'Unable to find or load class Goatfish::Beelzebub',  "bogus dispatcher class";

throws-like {
    my $config = Lumberjack::Config::JSON.from-json(q:to/EOJ/);
    {
       "dispatchers" : [
          {
             "dispatcher" : "Lumberjack::Dispatcher::Console",
             "levels": [
                "Debug", "Info", "Warn", "Error"
             ],
             "classes" : [
                "Goatfish::Beelzebub"
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

}, X::Lumberjack::Config::JSON::NoClass, message => 'Unable to find or load class Goatfish::Beelzebub',  "bogus class in dispatcher 'classes'";

throws-like {
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
             "class" : "Goatfish::Beelzebub",
             "level" : "Error"
          }
       ]
    }
    EOJ

}, X::Lumberjack::Config::JSON::NoClass, message => 'Unable to find or load class Goatfish::Beelzebub',  "bogus class in levels 'class'";

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
             "class" : "NotALogger",
             "level" : "Error"
          }
       ]
    }
    EOJ

}, "doesn't throw if a class in levels isn't a Logger";

throws-like {
    my $config = Lumberjack::Config::JSON.from-json(q:to/EOJ/);
    {
       "dispatchers" : [
          {
             "dispatcher" : "Lumberjack::Dispatcher::Console",
             "levels": [
                "GarbageLevel"
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

}, X::Lumberjack::Config::JSON::NoLevel, message => 'GarbageLevel is not a known log level',  "bogus Level in dispatcher 'levels'";

throws-like {
    my $config = Lumberjack::Config::JSON.from-json(q:to/EOJ/);
    {
       "dispatchers" : [
          {
             "dispatcher" : "Lumberjack::Dispatcher::Console",
             "levels": [
                "Info"
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
             "level" : "GarbageLevel"
          }
       ]
    }
    EOJ

}, X::Lumberjack::Config::JSON::NoLevel, message => 'GarbageLevel is not a known log level',  "bogus Level in levels 'level'";

throws-like {
    my $config = Lumberjack::Config::JSON.from-json(q:to/EOJ/);
    {
       "dispatchers" : [
          {
             "dispatcher" : "NotADispatcher",
             "levels": [
                "Info"
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
             "level" : "Info"
          }
       ]
    }
    EOJ

}, X::Lumberjack::Config::JSON::NotADispatcher, message => 'NotADispatcher is not a Lumberjack dispatcher',  "dispatcher is not a Lumberjack::Dispatcher";

throws-like {
    my $config = Lumberjack::Config::JSON.from-json(q:to/EOJ/);
    {
       "dispatchers" : [
          {
             "levels": [
                "Info"
             ],
             "classes" : [
                "My::Class"
             ],
             "args": {
                 "colour" : true
             }
          }
       ]
    }
    EOJ

}, X::Attribute::Required , message => q{The attribute '$!dispatcher-name' is required, but you did not provide a value for it.},  "missing dispatcher class name";

lives-ok {
    my $config = Lumberjack::Config::JSON.from-json(q:to/EOJ/);
    {
    }
    EOJ

}, "empty JSON does nothing";


done-testing;
# vim: ft=raku
