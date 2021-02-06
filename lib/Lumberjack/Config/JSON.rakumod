
use JSON::Name;
use JSON::Class;

=begin pod

=head1 NAME

Lumberjack::Config::JSON - configure Lumberjack from JSON

=head1 SYNOPSIS

=begin code

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


=end code

=head1 DESCRIPTION

This configures L<Lumberjack|https://github.com/jonathanstowe/Lumberjack> from a JSON description.
The configuration is somewhat simplified compared to what is possible working directly with the
C<Lumberjack> and the dispatchers, loggers and so forth.

The configuration is applied immediately after the JSON is parsed to an object and before the object
is returned, the intent of doing this is so that it can be embedded within a larger JSON configuration
that is managed by C<JSON::Class> without any need for further processing. You can do something like:

=begin code

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

=end code

And the C<Lumberjack> will be configured by the time C<from-json> returns, and
you will be able to use the returned object as normal, though you can ignore
the C<Lumberjack::Config::JSON> object in C<logger-config> if you wish.

=head2 CONFIG LAYOUT

The JSON config is a JSON object with two Array properties C<dispatchers> and
C<levels> each comprising a list of objects:

=head3 dispatchers

The C<dispatchers>  represents objects that do the C<Lumberjack::Dispatcher> role
that will be pushed on the L<Lumberjack> instance. C<dispatcher> must be the name
of a loaded or loadable class that does the C<Lumberjack::Dispatcher> role, and is
required, an exception will be thrown if the class cannot be resolved. C<levels>
is a list of the names of the C<Lumberjack::Level> that the dispatcher will handle,
this can be empty or omitted in which case the dispatcher will handle all levels.
C<classes> is a list of the names of classes that do the C<Lumberjack::Logger> role
that the dispatcher will handle, they must be resolvable (either defined or requirable,)
or an exception will be thrown. The C<args> object is an optional set of additional dispatcher
specific arguments ( such as the C<colour> argument to the Console dispatcher, or the C<file>
argument to L<Lumberjack::Dispatcher::File|https://github.com/jonathanstowe/Lumberjack/blob/master/Documentation.md#lumberjackdispatcherfile>.)
These can only be things that can be completely represented in JSON, so if your dispatcher
requires, say, an object argument you may need to provide an alternative constructor
which will take strings, numbers, booleans or a list or hash thereof.

=head3 levels

The C<levels> represents the initial C<log-level> of the named classes.  The C<class>
must be the name of a type that does the C<Lumberjack::Logger> role and which is either
already loaded or can be required; if it can't be resolved an exception will be thrown, if it isn't a L<Lumberjack::Logger> it will be ignored.
The C<level> must be the name of a value of the L<Lumberjack::Level|https://github.com/jonathanstowe/Lumberjack/blob/master/Documentation.md#lumberjacklevel> enumeration,
if the name isn't recognised an exception will be thrown.

=end pod

class Lumberjack::Config::JSON does JSON::Class {

    use Lumberjack;

    class X::Lumberjack::Config::JSON::NoClass is Exception {
        has Str $.class is required;
        method message( --> Str ) {
            "Unable to find or load class { $!class }";
        }
    }
    class X::Lumberjack::Config::JSON::NotADispatcher is Exception {
        has Str $.class is required;
        method message( --> Str ) {
            "{ $!class } is not a Lumberjack dispatcher";
        }
    }
    class X::Lumberjack::Config::JSON::NoLevel is Exception {
        has Str $.level-name is required;
        method message( --> Str ) {
            "{ $!level-name } is not a known log level";
        }
    }

    sub load-if-required(Str $class) {
        # not quite sure why
        my $f = $class.subst(/^'Lumberjack::'/, '');
        my $t = ::($f);
        if !$t && $t ~~ Failure {
            # if it wasn't loaded by the Lumberjack class then we want the original name
            $t = (require ::($class));
            CATCH {
                default {
                    X::Lumberjack::Config::JSON::NoClass.new(class => $class).throw;
                }
            }
        }
        $t;
    }

    my %level-enums = Lumberjack::Level.enums;

    sub level-from-name(Str() $level-name --> Lumberjack::Level) {
        my $l;

        with %level-enums{$level-name} -> $e {
            $l = Lumberjack::Level($e);
        }

        if $l ~~ Failure  || !$l.defined {
            X::Lumberjack::Config::JSON::NoLevel.new(:$level-name).throw;
        }
        $l;
    }

    class DispatcherConfig does JSON::Class {
        has Str $.dispatcher-name is json-name('dispatcher') is required;
        has Str @.levels;
        has Str @.classes;
        has     %.args;

        has Lumberjack::Dispatcher $.dispatcher-object;

        method dispatcher-object( --> Lumberjack::Dispatcher ) {
            $!dispatcher-object //= do {
                my $dispatcher-type = load-if-required($!dispatcher-name);
                if $dispatcher-type !~~ Lumberjack::Dispatcher {
                    X::Lumberjack::Config::JSON::NotADispatcher.new(class => $dispatcher-type.^name).throw;
                }
                my Lumberjack::Level @levels = @!levels.map(&level-from-name);
                my Mu                @classes = @!classes.map( -> $v { load-if-required($v) } );
                my %args = %!args;
                %args<classes> = any(@classes.list) if @classes.elems;
                %args<levels>  = any(@levels.list)  if @levels.elems;
                $dispatcher-type.new(|%args);
            }
        }
    }

    class Level does JSON::Class {
        has Str $.class-name is json-name('class');
        has Str $.level-name is json-name('level');

        submethod TWEAK {
            my $type = load-if-required($!class-name);
            my $level = level-from-name($!level-name);

            if ( $type ~~ Lumberjack::Logger && $level.defined ) {
                $type.log-level = $level;
            }
        }
    }

    has Level            @.levels;
    has DispatcherConfig @.dispatchers;

    submethod TWEAK {
        for @!dispatchers -> $dispatcher {
            Lumberjack.dispatchers.append: $dispatcher.dispatcher-object;
        }
    }
}

# vim: ft=raku
