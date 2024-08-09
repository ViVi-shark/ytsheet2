use strict;
#use warnings;
use utf8;
use open ":utf8";
use CGI::Cookie;
use List::Util qw/max min/;
use Fcntl;

### サブルーチン-SW ##################################################################################

### ユニットステータス出力 --------------------------------------------------
sub createUnitStatus {
  my %pc = %{$_[0]};
  my $target = $_[1] || '';
  return [] if $pc{type} eq 'm' && $::in{demon_action}; # 召喚された魔神はステータスをもたない
  my @unitStatus;
  my $memo;
  if ($pc{type} eq 'm'){
    my @n2a = ('','A' .. 'Z');
    if($pc{statusNum} > 1){ # 2部位以上
      my @hp; my @mp; my @def;
      my %multiple;
      foreach my $i (1 .. $pc{statusNum}){
        ($pc{"part${i}"} = $pc{"status${i}Style"}) =~ s/^.+[(（)](.+?)[)）]$/$1/;
        $multiple{ $pc{"part${i}"} }++;
      }
      my %count;
      foreach my $i (1 .. $pc{statusNum}){
        my $n = $i;
        my $partname = $pc{"part${i}"};
        if($pc{mount}){
          if($pc{lv}){
            my $ii = ($pc{lv} - $pc{lvMin} +1);
            $i .= $ii > 1 ? "-$ii" : '';
          }
        }
        if($multiple{ $partname } > 1){
          $count{ $partname }++;
          $partname .= $n2a[ $count{ $partname } ];
        }
        my $hp  = s_eval($pc{"status${i}Hp"});
        my $mp  = s_eval($pc{"status${i}Mp"});
        my $def = s_eval($pc{"status${i}Defense"});

        if ($pc{mount} && $pc{individualization}) {
          $hp += $pc{'partEquipment' . $n . '-armor-hp'} if $hp ne '';
          $mp += $pc{'partEquipment' . $n . '-armor-mp'} unless isEmptyValue($mp);
          $def += $pc{'partEquipment' . $n . '-armor-defense'} if $def ne '';

          if ($hp ne '') {
            $hp += 10 if $pc{exclusiveMount};
            $hp += 5 if $pc{ridingHpReinforcement};
            $hp += 5 if $pc{ridingHpReinforcementSuper};
          }
        }

        if ($pc{golem} && $pc{individualization} && $hp ne '') {
          my $offset;
          if ($pc{reinforcementItemGrade} eq '小') {
            $offset = 5;
          }
          elsif ($pc{reinforcementItemGrade} eq '中') {
            $offset = 10;
          }
          elsif ($pc{reinforcementItemGrade} eq '大') {
            $offset = 15;
          }
          elsif ($pc{reinforcementItemGrade} eq '極大') {
            $offset = 20;
          }
          else {
            $offset = 0;
          }

          $hp += $offset if $pc{'golemReinforcement_garnetEnergy_part' . $n . '_using'};
          $hp += $offset if $pc{'golemReinforcement_garnetLife_part' . $n . '_using'};
        }

        if ($pc{individualization} && $pc{swordFragmentNum} > 0) {
          $hp += $pc{"swordFragment_hpOffset_part$n"} unless isEmptyValue($hp);
          $mp += $pc{"swordFragment_mpOffset_part$n"} unless isEmptyValue($mp);
        }

        push(@hp , {$partname.':HP' => "$hp/$hp"});
        push(@mp , {$partname.':MP' => "$mp/$mp"}) unless isEmptyValue($mp);
        push(@def, $partname.$def);
      }
      @unitStatus = ();
      push(@unitStatus, @hp);
      push(@unitStatus, @mp) if $#mp >= 0;
      if ($target eq 'udonarium') {
        push(@unitStatus, {'防護' => join('／',@def)});
      } else {
        $memo = '防護:'.join('／',@def);
      }
    }
    else { # 1部位
      my $i = 1;
      if($pc{mount}){
        if($pc{lv}){
          my $ii = ($pc{lv} - $pc{lvMin} +1);
          $i .= $ii > 1 ? "-$ii" : '';
        }
      }
      my $hp = s_eval($pc{"status${i}Hp"});
      my $mp = s_eval($pc{"status${i}Mp"});
      my $def = s_eval($pc{"status${i}Defense"});

      if ($pc{mount} && $pc{individualization}) {
        $hp += $pc{'partEquipment1-armor-hp'} if $hp ne '';
        $mp += $pc{'partEquipment1-armor-mp'} unless isEmptyValue($mp);
        $def += $pc{'partEquipment1-armor-defense'} if $def ne '';

        if ($hp ne '') {
          $hp += 10 if $pc{exclusiveMount};
          $hp += 5 if $pc{ridingHpReinforcement};
          $hp += 5 if $pc{ridingHpReinforcementSuper};
        }
      }

      if ($pc{individualization} && $pc{swordFragmentNum} > 0) {
        $hp += $pc{swordFragmentNum} * 5 unless isEmptyValue($hp);
        $mp += $pc{swordFragmentNum} * 1 unless isEmptyValue($mp);
      }

      push(@unitStatus, { 'HP' => "$hp/$hp" });
      push(@unitStatus, { 'MP' => "$mp/$mp" }) unless isEmptyValue($mp);
      push(@unitStatus, { '防護' => "$def" });
    }

    push(@unitStatus, {'弱点' => $pc{weakness}}) if $pc{weakness};
  }
  else {
    @unitStatus = (
      { 'HP' => $pc{hpTotal}.'/'.$pc{hpTotal} },
      { 'MP' => $pc{mpTotal}.'/'.$pc{mpTotal} },
      { '防護' => $pc{defenseTotal1Def} },
    );

    if (!$::SW2_0) {
      if ($pc{lvBar}) {
        push(@unitStatus, { '⤴' => '0' });
        push(@unitStatus, { '⤵' => '0' });
        push(@unitStatus, { '♡' => '0' });
      }
      if ($pc{lvGeo}) {
        push(@unitStatus, { '天' => '0' });
        push(@unitStatus, { '地' => '0' });
        push(@unitStatus, { '人' => '0' });
      }
      push(@unitStatus, { '陣気' => '0' }) if $pc{lvWar};
    }

    if ($pc{lvRid}) {
      my $hasMagicIndication = undef;
      my $hasMagicIndicationIncrement = undef;

      foreach (1 .. $pc{lvRid}) {
        my $riding = $pc{"craftRiding$_"};
        $hasMagicIndication = 1 if $riding eq '魔法指示';
        $hasMagicIndicationIncrement = 1 if $riding eq '魔法指示回数増加';
      }

      if ($hasMagicIndication) {
        my $count = $hasMagicIndicationIncrement ? 4 : 2;
        push(@unitStatus, { '魔法指示' => "$count/$count" });
      }
    }
  }

  @unitStatus = @{formatUnitStatus \@unitStatus};

  foreach my $key (split ',', $pc{unitStatusNotOutput}){
    @unitStatus = grep { !exists $_->{$key} } @unitStatus;
  }

  foreach my $num (1..$pc{unitStatusNum}){
    next if !$pc{"unitStatus${num}Label"};
    push(@unitStatus, { $pc{"unitStatus${num}Label"} => $pc{"unitStatus${num}Value"} });
  }

  push(@unitStatus, {'メモ' => $pc{unitStatusMemo} || $memo}) if $pc{unitStatusMemo} || $memo;

  if ($#unitStatus >= 0 && $target eq 'udonarium') {
    foreach (0 .. $#unitStatus) {
      my %sourceHash = %{$unitStatus[$_]};
      my %destinationHash = ();

      for my $sourceKey (keys %sourceHash) {
        my $destinationKey = $sourceKey;
        $destinationKey =~ s/:/_/g;

        $destinationHash{$destinationKey} = $sourceHash{$sourceKey};
      }

      $unitStatus[$_] = \%destinationHash;
    }
  }

  return \@unitStatus;
}

