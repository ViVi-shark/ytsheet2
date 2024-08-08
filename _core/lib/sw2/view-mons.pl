################## データ表示 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";
use HTML::Template;

### データ読み込み ###################################################################################
require $set::data_races;
require $set::data_items;

### テンプレート読み込み #############################################################################
my $SHEET;
$SHEET = HTML::Template->new( filename => $set::skin_sheet, utf8 => 1,
  path => ['./', $::core_dir."/skin/sw2", $::core_dir."/skin/_common", $::core_dir],
  search_path_on_include => 1,
  die_on_bad_params => 0, die_on_missing_include => 0, case_sensitive => 1, global_vars => 1);

### モンスターデータ読み込み #########################################################################
our %pc = getSheetData();

if($pc{description} =~ s/#login-only//i){
  $pc{description} .= '<span class="login-only">［ログイン限定公開］</span>';
  $pc{forbidden} = 'all' if !$::LOGIN_ID;
}

### タグ置換前処理 ###################################################################################
### 閲覧禁止データ --------------------------------------------------
if($pc{forbidden} && !$pc{yourAuthor}){
  my $author = $pc{author};
  my $protect   = $pc{protect};
  my $forbidden = $pc{forbidden};
  
  if($forbidden eq 'all'){
    %pc = ();
  }
  if($forbidden ne 'battle'){
    $pc{monsterName} = noiseText(6,14);
    $pc{tags} = '';
    
    $pc{description} = '';
    foreach(1..int(rand 3)+1){
      $pc{description} .= '　'.noiseText(18,40)."\n";
    }
  }
  
  $pc{lv}   = noiseText(1);
  $pc{taxa} = noiseText(2,5);
  $pc{intellect}   = noiseText(3);
  $pc{perception}  = noiseText(3);
  $pc{disposition} = noiseText(3);
  $pc{sin}         = noiseText(1);
  $pc{language}    = noiseText(4,18);
  $pc{habitat}     = noiseText(3,8);
  $pc{reputation}  = noiseText(2);
  $pc{'reputation+'} = noiseText(2);
  $pc{weakness}    = noiseText(6,10);
  $pc{initiative}  = noiseText(2);
  $pc{mobility}    = noiseText(2,6);
  $pc{statusNum} = int(rand 3)+1;
  $pc{partsNum}  = noiseText(2);
  $pc{parts}     = noiseText(3,9);
  $pc{coreParts} = noiseText(2,5);
  
  foreach(1..$pc{statusNum}){
    $pc{'status'.$_.'Style'} = noiseText(3,10);
    $pc{'status'.$_.'Accuracy'}    = noiseText(1,2);
    $pc{'status'.$_.'AccuracyFix'} = noiseText(2);
    $pc{'status'.$_.'Damage'}      = noiseText(4);
    $pc{'status'.$_.'Evasion'}     = noiseText(1,2);
    $pc{'status'.$_.'EvasionFix'}  = noiseText(2);
    $pc{'status'.$_.'Defense'}     = noiseText(2);
    $pc{'status'.$_.'Hp'}          = noiseText(2,3);
    $pc{'status'.$_.'Mp'}          = noiseText(2,3);
  }
  $pc{skills} = '';
  foreach(1..int(rand 4)+1){
    $pc{skills} .= noiseText(6,18)."\n";
    $pc{skills} .= '　'.noiseText(18,40)."\n";
    $pc{skills} .= '　'.noiseText(18,40)."\n" if(int rand 2);
    $pc{skills} .= "\n";
  }
  
  $pc{author} = $author;
  $pc{protect} = $protect;
  $pc{forbidden} = $forbidden;
  $pc{forbiddenMode} = 1;
} else {
  $pc{sin} = 0 if !defined($pc{sin});
  $pc{sin} += $pc{sinOffset} if $pc{sin} ne '' && $pc{sinOffset};
}

### 個別化による特殊能力の追加や、ゴーレム強化アイテムによる特殊能力 --------------------------------------------------
%pc = %{resolveAdditionalSkills(\%pc);};

### その他 --------------------------------------------------
$SHEET->param(rawName => $pc{characterName}?"$pc{characterName}（$pc{monsterName}）":$pc{monsterName});

