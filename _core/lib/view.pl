################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

our %in;
for (param()){ $in{$_} = param($_); }

our $file;
my $type;
our %conv_data = ();

if(param('id')){
  ($file, $type) = getfile_open(param('id'));
}
elsif(param('url')){
  require $set::lib_convert;
  %conv_data = data_convert(param('url'));
  $type = $conv_data{'type'};
}

### 各システム別処理 --------------------------------------------------
if   ($type eq 'm'){ require $set::lib_view_mons; }
elsif($type eq 'i'){ require $set::lib_view_item; }
else               { require $set::lib_view_char; }


### データ取得 --------------------------------------------------
sub pcDataGet {
  my %pc;
  if($in{'id'}){
    my $datadir = ($type eq 'm') ? $set::mons_dir : ($type eq 'i') ? $set::item_dir : $set::char_dir;
    my $datafile = $in{'backup'} ? "${datadir}${file}/backup/$in{'backup'}.cgi" : "${datadir}${file}/data.cgi";
    open my $IN, '<', $datafile or error 'データがありません。';
    $_ =~ s/(.*?)<>(.*?)\n/$pc{$1} = $2;/egi while <$IN>;
    close($IN);
    if($in{'backup'}){
      $pc{'protect'} = protectTypeGet("${datadir}${file}/data.cgi");
      $pc{'backupId'} = $in{'backup'};
    }
  }
  elsif($in{'url'}){
    %pc = %conv_data;
    if(!$conv_data{'ver'}){
      require (($type eq 'm') ? $set::lib_calc_mons : ($type eq 'i') ? $set::lib_calc_item : $set::lib_calc_char);
      %pc = data_calc(\%pc);
    }
  }
  return %pc;
}

1;