### クラス色分け --------------------------------------------------
sub class_color {
  my $text = shift;
  $text =~ s/((?:.*?)(?:[0-9]+))/<span>$1<\/span>/g;
  $text =~ s/<span>((?:ファイター|グラップラー|フェンサー|バトルダンサー)(?:[0-9]+?))<\/span>/<span class="melee">$1<\/span>/;
  $text =~ s/<span>((?:プリースト)(?:[0-9]+?))<\/span>/<span class="healer">$1<\/span>/;
  $text =~ s/<span>((?:スカウト|ウォーリーダー|レンジャー)(?:[0-9]+?))<\/span>/<span class="initiative">$1<\/span>/;
  $text =~ s/<span>((?:セージ)(?:[0-9]+?))<\/span>/<span class="knowledge">$1<\/span>/;
  return $text;
}

### テキスト整形 --------------------------------------------------
# タグ変換
sub textToIcon {
  my $text = shift;
  
  $text =~ s{<i class="s-icon passive"><span class="raw">(\[[常準主補宣条選]])</span></i>}{$1}gi;
  
  if($::SW2_0){
    $text =~ s{\[常\]|[○◯〇]}{<i class="s-icon passive"><span class="raw">&#91;常&#93;</span></i>}gi;
    $text =~ s{\[主\]|[＞▶〆]}{<i class="s-icon major0"><span class="raw">&#91;主&#93;</span></i>}gi;
    $text =~ s{\[補\]|[☆≫»]|&gt;&gt;}{<i class="s-icon minor0"><span class="raw">&#91;補&#93;</span></i>}gi;
    $text =~ s{\[宣\]|[□☐☑🗨]}{<i class="s-icon active0"><span class="raw">&#91;宣&#93;</span></i>}gi;
    $text =~ s{\[条\]|[▽]}{<i class="s-icon condition"><span class="raw">&#91;条&#93;</span></i>}gi;
    $text =~ s{\[選\]|[▼]}{<i class="s-icon selection"><span class="raw">&#91;選&#93;</span></i>}gi;
  } else {
    $text =~ s{\[常\]|[○◯〇]}{<i class="s-icon passive"><span class="raw">&#91;常&#93;</span></i>}gi;
    $text =~ s{\[準\]|[△]}{<i class="s-icon setup"><span class="raw">&#91;準&#93;</span></i>}gi;
    $text =~ s{\[主\]|[＞▶〆]}{<i class="s-icon major"><span class="raw">&#91;主&#93;</span></i>}gi;
    $text =~ s{\[補\]|[☆≫»]|&gt;&gt;}{<i class="s-icon minor"><span class="raw">&#91;補&#93;</span></i>}gi;
    $text =~ s{\[宣\]|[□☐☑🗨]}{<i class="s-icon active"><span class="raw">&#91;宣&#93;</span></i>}gi;
  }
  
  return $text;
}
# アイテムの山括弧を追加する
sub formatItemName {
  my $raw = shift;
  return '' unless $raw;
  return $raw if $raw =~ /[＜〈].+[〉＞]/; # すでに山括弧らしきものがあればそのままにする.

  my $text = $raw;

  my $prefixes = '';
  my $suffixes = '';

  $prefixes .= $1 if $text =~ s/(\<img alt="(?:\[|&#91;)魔(?:]|&#93;)"[^>]+?>)//;
  $suffixes .= $1 if $text =~ s/(\<img alt="(?:\[|&#91;)刃(?:]|&#93;)"[^>]+?>)//;
  $suffixes .= $1 if $text =~ s/(\<img alt="(?:\[|&#91;)打(?:]|&#93;)"[^>]+?>)//;

  return $raw if $text =~ /^(?:[(（].+[）)]|[〃？])$/; # アイテム名ではなさそうな文字列ならそのままにする.

  return "$prefixes〈$text〉$suffixes";
}

### 穢れの算出 --------------------------------------------------
sub computeSin {
  my %pc = %{$_[0]};

  my $sin = $pc{sin} // 0;

  foreach (keys %pc) {
    next unless $_ =~ /^history\d+Note$/;
    if ($pc{$_} =~ /\@穢れ?\+(\d+)/) {
      $sin += $1;
    }
  }

  return $sin;
}

### 妖精魔法ランク --------------------------------------------------
sub fairyRank {
  my $lv = shift;
  my @elemental = @_;
  my $i = 0;
  $i += $_ foreach(@elemental);
  my %rank = (
    '4' => ['×','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15'],
    '3' => ['×','×','×','4','5','6','8','9','10','12','13','14','15','15','15','15'],
    '6' => ['×','×','×','2&1','3&1','4&1','4&2','5&2','6&2','6&3','7&3','8&3','8&4','9&4','10&4','10&5'],
  );
  return $rank{$i}[$lv] || '×';
}

### バージョンアップデート --------------------------------------------------
sub data_update_chara {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  delete $pc{updateMessage};
  if($pc{colorHeadBgA}) {
    ($pc{colorHeadBgH}, $pc{colorHeadBgS}, $pc{colorHeadBgL}) = rgb_to_hsl($pc{colorHeadBgR},$pc{colorHeadBgG},$pc{colorHeadBgB});
    ($pc{colorBaseBgH}, $pc{colorBaseBgS}, undef) = rgb_to_hsl($pc{colorBaseBgR},$pc{colorBaseBgG},$pc{colorBaseBgB});
    $pc{colorBaseBgS} = $pc{colorBaseBgS} * $pc{colorBaseBgA} * 10;
  }
  if($ver < 1.10){
    $pc{fairyContractEarth} = 1 if $pc{ftElemental} =~ /土|地/;
    $pc{fairyContractWater} = 1 if $pc{ftElemental} =~ /水|氷/;
    $pc{fairyContractFire } = 1 if $pc{ftElemental} =~ /火|炎/;
    $pc{fairyContractWind } = 1 if $pc{ftElemental} =~ /風|空/;
    $pc{fairyContractLight} = 1 if $pc{ftElemental} =~ /光/;
    $pc{fairyContractDark } = 1 if $pc{ftElemental} =~ /闇/;
  }
  if($ver < 1.11001){
    $pc{paletteUseBuff} = 1;
  }
  if($ver < 1.11004){
    $pc{armour1Name} = $pc{armourName};
    $pc{armour1Reqd} = $pc{armourReqd};
    $pc{armour1Eva}  = $pc{armourEva};
    $pc{armour1Def}  = $pc{armourDef};
    $pc{armour1Own}  = $pc{armourOwn};
    $pc{armour1Note} = $pc{armourNote};
    $pc{shield1Name} = $pc{shieldName};
    $pc{shield1Reqd} = $pc{shieldReqd};
    $pc{shield1Eva}  = $pc{shieldEva};
    $pc{shield1Def}  = $pc{shieldDef};
    $pc{shield1Own}  = $pc{shieldOwn};
    $pc{shield1Note} = $pc{shieldNote};
    $pc{defOther1Name} = $pc{defOtherName};
    $pc{defOther1Reqd} = $pc{defOtherReqd};
    $pc{defOther1Eva}  = $pc{defOtherEva};
    $pc{defOther1Def}  = $pc{defOtherDef};
    $pc{defOther1Note} = $pc{defOtherNote};
    $pc{defenseTotal1Eva} = $pc{defenseTotalAllEva};
    $pc{defenseTotal1Def} = $pc{defenseTotalAllDef};
    $pc{defTotal1CheckArmour1} = $pc{defTotal1CheckShield1} = $pc{defTotal1CheckDefOther1} = $pc{defTotal1CheckDefOther2} = $pc{defTotal1CheckDefOther3} = 1;
  }
  if($ver < 1.12022){
    $pc{updateMessage}{'ver.1.12.022'} = '「言語」欄が、セージ技能とバード技能による習得数をカウントする仕様になりました。<br>　このシートのデータは、自動的に、新仕様に合わせて項目を振り分けていますが、念の為、言語欄のチェックを推奨します。';
    foreach my $n (1 .. $pc{languageNum}){
      if($pc{race} =~ /人間/ && $pc{"language${n}"} =~ /地方語/){
        $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
        $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
        last;
      }
    }
    foreach my $n (1 .. $pc{languageNum}){
      if(($pc{lvDem} || $pc{lvGri}) && $pc{"language${n}"} =~ /魔法文明語/){
        $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
      }
      if($pc{lvDem} && $pc{"language${n}"} =~ /魔神語/){
        $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
      }
      if(($pc{lvSor} || $pc{lvCon}) && $pc{"language${n}"} =~ /魔法文明語/){
        $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
        $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
      }
      if(($pc{lvMag} || $pc{lvAlc}) && $pc{"language${n}"} =~ /魔動機文明語/){
        $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
        $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
      }
      if($pc{lvFai} && $pc{"language${n}"} =~ /妖精語/){
        $pc{"language${n}Talk"} = $pc{"language${n}Talk"} ? 'auto' : '';
        $pc{"language${n}Read"} = $pc{"language${n}Read"} ? 'auto' : '';
      }
    }
    my $bard = 0;
    foreach my $n (reverse 1 .. $pc{languageNum}){
      last if $bard >= $pc{lvBar};
      if($pc{"language${n}Talk"} == 1){ $pc{"language${n}Talk"} = 'Bar'; $bard++; }
    }
    my $sage = 0;
    foreach my $n (reverse 1 .. $pc{languageNum}){
      last if $sage >= $pc{lvSag};
      if($pc{"language${n}Talk"} == 1){ $pc{"language${n}Talk"} = 'Sag'; $sage++; }
      last if $sage >= $pc{lvSag};
      if($pc{"language${n}Read"} == 1){ $pc{"language${n}Read"} = 'Sag'; $sage++; }
    }
    foreach my $n (1 .. $pc{languageNum}){
      if($pc{"language${n}Talk"} == 1){ $pc{"language${n}Talk"} = 'auto'; }
      if($pc{"language${n}Read"} == 1){ $pc{"language${n}Read"} = 'auto'; }
    }
  }
  if($ver < 1.13002){
    ($pc{characterName},$pc{characterNameRuby}) = split(':', $pc{characterName});
    ($pc{aka},$pc{akaRuby}) = split(':', $pc{aka});
  }
  if($ver < 1.15003){
    foreach my $i (0 .. $pc{historyNum}){
      $pc{historyExpTotal} += s_eval($pc{"history${i}Exp"});
      $pc{historyMoneyTotal} += s_eval($pc{"history${i}Money"});
      
      if   ($pc{"history${i}HonorType"} eq 'barbaros'){ $pc{historyHonorBarbarosTotal} += s_eval($pc{"history${i}Honor"}); }
      elsif($pc{"history${i}HonorType"} eq 'dragon'  ){ $pc{historyHonorDragonTotal}   += s_eval($pc{"history${i}Honor"}); }
      else {
        $pc{historyHonorTotal} += s_eval($pc{"history${i}Honor"});
      }
    }
    $pc{historyGrowTotal} = $pc{sttPreGrowA}  + $pc{sttPreGrowB}  + $pc{sttPreGrowC}  + $pc{sttPreGrowD}  + $pc{sttPreGrowE}  + $pc{sttPreGrowF}
                            + $pc{sttHistGrowA} + $pc{sttHistGrowB} + $pc{sttHistGrowC} + $pc{sttHistGrowD} + $pc{sttHistGrowE} + $pc{sttHistGrowF};
  }
  if($ver < 1.15009){
    foreach my $i (1 .. $pc{lvWar}){
      $pc{'craftCommand'.$i} =~ s/濤/涛/g;
      $pc{'craftCommand'.$i} =~ s/^軍師の知略$/陣率：軍師の知略/g;
      $pc{packWarAgi} = $pc{lvWar} + $pc{bonusAgi};
      $pc{packWarInt} = $pc{lvWar} + $pc{bonusInt};
    }
    if($pc{lvSor} && $pc{lvCon}){
      $pc{lvWiz} = max($pc{lvSor},$pc{lvCon});
      $pc{magicPowerWiz} = max($pc{magicPowerSor},$pc{magicPowerCon});
      $pc{magicPowerOwnWiz} = ($pc{magicPowerOwnSor} && $pc{magicPowerOwnCon}) ? 1 : 0;
    }
    else { $pc{lvWiz} = 0; }
  }
  if($ver < 1.16013){
    $pc{historyMoneyTotal} = $pc{hisotryMoneyTotal};
  }
  if($ver < 1.17014){
    $pc{updateMessage}{'ver.1.17.014'} = 'ルールブックに合わせ、<br>「性別」「年齢」の並びを「年齢」「性別」の順に変更、<br>「作成レギュレーション」「セッション履歴」における項目の並びを<br>「経験点・名誉点・所持金（ガメル）」から、<br>「経験点・所持金（ガメル）・名誉点」に変更しました。<br>記入の際はご注意ください。';
  }
  if($ver < 1.20109){
    $pc{packWarIntAdd} -= 1 if $pc{packWarIntAdd} > 0;
    $pc{packWarIntAuto} = 1;
  }
  if($ver < 1.22010){
    $pc{updateMessage}{'ver.1.22.010'} = '追加種族「スプリガン」を考慮し、防具欄の仕様を変更しました。<br>鎧や盾を複数記入できるようになった代わりに、金属鎧や非金属鎧などのカテゴリを選択する必要があります。<br>（既存のキャラクターシートについては、ある程度は自動で金属／非金属を振り分けました）';
    $pc{armour1Category}
      = $pc{masteryMetalArmour} ? '金属鎧'
      : $pc{masteryNonMetalArmour} ? '非金属鎧'
      : $pc{armour1Name} =~ /(スプリント|プレート|スーツ|ラメラー)アーマー|チェインメイル|堅忍鎧|魔壮鎧|スティールガード|コート・?オブ・?プレート|フォートレス/ ? '金属鎧'
      : $pc{armour1Name} =~ /(クロース|ブレスト)アーマー|ポイントガード|(ソフト|ハード)レザー|(マナ|アラミド|ミラージュ|サー)コート|ミラージュパッド|布鎧|のローブ|コンバット.*スーツ|ボーンベスト/ ? '非金属鎧'
      : '';
    my $num = 1;
    foreach('shield1','defOther1','defOther2','defOther3'){
      if ( $pc{$_.'Name'}
        || $pc{$_.'Reqd'}
        || $pc{$_.'Eva'}
        || $pc{$_.'Def'}
        || $pc{$_.'Own'}
        || $pc{$_.'Note'}
      ){
        $num++;
        $pc{"armour${num}Name"} = $pc{$_.'Name'};
        $pc{"armour${num}Category"} = $_ eq 'shield1' ? '盾' : 'その他';
        $pc{"armour${num}Reqd"} = $pc{$_.'Reqd'};
        $pc{"armour${num}Eva"}  = $pc{$_.'Eva'};
        $pc{"armour${num}Def"}  = $pc{$_.'Def'};
        $pc{"armour${num}Own"}  = $pc{$_.'Own'};
        $pc{"armour${num}Note"} = $pc{$_.'Note'};
        foreach my $i(1..3){ $pc{"defTotal${i}CheckArmour${num}"} = $pc{'defTotal'.$i.'Check'.ucfirst($_)}; }
      }
    }
    $pc{armourNum} = $num;
  }
  if($ver < 1.23000){
    $pc{raceAbilitySelect1} = $pc{raceAbilityLv6}  =~ s/^［|］$//gr;
    $pc{raceAbilitySelect2} = $pc{raceAbilityLv11} =~ s/^［|］$//gr;
    $pc{raceAbilitySelect3} = $pc{raceAbilityLv16} =~ s/^［|］$//gr;
    if($pc{race} eq 'ルーンフォーク（戦闘用ルーンフォーク）'){ $pc{race} = 'ルーンフォーク（戦闘型ルーンフォーク）' }
  }
  if($ver < 1.24011){
    $pc{'craftEnhance'.$_} =~ s/^ヴジャドーアイ$/ヴジャトーアイ/ foreach (16..17);
  }
  if($ver < 1.24024){
    if($pc{money}   =~ /^(?:自動|auto)$/i){ $pc{moneyAuto  } = 1; $pc{money  } = commify $pc{moneyTotal}; }
    if($pc{deposit} =~ /^(?:自動|auto)$/i){ $pc{depositAuto} = 1; $pc{deposit} = commify($pc{depositTotal}).'／'.commify($pc{debtTotal}); }
  }
  if($ver < 1.25008){
    foreach(1..3){
      foreach my $num (1..$pc{armourNum}){
        if($pc{"defTotal${_}CheckArmour${num}"}){
          $pc{"evasionClass$_"} = $pc{evasionClass};
          $pc{defenseNum} = $_;
          last;
        }
      }
    }
    if($pc{evasionClass} && !$pc{evasionClass1}.$pc{evasionClass2}.$pc{evasionClass3}){
      $pc{evasionClass1} = $pc{evasionClass};
    }
    if($pc{defenseNum} < 2){ $pc{defenseNum} = 2 }
  }
  if($ver < 1.25010){
    $pc{mobilityLimited} = $pc{mobilityTotal} if $pc{mobilityLimited} > $pc{mobilityTotal};
  }
  if($ver < 1.25015){
    foreach my $num (1 .. $pc{weaponNum}) {
      $pc{"weapon${num}Category"} = 'その他' if $pc{"weapon${num}Category"} eq '盾';
    }
  }
  if($ver < 1.25016){
    if(!$::SW2_0) {
      $pc{race} = 'ドレイク' if $pc{race} eq 'ドレイク（ナイト）';
      $pc{race} = 'ドレイクブロークン' if $pc{race} eq 'ドレイク（ブロークン）';
    }
  }
  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}
sub data_update_mons {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  delete $pc{updateMessage};
  
  if($ver < 1.26000){
    $pc{partsManualInput} = 1;
  }

  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}
sub data_update_item {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  delete $pc{updateMessage};

  if($ver < 1.22011){
    $pc{weaponNum} = $pc{armourNum} = 0;
    foreach (1 .. 3){
      if ( $pc{'weapon'.$_.'Usage'}
        || $pc{'weapon'.$_.'Reqd'}
        || $pc{'weapon'.$_.'Acc'}
        || $pc{'weapon'.$_.'Rate'}
        || $pc{'weapon'.$_.'Crit'}
        || $pc{'weapon'.$_.'Dmg'}
        || $pc{'weapon'.$_.'Note'}
      ){
        $pc{weaponNum}++;
      }
      if ( $pc{'armour'.$_.'Usage'}
        || $pc{'armour'.$_.'Reqd'}
        || $pc{'armour'.$_.'Eva'}
        || $pc{'armour'.$_.'Def'}
        || $pc{'armour'.$_.'Note'}
      ){
        $pc{armourNum}++;
      }
    }
  }

  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}
sub data_update_arts {
  my %pc = %{$_[0]};
  my $ver = $pc{ver};
  $ver =~ s/^([0-9]+)\.([0-9]+)\.([0-9]+)$/$1.$2$3/;
  delete $pc{updateMessage};

  if($ver < 1.20000){
    foreach my $num (1..$pc{schoolArtsNum}){
      $pc{"schoolArts${num}Type"} = $pc{"schoolArts${num}Base"};
    }
  }

  $pc{ver} = $main::ver;
  $pc{lasttimever} = $ver;
  return %pc;
}

sub isEmptyValue {
  my $value = shift;
  return defined($value) && $value ne '' && $value !~ /^[-ー－―]$/ ? 0 : 1;
}

sub addOffsetToDamage {
  my $original = shift;
  my $offset = shift;
  return '' if $original eq '';
  return $original if !defined($offset) || $offset eq '' || $offset == 0;

  if ($original =~ /^(\d+[d]6?)[+]?(-?\d+)$/i) {
    my $dice = $1;
    my $fixed = $2;
    $fixed += $offset;
    return $dice if $fixed == 0;
    return $dice . ($fixed > 0 ? '+' : '') . $fixed;
  }

  return $original;
}

sub resolveAdditionalSkills {
  my %pc = %{shift;};

  if ($pc{individualization}) {
    require $set::data_mons if $pc{golem};

    my @partNames;

    if ($pc{parts} ne '') {
      @partNames = ('全身');

      for my $partName (split(/[\/／]/, $pc{parts})) {
        next if $partName eq '';
        $partName =~ s/×(\d+)$//;
        my $count = $1;

        push(@partNames, $partName) unless grep {$_ eq $partName} @partNames;

        if ($count && $count > 1) {
          foreach (('A' .. 'Z')[0 .. ($count - 1)]) {
            push(@partNames, $partName . $_);
          }
        }
      }
    }
    else {
      @partNames = ('');
    }

    my %skillsByParts = ();

    if ($pc{swordFragmentNum} > 0) {
      my $text = "○剣のかけら＝$pc{swordFragmentNum}個<br>ＨＰ・ＭＰ・生命抵抗力・精神抵抗力が上昇しています。（いずれも反映済みです）";
      $skillsByParts{$partNames[0]} = [$text];
    }

    my %skillIndexes = ();

    for my $key ('skills', 'additionalSkills') {
      my $lastPartName;
      my $lastSkillIndex;

      for my $line (split(/&lt;br&gt;/i, $pc{$key})) {
        next if $line =~ /^\s*$/;

        if ($line =~ /^●\s*(.+?)\s*$/) {
          $lastPartName = $1;

          unless (defined($skillsByParts{$lastPartName})) {
            $skillsByParts{$lastPartName} = [];

            my $index = undef;

            for my $i (0.. $#partNames) {
              next if $partNames[$i] ne $lastPartName;
              $index = $i;
            }

            unless (defined($index)) {
              for my $i (0 .. $#partNames) {
                my $partName = $partNames[$i];
                if ($lastPartName =~ /^$partName/) {
                  $index = $i;
                  last;
                }
              }

              if (defined($index)) {
                splice(@partNames, $index, 0, ($lastPartName));
              }
              else {
                push(@partNames, $lastPartName) unless grep {$_ eq $lastPartName} @partNames;
              }
            }
          }
        }
        else {
          $lastPartName = '' unless defined($lastPartName);
          my %currentPartSkillIndexes = %{$skillIndexes{$lastPartName} || {}};
          my @partSkills = @{$skillsByParts{$lastPartName} || []};

          my $row;
          if ($line =~ /^(?:[○◯〇△＞▶〆☆≫»□☐☑🗨▽▼]|>>)/) {
            (my $firstHalf, my $lastHalf) = $key eq 'skills' ? ($line, undef) : split(/\s*\|&gt;\s*/, $line);
            $row = $lastHalf || $firstHalf;

            unless ($currentPartSkillIndexes{$firstHalf}) {
              push(@partSkills, '');
              $lastSkillIndex = $#partSkills;
              $currentPartSkillIndexes{$firstHalf} = $lastSkillIndex;
            }
            else {
              $lastSkillIndex = $currentPartSkillIndexes{$firstHalf};
              $partSkills[$lastSkillIndex] = '';
            }

            if ($lastHalf) {
              $currentPartSkillIndexes{$firstHalf} = undef;
              $currentPartSkillIndexes{$lastHalf} = $lastSkillIndex;
            }
          }
          else {
            $row = $line;
          }

          error unless defined($lastSkillIndex);

          $partSkills[$lastSkillIndex] .= '<br>' if $partSkills[$lastSkillIndex] ne '';
          $partSkills[$lastSkillIndex] .= $row;
          $skillsByParts{$lastPartName} = \@partSkills;
          $skillIndexes{$lastPartName} = \%currentPartSkillIndexes;
        }
      }
    }

    if ($pc{golem}) {
      my @allItems = data::getGolemReinforcementItems($::SW2_0 ? '2.0' : '2.5');

      my @golemPartNames;

      if ($pc{parts} ne '') {
        @golemPartNames = ('全身');

        for my $partName (split(/[\/／]/, $pc{parts})) {
          next if $partName eq '';
          $partName =~ s/×(\d+)$//;
          my $count = $1;

          if ($count && $count > 1) {
            foreach (('A' .. 'Z')[0 .. ($count - 1)]) {
              push(@golemPartNames, $partName . $_);
            }
          }
          else {
            push(@golemPartNames, $partName);
          }
        }
      }
      else {
        @golemPartNames = ('');
      }

      for my $partIndex (0 .. ($#golemPartNames + 1)) {
        my $partName = $partIndex <= $#golemPartNames ? $golemPartNames[$partIndex + ((grep {$_ eq '全身'} @golemPartNames) ? 1 : 0)] : "全身";
        my $partSuffix = $partIndex <= $#golemPartNames ? $partIndex + 1 : 'All';
        my @usingItems = ();
        my @ignoreItems = ();

        for my $itemAddress (reverse @allItems) {
          my %item = %{$itemAddress};
          next if grep {$_ eq $item{name}} @ignoreItems;

          my $key = "golemReinforcement_$item{fieldName}_part${partSuffix}_using";
          next if $pc{$key} ne 'on';

          push(@ignoreItems, $item{prerequisiteItem}) if $item{prerequisiteItem};
          unshift(@usingItems, \%item);
        }

        my @partSkills = @{$skillsByParts{$partName} ? $skillsByParts{$partName} : []};

        for my $itemAddress (@usingItems) {
          my %item = %{$itemAddress};
          my $keyForUsing = "golemReinforcement_$item{fieldName}_part${partSuffix}_using";

          if ($pc{$keyForUsing} eq 'on') {
            if ($item{name} eq '月長石の安らぎ') {
              foreach (0 .. $#partSkills) {
                next if $partSkills[$_] !~ /^[○◯〇][^\n<>&]+に弱い(?:<br>|$)/;
                $partSkills[$_] = '';
                last;
              }

              next;
            }

            my $keyForDetails = "golemReinforcement_$item{fieldName}_details";
            if ($pc{$keyForDetails}) {
              push(@partSkills, $pc{$keyForDetails});
            }
            elsif ($item{abilityRaw} eq '◯水中特化') {
              foreach (0 .. $#partSkills) {
                if ($partSkills[$_] =~ /^[○◯〇]水中専用/) {
                  $partSkills[$_] = '○水中特化<br>水中での行動で制限やペナルティ修正を受けません。<br>地上ではすべての行動判定に－２のペナルティ修正を受けます。';
                  last;
                }
              }
            }
            else {
              push(@partSkills, $item{abilityRaw});

              if ($item{abilitySuffixes}) {
                my %suffixes = %{$item{abilitySuffixes}};
                $partSkills[$#partSkills] .= $suffixes{$pc{reinforcementItemGrade}} || '';
              }

              if ($item{abilityRaw} =~ /^◯(?:ＨＰ超?強化|移動力強化)$/) {
                $partSkills[$#partSkills] .= '<br>反映済み';
              }
              elsif ($item{abilityRaw} eq '▶振りかぶる') {
                $partSkills[$#partSkills] .= "＝次手番必中、打撃点+$pc{golemReinforcement_sunstone_damageOffset}";
              }
              elsif ($item{abilityRaw} eq '◯属性耐性' && $pc{golemReinforcement_quartzDisruption_attribute}) {
                my $attribute = $pc{golemReinforcement_quartzDisruption_attribute};
                $partSkills[$#partSkills] .= "＝${attribute}";
                $partSkills[$#partSkills] .= "<br>${attribute}属性のダメージを受けるときに、それを自動的に半減します。「抵抗：半減」の効果は、抵抗に成功すればいっさいダメージを受けません。<br>ダメージ以外の${attribute}属性による効果をいっさい受けません。";
              }
            }
          }
        }

        $skillsByParts{$partName} = $#partSkills >= 0 ? \@partSkills : undef;
      }
    }

    my $skills = '';

    for my $partName (@partNames) {
      if ($partName =~ /A$/) {
        my $originalPartName = $partName;
        $originalPartName =~ s/A$//;

        if (!(grep {$_ eq $originalPartName} @partNames) && $skillsByParts{$originalPartName}) {
          $skills .= '<br>' if $skills ne '';
          $skills .= "●$originalPartName<br>" if $originalPartName ne '';
          $skills .= join('<br>', @{$skillsByParts{$originalPartName}});
        }
      }

      if ($skillsByParts{$partName}) {
        $skills .= '<br>' if $skills ne '';
        $skills .= "●$partName<br>" if $partName ne '';
        $skills .= join('<br>', @{$skillsByParts{$partName}});
      }
    }

    $pc{skillsRaw} = $pc{skills};
    $pc{skills} = $skills;
    $pc{skills} =~ s/<br>/&lt;br&gt;/ig;
  }

  return \%pc;
}

1;