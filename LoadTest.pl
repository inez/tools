#!/usr/bin/env perl

use feature "say";
use LWP::UserAgent;
use JSON::XS;
use Data::Dumper;
use Thread::Pool::Simple;
use Getopt::Long;

my $coder = JSON::XS->new->ascii->pretty->allow_nonref;

our $mwurl;

sub run2 {
	my $revid = shift;
	my $lwp = LWP::UserAgent->new();
	$lwp->proxy('http', 'http://squid-proxy.local:3128/');
	my $apiurl = 'http://' . $mwurl . '/api.php?action=query&format=xml&revids=' . $revid . '&maxlag=5&cllimit=max&prop=categories%7Cinfo%7Crevisions&rvprop=comment%7Ccontent%7Cflags%7Cids%7Ctimestamp%7Cuser';
	say "Calling API for url: ".$apiurl;
	my $jsonResp = $lwp->request( HTTP::Request->new( 'GET', $apiurl ) );
}

sub run {
	say "Run!";

	my $pool = Thread::Pool::Simple->new(
		min => 2,
		max => 4,
		load => 4,
		do => [ sub {
			run2( shift );
		} ]		
	);

	my $lwp = LWP::UserAgent->new();
	$lwp->proxy('http', 'http://squid-proxy.local:3128/');
	my $apiurl = 'http://' . $mwurl . '/api.php?action=query&format=json&list=recentchanges&rclimit=500&rcnamespace=0%7C2%7C4%7C6%7C10%7C14&rcprop=comment%7Cflags%7Cids%7Cloginfo%7Csizes%7Ctimestamp%7Ctitle%7Cuser';

	while ( true ) {
		say "Calling API for url: ".$apiurl;
		
		my $jsonResp = $lwp->request( HTTP::Request->new( 'GET', $apiurl ) );
		my $json = $coder->decode ( $jsonResp->content );

		my $i = 0;
		foreach ( @{$json->{ "query" }->{ "recentchanges" }} ) {
			my $revid =  $_->{ 'revid' };
			$pool->add( $revid ); 
			$i++; last if ( $i == 10 ) ;
		}

		sleep(30);
	}	
}

GetOptions( 
	"mwurl=s"	=>	\( $mwurl = '' )
);

run();
