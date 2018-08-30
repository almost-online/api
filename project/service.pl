#!/usr/bin/perl
package Model::Exercise;
use Mojo::Base -base;

has 'pg';

sub add {
  my ($self, $post) = @_;
  return $self->pg->db->insert('exercise', $post, {returning => 'id'})->hash->{id};
}

sub all { shift->pg->db->select('exercise')->hashes->to_array }

sub find {
  my ($self, $id) = @_;
  return $self->pg->db->select('exercise', '*', {id => $id})->hash;
}

sub remove {
  my ($self, $id) = @_;
  $self->pg->db->delete('exercise', {id => $id});
}

sub save {
  my ($self, $id, $post) = @_;
  $self->pg->db->update('exercise', $post, {id => $id});
}

1;

package Main;
use strict;
use warnings;
use Mojo::Pg;
use Mojo::JSON 'encode_json';
use Data::Dumper;
use FindBin;
#use lib "$FindBin::Bin/lib";
#use Model::Exercise;
use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

BEGIN {
	unshift @INC, '/home/vasyl/Завантаження/citrusleaf_client_swig_2.1.34/swig/perl';
}
use citrusleaf;
use perl_citrusleaf;

my $pg = Mojo::Pg->new('postgresql://postgres@/clover');
my $exercise = Model::Exercise->new(pg => $pg);

sub main {
	# get Params
	print "Content-type:text/html\n\n";
	print <<EndOfHTML;
	<html><head><title>CLOVER</title></head>
	<body>
EndOfHTML
	my $params = getParameters();
	my $res = processRequest($params);
	my $data = encode_json $res;
	print $data;
	#print Dumper $params;
}

sub processRequest {
	my ($params) = @_;
	my $method = $ENV{REQUEST_URI};
	$method =~ s/^\/api\///;
	$method =~ s/\?.*$//;
	#print Dumper $method;
	my $methods = {
		'exercise' => \&exercise
	};

	my $asc = initCluster();
	# set up the key. Create a stack object, set its value to a string
	my $key_obj = new citrusleaf::cl_object();
	citrusleaf::citrusleaf_object_init_str($key_obj, "mykey");

	#TODO $method . $params->{id}
	my $res;
	$res = getFromCash($method . $params->{id}, $asc, $key_obj) if $ENV{REQUEST_METHOD} eq 'GET';
	if ($res) {
		return $res;
	}
	$res = $methods->{$method}->($params);

	cashResult($method . $params->{id}, $res, $asc, $key_obj);

	return $res;
}

sub initCluster {
	# Initialize citrusleaf once
	citrusleaf::citrusleaf_init();
	# Create a cluster with a particular starting host
	my $asc = citrusleaf::citrusleaf_cluster_create();
	# Add host to the cluster
	my $return_value = citrusleaf::citrusleaf_cluster_add_host($asc, "127.0.0.1", 3000, 1000);

	return $return_value != citrusleaf::CITRUSLEAF_OK ? undef : $asc;
}

sub getFromCash {
	my ($uri, $asc, $key_obj) = @_;

	my $size = citrusleaf::new_intp();
	my $generation = citrusleaf::new_intp();
	# Declare a reference pointer for cl_bin *
	my $bins_get_all = citrusleaf::new_cl_bin_p();
	my $rv = citrusleaf::citrusleaf_get_all($asc, "test", "myset", $key_obj, $bins_get_all , $size, 100, $generation);
	# Number of bins returned
	my $number_bins = citrusleaf::intp_value($size);
	#print "BINS=", Dumper $number_bins;
	# Use helper function get_bins to get the bins from pointer bins_get_all and the number of bins
	my $bins = perl_citrusleaf::get_bins ($bins_get_all, $number_bins);
	# Printing value received
	for (my $i=0; $i < $number_bins; $i++) {
		my $bin = $bins->getitem($i);
	    my $bin_name = $bin->{bin_name};
	    my $type = $bin->{object}->{type};
	    if ($bin_name eq $uri) {
		    if ($type == citrusleaf::CL_STR) {
		        #print "Bin name: ", $bin_name," Resulting string: ",$bin->{object}->{u}->{str}, "\n";
		    	return $bin->{object}->{u}->{str};
		    #} elsif ($type == citrusleaf::CL_INT) {
		    #    print "Bin name: ",$bin_name," Resulting int: ",$bin->{object}->{u}->{i64}, "\n";
		    #} elsif ($type == citrusleaf::CL_BLOB) {
		    #    my $binary_data = citrusleaf::cdata($bin->{object}->{u}->{blob}, $bin->{object}->{sz});
		    #    print "Bin name: ",$bin_name," Resulting decompressed blob: ",uncompress($binary_data), "\n";
		    } else{
		        #print "Bin name: ",$bin_name," Unknown bin type: ",$type, "\n";
		        return undef;
		    }
		}
	}

	return undef;
}

