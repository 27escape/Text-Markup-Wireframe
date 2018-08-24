# -----------------------------------------------------------------------------

use strict ;
use warnings ;

package Text::Markup::Wireframe ;

use Exporter ;
use Data::Printer ;
use WebColors ;
use SVG ;

# -----------------------------------------------------------------------------
use vars qw( @EXPORT @ISA) ;

@ISA = qw(Exporter) ;

# this is the list of things that will get imported into the loading packages
# namespace
@EXPORT = qw(
    wireframe
    ) ;

my $DEFAULT_COLS = 12 ;
# -----------------------------------------------------------------------------

my %grids = (
    default => {
        row_start => "<div",
        row_end   => "</div>",
        # cell_start => "<span",
        # cell_end   => "</span>",
        cell_start => "<div",
        cell_end   => "</div>",
        cell_class => 'span',
        row_class  => 'row',
        class_re   => qr/col\d+/,
        # class_re => 'col\d+',
        class_add => 'col1',
    },
    test => {
        row_start  => "<row_start",
        row_end    => "</row_end>",
        cell_start => "<cell_start",
        cell_end   => "</cell_end>",
    },
) ;

# ----------------------------------------------------------------------------

# =item _to_hex_color

# when using colors, mke sure colour triplets etc get a hash in front
# , actual triplets (ABC) will get expanded to (AABBCC)

# B<Parameters>
#     color     - the color to check

# B<Returns>
#     the color with a hash if needed, eg #AABBCC

# =cut

sub _to_hex_color
{
    my $c = shift ;

    if ($c) {
        if ( $c =~ /(^\w+[50]0$|^oc[\w\-]+[0-9]$)/ ) {
            my $c2 = colorname_to_hex($c) ;
            $c = "#$c2" if ($c2) ;
        } else {
            $c =~ s/^([0-9a-f])([0-9a-f])([0-9a-f])$/#$1$1$2$2$3$3/i ;
            $c =~ s/^([0-9a-f]{6})$/#$1/i ;
        }
    }
    return $c ;
}

# -----------------------------------------------------------------------------
sub _extract_format
{
    my ( $format, $eclass ) = @_ ;
    my $class = "wf" . ( $eclass ? " $eclass" : "" ) ;
    # my $class = "" . ( $eclass ? " $eclass" : "" ) ;
    my $style = "" ;
    my $cols  = $DEFAULT_COLS ;

    return ( " class='$class' ", $style, $cols ) if ( !$format ) ;

    $format =~ s/[\{\}]//g ;

    # cell color may contain a period so lets do that first
    if ( $format =~ s/#(([\w\-]+)?\.?([\w\-]+)?)// ) {
        my ( $fg, $bg ) = ( $2, $3 ) ;
        $style .= "color: " . _to_hex_color($fg) . ";" if ($fg) ;
        $style .= "background-color: " . _to_hex_color($bg) . ";"
            if ($bg) ;
    }

    if ( $format =~ s/(\d+%|\d+px|\d+em)// ) {
        $style .= "width: $1;" ;
    }

    # 1.2, 2
    if ( $format =~ s/\@(\d(\.\d)?)// ) {
        $style .= "font-size: $1" . "em;" ;
    }

    # we can have one horizontal align
    if ( $format =~ s/=// ) {
        $style .= "text-align: center;" ;
    } elsif ( $format =~ s/<// ) {
        $style .= "text-align: left;" ;
    } elsif ( $format =~ s/>// ) {
        $style .= "text-align: right;" ;
    }

    # and one vertical align
    if ( $format =~ s/\^// ) {
        $style .= "vertical-align: top;" ;
    } elsif ( $format =~ s/-// ) {
        $style .= "vertical-align: middle;" ;
    } elsif ( $format =~ s/_// ) {
        $style .= "vertical-align: bottom;" ;
    }

    # do we have any columns defined
    if ( $format =~ s/\b(\d+\b)// ) {
        $cols = $1 ;
    }

    # if there are any extra styling things grab them too


    # any class is mostly what is left
    $format =~ s/(^\s+|\s+$)//g ;
    $class .= " $format" ;

    if ($class) {
        $class = " class='$class'" ;
    } else {
        $class = "" ;
    }
    if ($style) {
        $style = " style='$style'" ;
    } else {
        $style = "" ;
    }
    return ( $class, $style, $cols ) ;
}

# -----------------------------------------------------------------------------
# basic button (_button_)
# select button with dropdown (_button_v)

