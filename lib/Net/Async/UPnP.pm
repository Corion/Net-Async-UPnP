package Net::Async::UPnP;
use 5.020; # signatures
use feature 'signatures';
no warnings 'experimental::signatures';
use Exporter 'import';

our @EXPORT_OK = ('$SSDP_ADDR', '$SSDP_PORT', 'entity_decode');

our $VERSION = '0.01';

=head1 NAME

Net::Async::UPnP - Async Perl extension for UPnP

=cut

our $SSDP_ADDR = '239.255.255.250';
our $SSDP_PORT = 1900;

sub entity_decode( $r ) {
    # Fake-decode XML
    $r =~ s/\&gt;/>/g;
    $r =~ s/\&lt;/</g;
    $r =~ s/\&quot;/\"/g;
    $r =~ s/\&amp;/\&/g;
    return $r
}

1;

=head1 SEE ALSO

L<Net::UPnP> - the module which this code is based on

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/net-async-upnp>.

=head1 SUPPORT

The public support forum of this module is L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the Github bug queue at
L<https://github.com/Corion/Net-Async-UPnP/issues>

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2010-2023 by Max Maischein C<corion@cpan.org>.
Based on Code by Satoshi Konno Copyright 2005-2018.

=head1 LICENSE

It may be used, redistributed, and/or modified under the terms of BSD License.

=cut