sub cashResult {
	my ($uri, $res, $asc, $key_obj) = @_;
	#print Dumper $asc;
	#print Dumper $key_obj;
	#print Dumper $res;

	# Declaring an array in this interface
	my $bins = new citrusleaf::cl_bin_arr(1);
	# Provide values for those bins and then initialize them.
	# Initializing bin of type string
	my $b0 = $bins->getitem(0);
	$b0->{bin_name} = $uri;
	citrusleaf::citrusleaf_object_init_str($b0->{object}, $res);
	## Initializing bin of type int
	#my $b1 = $bins->getitem(1);
	#$b1->{bin_name} = "hits";
	#citrusleaf::citrusleaf_object_init_int($b1->{object}, 314);
	# Assign the structure back to the "bins" variable
	$bins->setitem(0,$b0); #$bins->setitem(1,$b1);

	# Define write-parameters
	my $cl_wp = new citrusleaf::cl_write_parameters();
	citrusleaf::cl_write_parameters_set_default($cl_wp);
	$cl_wp->{timeout_ms} = 1000;
	$cl_wp->{record_ttl} = 100;

	my $return_value = citrusleaf::citrusleaf_put($asc, "test", "myset",$key_obj, $bins, 1, $cl_wp);
	if ($return_value != citrusleaf::CITRUSLEAF_OK ) {
	       print "Failure setting values ", $return_value;
	       exit(-1);
	}
}

sub exercise {
	my ($params) = @_;

	my $res;
	if ($ENV{REQUEST_METHOD} eq 'GET') {
		$res = $params->{id} ? $exercise->find($params->{id}) : $exercise->all();
	} elsif ($params) {
		my @params = %{$params};
		print Dumper $params;
		$res = $exercise->add($params);
	}

	return encode_json $res;
}

sub getParameters {
	my $buffer;
	$ENV{REQUEST_URI} =~ m/\?(.*)$/;
	if($ENV{'REQUEST_METHOD'} eq "POST") {
	   	read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
	   	$buffer = $buffer . ($1 ? "&$1" : '');
	} else {
		#$ENV{REQUEST_URI} =~ m/\?(.*)$/;
		#$buffer = $ENV{'QUERY_STRING'};
		$buffer = $1;
	}
	return parsePairs($buffer);
}

sub parsePairs {
	my $pairs = [split(/&/, shift)];
	my $hashParams = {};
	my ($name, $value);
	foreach my $pair (@{$pairs}) {
		($name, $value) = split(/=/, $pair);

		$value =~ tr/+/ /;
		$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$name =~ tr/+/ /;
		$name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$value =~ s/\&\&/\&/g;

		$hashParams->{$name} = $value;

		if ($hashParams->{$name} =~ /<script(|[^>]*)>/i) {
			die("Script injection is not permitted. <BR> This incident will be reported. <\!--\$hashParams->{$name}=$hashParams->{$name}-->",__FILE__.':'.__LINE__,"yes","critical");
		}
	}

	return $hashParams;
}