sub _extract_button
{
    my ($button) = @_ ;
    my ( $text, $select ) = ( $button =~ /\(_(.*?)_(v)?\)/ ) ;
    $text =~ s/\{(.*?)\}// ;
    my $format = $1 ;
    $format = 0 if ( $format eq $text ) ;

    if ($select) {
        # do | as symbol so that it is not re-interpreted
        $text .= " &#x7c;&#x25BC;" ;
    }
    my ( $class, $style ) = _extract_format($format) ;
    $button = "<button$class$style>$text</button>" ;

    return $button ;
}

# -----------------------------------------------------------------------------
# text input [_input text_]
# textarea [_input text_30x40]
sub _extract_input
{
    my ($input) = @_ ;
    $input =~ s/\[_(.*?)_(.*?)?\]// ;
    my ( $text, $size ) = ( $1, $2 ) ;
    $text =~ s/\{(.*?)\}// ;
    my $format = $1 ;
    $format = 0 if ( $format eq $text ) ;

    my ( $x, $y ) = ( $size =~ /(\d+)x?(\d+)?/ ) ;

    my ( $class, $style ) = _extract_format($format) ;
    if ($y) {
        $input = "<textarea$class$style cols=$x rows=$y>$text</textarea>" ;
    } else {
        if ($x) {
            $x = " size='$x'" ;
        } else {
            $x = "" ;
        }
        $input = "<input$class$style$x type=text value='$text'>" ;
    }

    return $input ;
}

# -----------------------------------------------------------------------------
# create a rectanglur SVG image img
# [><] [>text<] [>2<] [>100x50<] [>_text_2<] [>_text_100x50<]
# [><{#color}] [>!400x50<]

# [>_Thumbnail_160x120!1280x720<]

