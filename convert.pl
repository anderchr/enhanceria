#!/usr/bin/perl

use Text::ParseWords ;  # for parsing quoted fields in CSV-files
use Text::CSV ; 

$includeRiNo = 0 ;  # set to true if you want heading to print RI number from cvs-file. 
$inlineCSS   = 1 ; 
#$baseURL     = "." ;
$baseURL     = "https://folk.ntnu.no/anders/enhanceria" ;

sub print_full_expandable {
    my( $title, $content ) = @_ ;
    my $output = "" ;
    my $variant ; 
    $output .= " <div class=\"enh_fullwidthline\">\n" ; 
    for $variant ( "brief", "complete" ) {
      $output .= " <div class=\"enh_fullwid2 $variant\">\n" ; 
      $output .= "  <div class=\"enh_labeled\">\n" ;
      $output .= "   <span class=\"enh_label\">$title</span><br>\n" ;
      $tmp = $content || "(none)" ; 
      if ($variant eq "brief") { # remove everything that introduses linebreaks in the output 
	$tmp =~ s/(\s|<br>|<p>|\&nbsp;)+/ /gms ;
      }
      $tmp = sprintf( "<div class=\"enh_$variant\">\n$tmp\n</div>" ) ;
      $tmp = sprintf( "<div class=\"myDIV1\">\n$tmp\n</div>" ) if ($variant eq "brief") ; 
      $output .= "   $tmp\n" ;
      $output .= "  </div>\n" ;  # labeled
      $output .= " </div>\n\n" ;  # fullwid
    }
    $output .= "  </div>\n" ;  # labeled
    return $output ;
}




my $input, $out, $page ; 
my $arg = shift @ARGV ;
if ($arg) {
    $input = $arg ; 
} else {
    $input = "Enhanceria-data.csv" ;
}

$arg = shift @ARGV ;
if ($arg) {
    open($out, "$arg") || die( "couldn't open input file $arg") ;
} else {
    $out = STDOUT ;
    binmode($out, ":encoding(UTF-8)");
}


# identificators for the columns/fields read from te cvs-file
my @headernames = (
    "id", "ri_name", "contact", "c_email", "webpage", "hostuniv", "shortname",
    "risize", "description", "ritype", "localization", "services", "pricelist",
    "lims", "booking", "majorassets", "scifield", "otherinfo") ;


print( $out "<!DOCTYPE html>\n" ) ;
print( $out "<html lang=\"en_US\">\n<head>\n" ) ;
print( $out "<meta charset=\"UTF-8\">\n" ) ;