sub trim {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

#just for test
sub go {
	print "Content-type:text/html\n\n";
	print <<EndOfHTML;
	<html><head><title>Perl Environment Variables</title></head>
	<body>
EndOfHTML
	#print Dumper $pg->db->select('exercise')->hashes->to_array;
	my $data = encode_json $exercise->all;
	print"\n!!!!!!!!\n", $data, "\n!!!!!!!!!!!!\n";
	#my $q = CGI->new;
	#print "<br>", Dumper($q), "</br>";
	#my $data = $q->param('GETDATA');
	#my $params = Vars();
	#print "<br>", Dumper($params), "</br>";

################################################################
	# Initialize citrusleaf once
	citrusleaf::citrusleaf_init();
	# Create a cluster with a particular starting host
	my $asc = citrusleaf::citrusleaf_cluster_create();
	# Add host to the cluster
	my $return_value = citrusleaf::citrusleaf_cluster_add_host($asc, "127.0.0.1", 3000, 1000);

	# set up the key. Create a stack object, set its value to a string
	my $key_obj = new citrusleaf::cl_object();
	citrusleaf::citrusleaf_object_init_str($key_obj, "mykey");

	# Declaring an array in this interface
	my $bins = new citrusleaf::cl_bin_arr(2);
	# Provide values for those bins and then initialize them.
	# Initializing bin of type string
	my $b0 = $bins->getitem(0);
	$b0->{bin_name} = "email";
	citrusleaf::citrusleaf_object_init_str($b0->{object}, "support\@citrusleaf.com");
	# Initializing bin of type int
	my $b1 = $bins->getitem(1);
	$b1->{bin_name} = "hits";
	citrusleaf::citrusleaf_object_init_int($b1->{object}, 314);
	# Assign the structure back to the "bins" variable
	$bins->setitem(0,$b0); $bins->setitem(1,$b1);

	# Define write-parameters
	my $cl_wp = new citrusleaf::cl_write_parameters();
	citrusleaf::cl_write_parameters_set_default($cl_wp);
	$cl_wp->{timeout_ms} = 1000;
	$cl_wp->{record_ttl} = 100;

	my $return_value = citrusleaf::citrusleaf_put($asc, "test", "myset",$key_obj, $bins, 2, $cl_wp);
	if ($return_value != citrusleaf::CITRUSLEAF_OK ) {
	       print "Failure setting values ", $return_value;
	       exit(-1);
	}

	my $size = citrusleaf::new_intp();
	my $generation = citrusleaf::new_intp();
	# Declare a reference pointer for cl_bin *
	my $bins_get_all = citrusleaf::new_cl_bin_p();
	my $rv = citrusleaf::citrusleaf_get_all($asc, "test", "myset", $key_obj, $bins_get_all , $size, 100, $generation);
	# Number of bins returned
	my $number_bins = citrusleaf::intp_value($size);
	# Use helper function get_bins to get the bins from pointer bins_get_all and the number of bins
	my $bins = perl_citrusleaf::get_bins ($bins_get_all, $number_bins);
	# Printing value received
	for (my $i=0; $i < $number_bins; $i++) {
		my $bin = $bins->getitem($i);
	    my $bin_name = $bin->{bin_name};
	    my $type = $bin->{object}->{type};
	    if ($type == citrusleaf::CL_STR) {
	        print "Bin name: ", $bin_name," Resulting string: ",$bin->{object}->{u}->{str}, "\n";
	    } elsif ($type == citrusleaf::CL_INT) {
	        print "Bin name: ",$bin_name," Resulting int: ",$bin->{object}->{u}->{i64}, "\n";
	    } elsif ($type == citrusleaf::CL_BLOB) {
	        my $binary_data = citrusleaf::cdata($bin->{object}->{u}->{blob}, $bin->{object}->{sz});
	        print "Bin name: ",$bin_name," Resulting decompressed blob: ",uncompress($binary_data), "\n";
	    } else{
	        print "Bin name: ",$bin_name," Unknown bin type: ",$type, "\n";
	    }
	}
}

sub showENV {
	foreach my $key (sort(keys %ENV)) {
	    print "$key = $ENV{$key}<br>\n";
	}
}

#Main::go();
#Main::showENV();
Main::main();


