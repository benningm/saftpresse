package Log::Saftpresse::Log4perl;

use strict;
use warnings;

# ABSTRACT: logging for Log::Saftpresse
# VERSION

use Exporter;
use Log::Log4perl qw(:levels);

our @ISA = ('Exporter');

our $log;
our @EXPORT = qw( $log );

sub init {
	my ( $class, $level, $file ) = @_;
	my $layout = 'Log::Log4perl::Layout::SimpleLayout';

	if( defined $file && $file eq 'syslog' ) {
		Log::Log4perl->init(\ qq{
			log4perl.rootLogger = $level, Syslog
			log4perl.appender.Syslog = Log::Dispatch::Syslog
			log4perl.appender.Syslog.min_level = debug
			log4perl.appender.Syslog.ident = saftpresse
			log4perl.appender.Syslog.facility = daemon
			log4perl.appender.Syslog.layout = $layout
		});
	} elsif( defined $file ) {
		Log::Log4perl->init(\ qq{
			log4perl.rootLogger = $level, File
			log4perl.appender.File = Log::Log4perl::Appender::File
			log4perl.appender.File.filename = $file
			log4perl.appender.FileAppndr1.layout = $layout
		});
	} else {
    my $appender = 'Log::Log4perl::Appender::ScreenColoredLevels';
    my $colored = 1;
    eval { require Log::Log4perl::Appender::ScreenColoredLevels; };
    if( $@ ) {
      $appender = 'Log::Log4perl::Appender::Screen';
    }
		Log::Log4perl->init(\ qq{
			log4perl.rootLogger = $level, Screen
			log4perl.appender.Screen = $appender
			log4perl.appender.Screen.stderr  = 0
			log4perl.appender.Screen.layout = $layout
		});
    if( ! $colored ) {
      $log->debug('disabled colored logging. (install Log::Log4perl::Appender::ScreenColoredLevels)');
    }
	}

	$log = Log::Log4perl::get_logger;
  $log->info('initialized logging with level '.$level);
}

sub level {
	my ( $class, $level ) = @_;
	$log->level( $OFF );
	$log->more_logging( $level );
	return;
}

