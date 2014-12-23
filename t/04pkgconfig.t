use strict;
use warnings;
use Test::More tests => 3;

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('Catalyst::Test', 'TestApp');

my $view = 'Pkgconfig';

my $response;
ok(($response = request("/test?view=$view"))->is_success, 'request ok');
is($response->content, "#header {
  background-color: #FFFFFF; }

.error {
  color: #FF0000; }
", 'message ok');