sub _svg_rectangle
{
    my $params = @_ % 2 ? shift : {@_} ;
    my $report_size = "" ;
    my $nosize = 0 ;

    if ( ref($params) ne 'HASH' ) {
        my @info = caller ;
        warn "$info[3] accepts a hash or a hashref of parameters" ;
        return 0 ;
    }

    my $color     = '#A0A0A0' ;
    my $fill = "#E0E0E0" ;
    my $textcolor = 'black' ;

    if ( $params->{size} =~ s/\{#(([\w\-]+)?\.?([\w\-]+)?)\}// ) {
        my ( $fg, $bg ) = ( $2, $3 ) ;
        $color =  _to_hex_color($fg)  if ($fg) ;
        $fill =  _to_hex_color($bg) if ($bg) ;
    }

    if( $params->{size} =~ s/\{#(\w+)\}//) {
        $color = $1 ;
    }

    $params->{text} ||= "" ;
    if ( $params->{size} =~ s/_(.*?)_// ) {
        $params->{text} ||= $1 ;
    }

    # if the thing starts with a '!' then we do not want to have the size on the image
    # if( $params->{size} =~ s/^\!//) {
    if( $params->{size} =~ s/\!(\d+)x(\d+)//) {
        $nosize = 1 ;
        $params->{width}  = $1 ;
        $params->{height} = $2 ;
        $report_size = "$1 x $2" ;
    }

    # if ( $params->{size} =~ s/!(\d+)x(\d+)$// ) {
    #     $report_size = "$1 x $2" ;
    # }

    # if ( $params->{size} =~ s/^(\d+)x(\d+)$// ) {
    #     $params->{width}  = $1 ;
    #     $params->{height} = $2 ;
    # }

    $params->{width}  ||= 50 ;
    $params->{height} ||= 50 ;

    if ( $params->{size} =~ /(\d+)x(\d+)$/ ) {
        $params->{width}  = $1 || 10 ;
        $params->{height} = $2 || 10;

        # assign min sizes just in case
        # $params->{width}  ||= 10 ;
        # $params->{height} ||= 10 ;
        # if we have 2 sizes, then we do actually want to report the size
        $nosize = 0 if( $nosize) ;
    } elsif ( $params->{size} =~ /\d+$/ ) {
        $params->{size} ||= 1 ;
        $params->{width}  *= $params->{size} ;
        $params->{height} *= $params->{size} ;
    } else {
        $params->{text} = $params->{size} ;

        $params->{text} =~ s/^_|_$//g ;
        if ( $params->{width} == 50 && $params->{height} == 50 ) {
            # max length 7
            $params->{text} = substr( $params->{text}, 0, 7 ) ;
        }
    }
    my $isize = "$params->{width} x $params->{height}" ;
    $isize = $report_size if ($report_size) ;
    $isize = " " if( $nosize);

    # create an SVG object with a size of 100x100 pixels
    my $svg = SVG->new(
        width      => $params->{width},
        height     => $params->{height},
        -inline    => 1,
        -nocredits => 1,
        -namespace => "",
        -indent    => "",
    ) ;

    $svg->rectangle(
        x      => 0,
        y      => 0,
        width  => $params->{width},
        height => $params->{height},
        style  => {
            'fill'           => $fill,
            'stroke'         => $color,
            'stroke-width'   => 3,
            'stroke-opacity' => 1,
            'fill-opacity'   => 1,
        },
    ) ;

    my $l1 = $svg->line(
        x1    => 0,
        y1    => 0,
        x2    => $params->{width},
        y2    => $params->{height},
        style => {
            stroke         => $color,
            'stroke-width' => 2,
        },
    ) ;

    my $l2 = $svg->line(
        x1    => $params->{width},
        y1    => 0,
        x2    => 0,
        y2    => $params->{height},
        style => {
            stroke         => $color,
            'stroke-width' => 2,
        },
    ) ;

    # need to figure out point size of text, to be able to center and split on new lines
    # als split on char width too
    # default text  seems to be 8x10

    if ( $params->{height} >= 15 && $params->{width} >= 50 ) {
        # report size of the icon
        my $text1 = $svg->text(
            x => int( ( $params->{width} - ( length($isize) * 7 ) ) / 2 ),
            y => 15,
            style => { stroke => $textcolor, },
        )->cdata($isize) ;

        if ( $params->{height} > 30 && $params->{text} ) {
            # extra text on the icon
            my $text2 = $svg->text(
                x => int( ( $params->{width} - ( length( $params->{text} ) * 7 ) ) / 2 ),

                # y     => int( $params->{height} / 2 ) + 5,
                y     => $params->{height} - 7,
                style => { stroke => $textcolor, },
            )->cdata( $params->{text} ) ;
        }
    }

    my $out = $svg->xmlify ;
    return $out ;
}

# -----------------------------------------------------------------------------

sub _replace_cell
{
    my ( $ref, $format ) = @_ ;
    my ( $class, $style ) = _extract_format( $format, $ref->{cell_class} ) ;

    if ( $ref->{cell_re} && $class !~ $ref->{cell_re} ) {
        $class =~ s/(class=['"])(.*?)(['"])/$1$2 $ref->{cell_add}$3/ ;
    }
    my $out = "" ;
    if ( $ref->{cc} ) {
        $out .= "$ref->{cell_end}" ;
    }
    $out .= "$ref->{cell_start}$class$style>" ;
    $ref->{cc} = 1 ;

    return $out ;
}
# -----------------------------------------------------------------------------

sub _replace_row
{
    my ( $ref, $loc, $format ) = @_ ;
    my $out = "" ;

    if ( $ref->{cc} ) {
        # end last cell
        $out .= "$ref->{cell_end}" ;
        $ref->{cc} = 0 ;
    }
    if ( $loc eq 'end' ) {
        if ( $ref->{rc} ) {
            # end last row
            $out .= "$ref->{row_end}" ;
            $ref->{rc} = 0 ;
        }
    } else {
        $out .= "$ref->{row_end}" if ( $ref->{rc} ) ;
        my ( $class, $style ) =
            _extract_format( $format, $ref->{row_class} ) ;
        $out .= "$ref->{row_start}$class$style>" ;
        $ref->{rc} = 1 ;    # needs a row end
    }

    return $out ;
}
# -----------------------------------------------------------------------------
my %switches = (
    radio => {
        on    => ":fa:check-circle-o:",
        alt   => ":fa:check-circle-o:",
        off   => ":fa:circle-thin:",
        up    => ":fa:caret-up:",
        down  => ":fa:caret-down:",
        left  => ":fa:caret-left:",
        right => ":fa:caret-right:",
    },
    check => {
        on    => ":fa:check-square-o:",
        alt   => ':fa:fa-times-rectangle-o:',
        off   => ":fa:square-o:",
        up    => ":fa:caret-square-o-up:",
        down  => ":fa:caret-square-o-down:",
        left  => ":fa:caret-square-o-left:",
        right => ":fa:caret-square-o-right:",
    },
    # toggle => { on => ":fa:toggle-on:", off => ":fa:toggle-off:" },
    toggle => { on => ":fa:toggle-on:", alt => ":fa:toggle-on:", off => ":fa:toggle-on:[180]" },
) ;

sub _replace_switch
{
    my ( $start, $mark, $stop, $format ) = @_ ;
    my $errstr = "$start$mark$stop" ;
    $errstr .= "{$format}" if ($format) ;
    my $err     = 0 ;
    my %choices = (
        ' ' => 'off',
        '*' => 'on',
        'x' => 'alt',
        '>' => 'right',
        '<' => 'left',
        '^' => 'up',
        'v' => 'down',
    ) ;
    $mark = '*' if ( $mark eq '.' ) ;
    $mark = $choices{ lc($mark) } || "off" ;

    my $type ;
    if ( $start eq '<' ) {
        if ( $stop ne '>' ) {
            $err++ ;
        }
        $type = 'toggle' ;
    } elsif ( $start eq '(' ) {
        if ( $stop ne ')' ) {
            $err++ ;
        }
        $type = 'radio' ;
    } elsif ( $start eq '[' ) {
        if ( $stop ne ']' ) {
            $err++ ;
        }
        $type = 'check' ;
    }
    if ($err) {
        return $errstr ;
    }
    my $out = $switches{$type}->{$mark} ;
    $out .= "[$format]" if ($format) ;
    return $out ;
}

# -----------------------------------------------------------------------------
# convert a string
sub wireframe
{
    my ( $in, $grid ) = @_ ;
    return 0 if ( !$in ) ;
    die "grid '$grid' not available" if ( $grid && !$grids{$grid} ) ;
    my $modal = 0 ;

    $grid ||= "default" ;

    # first up do the easy replacements
    # checkbox [ ] [*], radio ( ) (*) and toggles < > <x>
    # . x X * are marks to show thing is on
    $in =~ s/([\<\(\[])([\*\.x^v<> ])([\]\)\>])(\{(.*?)\})?/_replace_switch( $1, $2, $3, $5)/gsmei ;

    # button (_text_) and select button (_text_v)
    $in =~ s/(\(_.*?_([vV])?\))/_extract_button( $1)/gsme ;

    # text input [_text_] [_text_23_] and text area [_text_72x21_]
    $in =~ s/(\[_.*?_(\d+(x?\d+)?)?\])/_extract_input($1)/gsme ;

    # replace as rectangular images
    # [><] [>2<] [>3x4<] [>_some text_3] [>_some text_30x5]
    # and describe size [>_some text_300x50!1280x720]
    $in =~ s/(\[>(.*?)<\])/_svg_rectangle( size=> $2)/gsme ;

    # we setup an overall div to hold the wireframe
    my $out = "<div class='wf_container'>" ;
    # now to do the rows
    my $ref = $grids{$grid} ;
    $ref->{cc} = 0 ;    # track closing a cell
    $ref->{rc} = 0 ;    # track closing a row
                        # $ref{left} = 12 ;    # the number fo cells per row

    # we have to process the row stuff in order
    foreach my $line ( split( /\n/, $in ) ) {
        # end row =|
        # $line =~ s/^(=\|)/_replace_row( $ref, 'end', 0 , $1 )/gsme ;

        # start a modal |M or !!M
        if ( $line =~ s/^(\|M|!!M)\s*(\{.*?\})?// && !$modal ) {
            my ( $class, $style ) = _extract_format( $2, 'modal' ) ;
            $out .= "<div $class $style>" ;
            $modal++ ;
            next ;
            # next if ( !$line ) ;
        }

        # end a modal M|
        if ( $line =~ s/^(M\||M!!)// ) {
            $out .= "</div>\n" ;
            $modal = 0 ;
            # next if( !$line);
            next ;
        }

        # start row |=
        # $line
        #     =~ s/^(\|=)\s?(\{.*?\})?/_replace_row( $ref, 'start', $2 )/gsme ;
        if ( $line =~ s/^(\|=)\s*(\{.*?\})?\s*// ) {
            $out .= _replace_row( $ref, 'start', $2 ) ;
            next if ( !$line ) ;
        }

        # do cell replacements |\
        $line =~ s/(\|\\)\s*(\{.*?\})?\s*/_replace_cell( $ref, $2)/gsme ;
        # $line =~ s/\s?$// ;

        # end a row =|
        # if ( $line =~ s/^(=\|)// ) {
        if ( $line =~ s/\s*(=\|)\s*// ) {
            $out .= $line . _replace_row( $ref, 'end', 0, $1 ) ;
            # next if ( !$line ) ;
            next ;
        }

        $out .= "$line\n" ;
    }
    # end cell if needed
    if ( $ref->{cc} ) {
        $out .= $ref->{cell_end} ;
    }

    # do we need to end a row
    if ( $ref->{rc} ) {
        $out .= $ref->{row_end} ;
    }
    # close the modal if its been forgotten
    if ($modal) {
        $out .= "</div>" ;
    }

    $out .= "</div>" ;    # end the overall container

    return $out ;
}

# -----------------------------------------------------------------------------
1 ;