my $svgLogo = "" ; 
if (open( LOGOFH, "<", "./enhance-logo.svg" )) {
    foreach $line ( <LOGOFH> ) {
	$line =~ s/\n$/ /sg ;
	$line =~ s/([<>"#?])/sprintf '%%%02x', ord $1/seg ; 
	$svgLogo .= $line ; 
	#    my $svgLogo = join('', grep( s/([#?])/sprintf '%%%02x', ord $1/seg, grep( tr/\n/ /, <LOGOFH> ))) ;
    }
    close( LOGOFH ) ;
    print( $out "<link rel=\"shortcut icon\" type=\"data:image/svg+xml\" href='data:image/svg+xml,".$svgLogo."' />\n" ) ;
}

if ($inlineCSS) {
    open( STYLE, "enhanceria.css" ) ;
    print( $out "<style>\n") ;
    print( $out <STYLE> ) ;
    print( $out "\n</style>\n" ) ; 
    close( SCRIPT ) ;
} else {
    print( $out "<link rel=\"stylesheet\" href=\"enhanceria.css\">\n" ) ;
}

open( SCRIPT, "jscode" ) ;
print( $out "<script>\n") ;
print( $out <SCRIPT> ) ;
print( $out "\n</script>\n" ) ; 
close( SCRIPT ) ;

print( $out "</head>\n<body>\n" ) ;

print( $out "<div class=\"fullwidth\" id=\"outerbox\">\n" ) ;
print( $out "<div class=\"maincat\" id=\"biglist\">\n" ) ;

my %allunivs ;  # id/name of all universities
my %allsizes ;  # all the size-spesificators for RIs
my %alllocale ; # all the localization ids for RIs

my @rows;  # storing each of the rows from the csv-file. 
       
# Read and parse the input CSV file
#   The charset Windows-1252 is used because some of the input text is using
#   special characters in the range 128-159 of this set, in particular bullits and
#   quote marks. Othervise, use iso-8859-1

my $csv = Text::CSV->new ({ binary => 1, auto_diag => 1 });
open my $fh, "<:encoding(Windows-1252)", $input or die "$input: $!";
while (my $row = $csv->getline ($fh)) {
    $row->[0] =~ m/\d/ or next; # skipping headerlines, i.e. lines where first field is non-numeric 
    push @rows, $row;
}
close $fh;

# Postprocess the input from the csv-file
#
while (my $row = shift @rows) {
    my @fields = @$row ; 
    my @headers = @headernames ;
    undef %felt ;
    for ($i=0; $i<scalar(@fields); $i++) {
	$felt = $fields[$i] ; 

	$felt =~ s/\n\s*(-)/<br>&nbsp; &bull;/mgs ;  
	$felt =~ s/^\s+//mg ;   # skip initial spaces
	$felt =~ s/\s+$//mg ;   # skip trailing spaces
	$felt =~ s/^(-)/&nbsp; &bull;/mgs ;  
	$felt =~ s/\n\n+/<p>/mgs ;  
	$felt =~ s/\n/<br>/mgs ;  

	# Character set issues: Latin-2 chars in names have been collapsed to question mark
	#   While there is no systematic way to restore these, we can correct those we know about
	$felt =~ s/i\?niewsk/i&sacute;niewsk/msg ; 
	$felt =~ s/l\?bieta/l&zdot;bieta/msg ; 
	$felt =~ s/astrz\?bsk/astrz&#553;bsk/msg ; 
	$felt =~ s/a\?gorz/a&lstrok;gorz/msg ; 
	$felt =~ s/\?oci\?sk/&lstrok;oci&nacute;sk/msg ; 
	$felt =~ s/\?ukasiew/&lstrok;ukasiew/msg ; 

	# Similar for various other special characters.
        $felt =~ s/(solinano)-\?\?(lab)/$1-&Sigma;-$2/gi ;
        $felt =~ s/(solinano)-\?/$1-&Sigma;/gi ;
        $felt =~ s/(10 000 )\?(m2)/$1&micro;$2/gi ;   # possibly?
        $felt =~ s/(10)\?(m resolution)/$1&micro;$2/gi ;   # possibly?
        $felt =~ s/\?(xrd|x-ray1|xrf)/&micro;$1/gi ;   # possibly?

	# Unknown what has happened here, so clearing up the data
        $felt =~ s/(@chalmers.se) \?/$1/gi ;   # possibly?

	$felt{shift @headers} = $felt ;
    }

    # Special case, incorrect data in database should actually be fixed there :-)
    if ($felt{hostuniv} =~ "Polimi" && $felt{shortname} eq "UPV") {
	$felt{shortname} = "Polimi" ;
    }

    # there is a lot of different format here, and these transformations are barely sufficient
    $felt{contact} =~ s/(.+),\s*(.+)/$2 $1/ ;  #some names on format "lastname, firstname"
    $email = $felt{c_email} ? "mailto:$felt{c_email}" : "" ; 


    # Normalize the spelling of the Host univ to something that can be used as a id. 
    $huniv = $felt{hostuniv} ;
    $huniv =~ s/\(.*\)//g ; 
    $huniv =~ s/\s+$// ;
    $huniv =~ s/^\s+// ;
    $huniv =~ s/[()\&]/X/g ;
    $huniv =~ s/ /_/g ;
    $allunivs{$huniv}++ ;

    $mysize = $felt{risize} ;
    $allsizes{$mysize}++ ; 
    
    $mylocale = $felt{localization} ;
    $mylocale =~ s/ /_/g ;
    $alllocale{$mylocale}++ ; 
    
    # Assume various fields separated by commas
    @fields = split( /\s*[&;,\/]\s*/, $felt{scifield} ) ;
#    warn( "fields with and: $felt{scifield} resulting in #######" . join("###",@fields) . '######') if ($felt{scifield}=~/and/ || 1 ) ; 
    @nfields = () ; 
    foreach $var (@fields) {
	$var =~ s/Telecommunications?/Telecomm./g ;
	$var =~ s/Technolog(y|ies)/Tech./g ;	
#	warn( "field too long; <<$var>>") if (length($var)>30) ; 
	next if (length($var)>30) ;  # ignore very long fields
	next if ($var =~ /^etc/i) ;     # 'etc' is not a proper field. 
	$var =~ s/(^|\s)(.)/$1\u$2/g ;  # convert first letter in field name to upper case.
	$allfields{$var}++ ;            # global list of all fields listed
	$var =~ s/[\&()]/X/g ;
	$var =~ s/ /_/g ;
	push( @nfields, ($var)) ; 
    }	
    my $myfields = join( ' ', @nfields) ; 

    
    
### Printing to the directory
    printf( $out "<div class=\"contactcard filterDiv $myfields $huniv $mysize $mylocale\" data-name=\"$felt{ri_name}\" " .
	    "data-host=\"$huniv\" data-size=\"$felt{risize}\" data-locale=\"$mylocale\" data-field=\"$myfields\" " .
	    "data-riid=\"$felt{id}\" id=\"RI-no-$felt{id}\">\n" ) ; 

    # We're not really supposed to display this internal id number
    if ($includeRiNo) {
	$riNumber = " (#$felt{id})" ;
    } else {
	$riNumber = "" ;
    }

    # Print out the Enhance header at te top of the entry
    printf( $out " <div class=\"enh_fullwid\">\n" ) ; 
    printf( $out "  <div class=\"enh_headline\">\n") ;
    printf( $out "   <span class=\"enh_RICatalog\">RI Catalogue$riNumber</span>\n") ;
    printf( $out "   <img class=\"enh_inlinelogo\" src=\"$baseURL/enhanceria-logo-white.png\">\n" ) ;
    printf( $out "   <span class=\"enh_RI\">RI</span>\n" ) ;
    printf( $out "  <button class=\"smallbutton\" id=\"button-RI-no-$felt{id}\"onclick=\"ExpandCard($felt{id})\">Expand</button>\n" ) ; 
    printf( $out "  </div>\n" ) ;  
    printf( $out " </div>\n\n") ;  

    printf( $out " <div class=\"enh_fullwid\">\n" ) ; 
    printf( $out "  <div class=\"enh_broadleft\">\n" ) ; 

    printf( $out "   <div class=\"enh_stackfield enh_bottomborder\">\n") ;
    printf( $out "    <div class=\"enh_labname\">\n") ;
    printf( $out "      $felt{ri_name}\n" ) ;
    printf( $out "    </div>\n" ) ;  # labname 
    printf( $out "   </div>\n" ) ;  # stackfield  

    # some prettyprinting the website URL
    if ($felt{webpage}) {
	$webpage = $felt{webpage} ;
	$webpage =~ s#^https?://## ; 
	$webpage =~ s#^www\.## ; 
	$webpage = "<a href=\"$felt{webpage}\">$webpage</a>"  ;
    } else {
	$webpage = "(none)" ;
    }

    # some prettyprinting of the mail adresses 
    if ($felt{c_email}) {
	$contactinfo = "<a href=\"mailto:$felt{c_email}\">$felt{contact}</a>" ;   
    } else {
	$contactinfo = "$felt{contact}" ;   
    }	

    print( $out &print_left_expandable( "Website", $webpage )) ; 
    print( $out &print_left_expandable( "Contact", $contactinfo )) ; 
    print( $out &print_left_expandable( "Description", $felt{description} )) ; 

    printf( $out "  </div>\n" ) ;  # broadleft

    # typeset the logos in at the right side of the card. 
    printf( $out "  <div class=\"narrowcol\">\n" ) ;

    # Firstly the lab logo, if one exists
    @labLogo = grep { m#^pictures/logo-RI-$felt{id}.(svg|jpg|jpeg|png)$# } <pictures/logo-RI-$felt{id}.*> ;
    if (@labLogo) { 
	printf( $out "   <div class=\"enh_RI_logo\"><img class=\"enh_logoadjust\" src=\"$baseURL/$labLogo[0]\"></div>\n" ) ;
    }

    # Secondly, the logo of the host institution 
    if ( -r "pictures/logo-$felt{shortname}.svg") {
	printf( $out "   <div class=\"enh_RI_logo logo-$felt{shortname}\"><img class=\"enh_logoadjust logo2-$felt{shortname}\" src=\"$baseURL/pictures/logo-$felt{shortname}.svg\"></div>\n" ) ;
    }

    # Thirdly, the a small picture representing te activity at the lab. 
    @profPict = grep { m#^pictures/pict-ri-$felt{id}-1.(jpg|jpeg|png)$# } <pictures/pict-ri-$felt{id}-1.*> ;
    if (@profPict) { 
	printf( $out "   <div class=\"enh_RI_pict\"><img class=\"enh_pictadjust\" src=\"$baseURL/$profPict[0]\"></div>\n" ) ;
    }

    printf( $out "   </div>\n" );  # narrowcol
    printf( $out " </div>\n" ) ; # fullwidth

    
sub print_one_field {
   my $output= "" ;
   my( $title, $content, $variant, $width ) = @_ ; 
   
   $output .= "  <div class=\"$width\">\n" ;
   $output .= "   <div class=\"enh_labeled\">\n" ;
   $output .= "    <span class=\"enh_label\">$title</span><br>\n" ;
   $tmp = $content || "(none)" ; 
   if ($variant eq "brief") { # remove everything that introduses linebreaks in the output 
      $tmp =~ s/(\s|<br>|<p>|\&nbsp;)+/ /gms ;
   }
   $variantx = $variant ; 
   $variantx = "complete" if ($variant eq "briefx") ; 
   $tmp = sprintf( "<div class=\"enh_$variantx\">\n$tmp\n</div>" ) ;
   $tmp = sprintf( "<div class=\"myDIV1\">\n$tmp\n</div>" ) if ($variant eq "brief") ; 
   $output .= "   $tmp\n" ;
   $output .= "  </div>\n" ;  # labeled
   $output .= "  </div>\n" ;  # labeled
   return $output ; 
}


    
sub print_left_expandable {
    my( $title, $content ) = @_ ;
    my $output = "" ;
    my $variant ;
    my $width ;
    my $foo ; 
    $output .= "   <div class=\"enh_bottomborder\">\n" ;
    for $variant ( "brief", "complete" ) {
      $output .= " <div class=\"enh_stackfield $variant\">\n" ;
      if ($title eq "Description" && $variant eq "brief") {
	 $foo = "enh_broadleft3descr" ;
	 $var = "briefx" ; 
      } else {
	  $foo = "enh_broadleft3" ;
	  $var = $variant ; 
      }
      $output .= &print_one_field( $title, $content, $var, $foo ) ; 
#      $output .= &print_one_field( $title2, $content2, $variant, "narrowcol3" ) ;
      $output .= " </div>\n\n" ;  # stackfield
    }
    $output .= "  </div>\n" ;
    return $output ;
}


    
sub print_split_expandable {
    my( $title1, $content1, $title2, $content2 ) = @_ ;
    my $output = "" ;
    my $variant ;
    my $width ;
    for $variant ( "brief", "complete" ) {
      $output .= " <div class=\"enh_fullwid3 enh_bottomborder $variant\">\n" ; 
      $output .= &print_one_field( $title1, $content1, $variant, "enh_broadleft5" ) ; 
      $output .= &print_one_field( $title2, $content2, $variant, "narrowcol3" ) ;
      $output .= " </div>\n\n" ;  # fullwid
    }
    return $output ;
}

    print( $out &print_split_expandable( "Science fields", $felt{scifield},
	                                 "Localized", $felt{localization} )) ; 

    
# ==========================     
#    printf( $out " <div class=\"enh_fullwid3 enh_bottomborder brief\">\n" ) ; 
#    printf( $out "  <div class=\"enh_broadleft3\">\n" ) ; 

#    printf( $out "  <div class=\"enh_labeled3\">\n" ) ;
#    printf( $out "    <span class=\"enh_label\">Science fields</span><br>\n" ) ;
#    if ($felt{scifield}) {
#	$felt{scifield} =~ s/(\s|<br>|<p>|\&nbsp;)+/ /gms ; 
##        if (length($felt{scifield})>$descrlength * 0.75) {
##	    $felt{scifield} = substr($felt{scifield},0,$descrlength * 0.75) . "..." ;
##	}
#	printf( $out "    <div class=\"myDIV1\"><div class=\"descrClass\">$felt{scifield}</div></div>\n" ) ;   
#    } else {
#	printf( $out "    <div class=\"myDIV1\"><div class=\"descrClass\">(none listed)</div></div>\n" ) ;   
#    }

#    printf( $out "  </div>\n" ) ;  # enh_labeled
#    printf( $out "  </div>\n" ) ;  # broadleft

#    printf( $out "  <div class=\"narrowcol3\">\n" ) ;
#    printf( $out "  <div class=\"enh_labeled3\">\n" ) ;
#    printf( $out "    <span class=\"enh_label\">Localized</span><br>\n" ) ;
#    if ($felt{localization}) {
#	printf( $out "    $felt{localization}\n" ) ;   
#    } else {
#	printf( $out "    (none listed)\n" ) ;   
#    }
#    printf( $out " </div>\n" ) ;  # narrowcol
#    printf( $out " </div>\n" ) ;  # enh_labeled
#    printf( $out " </div>\n" ) ;  # fullwidth

    
    print( $out &print_full_expandable( "Major Assets", $felt{majorassets} )) ; 
    print( $out &print_full_expandable( "Other information", $felt{otherinfo} )) ; 

    printf( $out " <div class=\"enh_fullxwidthline2 complete\">\n" ) ; 
    printf( $out " <div class=\"enh_fullwid4 complete\">\n" ) ; 
    printf( $out " <div class=\"enh_RI_pict\" style=\"display:block\">\n" ) ; 

    my @pictures = grep {m#^pictures/pict-(ri|RI)-$felt{id}-([2-9]|[1-9][0-9]+).(jpg|jpeg|png)#} <pictures/pict-ri-$felt{id}-*.*> ; 
    if (@pictures) {
	for $pictFile ( @pictures ) { 
	    printf( $out "   <a href=\"$pictFile\"><img class=\"enh_pictadjust\" src=\"$baseURL/$pictFile\"></a>\n" ) ;
	}
    } else {
	printf( $out "(no pictures)\n" ) ;
    }
    
    printf( $out " </div>\n" ) ;  ;  # labeled
    printf( $out " </div>\n" ) ;  ;  # labeled
    printf( $out " </div>\n" ) ;  ;  # labeled




    printf( $out "\n\n</div>\n" ) ;
}


# default card with a message that no cards was found

my $mymsg = << 'EndOfEmptyMsg';
<div id="NoRiFound">
 <div class="enh_fullwid">
  <div class="enh_headline">
   <span class="enh_RICatalog">RI Catalogue</span>
   <img class="enh_inlinelogo" src="enhanceria-logo-white.png">
   <span class="enh_RI">RI</span>
  </div>
 </div>

 <div class="enh_fullwid">
  <div class="enh_fullwid2">
   <div class="enh_labname">
     No matching Research Infrastructures.
   </div>
  </div>
 </div>
</div>
EndOfEmptyMsg

print $out $mymsg ; 

printf( $out "</div>\n" ) ;


#printf( $out "</div>\n" ) ;   
#printf( $out "<div class=\"left-nav\" style=\"width:25%; float:right; position:fixed; height:100%; background-color:#e0e0e0; overflow-y:scroll; top: 0px; right: -0px;\">      \n" ) ; 
#printf( $out "<div id=\"tableofcontents\" runat=\"server\">\n" ) ; 

print( $out " <div class=\"sidebar\" id=\"outersidebar\">\n" ) ;
print( $out " <div class=\"innersidebar\" id=\"innersidebarid\">\n" ) ;

print( $out " <div class=\"bigger-headline\">Filtering and sorting</div>\n" ) ; 

print( $out " <div class=\"sidebar-headline\">Amount of information</div>\n" ) ;
print( $out "<button onclick=\"ExpandData()\">Expand all</button>\n" ) ; 
print( $out "<button onclick=\"ShortenData()\">Compact all</button>\n" ) ; 

print( $out " <div class=\"sidebar-headline\">Sorting</div>\n" ) ; 
print( $out "<button onclick=\"SortData('name')\">Sort by RI name</button>\n" ) ; 
print( $out "<button onclick=\"SortData('host')\">Sort by host</button>\n" ) ; 
#print( $out "<button onclick=\"SortData('riid')\">Sort by RI id</button>\n" ) ;
print( $out "<button onclick=\"SortData('size')\">Sort by size</button>\n" ) ;
print( $out "<button onclick=\"SortData('locale')\">Sort by localization</button>\n" ) ; 

print( $out " <div class=\"sidebar-headline\">Host universities</div>\n" ) ;
print( $out " <form id=\"selectHost\">\n" ) ;

foreach $var (sort keys %allunivs) {   
    $tvar = $var ;
    $tvar =~ s/[()\&]/X/g ; 
    $tvar =~ s/ /_/g ; 
    $var =~ s/_/ /g ;
    $var =~ s/University/Univ./g ;
    $var =~ s/Technology/Tech./g ;
    $var =~ s/Norwegian/Norw./g ;
    $var =~ s/Science/Sci./g ;

    print( $out "   <label><input type=\"checkbox\" name=\"host\" value=\"$tvar\" onclick=\"sciSearchTerm()\"/>$var</label><br>\n" ) ; 
#	print( $out "   <li><a href=\"#\" onclick=\"filterSelection('$tvar')\">$var</a>\n" ) ;
}
print( $out "   <label><input type=\"checkbox\" onclick=\"deSelectList('Host')\" value=\"deselect\" />Deselect all</label><br>\n" ) ;
print( $out " </form>\n" ) ;



print( $out " <div class=\"sidebar-headline\">Infrastructure Size</div>\n" ) ; 
print( $out " <form id=\"selectSize\">\n" ) ;

foreach $var (sort keys %allsizes) {   
    print( $out "   <label><input type=\"checkbox\" name=\"size\" value=\"$var\" onclick=\"sciSearchTerm()\" />$var</label><br>\n" ) ;
}
print( $out "   <label><input type=\"checkbox\" onclick=\"deSelectList('Size')\" value=\"deselect\" />Deselect all</label><br>\n" ) ;
print( $out " </form>\n" ) ;


print( $out " <div class=\"sidebar-headline\">Localization</div>\n" ) ; 
print( $out " <form id=\"selectLocale\">\n" ) ;

foreach $var (sort keys %alllocale) {   
    $tvar = $var ;
    $tvar =~ s/\&/X/g ; 
    $tvar =~ s/ /_/g ;
    
	print( $out "   <label><input type=\"checkbox\" name=\"locale\" value=\"$tvar\" onclick=\"sciSearchTerm()\" />$var</label><br>\n" ) ;
}
print( $out "   <label><input type=\"checkbox\" onclick=\"deSelectList('Locale')\" value=\"deselect\" />Deselect all</label><br>\n" ) ;
print( $out " </form>\n" ) ;


print( $out " <div class=\"sidebar-headline\">Science Fields</div>\n" ) ;

print( $out "  <input type=\"text\" id=\"sciSearch\" onkeyup=\"sciSearchTerm()\" placeholder=\"Science field...\"><br>\n" ) ; 

print( $out " <form id=\"selectField\">\n" ) ;
#print( $out " <div id="myBtnContainer">

foreach $var (sort keys %allfields) {
    next unless ($allfields{$var}>2) ;  # dont list the smaller fields, only the bigger and broader
    $tvar = $var ;
    $tvar =~ s/\&/X/g ; 
    $tvar =~ s/ /_/g ;
    print( $out "   <label><input type=\"checkbox\" name=\"field\" value=\"$tvar\" onclick=\"sciSearchTerm()\"/>$var</label><br>\n" ) ;
}
print( $out "   <label><input type=\"checkbox\" onclick=\"deSelectList('Field')\" value=\"deselect\" />Deselect all</label><br>\n" ) ;
print( $out " </form>\n" ) ;
print( $out " </div>\n" ) ;
print( $out " </div>\n" ) ;
print( $out " </div>\n" ) ;


#print( $out " 		</div>\n" ) ; 
#print( $out "               </div>\n" ) ; 
#print( $out "            </form>\n" ) ; 
#print( $out "         </div>\n" ) ; 
#print( $out "     </div>\n" ) ; 


printf( $out "</body>\n" ) ; 
printf( $out "</html>\n" ) ; 
close $out ;






