package Catalyst::View::Sass;

use strict;
use warnings;

use base qw/Catalyst::View/;
use CSS::Sass;
use File::Slurp;

our $VERSION = '0.002';

__PACKAGE__->mk_accessors('sass');

=head1 NAME

Catalyst::View::Sass - Sass View Class

=head1 SYNOPSIS

# use the helper to create your View

    myapp_create.pl view CSS Sass

# add custom configration in View/CSS.pm

    __PACKAGE__->config(
    );

# render view from lib/MyApp.pm or lib/MyApp::Controller::SomeController.pm

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->forward( $c->view('CSS') );
    }

=cut

sub new {
    my ($class, $c, $arguments) = @_;
    my $config = {
        $c->debug()? (
            output_style    => SASS_STYLE_NESTED,
            source_comments => 1
        ) : (),
        %{$class->config},
        %{$arguments}
    };

    if (!(ref $config->{include_paths} eq 'ARRAY')) {
        my $delim = $config->{DELIMITER};
        my @include_path = _coerce_paths($config->{include_paths}, $delim);
        if (!@include_path) {
            my $root = $c->config->{root};
            my $base = Path::Class::dir($root, 'sass');
            @include_path = ("$base");
        }
        $config->{include_paths} = \@include_path;
    }

    my $self = $class->next::method($c, {%$config},);
    $self->config($config);

    $self->{sass} = CSS::Sass->new(%$config);

    return $self;
}

sub _coerce_paths {
    my ($paths, $dlim) = shift;
    return () if (!$paths);
    return @{$paths} if (ref $paths eq 'ARRAY');

    # tweak delim to ignore C:/
    unless (defined $dlim) {
        $dlim = ($^O eq 'MSWin32') ? ':(?!\\/)' : ':';
    }
    return split(/$dlim/, $paths);
}

sub process {
    my ($self, $c) = @_;

    my $sass = $c->stash->{sass}
        || join('/', @{$c->req->arguments});

    unless (defined $sass) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    my $output = $self->render($c, $sass);

    $c->response->header('Content-Type' => 'text/css');
    $c->response->body($output);

    return 1;
}

sub render {
    my ($self, $c, $sass, $args) = @_;

    if (ref $sass eq 'SCALAR') {
        my $output = $self->{sass}->sass2css($$sass);
        return $output;
    }

    foreach my $dir (@{$self->config->{include_paths}}) {
        my $file = File::Spec->catfile($dir, $sass);
        if (-e $file) {
            my $sass_content = File::Slurp::read_file($file);
            my $output       = $self->{sass}->compile($sass_content);
            return $output;
        }
    }
    $c->error("file error - " . $sass . ": not found");
    die "file error - " . $sass . ": not found";
    return "file error - " . $sass . ": not found";
}

1;

__END__

=head2 METHODS

=head2 new

The constructor for the Sass view.

=head2 process($c)

Renders the Sass file.

=head2 render($c, $file)

Returns the file, rendered.

=head1 AUTHORS

Bjorn-Olav Strand, C<bolav@cpan.org>
Gerard Ribugent Navarro, C<ribugent+github@gmail.com>

=head1 COPYRIGHT

This program is free software. You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