### タグ置換 #########################################################################################
foreach (keys %pc) {
  if($_ =~ /^(?:skills|additionalSkills|description|additionalDescription|golemReinforcement_.+_details)$/){
    $pc{$_} = unescapeTagsLines($pc{$_});
  }
  $pc{$_} = unescapeTags($pc{$_});
}
$pc{skills} =~ s/<br>/\n/gi;
$pc{skills} =~ s#(<p>|</p>|</details>)#$1\n#gi;
$pc{skills} =~ s/^●(.*?)$/<\/p><h3>●$1<\/h3><p>/gim;
if($::SW2_0){
  $pc{skills} =~ s/^((?:[○◯〇＞▶〆☆≫»□☐☑🗨▽▼]|&gt;&gt;)+.*?)(　|$)/&textToIcon($1).$2/egim;
} else {
  $pc{skills} =~ s/^((?:[○◯〇△＞▶〆☆≫»□☐☑🗨]|&gt;&gt;)+.*?)(　|$)/&textToIcon($1).$2/egim;
}
$pc{skills} =~ s/^((?:<i class="s-icon [a-z0]+?">.+?<\/i>)+.*?)(　|$)/<\/p><h5>$1<\/h5><p>$2/gim;
$pc{skills} =~ s/\n+<\/p>/<\/p>/gi;
$pc{skills} =~ s/(^|<p(?:.*?)>|<hr(?:.*?)>)\n/$1/gi;
$pc{skills} = "<p>$pc{skills}</p>";
$pc{skills} =~ s#(</p>|</details>)\n#$1#gi;
$pc{skills} =~ s/<p><\/p>//gi;
$pc{skills} =~ s/\n/<br>/gi;
$pc{skills} = splitParagraph($pc{skills});
while ($pc{skills} =~ s#(?<!<section class="level5">)<h5>(.+?)</h5>(.*?)(<(?:h[3-5]|section)(?:\s+.+?)?>|$)#<section class="level5"><h5>$1</h5>$2</section>$3#g) {};
while ($pc{skills} =~ s#(?<!<section class="level3">)<h3>(.+?)</h3>(.*?)(<(?:h3|section class="level3")>|$)#<section class="level3"><h3>$1</h3>$2</section>$3#g) {};
$pc{description} .= "<br><br>" . $pc{additionalDescription} if $pc{individualization} && $pc{additionalDescription};
$pc{description} = splitParagraph($pc{description});

### カラー設定 --------------------------------------------------
setColors();

### 置換後出力 #######################################################################################
### データ全体 --------------------------------------------------
while (my ($key, $value) = each(%pc)){
  $SHEET->param("$key" => $value);
}
### ID / URL--------------------------------------------------
$SHEET->param(id => $::in{id});

if($::in{url}){
  $SHEET->param(convertMode => 1);
  $SHEET->param(convertUrl => $::in{url});
}
### 個別化 --------------------------------------------------
$SHEET->param(individualization => $pc{individualization});
# 剣のかけらによる抵抗力へのボーナス修正
if ($pc{individualization} && $pc{swordFragmentNum} > 0) {
  my $resistanceOffset = min(ceil(($pc{swordFragmentNum}) / 5.0), 4);

  $pc{vitResist} += $resistanceOffset;
  $pc{vitResistFix} += $resistanceOffset;
  $pc{mndResist} += $resistanceOffset;
  $pc{mndResistFix} += $resistanceOffset;
}

### タグ --------------------------------------------------
my @tags;
foreach(split(/ /, $pc{tags})){
    push(@tags, {
      URL  => uri_escape_utf8($_),
      TEXT => $_,
    });
}
$SHEET->param(Tags => \@tags);

### ゴーレム素材 --------------------------------------------------
if ($pc{golem}) {
  if ($pc{individualization}) {
    if ($pc{golemMaterialRank} eq 'higher') {
      $pc{materialName} = '強く' . $pc{materialName} if $pc{golemMaterialRank} eq 'higher';
      $SHEET->param(materialName => $pc{materialName});

      $pc{materialPriceNormal} = '';
    }
    else {
      $pc{materialPriceHigher} = '';
    }
  }

  $pc{materialPriceNormal} = commify $pc{materialPriceNormal} if $pc{materialPriceNormal};
  $pc{materialPriceHigher} = commify $pc{materialPriceHigher} if $pc{materialPriceHigher};

  $SHEET->param(materialPriceNormal => $pc{materialPriceNormal});
  $SHEET->param(materialPriceHigher => $pc{materialPriceHigher});
}
### 価格 --------------------------------------------------
{
  my $price;

  my @prices = (
      ['購入', $pc{price}],
      ['レンタル', $pc{priceRental}],
      ['部位再生', $pc{priceRegenerate}],
  );

  foreach (@prices) {
    (my $term, my $value) = @{$_};
    my $unit = $value =~ /\d$/ ? 'G' : '';
    $price .= "<dt>$term</dt><dd>$value<small>$unit</small></dd>" if $value;
  }

  if(!$price){ $price = '―' }
  $SHEET->param(price => "<dl class=\"price\">$price</dl>");
}
### 適正レベル --------------------------------------------------
my $appLv = $pc{lvMin}.($pc{lvMax} != $pc{lvMin} ? "～$pc{lvMax}":'');
{
  $SHEET->param(appLv => $appLv);
}
### 言語 --------------------------------------------------
if ($pc{individualization} && $pc{additionalLanguage}) {
  $pc{language} .= '、' if $pc{language};
  $pc{language} .= $pc{additionalLanguage};
  $SHEET->param(language => $pc{language});
}
### 生息地 --------------------------------------------------
if ($pc{individualization} && $pc{habitatReplacementEnabled}) {
  $pc{habitat} = $pc{habitatReplacement} || '';
  $SHEET->param(habitat => $pc{habitat});
}
### 穢れ --------------------------------------------------
$SHEET->param(sin => $pc{sin});
unless(
  ($pc{taxa} eq 'アンデッド' && ($pc{sin} == 5 || $pc{sin} eq '')) ||
  ($pc{taxa} ne '蛮族'       && ($pc{sin} == 0 || $pc{sin} eq ''))
){
  $SHEET->param(displaySin => 1);
}
### ステータス --------------------------------------------------
$SHEET->param(exclusiveMount => $pc{exclusiveMount});
$SHEET->param(ridingHpReinforcement => $pc{ridingHpReinforcement});
$SHEET->param(ridingHpReinforcementSuper => $pc{ridingHpReinforcementSuper});
$SHEET->param(ridingMountReinforcement => $pc{ridingMountReinforcement});
$SHEET->param(ridingMountReinforcementSuper => $pc{ridingMountReinforcementSuper});
if($pc{vitResist} ne ''){ $SHEET->param(vitResist => $pc{vitResist}.(!$pc{statusTextInput}?' ('.$pc{vitResistFix}.')':'')) }
if($pc{mndResist} ne ''){ $SHEET->param(mndResist => $pc{mndResist}.(!$pc{statusTextInput}?' ('.$pc{mndResistFix}.')':'')) }

my $corePartName = $pc{coreParts};
$corePartName =~ /[(（]すべて[）)]$/ if $corePartName;
my @status_tbody;
my @status_row;
foreach (1 .. $pc{statusNum}){
  unless ($pc{mount}) {
    $pc{'status'.$_.'Accuracy'} += $pc{'status'.$_.'AccuracyModification'} if $pc{'status'.$_.'Accuracy'} ne '' && $pc{'status'.$_.'AccuracyModification'};
    $pc{'status'.$_.'AccuracyFix'} += $pc{'status'.$_.'AccuracyModification'} if $pc{'status'.$_.'AccuracyFix'} && $pc{'status'.$_.'AccuracyModification'};
    $pc{'status'.$_.'Damage'} = addOffsetToDamage($pc{'status'.$_.'Damage'}, $pc{'status'.$_.'DamageModification'}) if $pc{'status'.$_.'Damage'} ne '' && $pc{'status'.$_.'DamageModification'};
    $pc{'status'.$_.'Evasion'} += $pc{'status'.$_.'EvasionModification'} if $pc{'status'.$_.'Evasion'} ne '' && $pc{'status'.$_.'EvasionModification'};
    $pc{'status'.$_.'EvasionFix'} += $pc{'status'.$_.'EvasionModification'} if $pc{'status'.$_.'EvasionFix'} && $pc{'status'.$_.'EvasionModification'};
    $pc{'status'.$_.'Defense'} += $pc{'status'.$_.'DefenseModification'} if $pc{'status'.$_.'Defense'} ne '' && $pc{'status'.$_.'DefenseModification'};
    $pc{'status'.$_.'Hp'} += $pc{'status'.$_.'HpModification'} if $pc{'status'.$_.'Hp'} ne '' && $pc{'status'.$_.'HpModification'};
    $pc{'status'.$_.'Mp'} += $pc{'status'.$_.'MpModification'} if $pc{'status'.$_.'Mp'} ne '' && $pc{'status'.$_.'MpModification'};
  }

  $pc{'status'.$_.'Accuracy'} += $pc{'partEquipment'.$_.'-weapon-accuracy'} if $pc{'status'.$_.'Accuracy'} ne '' && $pc{'partEquipment'.$_.'-weapon-accuracy'};
  $pc{'status'.$_.'Damage'} = addOffsetToDamage($pc{'status'.$_.'Damage'}, $pc{'partEquipment'.$_.'-weapon-damage'}) if $pc{'status'.$_.'Damage'} ne '' && $pc{'partEquipment'.$_.'-weapon-damage'};
  $pc{'status'.$_.'Evasion'} += $pc{'partEquipment'.$_.'-armor-evasion'} if $pc{'status'.$_.'Evasion'} ne '' && $pc{'partEquipment'.$_.'-armor-evasion'};
  $pc{'status'.$_.'Defense'} += $pc{'partEquipment'.$_.'-armor-defense'} if $pc{'status'.$_.'Defense'} ne '' && $pc{'partEquipment'.$_.'-armor-defense'};
  $pc{'status'.$_.'Hp'} += $pc{'partEquipment'.$_.'-armor-hp'} if $pc{'status'.$_.'Hp'} ne '' && $pc{'partEquipment'.$_.'-armor-hp'};
  $pc{'status'.$_.'Mp'} += $pc{'partEquipment'.$_.'-armor-mp'} if $pc{'status'.$_.'Mp'} ne '' && $pc{'partEquipment'.$_.'-armor-mp'};

  $pc{'status'.$_.'Hp'} += $pc{'swordFragment_hpOffset_part' . $_} if $pc{swordFragmentNum} > 0 && $pc{'swordFragment_hpOffset_part' . $_};
  $pc{'status'.$_.'Mp'} += $pc{'swordFragment_mpOffset_part' . $_} if $pc{swordFragmentNum} > 0 && $pc{'swordFragment_mpOffset_part' . $_};

  $pc{'status'.$_.'Damage'} = '―' if $pc{'status'.$_.'Damage'} eq '2d+' && ($pc{'status'.$_.'Accuracy'} eq '' || $pc{'status'.$_.'Accuracy'} eq '―');

  if ($pc{golem} && $pc{individualization}) {
    my $offset;
    if ($pc{reinforcementItemGrade} eq '小') {
      $offset = 5;
    } elsif ($pc{reinforcementItemGrade} eq '中') {
      $offset = 10;
    } elsif ($pc{reinforcementItemGrade} eq '大') {
      $offset = 15;
    } elsif ($pc{reinforcementItemGrade} eq '極大') {
      $offset = 20;
    } else {
      $offset = 0;
    }

    $pc{'status'.$_.'Hp'} += $offset if $pc{"golemReinforcement_garnetEnergy_part${_}_using"};
    $pc{'status'.$_.'Hp'} += $offset if $pc{"golemReinforcement_garnetLife_part${_}_using"};
  }

  if ($pc{'status'.$_.'Accuracy'} ne ''){ $pc{'status'.$_.'Accuracy'} = $pc{'status'.$_.'Accuracy'}.(!$pc{statusTextInput} && !$pc{mount}?' ('.$pc{'status'.$_.'AccuracyFix'}.')':'') }
  if ($pc{'status'.$_.'Evasion'}  ne ''){ $pc{'status'.$_.'Evasion'}  = $pc{'status'.$_.'Evasion'} .(!$pc{statusTextInput} && !$pc{mount}?' ('.$pc{'status'.$_.'EvasionFix'}.')' :'') }
# $pc{'status'.$_.'Damage'}   = $pc{'status'.$_.'Damage'}   eq '' ? '―' : $pc{'status'.$_.'Damage'} ;
# $pc{'status'.$_.'Defense'}  = $pc{'status'.$_.'Defense'}  eq '' ? '―' : $pc{'status'.$_.'Defense'};
# $pc{'status'.$_.'Hp'}       = $pc{'status'.$_.'Hp'}       eq '' ? '―' : $pc{'status'.$_.'Hp'}     ;
# $pc{'status'.$_.'Mp'}       = $pc{'status'.$_.'Mp'}       eq '' ? '―' : $pc{'status'.$_.'Mp'}     ;
# $pc{'status'.$_.'Vit'}      = $pc{'status'.$_.'Vit'}      eq '' ? '―' : $pc{'status'.$_.'Vit'}    ;
# $pc{'status'.$_.'Mnd'}      = $pc{'status'.$_.'Mnd'}      eq '' ? '―' : $pc{'status'.$_.'Mnd'}    ;

  if ($pc{'status' . $_ . 'Hp'} ne '―') {
    $pc{'status' . $_ . 'Hp'} += 10 if $pc{'ridingHpReinforcement'};
    $pc{'status' . $_ . 'Hp'} += 5 if $pc{'ridingHpReinforcement'};
    $pc{'status' . $_ . 'Hp'} += 5 if $pc{'ridingHpReinforcementSuper'};
  }

  my $partName = $pc{'status' . $_ . 'Style'};
  if ($partName) {
    $partName =~ s/\(/（/g;
    $partName =~ s/\)/）/g;
  }

  if ($pc{'status' . $_ . 'Accuracy'} ne '―' && index($partName, $corePartName) >= 0) {
    $pc{'status' . $_ . 'Accuracy'} += 1 if $pc{'ridingMountReinforcement'};
    $pc{'status' . $_ . 'Accuracy'} += 1 if $pc{'ridingMountReinforcementSuper'};
  }

  if ($pc{'status' . $_ . 'Evasion'} ne '―' && index($partName, $corePartName) >= 0) {
    $pc{'status' . $_ . 'Evasion'} += 1 if $pc{'ridingMountReinforcement'};
    $pc{'status' . $_ . 'Evasion'} += 1 if $pc{'ridingMountReinforcementSuper'};
  }

  push(@status_row, {
    LV       => $pc{lvMin},
    STYLE    => $pc{'status'.$_.'Style'},
    ACCURACY => $pc{'status'.$_.'Accuracy'} // '―',
    DAMAGE   => $pc{'status'.$_.'Damage'  } // '―',
    EVASION  => $pc{'status'.$_.'Evasion' } // '―',
    DEFENSE  => $pc{'status'.$_.'Defense' } // '―',
    HP       => $pc{'status'.$_.'Hp'      } // '―',
    MP       => $pc{'status'.$_.'Mp'      } // '―',
    VIT      => $pc{'status'.$_.'Vit'     } // '―',
    MND      => $pc{'status'.$_.'Mnd'     } // '―',
  } );
}
push(@status_tbody, { "ROW" => \@status_row }) if !$pc{mount} || $pc{lv} eq '' || $pc{lvMin} == $pc{lv};
foreach my $lv (2 .. ($pc{lvMax}-$pc{lvMin}+1)){
  my @status_row;
  foreach (1 .. $pc{statusNum}){
    my $num = "$_-$lv";

    $pc{'status'.$num.'Accuracy'} += $pc{'partEquipment'.$_.'-weapon-accuracy'} if $pc{'status'.$num.'Accuracy'} ne '' && $pc{'partEquipment'.$_.'-weapon-accuracy'};
    $pc{'status'.$num.'Damage'} = addOffsetToDamage($pc{'status'.$num.'Damage'}, $pc{'partEquipment'.$_.'-weapon-damage'}) if $pc{'status'.$num.'Damage'} ne '' && $pc{'partEquipment'.$_.'-weapon-damage'};
    $pc{'status'.$num.'Evasion'} += $pc{'partEquipment'.$_.'-armor-evasion'} if $pc{'status'.$num.'Evasion'} ne '' && $pc{'partEquipment'.$_.'-armor-evasion'};
    $pc{'status'.$num.'Defense'} += $pc{'partEquipment'.$_.'-armor-defense'} if $pc{'status'.$num.'Defense'} ne '' && $pc{'partEquipment'.$_.'-armor-defense'};
    $pc{'status'.$num.'Hp'} += $pc{'partEquipment'.$_.'-armor-hp'} if $pc{'status'.$num.'Hp'} ne '' && $pc{'partEquipment'.$_.'-armor-hp'};
    $pc{'status'.$num.'Mp'} += $pc{'partEquipment'.$_.'-armor-mp'} if $pc{'status'.$num.'Mp'} ne '' && $pc{'partEquipment'.$_.'-armor-mp'};

    $pc{'status'.$num.'Damage'} = '―' if $pc{'status'.$num.'Damage'} eq '2d+' && ($pc{'status'.$num.'Accuracy'} eq '' || $pc{'status'.$num.'Accuracy'} eq '―');

#   $pc{'status'.$num.'Accuracy'} = $pc{'status'.$num.'Accuracy'} eq '' ? '―' : $pc{'status'.$num.'Accuracy'};
#   $pc{'status'.$num.'Evasion'}  = $pc{'status'.$num.'Evasion'}  eq '' ? '―' : $pc{'status'.$num.'Evasion'} ;
#   $pc{'status'.$num.'Damage'}   = $pc{'status'.$num.'Damage'}   eq '' ? '―' : $pc{'status'.$num.'Damage'}  ;
#   $pc{'status'.$num.'Defense'}  = $pc{'status'.$num.'Defense'}  eq '' ? '―' : $pc{'status'.$num.'Defense'} ;
#   $pc{'status'.$num.'Hp'}       = $pc{'status'.$num.'Hp'}       eq '' ? '―' : $pc{'status'.$num.'Hp'}      ;
#   $pc{'status'.$num.'Mp'}       = $pc{'status'.$num.'Mp'}       eq '' ? '―' : $pc{'status'.$num.'Mp'}      ;
#   $pc{'status'.$num.'Vit'}      = $pc{'status'.$num.'Vit'}      eq '' ? '―' : $pc{'status'.$num.'Vit'}     ;
#   $pc{'status'.$num.'Mnd'}      = $pc{'status'.$num.'Mnd'}      eq '' ? '―' : $pc{'status'.$num.'Mnd'}     ;

    if ($pc{'status' . $num . 'Hp'} ne '―') {
      $pc{'status' . $num . 'Hp'} += 10 if $pc{'ridingHpReinforcement'};
      $pc{'status' . $num . 'Hp'} += 5 if $pc{'ridingHpReinforcement'};
      $pc{'status' . $num . 'Hp'} += 5 if $pc{'ridingHpReinforcementSuper'};
    }

    my $partName = $pc{'status' . $_ . 'Style'};
    if ($partName) {
      $partName =~ s/\(/（/g;
      $partName =~ s/\)/）/g;
    }

    if ($pc{'status' . $num . 'Accuracy'} ne '―' && index($partName, $corePartName) >= 0) {
      $pc{'status' . $num . 'Accuracy'} += 1 if $pc{'ridingMountReinforcement'};
      $pc{'status' . $num . 'Accuracy'} += 1 if $pc{'ridingMountReinforcementSuper'};
    }

    if ($pc{'status' . $num . 'Evasion'} ne '―' && index($partName, $corePartName) >= 0) {
      $pc{'status' . $num . 'Evasion'} += 1 if $pc{'ridingMountReinforcement'};
      $pc{'status' . $num . 'Evasion'} += 1 if $pc{'ridingMountReinforcementSuper'};
    }

    push(@status_row, {
      LV       => $lv+$pc{lvMin}-1,
      STYLE    => $pc{'status'.$_.'Style'},
      ACCURACY => $pc{'status'.$num.'Accuracy'} // '―',
      DAMAGE   => $pc{'status'.$num.'Damage'  } // '―',
      EVASION  => $pc{'status'.$num.'Evasion' } // '―',
      DEFENSE  => $pc{'status'.$num.'Defense' } // '―',
      HP       => $pc{'status'.$num.'Hp'      } // '―',
      MP       => $pc{'status'.$num.'Mp'      } // '―',
      VIT      => $pc{'status'.$num.'Vit'     } // '―',
      MND      => $pc{'status'.$num.'Mnd'     } // '―',
    } );
  }
  push(@status_tbody, { ROW => \@status_row }) if !$pc{mount} || $pc{lv} eq '' || $lv+$pc{lvMin}-1 == $pc{lv};
}
$SHEET->param(Status => \@status_tbody);

### 部位 --------------------------------------------------
$SHEET->param(partsOn => 1) if ($pc{partsNum} > 1 || $pc{parts} || $pc{coreParts});

### ゴーレム強化アイテム --------------------------------------------------
if ($pc{golem}) {
  require $set::data_mons;

  my @allItems = data::getGolemReinforcementItems($::SW2_0 ? '2.0' : '2.5');
  my $grade = $pc{reinforcementItemGrade};
  my %itemsByPart = ('任意部位' => []);
  my @partNames = ('任意部位');

  if ($pc{parts} ne '') {
    for my $partName (split(/[\/／]/, $pc{parts})) {
      next if $partName eq '';
      $partName =~ s/×\d+$//;
      push(@partNames, $partName);
    }

    push(@partNames, '全部位必須');
  }

  for my $itemAddress (@allItems) {
    my %itemDefinition = %{$itemAddress};

    next if !$pc{"golemReinforcement_$itemDefinition{fieldName}_supported"};

    my $price = $pc{"golemReinforcement_$itemDefinition{fieldName}_price"};

    my %abilitySuffixes = $itemDefinition{abilitySuffixes} ? %{$itemDefinition{abilitySuffixes}} : ();
    my $abilitySuffix = $abilitySuffixes{$grade} || '';

    my %itemState = (
        name    => "$itemDefinition{name}($grade)",
        price   => commify($price),
        ability => $itemDefinition{ability} . $abilitySuffix,
    );

    if ($itemDefinition{prerequisiteItem}) {
      $itemState{'hasPrerequisiteItem'} = 1;
    }

    if ($itemDefinition{additionalField} eq '詳細') {
      delete($itemState{ability});
      $itemState{abilityDetails} = $pc{"golemReinforcement_$itemDefinition{fieldName}_details"};
      $itemState{abilityDetails} =~ s/<br>/\n/gi;
      if($::SW2_0){
        $itemState{abilityDetails} =~ s/^((?:[○◯〇＞▶〆☆≫»□☐☑🗨▽▼]|&gt;&gt;)+.*?)(　|$)/"<\/p><h5>".&textToIcon($1)."<\/h5><p>".$2;/egim;
      } else {
        $itemState{abilityDetails} =~ s/^((?:[○◯〇△＞▶〆☆≫»□☐☑🗨]|&gt;&gt;)+.*?)(　|$)/"<\/p><h5>".&textToIcon($1)."<\/h5><p>".$2;/egim;
      }
      $itemState{abilityDetails} =~ s#(</h5><p>)\n#$1#i;
      $itemState{abilityDetails} =~ s#\n#</p><p>#;
      $itemState{abilityDetails} =~ s#^\s*</p>##mi;
      $itemState{abilityDetails} .= '</p>' if $itemState{abilityDetails} !~ /\s*<\/p>\s*$/mi;
    } elsif ($itemDefinition{additionalField} eq '打撃点') {
      $itemState{abilityDetails} = '次手番必中、' if $itemState{ability} =~ /振りかぶる/;
      $itemState{abilityDetails} .= '打撃点＋' . $pc{"golemReinforcement_$itemDefinition{fieldName}_damageOffset"};
    } elsif ($itemDefinition{additionalField} eq '地上移動速度') {
      $itemState{abilityDetails} = '地上移動速度：' . $pc{"golemReinforcement_$itemDefinition{fieldName}_landMobility"};
    }

    my $targetPart;
    my $partCount = @partNames;
    if ($partCount == 1) {
      $targetPart = $partNames[0];
    } elsif ($itemDefinition{requirementAllParts}) {
      $targetPart = '全部位必須';
    } else {
      $targetPart = $pc{"golemReinforcement_$itemDefinition{fieldName}_partRestriction"};
      $targetPart =~ s/のみ$//;
      $targetPart = '任意部位' if $targetPart eq '';
    }

    {
      $itemsByPart{$targetPart} = [] if !defined($itemsByPart{$targetPart});
      my @a = @{$itemsByPart{$targetPart}};
      push(@a, \%itemState);
      $itemsByPart{$targetPart} = \@a;
    }
  }

  my @expectedItems = ();
  for my $partName (@partNames) {
    next if !$itemsByPart{$partName};
    push(@expectedItems, {PartName => $partName, Items => $itemsByPart{$partName}});
  }

  $SHEET->param(golemReinforcementItems => \@expectedItems);
}
my @lootsByGolemReinforcement = ();
if ($pc{golem} && $pc{individualization}) {
  my @partNames = ();

  if ($pc{parts} ne '') {
    for my $partName (split(/[\/／]/, $pc{parts})) {
      next if $partName eq '';
      $partName =~ s/×(\d+)$//;
      my $count = $1;
      if ($count && $count > 1) {
        foreach (('A' .. 'Z')[0 .. ($count - 1)]) {
          push(@partNames, $partName . $_);
        }
      }
      else {
        push(@partNames, $partName);
      }
    }
  }
  else {
    push(@partNames, '');
  }

  my @allItems = data::getGolemReinforcementItems($::SW2_0 ? '2.0' : '2.5');

  if ($pc{reinforcementItemGrade}) {
    foreach (0 .. $#allItems) {
      my %item = %{$allItems[$_]};
      $item{name} .= "($pc{reinforcementItemGrade})";
      $allItems[$_] = \%item;
    }
  }

  my @parts = ();
  my $mobilityEnhancement = undef;

  for my $index (1 .. ($#partNames + 1 + 1)) {
    my @partItems = ();

    for my $itemAddress (@allItems) {
      my %item = %{$itemAddress};
      my $partSuffix = $index <= $#partNames + 1 ? $index : 'All';
      my $key = "golemReinforcement_$item{fieldName}_part${partSuffix}_using";
      my $isUsing = $pc{$key} eq 'on';
      next unless $isUsing;

      if ($item{name} =~ /^月長石の安らぎ/) {
        $item{ability} .= textToIcon('に変更、「○＊＊に弱い」除去') if $pc{skillsRaw} =~ /^[○◯〇][^\n<>&]+に弱い/;

        $pc{'reputation+'} = '―';
        $SHEET->param('reputation+' => $pc{'reputation+'});

        $pc{weakness} = 'なし';
        $SHEET->param(weakness => $pc{weakness});
      }
      elsif ($item{name} =~ /^異方の菫青石/) {
        if ($pc{golemReinforcement_cordierite_landMobility}) {
          $pc{mobility} =~ s/^\s*(?:[-‐－―ー]\s*([\/／]))?/$pc{golemReinforcement_cordierite_landMobility}$1/;
          $SHEET->param(mobility => $pc{mobility});
        }
      }
      elsif ($item{abilityRaw} eq '◯移動力強化') {
        $mobilityEnhancement = 5;
      }
      elsif ($item{abilityRaw} eq '◯属性耐性') {
        $item{ability} .= "＝" . $pc{golemReinforcement_quartzDisruption_attribute} if $pc{golemReinforcement_quartzDisruption_attribute};
      }

      push(@partItems, \%item);
      push(@lootsByGolemReinforcement, \%item);
    }

    # ○移動力強化
    if (defined($mobilityEnhancement)) {
      $pc{mobility} =~ s/(\d+)/$1 + $mobilityEnhancement/eg;
      $SHEET->param(mobility => $pc{mobility});
    }

    my %part = (partName => $index <= $#partNames + 1 ? $partNames[$index - 1] : '全部位必須');
    next if !@partItems && $part{partName} eq '全部位必須';

    $part{items} = \@partItems;

    push(@parts, \%part);
  }

  $SHEET->param(golemReinforceItemByParts => \@parts);
}

### 騎獣用武装 --------------------------------------------------
if ($pc{mount} && $pc{individualization}) {
  my @mountEquipments = ();

  foreach (1 .. $pc{statusNum}) {
    my $partName = $pc{'status' . $_ . 'Style'};
    $partName =~ s/^.+[(（]\s*(.+?)\s*[）)]\s*$/$1/;

    my $weaponName = $pc{'partEquipment' . $_ . '-weapon-name'} || '';
    my $weaponAccuracy = formatMountEquipmentOffset($pc{'partEquipment' . $_ . '-weapon-accuracy'} || 0);
    my $weaponDamage = formatMountEquipmentOffset($pc{'partEquipment' . $_ . '-weapon-damage'} || 0);
    my $hasWeapon = $weaponName || $weaponAccuracy || $weaponDamage ? 1 : 0;

    my $armorName = $pc{'partEquipment' . $_ . '-armor-name'} || '';
    my $armorEvasion = formatMountEquipmentOffset($pc{'partEquipment' . $_ . '-armor-evasion'} || 0);
    my $armorDefense = formatMountEquipmentOffset($pc{'partEquipment' . $_ . '-armor-defense'} || 0);
    my $armorHp = formatMountEquipmentOffset($pc{'partEquipment' . $_ . '-armor-hp'} || 0);
    my $armorMp = formatMountEquipmentOffset($pc{'partEquipment' . $_ . '-armor-mp'} || 0);
    my $hasArmor = $armorName || $armorEvasion || $armorDefense || $armorHp || $armorMp ? 1 : 0;

    push(@mountEquipments, {
        hasEquipment   => $hasWeapon || $hasArmor,
        partName       => $partName,
        hasWeapon      => $hasWeapon,
        weaponName     => $weaponName,
        weaponAccuracy => $weaponAccuracy,
        weaponDamage   => $weaponDamage,
        hasArmor       => $hasArmor,
        armorName      => $armorName,
        armorEvasion   => $armorEvasion,
        armorDefense   => $armorDefense,
        armorHp        => $armorHp,
        armorMp        => $armorMp,
    });
  }

  $SHEET->param(mountEquipments => \@mountEquipments);
}
sub formatMountEquipmentOffset {
  my $value = shift;
  return $value if !$value;
  return ($value > 0 ? '+' : '') . $value;
}

# 特殊能力関連の騎芸が不要なら非表示にする
$SHEET->param(ridingMagicIndication => 0) unless $pc{skills} =~ /魔法指示/;
$SHEET->param(ridingUnlockSpecialSkills => 0) unless $pc{skills} =~ /特殊能力解放/;
$SHEET->param(ridingUnlockSpecialSkillsFully => 0) unless $pc{skills} =~ /特殊能力完全解放/;

### 戦利品 --------------------------------------------------
my @loots;
if ($pc{individualization}) {
  push(@loots, {NUM => '自動', ITEM => "〈剣のかけら〉×$pc{swordFragmentNum}"}) if $pc{swordFragmentNum} > 0;

  if ($pc{golem} && $#lootsByGolemReinforcement >= 0) {
    foreach (@lootsByGolemReinforcement) {
      my %item = %{$_};
      $item{name} =~ /\((小|中|大|極大)\)$/;
      my $grade = $1;
      my %prices = %{$item{prices}};
      my $price = commify($prices{$grade} / 2);
      my $text = "〈$item{name}〉（売却価格${price}Ｇ／－）";
      push(@loots, {NUM => 'ゴーレム強化アイテム', ITEM => $text});
    }
  }

  if ($pc{additionalLootsNum} > 0) {
    foreach (1 .. $pc{additionalLootsNum}) {
      my $loot = $pc{'additionalLoots' . $_ . 'Item'};
      next unless $loot;
      push(@loots, {'NUM' => '自動', 'ITEM' => $loot});
    }
  }
}
foreach (1 .. $pc{lootsNum}){
  next if !$pc{'loots'.$_.'Num'} && !$pc{'loots'.$_.'Item'};
  push(@loots, {
    NUM  => $pc{'loots'.$_.'Num'},
    ITEM => $pc{'loots'.$_.'Item'},
  } );
}
@loots = () if $pc{individualization} && $pc{disableLoots};
$SHEET->param(Loots => \@loots);

### 魔神行動表 --------------------------------------------------
my $isDemon = $pc{taxa} eq '魔神';
my $isDemonActions = $isDemon && $pc{enableDemonActions} && $::in{demon_action};
if ($isDemonActions) {
  $SHEET->param(isDemonActions => 1);
  $SHEET->param(monsterUrl => './?id=' . $::in{id});
  $SHEET->param(jsonUrl => './?id=' . $::in{id} . '&mode=json&demon_action=1');
  $SHEET->param(paletteUrl => './?id=' . $::in{id} . '&mode=palette&demon_action=1');

  $SHEET->param(demonSummoningMp => $pc{lv} ? $pc{lv} * 2 : '');
  $SHEET->param(demonCancellationCost => $pc{lv} ? $pc{lv} : '');
  $SHEET->param(demonSummoningOfferingPrice => commify $pc{demonSummoningOfferingPrice}) if $pc{demonSummoningOfferingPrice};
  $SHEET->param(demonDeportationOfferingPrice => commify $pc{demonDeportationOfferingPrice}) if $pc{demonDeportationOfferingPrice};

  my $explanation = '';
  if ($pc{demonActionExplanation}) {
    foreach (split '<br>', $pc{demonActionExplanation}) {
      next if $_ =~ /^\s*$/;

      if ($_ =~ s/^\*\s*(.+?)$//) {
        my $headline = $1;
        my $reference;
        if ($headline =~ s/\s*[(（]\s*(?:⇒|=&gt;)\s*(.+?)\s*[）)]\s*$//) {
          $reference = $1;
        }

        $explanation .= '</section>' if $explanation =~ /<section>/;
        $explanation .= "<section><h4>$headline</h4>";
        $explanation .= "<i class='reference'>$reference</i>" if $reference;
      }
      else {
        $explanation .= "<p>$_</p>";
      }
    }

    $explanation .= '</section>' if $explanation =~ /<section>/;
  }
  $SHEET->param(demonActionExplanation => $explanation);
}

### バックアップ --------------------------------------------------
if($::in{id}){
  my($selected, $list) = getLogList($set::char_dir, $main::file);
  $SHEET->param(LogList => $list);
  $SHEET->param(selectedLogName => $selected);
  if($pc{yourAuthor} || $pc{protect} eq 'password'){
    $SHEET->param(viewLogNaming => 1);
  }
}

### タイトル --------------------------------------------------
$SHEET->param(title => $set::title);
if($pc{forbidden} eq 'all' && $pc{forbiddenMode}){
  $SHEET->param(titleName => "非公開データ - $set::title");
}
else {
  my $name    = removeTags nameToPlain($pc{characterName});
  my $species = removeTags nameToPlain($pc{monsterName});
  if($name && $species){ $SHEET->param(titleName => "${name}（${species}）"); }
  else { $SHEET->param(titleName => $name || $species); }
}

### OGP --------------------------------------------------
$SHEET->param(ogUrl => url().($::in{url} ? "?url=$::in{url}" : "?id=$::in{id}"));
#if($pc{image}) { $SHEET->param(ogImg => url()."/".$imgsrc); }
$SHEET->param(ogDescript => removeTags(
  ($pc{mount} && $pc{lv} eq '' ? "適正レベル:$appLv" : "レベル:$pc{lv}").
  "　分類:$pc{taxa}".
  ($pc{partsNum} > 1 ? "　部位数:$pc{partsNum}" : '').
  (!$pc{mount} ? "　知名度:$pc{reputation}／$pc{'reputation+'}" : '')
));

### バージョン等 --------------------------------------------------
$SHEET->param(ver => $::ver);
$SHEET->param(coreDir => $::core_dir);
$SHEET->param(gameDir => 'sw2');
$SHEET->param(sheetType => 'monster');
$SHEET->param(generateType => 'SwordWorld2Enemy');
$SHEET->param(defaultImage => $::core_dir.'/skin/sw2/img/default_enemy.png');

### メニュー --------------------------------------------------
my @menu = ();
if(!$pc{modeDownload}){
  push(@menu, { TEXT => '⏎', TYPE => "href", VALUE => './?type=m', });
  if($::in{url}){
    push(@menu, { TEXT => 'コンバート', TYPE => "href", VALUE => "./?mode=convert&url=$::in{url}" });
  }
  else {
    if($pc{logId}){
      push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => 'loglistOn()', });
      if($pc{reqdPassword}){ push(@menu, { TEXT => '復元', TYPE => "onclick", VALUE => "editOn()", }); }
      else                 { push(@menu, { TEXT => '復元', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}&log=$pc{logId}", }); }
    }
    else {
      if(!$pc{forbiddenMode}){
        if ($isDemon && $pc{enableDemonActions} && !$isDemonActions) {
          push(@menu, { TEXT => '魔神<br>行動表', TYPE => "href", VALUE => './?id=' . $::in{id} . '&demon_action=1',});
        }
        push(@menu, { TEXT => 'パレット', TYPE => "onclick", VALUE => "chatPaletteOn()",   });
        push(@menu, { TEXT => '出力'    , TYPE => "onclick", VALUE => "downloadListOn()",  }) unless $isDemonActions;
        push(@menu, { TEXT => '過去ログ', TYPE => "onclick", VALUE => "loglistOn()",      });
      }
      if($pc{reqdPassword}){ push(@menu, { TEXT => '編集', TYPE => "onclick", VALUE => "editOn()", }); }
      else                 { push(@menu, { TEXT => '編集', TYPE => "href"   , VALUE => "./?mode=edit&id=$::in{id}", }); }
    }
  }
}
$SHEET->param(Menu => sheetMenuCreate @menu);

### エラー --------------------------------------------------
$SHEET->param(error => $main::login_error);

### 出力 #############################################################################################
print "Access-Control-Allow-Origin: *\n";
print "Access-Control-Allow-Methods: GET\n";
print "Content-Type: text/html\n\n";
if($pc{modeDownload}){
  if($pc{forbidden} && $pc{yourAuthor}){ $SHEET->param(forbidden => ''); }
  print downloadModeSheetConvert $SHEET->output;
}
else {
  print $SHEET->output;
}

1;