unit class App::GymScheduler;
use Terminal::ANSIColor;
use Config::JSON '';

method run {
    init-config my $conf-file := ($*HOME//'.').IO.add: '.gym.p6.conf';
    my %conf  := jconf $conf-file, *;

    my $day   := Date.new(Instant.from-posix: %conf<seed>)
      .truncated-to('month').earlier: months => %conf<show-months-before>;

    my $wdays := %conf<workout-days-per-month>;
    my @days  := ($day …^ Date.today.truncated-to('month')
      .later(months => 1+%conf<show-months-after>)
      .earlier: :day).map(*.&[does]: role {
          method day-of-week { callsame() andthen $_ == 7 ?? 0 !! $_ }
      }).List;

    srand %conf<seed>;
    for @days.categorize({.month ~ "|" ~ .year}).sort».value {
        .grep(*.day-of-week == none 0, 6).pick($wdays)».&[does]:
            role WorkoutDay {
                method day {
                    callsame() but role {
                        method fmt(|) { colored callsame, 'inverse' }
                    }
                }
            }

        say "{.year}/{.month}\n  S   M   T   W   T   F   S" with .head;
        print "    " x .head.day-of-week;
        for .<> {
            print .day.fmt: " %2d ";
            say() if .day-of-week == 6;
        }
        say "\n";
    }
}

sub init-config {
    $^conf-file.e and jconf $conf-file, 'seed' and return()
      or $conf-file.IO.spurt: '{}';
    jconf-write $conf-file, 'seed', time;
    jconf-write $conf-file, 'workout-days-per-month', 14;
    jconf-write $conf-file, 'modes', <cardio  weights>;
    jconf-write $conf-file, 'show-months-before', 1;
    jconf-write $conf-file, 'show-months-after',  1;
}
