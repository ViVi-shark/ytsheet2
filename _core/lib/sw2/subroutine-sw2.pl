use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use Encode qw/encode decode/;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-SW ##################################################################################

### クラス色分け --------------------------------------------------
sub class_color {
  my $text = shift;
  $text =~ s/((?:.*?)(?:[0-9]+))/<span>$1<\/span>/g;
  $text =~ s/<span>((?:ファイター|グラップラー|フェンサー)(?:[0-9]+?))<\/span>/<span class="melee">$1<\/span>/;
  $text =~ s/<span>((?:プリースト)(?:[0-9]+?))<\/span>/<span class="healer">$1<\/span>/;
  $text =~ s/<span>((?:スカウト|ウォーリーダー|レンジャー)(?:[0-9]+?))<\/span>/<span class="initiative">$1<\/span>/;
  $text =~ s/<span>((?:セージ)(?:[0-9]+?))<\/span>/<span class="knowledge">$1<\/span>/;
  return $text;
}

### タグ変換 --------------------------------------------------
sub tag_unescape {
  my $text = $_[0];
  $text =~ s/&amp;/&/g;
  $text =~ s/&quot;/"/g;
  $text =~ s/&lt;br&gt;/\n/gi;
  
  #$text =~ s/\{\{([0-9\+\-\*\/\%\(\) ]+?)\}\}/s_eval($1);/eg;
  
  $text =~ s#(―+)#<span class="d-dash">$1</span>#g;
  
  
  $text =~ s/\[魔\]/<img alt="&#91;魔&#93;" class="i-icon" src="${set::icon_dir}wp_magic.png">/gi;
  $text =~ s/\[刃\]/<img alt="&#91;刃&#93;" class="i-icon" src="${set::icon_dir}wp_edge.png">/gi;
  $text =~ s/\[打\]/<img alt="&#91;打&#93;" class="i-icon" src="${set::icon_dir}wp_blow.png">/gi;
  
  $text =~ s/'''(.+?)'''/<span class="oblique">$1<\/span>/gi; # 斜体
  $text =~ s/''(.+?)''/<b>$1<\/b>/gi;  # 太字
  $text =~ s/%%(.+?)%%/<span class="strike">$1<\/span>/gi;  # 打ち消し線
  $text =~ s/__(.+?)__/<span class="underline">$1<\/span>/gi;  # 下線
  $text =~ s/\{\{(.+?)\}\}/<span style="color:transparent">$1<\/span>/gi;  # 透明
  $text =~ s/[|｜]([^|｜]+?)《(.+?)》/<ruby>$1<rp>(<\/rp><rt>$2<\/rt><rp>)<\/rp><\/ruby>/gi; # なろう式ルビ
  $text =~ s/《《(.+?)》》/<span class="text-em">$1<\/span>/gi; # カクヨム式傍点
  
  $text =~ s/\[\[(.+?)&gt;((?:(?!<br>)[^"])+?)\]\]/&tag_link_url($2,$1)/egi; # リンク
  $text =~ s/\[(.+?)#([a-zA-Z0-9\-]+?)\]/<a href="?id=$2">$1<\/a>/gi; # シート内リンク
  $text =~ s/(?<!href=")(https?:\/\/[^\s\<]+)/<a href="$1">$1<\/a>/gi; # 自動リンク
  
  $text =~ s/\n/<br>/gi;
  
  $text =~ s/「((?:[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;)+)/"「".&text_convert_icon($1);/egi;
  
  return $text;
}
sub text_convert_icon {
  my $text = $_[0];
  
  $text =~ s{[○◯〇]}{<i class="s-icon passive">○</i>}gi;
  $text =~ s{[△]}{<i class="s-icon setup">△</i>}gi;
  $text =~ s{[＞▶〆]}{<i class="s-icon major">▶</i>}gi;
  $text =~ s{[☆≫»]|&gt;&gt;}{<i class="s-icon minor">≫</i>}gi;
  $text =~ s{[□☑🗨]}{<i class="s-icon active">☑</i>}gi;
  
  return $text;
} 
sub tag_unescape_ytc {
  my $text = $_[0];
  $text =~ s/&amp;/&/g;
  $text =~ s/&quot;/"/g;
  $text =~ s/&lt;br&gt;/\n/gi;
  
  $text =~ s/\[魔\]/&#91;魔&#93;/gi;
  $text =~ s/\[刃\]/&#91;刃&#93;/gi;
  $text =~ s/\[打\]/&#91;打&#93;/gi;
  
  $text =~ s/\[\[(.+?)&gt;((?:(?!<br>)[^"])+?)\]\]/$1/gi; # リンク削除
  $text =~ s/\[(.+?)#([a-zA-Z0-9\-]+?)\]/$1/gi; # シート内リンク削除
  
  $text =~ s/&#91;(.)&#93;/[$1]/g;
  
  $text =~ s/\n/<br>/gi;
  return $text;
}

### バージョンアップデート --------------------------------------------------
sub data_update_chara {
  my %pc = %{$_[0]};
  $pc{'ver'} =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  if($pc{'ver'} < 1.10){
    $pc{'fairyContractEarth'} = 1 if $pc{'ftElemental'} =~ /土|地/;
    $pc{'fairyContractWater'} = 1 if $pc{'ftElemental'} =~ /水|氷/;
    $pc{'fairyContractFire' } = 1 if $pc{'ftElemental'} =~ /火|炎/;
    $pc{'fairyContractWind' } = 1 if $pc{'ftElemental'} =~ /風|空/;
    $pc{'fairyContractLight'} = 1 if $pc{'ftElemental'} =~ /光/;
    $pc{'fairyContractDark' } = 1 if $pc{'ftElemental'} =~ /闇/;
  }
  if($pc{'ver'} < 1.11001){
    $pc{'paletteUseBuff'} = 1;
  }
  if($pc{'ver'} < 1.11004){
    $pc{'armour1Name'} = $pc{'armourName'};
    $pc{'armour1Reqd'} = $pc{'armourReqd'};
    $pc{'armour1Eva'}  = $pc{'armourEva'};
    $pc{'armour1Def'}  = $pc{'armourDef'};
    $pc{'armour1Own'}  = $pc{'armourOwn'};
    $pc{'armour1Note'} = $pc{'armourNote'};
    $pc{'shield1Name'} = $pc{'shieldName'};
    $pc{'shield1Reqd'} = $pc{'shieldReqd'};
    $pc{'shield1Eva'}  = $pc{'shieldEva'};
    $pc{'shield1Def'}  = $pc{'shieldDef'};
    $pc{'shield1Own'}  = $pc{'shieldOwn'};
    $pc{'shield1Note'} = $pc{'shieldNote'};
    $pc{'defOther1Name'} = $pc{'defOtherName'};
    $pc{'defOther1Reqd'} = $pc{'defOtherReqd'};
    $pc{'defOther1Eva'}  = $pc{'defOtherEva'};
    $pc{'defOther1Def'}  = $pc{'defOtherDef'};
    $pc{'defOther1Note'} = $pc{'defOtherNote'};
    $pc{"defenseTotal1Eva"} = $pc{"defenseTotalAllEva"};
    $pc{"defenseTotal1Def"} = $pc{"defenseTotalAllDef"};
    $pc{"defTotal1CheckArmour1"} = $pc{"defTotal1CheckShield1"} = $pc{"defTotal1CheckDefOther1"} = $pc{"defTotal1CheckDefOther2"} = $pc{"defTotal1CheckDefOther3"} = 1;
  }
  return %pc;
}

1;