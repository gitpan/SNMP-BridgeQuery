package SNMP::BridgeQuery;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA 		= qw(Exporter);
@EXPORT 	= qw(queryfdb);
@EXPORT_OK	= qw(querymacs queryports);
$VERSION	= 0.56;

use Net::SNMP;

my ($session);

sub connect {
   my %cla = @_;
   $cla{comm} = "public" unless exists $cla{comm};
   $session = Net::SNMP->session(Hostname  => $cla{host},
                                 Community => $cla{comm});
}

sub queryfdb {
   my ($key, $newkey, %port, %final);
   &connect(@_);

   my $macoid = '1.3.6.1.2.1.17.4.3.1.1';
   my $macref = $session->get_table($macoid);

   if ($session->error) {
      return {error => "true"};
      exit 1;
   }
   
   my $portoid = '1.3.6.1.2.1.17.4.3.1.2';
   my $portref = $session->get_table($portoid);

   if ($session->error) {
      return {error => "true"};
      exit 1;
   }

   foreach $key (keys %{$portref}) {
      ($newkey = $key) =~ s/$portoid\.//;
      $port{$newkey} = $portref->{$key};
   }

   foreach $key (keys %{$macref}) {
      next if (length($macref->{$key}) < 14);
      $macref->{$key} =~ s/0x//;
      ($newkey = $key) =~ s/$macoid\.//;
      $final{$macref->{$key}} = $port{$newkey}
   }

   return \%final;
}

sub querymacs {
   my ($key, $newkey, %mac);
   &connect(@_);

   my $macoid = '1.3.6.1.2.1.17.4.3.1.1';
   my $macref = $session->get_table($macoid);

   if ($session->error) {
      return {error => "true"};
      exit 1;
   }

   foreach $key (keys %{$macref}) {
      $macref->{$key} =~ s/0x//;
      ($newkey = $key ) =~ s/$macoid\.//;
      next if (length($macref->{$key}) < 12);
      $mac{$newkey} = sprintf("%12s", $macref->{$key});
   }

   return \%mac;
}

sub queryports {
   my ($key, $newkey, %port);
   &connect(@_);

   my $portoid = '1.3.6.1.2.1.17.4.3.1.2';
   my $portref = $session->get_table($portoid);

   if ($session->error) {
      return {error => "true"};
      exit 1;
   }

   foreach $key (keys %{$portref}) {
      ($newkey = $key ) =~ s/$portoid\.//;
      $port{$newkey} = $portref->{$key};
   }

   return \%port;
}

1;

__END__

=head1 NAME

BridgeQuery - Perl extension for retrieving bridge tables.

=head1 SYNOPSIS

  use BridgeQuery;
  use BridgeQuery qw(querymacs queryports);

  $fdb = queryfdb(host => $address,
                  comm => $community);
  unless (exists $fdb->{error}) {
     ($fdb->{$mac} = "n/a") unless (exists $fdb->{$mac});
     print "This MAC address was found on port: ".$fdb->{$mac}."\n";
  }

=head1 DESCRIPTION

BridgeQuery polls a device which respond to SNMP Bridge Table
queries and generates a hash reference with each polled MAC
address as the key and the associated port as the value.  The
specific MIBs that are polled are described in RFC1493.

SNMP::BridgeQuery requires Net::SNMP in order to function.

Devices can be switches, bridges, or most anything that responds
as a OSI Layer 2 component.  Layer 3 devices do not generally
respond and will cause an error.  If an error is generated, it will
return a hash reference with a single element ('error') which
can be tested for.

Two other functions (querymacs & queryports) can be explicitly
exported.  They work the same way as queryfdb, but they return MAC
addresses or ports (respectively) with the SNMP MIB as the hash key.

=head1 ACKNOLEDGEMENTS

David M. Town - Author of Net::SNMP

=head1 AUTHOR

John D. Shearer <jds@jkshearer.com>

=head1 SEE ALSO

perl(1), perldoc(1) Net::SNMP.

=head1 COPYRIGHT

Copyright (c) 2001 John D. Shearer.  All rights reverved.
This program is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut


