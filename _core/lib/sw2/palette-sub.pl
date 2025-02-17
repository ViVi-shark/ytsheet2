################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

require $set::data_class;
require $set::data_items;
my @classNames;
foreach(@data::class_names){
  push(@classNames, $_);
  if($_ eq 'コンジャラー'){ push(@classNames, 'ウィザード'); }
}

### 魔法威力 #########################################################################################
my %pows = (
  Sor => {
    10  =>  1,
    20  =>  3,
    30  =>  5,
    40  =>  8,
    50  => 11,
    60  => 14,
    100 => 15,
  },
  Con => {
    0   =>  1,
    10  =>  7,
    20  =>  8,
    30  =>  9,
    60  => 15,
  },
  Wiz => {
    10  =>  7,
    20  =>  4,
    30  =>  9,
    70  => 13,
  },
  Pri => {
    10  =>  3,
    20  =>  5,
    30  =>  9,
    50  => 11,
  },
  Mag => {
    30  =>  5,
    90  => 15,
  },
  Fai => {
    10  =>  2,
    20  =>  5,
    30  =>  4,
    40  => 10,
    50  => 11,
    60  => 14,
    80  => 10
  },
  Dru => {
    10  =>  4,
    20  =>  4,
    30  => 12,
    50  => 15,
  },
  Dem => {
    10  =>  3,
    20  =>  2,
    30  => 15,
    40  =>  9,
    70  => 14,
  },
  Aby => {
    0   =>  1,
    10  =>  3,
    20  =>  0,
    30  =>  7,
    40  =>  9,
    50  => 13,
    60  => 11,
    70  => 13,
  },
  Gri => {
    10  =>  1,
    20  =>  1,
    30  =>  4,
    40  =>  7,
    50  =>  7,
    60  => 10,
    80  => 13,
    100 => 13,
  },
  Bar => {
    10  => '終律：春の強風|終律：冬の寒風',
    20  => '終律：獣の咆哮|終律：蛇穴の苦鳴',
    30  => '終律：火竜の舞|終律：水竜の轟',
  },
  Dar => {
    20  => '破邪光弾',
    40  => '破邪光弾',
    30  => '破邪光槍',
    60  => '破邪光槍',
  },
);
if($::SW2_0){
  $pows{Dem} = {
    10  =>  1,
    20  =>  1,
    30  =>  5,
    40  =>  5,
    50  =>  5,
  };
}

my %heals = (
  Con => {
    0   =>  2,
    30  => 11,
  },
  Pri => {
    10  =>  2,
    30  =>  5,
    50  => 10,
    70  => 13,
  },
  Aby => {
    0   =>  2,
    20  =>  6,
    40  =>  6,
    70  => 10,
  },
  Gri => {
    20  =>  1,
    40  =>  7,
    100 => 13,
  },
  Bar => {
    0   => '終律：秋の実り',
    10  => '終律：華の宴',
    20  => '終律：夏の生命|終律：蒼月の光',
    30  => '終律：草原の息吹',
    40  => '終律：白日の暖',
  },
);

my @gunPowers = (
  { lv =>  1, p => 20, c => '' },
  { lv =>  2, p => 20, c => -1 },
  { lv =>  6, p => 30, c => '' },
  { lv =>  7, p => 10, c => '' },
  { lv =>  9, p => 30, c => -1 },
  { lv => 12, p => 40, c => '', h => '2H' },
  { lv => 15, p => 70, c => '', h => '2H' },
);
my @gunHeals = (
  { lv =>  2, p =>  0 },
  { lv => 10, p => 30 },
  { lv => 13, p => 20, h => '2H' },
);

my $skillMarkRE = "\\[[常準主補宣]\\]|[○◯〇△＞▶〆☆≫»□☑🗨]|&gt;&gt;";

sub normalizeCrit {
  my $crit = shift;
  $crit =~ s/⑦|➆/7/;
  $crit =~ s/⑧|➇/8/;
  $crit =~ s/⑨|➈/9/;
  $crit =~ s/⑩|➉/10/;
  $crit =~ s/⑪/11/;
  $crit =~ s/⑫/12/;
  $crit =~ s/⑬/13/;
  return $crit;
}
sub appendPaletteInsert {
  my $position = shift;
  my $text;
  foreach (1 .. $::pc{chatPaletteInsertNum}) {
    if($::pc{"chatPaletteInsert${_}Position"} eq $position){
      $text .= $::pc{"chatPaletteInsert$_"} =~ s/<br>/\n/gr;;
      $text .= "\n" if $::pc{"chatPaletteInsert$_"};
    }
  }
  return $text;
}

### プリセット #######################################################################################
sub palettePreset {
  my $tool = shift;
  my $type = shift;
  my $text;
  my %bot;
  if   (!$tool)           { $bot{YTC} = 1; }
  elsif($tool eq 'tekey' ){ $bot{TKY} = $bot{BCD} = 1; }
  elsif($tool eq 'bcdice'){ $bot{BCD} = 1; }
  ## ＰＣ
  if(!$type){
    $text .= appendPaletteInsert('');
    $text .= "//行為判定修正=0\n";
    $text .= "//行動判定修正=0\n";
    # 基本判定
    $text .= "### ■非戦闘系\n";
    foreach my $statusName ('器用', '敏捷', '筋力', '生命', '知力') {
      $text .= "2d+{冒険者}+{${statusName}B}+{行為判定修正}+{行動判定修正} 冒険者＋${statusName}\n";
    }
    foreach my $class (@classNames){
      my $c_id = $data::class{$class}{id};
      next if !$data::class{$class}{package} || !$::pc{'lv'.$c_id};
      my %data = %{$data::class{$class}{package}};
      foreach my $p_id (sort{$data{$a}{stt} cmp $data{$b}{stt} || $data{$a} cmp $data{$b}} keys %data){
        my $name = $class.$data{$p_id}{name};
        $text .= "2d+{$name}+{行為判定修正}+{行動判定修正} $name\n";
        if($data{$p_id}{monsterLore} && $::pc{monsterLoreAdd}){ $text .= "2d+{$name}+$::pc{monsterLoreAdd}+{行為判定修正}+{行動判定修正} 魔物知識\n"; }
        my $initiativeModifiers = makeStatesExpression(\%::pc, '先制判定');
        if($data{$p_id}{initiative } && ($::pc{initiativeAdd} || $initiativeModifiers)){ $text .= "2d+{$name}+$::pc{initiativeAdd }${initiativeModifiers}+{行為判定修正}+{行動判定修正} 先制\n"; }
      }
    }
    $text .= "\n";
    $text .= appendPaletteInsert('general');

    foreach (1 .. $::pc{commonClassNum}){
      next if !$::pc{"commonClass$_"};
      my $name = removeTags unescapeTags $::pc{'commonClass'.$_};
      $name =~ s/[(（].+?[）)]$//;
      $text .= "2d+{$name}+{器用B}+{行為判定修正}+{行動判定修正} ${name}＋器用\n" if $::pc{"paletteCommonClass${_}Dex"};
      $text .= "2d+{$name}+{敏捷B}+{行為判定修正}+{行動判定修正} ${name}＋敏捷\n" if $::pc{"paletteCommonClass${_}Agi"};
      $text .= "2d+{$name}+{筋力B}+{行為判定修正}+{行動判定修正} ${name}＋筋力\n" if $::pc{"paletteCommonClass${_}Str"};
      $text .= "2d+{$name}+{生命B}+{行為判定修正}+{行動判定修正} ${name}＋生命\n" if $::pc{"paletteCommonClass${_}Vit"};
      $text .= "2d+{$name}+{知力B}+{行為判定修正}+{行動判定修正} ${name}＋知力\n" if $::pc{"paletteCommonClass${_}Int"};
      $text .= "2d+{$name}+{精神B}+{行為判定修正}+{行動判定修正} ${name}＋精神\n" if $::pc{"paletteCommonClass${_}Mnd"};
    }
    $text .= "\n";
    $text .= appendPaletteInsert('common');

    # バフ・デバフ
    $text .= "### バフ・デバフ\n";
    foreach (@{getAvailableStates(\%::pc)}) {
      my %state = %{$_};
      my $stateName = $state{name};
      my $defaultValue = $state{defaultValue};
      $text .= "//${stateName}=${defaultValue}\n";
    }
    $text .= "###\n";

    # 練技
    if ($::pc{lvEnh} > 0) {
      $text .= "### ■練技\n";

      my @namesOf30secs = ();
      my @namesOf10secs = ();
      my %costCountOf30secs = ();
      my %costCountOf10secs = ();

      foreach (1 .. $::pc{lvEnh}) {
        my $craftName = $::pc{"craftEnhance${_}"};
        next unless $craftName;

        my $craft = data::getEnhancerCraft($craftName);
        $craftName = "【${craftName}】";

        my $cost = 3; # 消費ＭＰの既定値は 3
        my $costReduction = $::pc{lvSag} >= 9 ? 1 : 0; # 《マナセーブ》

        if (ref $craft) {
          my %craft = %{$craft};
          my $duration = $craft{duration};
          $cost = $craft{cost} if defined($craft{cost}); # 明示的な消費ＭＰの指定があれば反映する（超越者向けの練技用）
          $cost -= $costReduction;

          if (!$craft{no_grouping}) {
            if ($duration eq '30秒') {
              push(@namesOf30secs, $craftName);
              $costCountOf30secs{$cost} += 1;
            }

            if ($duration eq '10秒') {
              push(@namesOf10secs, $craftName);
              $costCountOf10secs{$cost} += 1;
            }
          }
        }
        else {
          $cost -= $costReduction;
        }

        my $otherStatusManipulation = '';

        if ($craftName eq '【リカバリィ】') {
          $otherStatusManipulation .= 'HP+{エンハンサー}';
          $otherStatusManipulation .= '+{生命B}' if grep { /スマルティエの武道帯/ } getAvailableAccessoryNames(\%::pc);
        }

        $text .= "\@MP-${cost}";
        $text .= " ${otherStatusManipulation}" if $otherStatusManipulation ne '';
        $text .= " ${craftName}\n";
      }

      if ($#namesOf30secs > 0) {
        $text .= '@MP';
        foreach my $cost (2, 3, 9, 10) {
          $text .= "-${cost}*$costCountOf30secs{$cost}" if $costCountOf30secs{$cost};
        }
        $text .= ' ' . join('', @namesOf30secs) . "\n";
      }

      if ($#namesOf10secs > 0) {
        $text .= '@MP';
        foreach my $cost (2, 3, 9, 10) {
          $text .= "-${cost}*$costCountOf10secs{$cost}" if $costCountOf10secs{$cost};
        }
        $text .= ' ' . join('', @namesOf10secs) . "\n";
      }

      $text .= "###\n";
    }

    # 宣言特技
    require $set::data_feats;
    my @declarationFeats = ();
    foreach ('1+', @set::feats_lv) {
      my $level = $_;
      last if $level ne '1+' && $level > $::pc{level};
      my $featName = $::pc{"combatFeatsLv${level}"};
      next unless $featName;
      my $category = data::getFeatCategoryByName($featName);
      next if $category !~ /宣/;
      my $marks = '[宣]';
      $marks .= '[準]' if $category =~ /準/;
      push(@declarationFeats, [$marks, $featName]);
    }
    foreach (1 .. $::pc{mysticArtsNum}) {
      my $artsName = $::pc{"mysticArts${_}"};
      my $marks = '';
      $marks .= $& while $artsName =~ s/\[.]//;
      next if $marks !~ /宣|準/;
      next unless $artsName;
      push(@declarationFeats, [$marks, $artsName]);
    }
    if (@declarationFeats) {
      $text .= "###\n" if $bot{TKY};
      $text .= "\n### ■宣言特技\n";
      foreach (@declarationFeats) {
        (my $marks, my $featName) = @{$_};
        $text .= "${marks}《${featName}》\n";
      }
      $text .= "\n";
    }
    $text .= appendPaletteInsert('feats');

    # 魔法
    foreach my $name (@classNames){
      next if !($data::class{$name}{magic}{jName} || $data::class{$name}{craft}{stt});
      next if !$::pc{'lv' . $data::class{$name}{id} };
      $text .= "###\n" if $bot{TKY};
      $text .= "### ■魔法系\n";
      $text .= "//魔力修正=".($::pc{magicPowerAdd}+$::pc{magicPowerEquip})."\n";
      $text .= "//行使修正=".($::pc{magicCastAdd }+$::pc{magicCastEquip })."\n";
      $text .= "//魔法C=10\n";
      $text .= "//魔法D修正=".($::pc{magicDamageAdd}+$::pc{magicDamageEquip})."\n";
      $text .= "//物理魔法D修正=".($::pc{magicDamageAdd}||0)."\n" if $::pc{lvDru} || $::pc{lvSor} >= 12 || ($::pc{lvFai} && $::pc{fairyContractEarth});
      $text .= "//回復量修正=0\n" if $::pc{lvCon} || $::pc{lvPri} || $::pc{lvAby} || $::pc{lvGri} || $::pc{lvBar} || $::pc{lvMag} >= 2;
      last;
    }

    foreach my $class (@classNames){
      next if !($data::class{$class}{magic}{jName} || $data::class{$class}{craft}{stt});
      my $id   = $data::class{$class}{id};
      my $name = $data::class{$class}{magic}{jName} || $data::class{$class}{craft}{jName};
      my $power = $data::class{$class}{craft}{power} || $name;
      next if !$::pc{'lv'.$id};
      
      my %dmgTexts;
      foreach my $paNum (0 .. $::pc{paletteMagicNum}){
        next if($paNum && !($::pc{'paletteMagic'.$paNum.'Name'} && $::pc{'paletteMagic'.$paNum.'Check'.$id}));

        my $text;

        my $activeName  = $::pc{'paletteMagic'.$paNum.'Name'} ? "＋$::pc{'paletteMagic'.$paNum.'Name'}" : '';
        my $activePower = $::pc{'paletteMagic'.$paNum.'Power'} ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Power'}") : '';
        my $activeCrit  = $::pc{'paletteMagic'.$paNum.'Crit' } ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Crit' }") : '';
        my $activeDmg   = $::pc{'paletteMagic'.$paNum.'Dmg'  } ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Dmg'  }") : '';
        my $activeRoll  = $::pc{'paletteMagic'.$paNum.'Roll' } ? '#'.optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Roll' }") : '';

        my $magicPower = "{$power}" . ($name =~ /魔/ ? $activePower :"");
        
        my $half;
        foreach my $pow (sort {$a <=> $b} keys %{$pows{$id}}) {
          if($pows{$id}{$pow} =~ /^[0-9]+$/){
            next if($pows{$id}{$pow} > $::pc{'lv'.$id} && $id ne 'Fai');
            next if($id eq 'Wiz' && $pows{$id}{$pow} > min($::pc{lvSor},$::pc{lvCon}));
            next if($id eq 'Fai' && $pows{$id}{$pow} > fairyRank($::pc{lvFai},$::pc{fairyContractEarth},$::pc{fairyContractWater},$::pc{fairyContractFire },$::pc{fairyContractWind },$::pc{fairyContractLight},$::pc{fairyContractDark }));
            next if($id eq 'Fai' && $pow == 80 && $::pc{lvFai} < 15);
          }
          else {
            my $eName = $data::class{$class}{craft}{eName};
            my $exist;
            foreach(1 .. $::pc{'lv'.$id}+$::pc{$eName.'Addition'}){
              if($::pc{'craft'.ucfirst($eName).$_} =~ /^($pows{$id}{$pow})$/){ $exist = 1; last; }
            }
            next if !$exist;
          }
          if($id eq 'Bar'){ $pow += $::pc{finaleEnhance} || 0; }

          $text .= "k${pow}[{魔法C}$activeCrit]+$magicPower".addNum($::pc{'magicDamageAdd'.$id}).makeStatesExpression(\%::pc, '与魔法ダメージ')."+{魔法D修正}$activeDmg ダメージ\n";
          if ($id eq 'Sor' && $pow == 30 && $::pc{lvSor} >= 12) {
            $text .= "k${pow}[10$activeCrit]+$magicPower".addNum($::pc{'magicDamageAdd'.$id}).makeStatesExpression(\%::pc, '与物理ダメージ')."+{物理魔法D修正}$activeDmg 物理ダメージ\n";
          }
          if ($id eq 'Fai' && $::pc{fairyContractEarth} && ($pow == 10 || $pow == 50)) {
            $text .= "k${pow}[12$activeCrit]+$magicPower".addNum($::pc{'magicDamageAdd'.$id}).makeStatesExpression(\%::pc, '与物理ダメージ')."+{物理魔法D修正}$activeDmg 物理ダメージ\n";
          }
          my $halfCrit = $activeName =~ /クリティカルキャスト/ ? "{魔法C}$activeCrit" : "13";
          if ($bot{YTC}) { $half .= "k${pow}[$halfCrit]+$magicPower" . "//" . addNum($::pc{'magicDamageAdd'.$id}) . "+{魔法D修正}$activeDmg 半減\n"; }
          if ($bot{BCD}) { $half .= "k${pow}[$halfCrit]+$magicPower" . "h+("  . ($::pc{'magicDamageAdd'.$id} || '') . "+{魔法D修正}$activeDmg) 半減\n"; }
        }
        $text .= $half;
        if($id eq 'Dru'){
          my $druidBase = "$magicPower" . makeStatesExpression(\%::pc, '与物理ダメージ') . "+{物理魔法D修正} 物理ダメージ";
          if($bot{YTC}){
            $text .= "kウルフバイト+$druidBase\n"       if($::pc{lvDru} >=  1);
            $text .= "kソーンバッシュ+$druidBase\n"     if($::pc{lvDru} >=  3);
            $text .= "kコングスマッシュ+$druidBase\n"   if($::pc{lvDru} >=  7);
            $text .= "kボアラッシュ+$druidBase\n"       if($::pc{lvDru} >=  9);
            $text .= "kマルサーヴラプレス+$druidBase\n" if($::pc{lvDru} >= 10);
            $text .= "kルナアタック+$druidBase\n"       if($::pc{lvDru} >= 13);
            $text .= "kダブルストンプ+$druidBase\n"     if($::pc{lvDru} >= 15);
          }
          elsif ($bot{BCD}) {
            $text .= "Dru[0,3,6]+$druidBase／【ウルフバイト】\n"          if($::pc{lvDru} >=  1);
            $text .= "Dru[4,7,13]+$druidBase／【ソーンバッシュ】\n"       if($::pc{lvDru} >=  3);
            $text .= "Dru[12,15,18]+$druidBase／【コングスマッシュ】\n"   if($::pc{lvDru} >=  7);
            $text .= "Dru[13,16,19]+$druidBase／【ボアラッシュ】\n"       if($::pc{lvDru} >=  9);
            $text .= "Dru[18,21,24]+$druidBase／【マルサーヴラプレス】\n" if($::pc{lvDru} >= 10);
            $text .= "Dru[18,21,36]+$druidBase／【ルナアタック】\n"       if($::pc{lvDru} >= 13);
            $text .= "Dru[24,27,30]+$druidBase／【ダブルストンプ】\n"     if($::pc{lvDru} >= 15);
          }
        }

        if ($id eq 'Aby' && $::pc{'lv'.$id} >= 7) {
          foreach my $count (1 .. 2) {
            $text .= makeChoiceCommand($count, ['雷', '純エネルギー', '衝撃', '断空', '毒', '呪い'], \%bot);
          }
        }

        foreach my $pow (sort {$a <=> $b} keys %{$heals{$id}}) {
          if($heals{$id}{$pow} =~ /^[0-9]+$/){
            next if($::pc{'lv'.$id} < $heals{$id}{$pow});
          }
          else {
            my $eName = $data::class{$class}{craft}{eName};
            my $exist;
            foreach(1 .. $::pc{'lv'.$id}+$::pc{$eName.'Addition'}){
              if($::pc{'craft'.ucfirst($eName).$_} =~ /^($heals{$id}{$pow})$/){ $exist = 1; last; }
            }
            next if !$exist;
          }
          $text .= "k${pow}[13]+$magicPower+{回復量修正} 回復量\n"
        }

        $text =~ s/^(k[0-9]+)\[(.+?)\]/$1\[($2)\]/gm if $bot{BCD};
        $dmgTexts{$paNum} = $text;
      }
      
      foreach my $paNum (0 .. $::pc{paletteMagicNum}){
        next if($paNum && !($::pc{'paletteMagic'.$paNum.'Name'} && $::pc{'paletteMagic'.$paNum.'Check'.$id}));
        
        my $activeName  = $::pc{'paletteMagic'.$paNum.'Name'} ? "＋$::pc{'paletteMagic'.$paNum.'Name'}" : '';
        my $activePower = $::pc{'paletteMagic'.$paNum.'Power'} ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Power'}") : '';
        my $activeCast  = $::pc{'paletteMagic'.$paNum.'Cast' } ? optimizeOperatorFirst("+$::pc{'paletteMagic'.$paNum.'Cast' }") : '';

        my $modification;
        if ($name =~ /魔/) {
          $modification = makeStatesExpression(\%::pc, ['知力ボーナス', '行使判定']);
        }
        elsif ($name =~ /歌/ || $name eq '操気') {
          $modification = makeStatesExpression(\%::pc, ['精神力ボーナス']);
        }
        elsif ($name eq '賦術') {
          $modification = makeStatesExpression(\%::pc, ['知力ボーナス']);
        }

        $text .= "2d+{$power}";
        if   ($name =~ /魔/){ $text .= "$activePower${modification}+{行使修正}+{行為判定修正}+{行動判定修正}$activeCast ${name}行使$activeName\n"; }
        elsif($name =~ /歌/){ $text .= "${modification}+{行為判定修正}+{行動判定修正} 呪歌演奏\n"; }
        else                { $text .= "${modification}+{行為判定修正}+{行動判定修正} ${name}\n"; }
        
        if($dmgTexts{$paNum + 1} && $dmgTexts{$paNum} eq $dmgTexts{$paNum + 1}){
          next;
        }
        if($dmgTexts{$paNum} eq $dmgTexts{$paNum - 1}){
          $activeName = $::pc{'paletteMagic'.($paNum - 1).'Name'} ? "＋$::pc{'paletteMagic'.($paNum - 1).'Name'}" : '';
        }
        $text .= $bot{BCD} ? ($dmgTexts{$paNum} =~ s/(ダメージ|半減)(\n|／)/$1／$name$activeName$2/gr) : $dmgTexts{$paNum};
        $text .= "\n";
      }
    }
    
    $text .= appendPaletteInsert('magic');

    # 攻撃
    foreach (1 .. $::pc{weaponNum}){
      next if $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.
              $::pc{'weapon'.$_.'Crit'}.$::pc{'weapon'.$_.'Dmg'} eq '';
      $text .= "###\n" if $bot{TKY};
      $text .= "### ■武器攻撃系\n";
      $text .= "//命中修正=0\n";
      $text .= "//C修正=0\n";
      $text .= "//追加D修正=0\n";
      $text .= "//必殺効果=0\n";
      $text .= "//クリレイ=0\n";
      last;
    }
    
    foreach (1 .. $::pc{weaponNum}){
      if($::pc{'weapon'.$_.'Category'} eq 'ガン'){
        $text .= "//ガン追加D修正=0\n";
        last;
      }
    }
    
    foreach (1 .. $::pc{weaponNum}){
      next if $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.
              $::pc{'weapon'.$_.'Crit'}.$::pc{'weapon'.$_.'Dmg'} eq '';
      next if (
        $::pc{'weapon'.$_.'Name'}  eq $::pc{'weapon'.($_-1).'Name'}  &&
        $::pc{'weapon'.$_.'Part'}  eq $::pc{'weapon'.($_-1).'Part'}  &&
        $::pc{'weapon'.$_.'Usage'} eq $::pc{'weapon'.($_-1).'Usage'} &&
        $::pc{'weapon'.$_.'Acc'}   eq $::pc{'weapon'.($_-1).'Acc'}   &&
        $::pc{'weapon'.$_.'Rate'}  eq $::pc{'weapon'.($_-1).'Rate'}  &&
        $::pc{'weapon'.$_.'Crit'}  eq $::pc{'weapon'.($_-1).'Crit'}  &&
        $::pc{'weapon'.$_.'Dmg'}   eq $::pc{'weapon'.($_-1).'Dmg'}   &&
        $::pc{'weapon'.$_.'Class'} eq $::pc{'weapon'.($_-1).'Class'} &&
        $::pc{'weapon'.$_.'Category'} eq $::pc{'weapon'.($_-1).'Category'}
      );
      $::pc{'weapon'.$_.'Name'} ||= $::pc{'weapon'.($_-1).'Name'};
      if($::pc{'weapon'.$_.'Name'} eq $::pc{'weapon'.($_-1).'Name'}){
        $::pc{'weapon'.$_.'Note'} ||= $::pc{'weapon'.($_-1).'Note'}
      }
      $::pc{'weapon'.$_.'Name'} = formatItemName($::pc{'weapon'.$_.'Name'});
      $::pc{'weapon'.$_.'Crit'} = normalizeCrit $::pc{'weapon'.$_.'Crit'};
      my $partName = $::pc{'part'.$::pc{'weapon'.$_.'Part'}.'Name'};
      
      my %dmgTexts;
      foreach my $paNum (0 .. $::pc{paletteAttackNum}){
        next if($paNum && !($::pc{'paletteAttack'.$paNum.'Name'} && $::pc{'paletteAttack'.$paNum.'CheckWeapon'.$_}));

        my $text;
        my $activeCrit = $::pc{'paletteAttack'.$paNum.'Crit'} ? optimizeOperatorFirst "+$::pc{'paletteAttack'.$paNum.'Crit'}" : '';
        my $activeDmg  = $::pc{'paletteAttack'.$paNum.'Dmg' } ? optimizeOperatorFirst "+$::pc{'paletteAttack'.$paNum.'Dmg' }" : '';

        if($::pc{'weapon'.$_.'Category'} eq 'ガン'){
          foreach my $bullet (sort {$a->{p} <=> $b->{p}} @gunPowers){
            next if $::pc{lvMag} < $bullet->{lv};
            next if $bullet->{h} && $::pc{'weapon'.$_.'Usage'} !~ /$bullet->{h}/;
            $text .= "k$bullet->{p}\[";
            $text .= "(" if $bot{BCD};
            $text .= "$::pc{'weapon'.$_.'Crit'}$bullet->{c}";
            $text .= "$::pc{'paletteAttack'.$paNum.'Crit'}";
            $text .= ")" if $bot{BCD};
            $text .= "\]+";
            $text .= $::pc{paletteUseVar} ? "{追加D$_}" : $::pc{"weapon${_}DmgTotal"};
            $text .= "+{ガン追加D修正}";
            $text .= makeStatesExpression(\%::pc, '与魔法ダメージ');
            $text .= "$::pc{'paletteAttack'.$paNum.'Dmg'}";
            $text .= " ダメージ";
            $text .= "\n";
          }
          foreach my $bullet (sort {$a->{p} <=> $b->{p}} @gunHeals){
            next if $::pc{lvMag} < $bullet->{lv};
            next if $bullet->{h} && $::pc{'weapon'.$_.'Usage'} !~ /$bullet->{h}/;
            $text .= "k$bullet->{p}\[";
            $text .= "13";
            $text .= "\]+";
            $text .= $::pc{paletteUseVar} ? "{追加D$_}" : $::pc{"weapon${_}DmgTotal"};
            $text .= "+{回復量修正}";
            $text .= " 回復量";
            $text .= "\n";
          }
        }
        else {
          $text .= "k$::pc{'weapon'.$_.'Rate'}\[";
          $text .= "(" if $bot{BCD};
          $text .= "$::pc{'weapon'.$_.'Crit'}@{[makeStatesExpression(\%::pc, ['武器攻撃クリティカル値'])]}+{C修正}$activeCrit";
          $text .= ")" if $bot{BCD};
          $text .= "\]+";
          $text .= $::pc{paletteUseVar} ? "{追加D$_}" : $::pc{"weapon${_}DmgTotal"};
          $text .= makeStatesExpression(\%::pc, ['筋力ボーナス', '与物理ダメージ']);
          $text .= $activeDmg;
          
          $text .= "+{追加D修正}";
          if($::pc{'paletteAttack'.$paNum.'Roll'}){
            $::pc{'paletteAttack'.$paNum.'Roll'} =~ s/^+//;
            $text .= "$+{クリレイ}\#$::pc{'paletteAttack'.$paNum.'Roll'}";
          }
          else {
            $text .= "{出目修正}";
          }
          $text .= "";

          if($::pc{'weapon'.$_.'Name'} =~ /首切/ || $::pc{'weapon'.$_.'Note'} =~ /首切/){
            $text .= $bot{YTC} ? '首切' : $bot{BCD} ? 'r5' : '';
          }
          $text .= " ダメージ";
          $text .= extractWeaponMarks($::pc{'weapon'.$_.'Name'}.$::pc{'weapon'.$_.'Note'}) unless $bot{BCD};
          $text .= "／$::pc{'weapon'.$_.'Name'}$::pc{'weapon'.$_.'Usage'}" if $bot{BCD};
          $text .= "（${partName}）" if $partName && $bot{BCD};
          $text .= "\n";
        }
        $dmgTexts{$paNum} = $text;
      }

      foreach my $paNum (0 .. $::pc{paletteAttackNum}){
        next if($paNum && !($::pc{'paletteAttack'.$paNum.'Name'} && $::pc{'paletteAttack'.$paNum.'CheckWeapon'.$_}));
        
        my $activeName = $::pc{'paletteAttack'.$paNum.'Name'} ? "＋$::pc{'paletteAttack'.$paNum.'Name'}" : '';

        $text .= "2d+";
        $text .= $::pc{paletteUseVar} ? "{命中$_}" : $::pc{"weapon${_}AccTotal"};
        $text .= makeStatesExpression(\%::pc, '命中力');
        $text .= "+{命中修正}+{行為判定修正}+{行動判定修正}";
        if($::pc{'paletteAttack'.$paNum.'Acc'}){
          $text .= optimizeOperatorFirst "+$::pc{'paletteAttack'.$paNum.'Acc'}";
        }
        $text .= " 命中力／$::pc{'weapon'.$_.'Name'}$::pc{'weapon'.$_.'Usage'}";
        $text .= "〈$::pc{'weapon'.$_.'Category'}〉" if $::pc{'weapon'.$_.'Usage'} =~ /H投/i && $::pc{'weapon'.$_.'Category'};
        $text .= "（${partName}）" if $partName;
        if($::pc{'paletteAttack'.$paNum.'Name'}){
          $text .= "＋$::pc{'paletteAttack'.$paNum.'Name'}";
        }
        $text .= "\n";
        
        if($dmgTexts{$paNum + 1} && $dmgTexts{$paNum} eq $dmgTexts{$paNum + 1}){
          next;
        }
        if($dmgTexts{$paNum} eq $dmgTexts{$paNum - 1}){
          $activeName = $::pc{'paletteAttack'.($paNum - 1).'Name'} ? "＋$::pc{'paletteAttack'.($paNum - 1).'Name'}" : '';
        }
        $text .= $bot{BCD} ? ($dmgTexts{$paNum} =~ s/(\n)/$activeName$1/gr) : $dmgTexts{$paNum};
        $text .= "\n";
      }
    }
    $text .= "//出目修正=\$+{クリレイ}\#{必殺効果}\n" if $text =~ /■武器攻撃系/;
    
    $text .= appendPaletteInsert('attack');
    # 抵抗回避
    $text .= "###\n" if $bot{TKY};
    $text .= "### ■抵抗・回避・ダメージ\n";
    $text .= "//生命抵抗修正=0\n";
    $text .= "//精神抵抗修正=0\n";
    $text .= "//回避修正=0\n";
    $text .= "2d+{生命抵抗}@{[ makeStatesExpression(\%::pc, '生命抵抗力') ]}+{生命抵抗修正}+{行為判定修正} 生命抵抗力\n";
    $text .= "2d+{精神抵抗}@{[ makeStatesExpression(\%::pc, '精神抵抗力') ]}+{精神抵抗修正}+{行為判定修正} 精神抵抗力\n";
    foreach my $i (1..$::pc{defenseNum}){
      my $hasChecked = 0;
      foreach my $j (1..$::pc{armourNum}){
        $hasChecked++ if($::pc{"defTotal${i}CheckArmour${j}"});
      }
      next if !$hasChecked && !$::pc{"evasionClass${i}"};

      $text .= "2d+";
      $text .= $::pc{paletteUseVar} ? "{回避${i}}" : $::pc{"defenseTotal${i}Eva"};
      $text .= makeStatesExpression(\%::pc, '回避力');
      $text .= "+{回避修正}+{行為判定修正}+{行動判定修正} 回避力".($::pc{"defenseTotal${i}Note"}?"／$::pc{'defenseTotal'.$i.'Note'}":'')."\n";
    }
    $text .= "//ダメージ軽減=0\n";
    $text .= "//物理ダメージ軽減=0\n";
    $text .= "//魔法ダメージ軽減=0\n";
    $text .= "\@HP-+({防護1}" . (makeStatesExpression(\%::pc, '防護点')) . "+{ダメージ軽減}+{物理ダメージ軽減}) ;物理ダメージ\n";
    $text .= "\@HP-+(@{[$::pc{lvSag} >= 12 ? 5 : 0]}+{ダメージ軽減}+{魔法ダメージ軽減}) ;魔法ダメージ\n";
    $text .= appendPaletteInsert('defense');
    
    #
    $text .= "###\n" if $bot{YTC} || $bot{TKY};
  }
  ## 魔神行動表
  elsif($type eq 'm' && $::pc{enableDemonActions} && $::in{demon_action}) {
    $text = "//魔神使いのユニット名=\n";

    my $commandToDraw = '1$';
    $commandToDraw .= '⚀' . $::pc{demonAction1Action};
    $commandToDraw .= ',⚁' . $::pc{demonAction23Action};
    $commandToDraw .= ',⚂' . $::pc{demonAction23Action};
    $commandToDraw .= ',⚃' . $::pc{demonAction45Action};
    $commandToDraw .= ',⚄' . $::pc{demonAction45Action};
    $commandToDraw .= ',⚅' . $::pc{demonAction6Action};

    if ($bot{BCD}) {
      $commandToDraw =~ s/\s//g;
      $commandToDraw =~ s/,/ /g;
      $commandToDraw =~ s/^1\$/choice /;
    }

    $text .= "$commandToDraw\n";

    if ($bot{YTC}) {
      my $cancellationCost = $::pc{lv} ? $::pc{lv} : '';
      $text .= "{魔神使いのユニット名}\@MP-$cancellationCost キャンセル\n" if $cancellationCost ne '';
    }

    $text .= "\n";

    $text .= "//魔神の大型容器=0\n";
    $text .= "//デモンズポテンシャル効果=0\n";
    $text .= "//イビルコントラクト効果=0\n";
    $text .= "//マイティデーモン効果=0\n";
    $text .= "//その他の達成値修正=0\n";
    $text .= "//その他のダメージ修正=0\n";
    $text .= "//達成値修正合計={魔神の大型容器}+{デモンズポテンシャル効果}+{イビルコントラクト効果}+{その他の達成値修正}\n";
    $text .= "//ダメージ修正合計={イビルコントラクト効果}+{マイティデーモン効果}+{その他のダメージ修正}\n\n";

    sub makeActionPalette {
      my $diceNumber = shift;
      my $diceMark;
      $diceMark = '⚀' if $diceNumber eq '1';
      $diceMark = '⚁⚂' if $diceNumber eq '23';
      $diceMark = '⚃⚄' if $diceNumber eq '45';
      $diceMark = '⚅' if $diceNumber eq '6';

      sub normalizeText {
        my $t = shift;

        $t =~ s/０/0/g;
        $t =~ s/１/1/g;
        $t =~ s/２/2/g;
        $t =~ s/３/3/g;
        $t =~ s/４/4/g;
        $t =~ s/５/5/g;
        $t =~ s/６/6/g;
        $t =~ s/７/7/g;
        $t =~ s/８/8/g;
        $t =~ s/９/9/g;
        $t =~ s/[Ｄｄ]/d/g;
        $t =~ s/＋/+/g;
        $t =~ s/[Ｃｃ]/C/g;
        $t =~ s/C値?12/Ｃ⑫/ig;
        $t =~ s/C値?11/Ｃ⑪/ig;
        $t =~ s/C値?10/Ｃ⑩/ig;
        $t =~ s/C値?9/Ｃ⑨/ig;
        $t =~ s/C値?8/Ｃ⑧/ig;
        $t =~ s/&/＆/g;

        return $t;
      }

      my $target = $::pc{"demonAction${diceNumber}Target"};
      my $actionAndRange = normalizeText $::pc{"demonAction${diceNumber}Action"};
      my $actionValue = $::pc{"demonAction${diceNumber}Value"} || '―';
      my $actionDamage = normalizeText $::pc{"demonAction${diceNumber}Damage"};

      sub makeActionValue {
        my $source = shift;
        return $source if $source eq '―';

        my @sourceParts = split('＆', normalizeText($source));
        my @destination = ();

        for my $i (0 .. $#sourceParts) {
          my $part = $sourceParts[$i];

          my $multiplier;
          if ($part =~ s/(×\d+$)//) {
            $multiplier = $1;
          }

          $part = "(${part}+{達成値修正合計})${multiplier}";
          push(@destination, $part);
        }

        return join('＆', @destination);
      }

      $actionValue = makeActionValue $actionValue;

      my $_text = "### $diceMark $actionAndRange\n"
        . "$target ‖ <b>$actionAndRange</b> ‖ 達成値： $actionValue ‖ 効果:$actionDamage\n";

      my @actionNames = split(/＆/, $actionAndRange);
      my @actionDamages = split(/＆/, $actionDamage);

      foreach (0 .. $#actionNames) {
        my $actionName = $actionNames[$_];
        my $damage = $actionDamages[$_] // '';

        $actionName =~ s/《マルチアクション》で近接攻撃/近接攻撃/;
        $actionName =~ s/《.+?》(?:の宣言下で|を宣言して)//;
        $actionName =~ s/「射程[:：].+?」で//;
        $actionName =~ s/\d+回攻撃|双撃/近接攻撃/;
        $actionName =~ s/[「」]//g;

        while ($damage =~ s/(2d\+\d+|(?:威力|k)(\d+)(?:[\/／]?[CＣ]([⑫⑪⑩⑨⑧]|なし))?(\+(\d+))?)//i) {
          my $all = $1;

          if ($all =~ /^2d/) {
            # 2d+n 形式のダメージ
            $_text .= "$all+{ダメージ修正合計} $actionName\n";
            $_text .= "$all//+{ダメージ修正合計} $actionName（半減）\n" if $actionName !~ /(?:近接|遠隔)攻撃|魔力撃|テイルスイープ/ && $damage !~ /(?:[\/／]|抵抗[:：])(?:消滅|必中)/;
          }
          else {
            # 威力

            sub parseCritical {
              my $source = shift;
              return '' if $source eq 'なし';
              return 12 if $source eq '⑫';
              return 11 if $source eq '⑪';
              return 10 if $source eq '⑩';
              return 9 if $source eq '⑨';
              return 8 if $source eq '⑧';
              return undef;
            }

            my $rate = $2;
            my $critical = parseCritical($3 || '⑩');
            my $add = $4 || 0;

            my $criticalOption = $critical && $critical ne 'なし' ? "[$critical]" : '';
            my $addOption = $add ? ($add =~ /^\d/ ? '+' : '') . $add : '';

            $_text .= "k$rate$criticalOption$addOption+{ダメージ修正合計} $actionName\n";
            $_text .= "k$rate$addOption//+{ダメージ修正合計} $actionName （半減）\n" if $damage !~ /(?:[\/／]|抵抗[:：])(?:消滅|必中)/;
          }
        }
      }

      $_text =~ s/\n$//;

      return $_text;
    }

    $text .= makeActionPalette('1') . "\n\n";
    $text .= makeActionPalette('23') . "\n\n";
    $text .= makeActionPalette('45') . "\n\n";
    $text .= makeActionPalette('6');

    unless ($bot{YTC}) {
      $text =~ s#<b>(.+?)</b>#$1#g; # 強調記法の除去
      $text =~ s/(^|\n)#{3}/$1■/g; # 折りたたみ記法をプレーンテキストの見出しに置き換え
    }

    if ($bot{BCD}) {
      $text =~ s#(2d\+\d+)//\+#($1)/2U+#ig; # 2d+n の半減
      $text =~ s#//\+#h+#g; # 威力表の半減
    }
  }
  ## 魔物
  elsif($type eq 'm') {
    my $achievementDiceEnabled = ($::in{sw2AchievementMode} // $::pc{sw2AchievementMode}) ne 'fixed';
    my $achievementFixedEnabled = ($::in{sw2AchievementMode} // $::pc{sw2AchievementMode}) ne 'dice';

    if ($::pc{individualization}) {
      if ($::pc{mount}) {
        my $corePartName = $::pc{coreParts};
        $corePartName =~ /[(（]すべて[）)]$/ if $corePartName;

        foreach (1 .. $::pc{statusNum}) {
          my $num = $::pc{lv} > $::pc{lvMin} ? $_ . '-' . ($::pc{lv} - $::pc{lvMin} + 1) : $_;
          $::pc{'status' . $num . 'Accuracy'} += $::pc{'partEquipment' . $_ . '-weapon-accuracy'} if $::pc{'status' . $num . 'Accuracy'} ne '';
          $::pc{'status' . $num . 'Damage'} = addOffsetToDamage($::pc{'status' . $num . 'Damage'}, $::pc{'partEquipment' . $_ . '-weapon-damage'}) if $::pc{'status' . $num . 'Damage'} ne '';
          $::pc{'status' . $num . 'Evasion'} += $::pc{'partEquipment' . $_ . '-armor-evasion'} if $::pc{'status' . $num . 'Evasion'} ne '';

          my $partName = $::pc{'status' . $_ . 'Style'};
          if ($partName) {
            $partName =~ s/\(/（/g;
            $partName =~ s/\)/）/g;
          }

          if ($::pc{ridingMountReinforcement} && index($partName, $corePartName) >= 0) {
            $::pc{'status' . $num . 'Accuracy'} += 1 if $::pc{'status' . $num . 'Accuracy'} ne '';
            $::pc{'status' . $num . 'Evasion'} += 1 if $::pc{'status' . $num . 'Evasion'} ne '';
          }

          if ($::pc{ridingMountReinforcementSuper} && index($partName, $corePartName) >= 0) {
            $::pc{'status' . $num . 'Accuracy'} += 1 if $::pc{'status' . $num . 'Accuracy'} ne '';
            $::pc{'status' . $num . 'Evasion'} += 1 if $::pc{'status' . $num . 'Evasion'} ne '';
          }
        }
      }
      else {
        # 剣のかけらによる抵抗力へのボーナス修正
        if ($::pc{swordFragmentNum} > 0) {
          my $resistanceOffset = min(ceil(($::pc{swordFragmentNum}) / 5.0), 4);

          $::pc{vitResist} += $resistanceOffset;
          $::pc{vitResistFix} += $resistanceOffset;
          $::pc{mndResist} += $resistanceOffset;
          $::pc{mndResistFix} += $resistanceOffset;
        }

        foreach (1 .. $::pc{statusNum}) {
          $::pc{'status' . $_ . 'Accuracy'} += $::pc{'status' . $_ . 'AccuracyModification'} if $::pc{'status' . $_ . 'Accuracy'} ne '' && $::pc{'status' . $_ . 'AccuracyModification'};
          $::pc{'status' . $_ . 'Damage'} = addOffsetToDamage($::pc{'status' . $_ . 'Damage'}, $::pc{'status' . $_ . 'DamageModification'}) if $::pc{'status' . $_ . 'Damage'} ne '' && $::pc{'status' . $_ . 'DamageModification'};
          $::pc{'status' . $_ . 'Evasion'} += $::pc{'status' . $_ . 'EvasionModification'} if $::pc{'status' . $_ . 'Evasion'} ne '' && $::pc{'status' . $_ . 'EvasionModification'};
        }
      }
    }

    foreach (1 .. $::pc{statusNum}) {
      next if $_ == $::pc{statusNum};
      if ($::pc{'status'.$_.'Style'} =~ /^(.+?)[（(](.+?)[)）]$/) {
        my $weaponNameA = $1;
        my $partNameA = $2;

        for my $i (($_ + 1) .. $::pc{statusNum}) {
          if ($::pc{'status'.$i.'Style'} =~ /^(.+?)[（(](.+?)[)）]$/) {
            my $weaponNameB = $1;
            my $partNameB = $2;

            if ($partNameB eq $partNameA) {
              my @alphabets = ('A' .. 'Z');
              my $alphabet = $alphabets[$i - $_];

              $::pc{'status'.$_.'Style'} = "${weaponNameA}（${partNameA}A）";
              $::pc{'status'.$i.'Style'} = "${weaponNameB}（${partNameB}${alphabet}）";
            }
            else {
              last;
            }
          }
          else {
            last;
          }
        }
      }
    }

    $text .= "//行為判定修正=0\n";
    $text .= "//行動判定修正=0\n";
    $text .= "### 抵抗，魔法ダメージ\n";
    $text .= "//生命抵抗修正=0\n";
    $text .= "//精神抵抗修正=0\n";
    $text .= "2d+{生命抵抗}+{生命抵抗修正}+{行為判定修正} 生命抵抗力\n" if $achievementDiceEnabled;
    $text .= "$::pc{vitResist}（<f>$::pc{vitResistFix}+{生命抵抗修正}+{行為判定修正}</f>） 生命抵抗力\n" if $achievementFixedEnabled;
    $text .= "2d+{精神抵抗}+{精神抵抗修正}+{行為判定修正} 精神抵抗力\n" if $achievementDiceEnabled;
    $text .= "$::pc{mndResist}（<f>$::pc{mndResistFix}+{精神抵抗修正}+{行為判定修正}</f>） 精神抵抗力\n" if $achievementFixedEnabled;
    $text .= "\n";
    if ($::pc{statusNum} > 1) {
      foreach (1 .. $::pc{statusNum}) {
        (my $part = $::pc{'status' . $_ . 'Style'}) =~ s/^.+?[（(](.+?)[)）]$/$1/;
        $text .= "\@${part}:HP- ;魔法ダメージ\n";
      }
    }
    else {
      $text .= "\@HP- ;魔法ダメージ\n";
    }

    $text .= "\n### 回避，物理ダメージ\n";
    $text .= "//回避修正=0\n";
    my $lastPart;
    foreach (1 .. $::pc{statusNum}){
      my $num = $::pc{mount} && $::pc{lv} > $::pc{lvMin} ? $_ . '-' . ($::pc{lv} - $::pc{lvMin} + 1) : $_;
      (my $part   = $::pc{'status'.$_.'Style'}) =~ s/^.+?[（(](.+?)[)）]$/$1/;
      $part = '' if $::pc{partsNum} == 1;
      my $partName = $part;
      $part = "／$part" if $part ne '';
      next if $part eq $lastPart && $::pc{'status'.$_.'Evasion'} == $::pc{'status'.($num - 1).'Evasion'};
      if ($::pc{statusNum} > 1 && $::pc{'status'.$num.'Evasion'} ne '') {
        $text .= "\n";
        $text .= "//${partName}_回避修正=0\n";
        $text .= "2d+{回避$_}+{${partName}_回避修正}+{回避修正}+{行為判定修正}+{行動判定修正} 回避".$part."\n" if $achievementDiceEnabled;
        $text .= "回避${part} {回避$_}（<f>" . ($::pc{'status'.$num.'Evasion'} + 7) . "+{${partName}_回避修正}+{回避修正}+{行為判定修正}+{行動判定修正}</f>）\n" if $achievementFixedEnabled;
        my $def = $::pc{'status'.$num.'Defense'} // 0;
        $text .= "\@${partName}:HP-+($def) ;物理ダメージ\n";
      }
      else {
        $text .= "2d+{回避$_}+{回避修正}+{行為判定修正}+{行動判定修正} 回避".$part."\n" if $::pc{'status' . $num . 'Evasion'} ne '' && $achievementDiceEnabled;
        $text .= "回避${part} {回避$_}（<f>" . ($::pc{'status' . $num . 'Evasion'} + 7) . "+{回避修正}+{行為判定修正}+{行動判定修正}</f>）\n" if $::pc{'status' . $num . 'Evasion'} ne '' && $achievementFixedEnabled;
        my $def = $::pc{'status'.$_.'Defense'} // 0;
        $text .= "\@HP-+($def) ;物理ダメージ\n";
      }
      $lastPart = $part;
    }
    $text .= "###\n\n";

    $text .= "//命中修正=0\n";
    $text .= "//打撃修正=0\n";
    $text .= "\n" if $::pc{statusNum} > 1;
    foreach (1 .. $::pc{statusNum}){
      my $num = $::pc{mount} && $::pc{lv} > $::pc{lvMin} ? $_ . '-' . ($::pc{lv} - $::pc{lvMin} + 1) : $_;
      (my $part   = $::pc{'status'.$_.'Style'}) =~ s/^.+?[（(](.+?)[)）]$/$1/;
      (my $weapon = $::pc{'status'.$_.'Style'}) =~ s/^(.+?)[（(].+?[)）]$/$1/;
      if($part ne $weapon){ $weapon = $::pc{'status'.$_.'Style'}; }

      $weapon .=
          $::pc{mount} && $::pc{'partEquipment' . $num . '-weapon-name'}
              ? extractWeaponMarks($::pc{'partEquipment' . $num . '-weapon-name'})
              : '';

      $weapon = '' if $::pc{partsNum} == 1;
      $weapon = "／$weapon" if $weapon ne '';

      $text .= "### 主動作：$part\n" if $::pc{statusNum} > 1;
      if ($::pc{statusNum} > 1 && $part ne '' && $::pc{'status'.$num.'Accuracy'} ne '' && $::pc{'status'.$num.'Damage'} ne '') {
        $text .= "//${part}_命中修正=0\n";
        $text .= "//${part}_打撃修正=0\n";
        $text .= "2d+{命中$_}+{${part}_命中修正}+{命中修正}+{行為判定修正}+{行動判定修正} 命中力$weapon\n" if $achievementDiceEnabled;
        $text .= "命中力${weapon} {命中${_}}（<f>" . ($::pc{'status'.$num.'Accuracy'} + 7) . "+{${part}_命中修正}+{命中修正}+{行為判定修正}+{行動判定修正}</f>）\n" if $achievementFixedEnabled;
        $text .= "{ダメージ$_}+{${part}_打撃修正}+{打撃修正} ダメージ".$weapon."\n";
      }
      else {
        $text .= "2d+{命中$_}+{命中修正}+{行為判定修正}+{行動判定修正} 命中力$weapon\n" if $::pc{'status' . $num . 'Accuracy'} ne '' && $achievementDiceEnabled;
        $text .= "命中力${weapon} {命中$_}（<f>" . ($::pc{'status' . $num . 'Accuracy'} + 7) . "+{命中修正}+{行為判定修正}+{行動判定修正}</f>）\n" if $::pc{'status' . $num . 'Accuracy'} ne '' && $achievementFixedEnabled;
        $text .= "{ダメージ$_}+{打撃修正} ダメージ" . $weapon . "\n" if $::pc{'status' . $num . 'Damage'} ne '';
      }
      $text .= "###\n" if $::pc{statusNum} > 1;
      $text .= "\n" if $::pc{'status'.$num.'Accuracy'} ne '' || $::pc{'status'.$num.'Damage'} ne '';
      $lastPart = $weapon;
    }
    my %pc = %::pc;
    $pc{skills} =~ s#\n#<br>#g;
    %pc = %{::resolveAdditionalSkills(\%pc)};
    $pc{skills} =~ s#&lt;br&gt;#\n#gi;
    my $skills = $pc{skills};
    $skills =~ tr/０-９（）/0-9\(\)/;
    $skills =~ s/\|/｜/g;
    $skills =~ s/<br>/\n/gi;
    $skills = convertFairyAttribute($skills) if $::pc{taxa} eq '妖精';

    while ($skills =~ s/(?:^|\n)(?:[○◯〇＞▶〆□☑🗨]+)魔法適性[^\n]*\n[^\n]*?((?:《.+?》、?)+)[^\n]*?//) {
      my $featNames = $1;
      while ($featNames =~ s/(《.+?》)//) {
        my $featName = $1;
        my $mark;
        if ($featName =~ /ターゲッティング|鷹の目|[MＭ][PＰ]軽減|マリオネット|魔晶石の達人|足さばき|ランアンドガン|マナセーブ|ルーンマスター|魔法拡大の達人/) {
          $mark = '◯';
        }
        elsif ($featName =~ /魔法(?:収束|制御)|魔法拡大(?:[\/／]|すべて)|バイオレントキャスト|マルチアクション|クリティカルキャスト|ダブルキャスト|カニングキャスト|クイックキャスト/) {
          $mark = '🗨';
        }
        elsif ($featName =~ /ワードブレイク/) {
          $mark = '▶'
        }
        $text .= "[${mark}]${featName}\n";
      }
      $text .= "\n";
    }

    $skills =~ s/^
      (?:$skillMarkRE)+
      (?<name>.+?)
      (?:限定)?
      (?: [0-9]+(?:レベル|LV)|\(.+\) )*
      [\/／]
      (?:魔力)
      (?<power>[0-9]+)
      (?:[(（][0-9]+[）)])?
      /$text .= ($achievementDiceEnabled ? "2d+{$+{name}}+{行為判定修正}+{行動判定修正} $+{name}\n" : '') . ($achievementFixedEnabled ? "$+{power}（<f>" . ($+{power} + 7) . "+{行為判定修正}+{行動判定修正}<\/f>） $+{name}\n" : '') . "\n";/megix;
    
    $skills =~ s/^
      (?<head>
        (?<mark>(?:$skillMarkRE)+)
        (?<name>.+?)
        (
        [\/／]
        (
          (
            (?<dice>(?<base>[0-9]+)  [(（]  (?<fix>[0-9]+)  [）)]  )
            |
            (?<fix>[0-9]+)
          )
          (?<other>.+?)
         |
         (?<fix>必中)
        )
        )?
      )
      (?:
        \s
        (?<note>[\s\S]*?)
      )?
      (?=^$skillMarkRE|^●|\z)
      /
      foreach my $skillName (split('、', $+{name})) {
      $text .= ($achievementFixedEnabled || $+{base} eq '' ? (convertMark($+{mark}).$skillName.($+{fix} ne '' || $+{other} ne '' ? "／$+{fix}$+{other}" : '')."\n") : '')
            .($+{base} ne '' && $achievementDiceEnabled ?"2d+{${skillName}}+{行為判定修正}+{行動判定修正} ".convertMark($+{mark})."${skillName}$+{other}\n":'')
            .skillNote($+{head},$skillName,$+{note})."\n";
      }
      /megix;

    if ($skills =~ /(?:^|\n)(?:(?:[☆≫»]|&gt;&gt;)△?|△)練技[^\n]*\n[\s　]*((?:【.+?】、?)+)/) { #
      my $enhanceNames = $1;
      while ($enhanceNames =~ s/(【.+?】)//) {
        $text .= "\@MP-3 $1\n";
      }
    }
  }
  
  return $text;

  sub skillNote {
    my $head = shift;
    my $name = shift;
    my $note = shift;
    my $half = ($head =~ /半減/ ? 1 : 0);
    $note =~ tr#＋－×÷#+\-*/#;
    my $out;
    $note =~ s/「\s*?(?<dice>[0-9]+[DＤ][0-9]*[+\-*\/()0-9]*)\s*」?点の(?<elm>.+属性)?の?(?<dmg>物理|魔法|落下|確定)?ダメージ/$out .= "{${name}ダメージ} $+{elm}$+{dmg}ダメージ\n".($half?"{${name}ダメージ}\/\/2 $+{elm}$+{dmg}ダメージ（半減）\n":'');/smegi if $bot{YTC};
    $note =~ s/「\s*?(?<dice>[0-9]+[DＤ][0-9]*[+\-*\/()0-9]*)\s*」?点の(?<elm>.+属性)?の?(?<dmg>物理|魔法|落下|確定)?ダメージ/$out .= "{${name}ダメージ} $+{elm}$+{dmg}ダメージ／${name}\n".($half?"({${name}ダメージ})\/2U $+{elm}$+{dmg}ダメージ（半減）／${name}\n":'');/smegi if $bot{BCD};
    return $out;
  }
  sub convertMark {
    my $text = shift;
    return $text if $bot{BCD}; #BCDは変換しない
    if($::SW2_0){
      $text =~ s{[○◯〇]\[常]}{[◯]}gi;
      $text =~ s{[＞▶〆]\[主]}{[〆]}gi;
      $text =~ s{[☆≫»]|&gt;&gt;|\[補]}{[☆]}gi;
      $text =~ s{[□☑🗨]|\[宣]}{[☑]}gi;
      $text =~ s{[▽]}{▽}gi;
      $text =~ s{[▼]}{▼}gi;
    } else {
      $text =~ s{[○◯〇]|\[常]}{[◯]}gi;
      $text =~ s{[△]|\[準]}{[△]}gi;
      $text =~ s{[＞▶〆]|\[主]}{[▶]}gi;
      $text =~ s{[☆≫»]|&gt;&gt;|\[補]}{[>>]}gi;
      $text =~ s{[□☑🗨]|\[宣]}{[🗨]}gi;
    }
    
    return $text;
  }
}
sub extractWeaponMarks {
  my $text = shift;
  my $marks = '';
  while ($text =~ s/(\[[刃打魔]\])//) {
    $marks .= $1;
  }
  return $marks;
}
### プリセット（シンプル） ###########################################################################
sub palettePresetSimple {
  my $tool = shift;
  my $type = shift;
  
  my $text = palettePreset($tool,$type);
  my %propaty;
  foreach (paletteProperties($tool,$type)){
    if($_ =~ /^\/\/(.+?)=(.*)$/){
      $propaty{$1} = $2;
    }
  }
  my $hit = 1;
  while ($hit){
    $hit = 0;
    foreach(keys %propaty){
      if($text =~ s/\Q{$_}\E/$propaty{$_}/i){ $hit = 1 }
    }
  }
  1 while $text =~ s/(?<![0-9])\([+\-*0-9]+\)/s_eval($&)/egi;
  $text =~ s/[0-9]+\/6/int s_eval($&)/egi;
  1 while $text =~ s/(?<![0-9])\([+\-*0-9]+\)/s_eval($&)/egi;
  
  return $text;
}

### デフォルト変数 ###################################################################################
my %stt_id_to_name = (
  A => '器用',
  B => '敏捷',
  C => '筋力',
  D => '生命',
  E => '知力',
  F => '精神',
);
sub paletteProperties {
  my $tool = shift;
  my $type = shift;
  my @propaties;
  ## PC
  if  (!$type){
    push @propaties, "### ■能力値";
    push @propaties, "//器用度=$::pc{sttDex}";
    push @propaties, "//敏捷度=$::pc{sttAgi}";
    push @propaties, "//筋力=$::pc{sttStr}"  ;
    push @propaties, "//生命力=$::pc{sttVit}";
    push @propaties, "//知力=$::pc{sttInt}"  ;
    push @propaties, "//精神力=$::pc{sttMnd}";
    push @propaties, "//器用度増強=".($::pc{sttAddA}+$::pc{sttEquipA});
    push @propaties, "//敏捷度増強=".($::pc{sttAddB}+$::pc{sttEquipB});
    push @propaties, "//筋力増強="  .($::pc{sttAddC}+$::pc{sttEquipC});
    push @propaties, "//生命力増強=".($::pc{sttAddD}+$::pc{sttEquipD});
    push @propaties, "//知力増強="  .($::pc{sttAddE}+$::pc{sttEquipE});
    push @propaties, "//精神力増強=".($::pc{sttAddF}+$::pc{sttEquipF});
    push @propaties, "###" if $tool eq 'tekey';
    push @propaties, "### ■技能レベル";
    push @propaties, "//冒険者レベル=$::pc{level}";
    my @classes_en;
    foreach my $name (@classNames){
      my $id = $data::class{$name}{id};
      next if !$::pc{'lv'.$id};
      push @propaties, "//$name=$::pc{'lv'.$id}";
      push @classes_en, "//".uc($id)."={$name}";
    }
    foreach my $num (1..($::pc{commonClassNum}||10)){
      my $name = removeTags unescapeTags $::pc{'commonClass'.$num};
      $name =~ s/[(（].+?[）)]$//;
      push @propaties, "//$name=$::pc{'lvCommon'.$num}" if $name;
    }
    push @propaties, '';
    push @propaties, "###" if $tool eq 'tekey';
    push @propaties, "### ■代入パラメータ";
    push @propaties, "//器用={器用度}";
    push @propaties, "//敏捷={敏捷度}";
    push @propaties, "//生命={生命力}";
    push @propaties, "//精神={精神力}";
    push @propaties, "//器用増強={器用度増強}";
    push @propaties, "//敏捷増強={敏捷度増強}";
    push @propaties, "//生命増強={生命力増強}";
    push @propaties, "//精神増強={精神力増強}";
    push @propaties, "//器用B=(({器用}+{器用増強})/6)";
    push @propaties, "//敏捷B=(({敏捷}+{敏捷増強})/6)";
    push @propaties, "//筋力B=(({筋力}+{筋力増強})/6)";
    push @propaties, "//生命B=(({生命}+{生命増強})/6)";
    push @propaties, "//知力B=(({知力}+{知力増強})/6)";
    push @propaties, "//精神B=(({精神}+{精神増強})/6)";
    push @propaties, "//DEX={器用}+{器用増強}";
    push @propaties, "//AGI={敏捷}+{敏捷増強}";
    push @propaties, "//STR={筋力}+{筋力増強}";
    push @propaties, "//VIT={生命}+{生命増強}";
    push @propaties, "//INT={知力}+{知力増強}";
    push @propaties, "//MND={精神}+{精神増強}";
    push @propaties, "//dexB={器用B}";
    push @propaties, "//agiB={敏捷B}";
    push @propaties, "//strB={筋力B}";
    push @propaties, "//vitB={生命B}";
    push @propaties, "//intB={知力B}";
    push @propaties, "//mndB={精神B}";
    push @propaties, @classes_en;
    push @propaties, '';
    push @propaties, "//生命抵抗=({冒険者}+{生命B})".($::pc{vitResistAddTotal}?"+$::pc{vitResistAddTotal}":"");
    push @propaties, "//精神抵抗=({冒険者}+{精神B})".($::pc{mndResistAddTotal}?"+$::pc{mndResistAddTotal}":"");
    push @propaties, "//最大HP=$::pc{hpTotal}";
    push @propaties, "//最大MP=$::pc{mpTotal}";
    push @propaties, '';
    push @propaties, "//冒険者={冒険者レベル}";
    push @propaties, "//LV={冒険者}";
    push @propaties, '';
    #push @propaties, "//魔物知識=$::pc{monsterLore}" if $::pc{monsterLore};
    #push @propaties, "//先制力=$::pc{initiative}" if $::pc{initiative};
    foreach my $class (@classNames){
      my $c_id = $data::class{$class}{id};
      next if !$data::class{$class}{package} || !$::pc{'lv'.$c_id};
      my %data = %{$data::class{$class}{package}};
      foreach my $p_id (sort{$data{$a}{stt} cmp $data{$b}{stt} || $data{$a} cmp $data{$b}} keys %data){
        my $name = $class.$data{$p_id}{name};
        my $stt  = $stt_id_to_name{$data{$p_id}{stt}};
        my $add  = $::pc{'pack'.$c_id.$p_id.'Add'} + $::pc{'pack'.$c_id.$p_id.'Auto'};
        push @propaties, "//$name=\{$class\}+\{${stt}B\}".addNum($add);
      }
    }
    push @propaties, '';
    
    foreach my $class (@classNames){
      next if !($data::class{$class}{magic}{jName} || $data::class{$class}{craft}{stt});
      my $id = $data::class{$class}{id};
      next if !$::pc{'lv'.$id};
      my $name = $data::class{$class}{craft}{power} || $data::class{$class}{magic}{jName} || $data::class{$class}{craft}{jName};
      my $stt = $data::class{$class}{craft}{stt} || '知力';
      my $own = $::pc{'magicPowerOwn'.$id} ? "+2" : "";
      my $add;
      if($data::class{$class}{magic}{jName}){
        $add .= addNum $::pc{magicPowerEnhance};
        $add .= addNum $::pc{'magicPowerAdd'.$id};
        $add .= addNum $::pc{raceAbilityMagicPower};
        $add .= addNum $::pc{'raceAbilityMagicPower'.$id};
        $add .= $::pc{paletteUseBuff} ? "+{魔力修正}" : addNum($::pc{magicPowerAdd}+$::pc{magicPowerEquip});
      }
      elsif($id eq 'Alc') {
        $add .= addNum($::pc{alchemyEnhance});
      }
      push @propaties, "//$name=({$class}+({$stt}+{$stt\増強}$own)/6)$add";
    }
    push @propaties, '';
    
    foreach (1 .. $::pc{weaponNum}){
      next if $::pc{'weapon'.$_.'Name'}.$::pc{'weapon'.$_.'Usage'}.$::pc{'weapon'.$_.'Reqd'}.
              $::pc{'weapon'.$_.'Acc'}.$::pc{'weapon'.$_.'Rate'}.$::pc{'weapon'.$_.'Crit'}.
              $::pc{'weapon'.$_.'Dmg'}.$::pc{'weapon'.$_.'Own'}.$::pc{'weapon'.$_.'Note'}
              eq '';
      $::pc{'weapon'.$_.'Name'} = $::pc{'weapon'.$_.'Name'} || $::pc{'weapon'.($_-1).'Name'};
      
      $::pc{'weapon'.$_.'Crit'} = normalizeCrit $::pc{'weapon'.$_.'Crit'};
      
      my $class = $::pc{"weapon${_}Class"};
      my $category = $::pc{"weapon${_}Category"};
      my $partNum = $::pc{"weapon${_}Part"};

      push @propaties, "//武器$_=$::pc{'weapon'.$_.'Name'}";
      
      # 命中
      if(!$::pc{'weapon'.$_.'Class'} || $::pc{'weapon'.$_.'Class'} eq '自動計算しない'){ push @propaties, "//命中$_=$::pc{'weapon'.$_.'Acc'}"; }
      else {
        my $accMod = 0;
        if(!$partNum || $partNum eq $::pc{partCore}) {
          $accMod += $::pc{accuracyEnhance};
          $accMod += 1 if $::pc{throwing} && $category eq '投擲';
        }
        else {
          $accMod += $::pc{partEnhance};
        }
        if($data::class{$class}{accUnlock}{acc} eq 'power'){
          push @propaties,
            "//命中$_=({".($data::class{$class}{craft}{power} || $data::class{$class}{craft}{power}).'}'
            ."+"
            .( ($::pc{'weapon'.$_.'Acc'}||0) + $accMod )
            .")";
        }
        else {
          push @propaties,
            "//命中$_=({$::pc{'weapon'.$_.'Class'}}+({器用}+{器用増強}"
            .($::pc{'weapon'.$_.'Own'}?"+2":"")
            .")/6+"
            .( ($::pc{'weapon'.$_.'Acc'}||0) + $accMod )
            .")";
        }
      }
      # 威力・C値
      push @propaties, "//威力$_=$::pc{'weapon'.$_.'Rate'}";
      push @propaties, "//C値$_=$::pc{'weapon'.$_.'Crit'}";
      # ダメージ
      if(!$::pc{'weapon'.$_.'Class'} || $::pc{'weapon'.$_.'Class'} eq '自動計算しない'){ push @propaties, "//追加D$_=$::pc{'weapon'.$_.'Dmg'}"; }
      else {
        my $dmgMod = 0;
        if(!$partNum || $partNum eq $::pc{partCore}) {
          $dmgMod += $::pc{'mastery' . ucfirst($data::weapon_id{ $category }) };
          if($category eq 'ガン（物理）'){ $dmgMod += $::pc{masteryGun}; }
          if($::pc{"weapon${_}Note"} =~ /〈魔器〉/){ $dmgMod += $::pc{masteryArtisan}; }
        }
        else {
          if($category eq '格闘'){ $dmgMod += $::pc{masteryGrapple}; }
          elsif($category && $::pc{race} eq 'ディアボロ' && $::pc{level} >= 6){
            $dmgMod += $::pc{'mastery' . ucfirst($data::weapon_id{$category}) };
          }
        }
        my $basetext;
        if   ($category eq 'クロスボウ'){ $basetext = $::SW2_0 ? '' : "{$::pc{'weapon'.$_.'Class'}}"; }
        elsif($category eq 'ガン'      ){ $basetext = "{魔動機術}"; }
        elsif($data::class{$class}{accUnlock}{dmg} eq 'power'){ $basetext = '{'.($data::class{$class}{magic}{jName} || $data::class{$class}{craft}{power} || $data::class{$class}{craft}{jName}).'}' }
        else { $basetext = "{$::pc{'weapon'.$_.'Class'}}+({筋力}+{筋力増強})/6"; }
        $basetext .= addNum($dmgMod);
        push @propaties, "//追加D$_=(${basetext}+".($::pc{'weapon'.$_.'Dmg'}||0).")";
      }

      push @propaties, '';
    }
    
    foreach my $i (1..$::pc{defenseNum}){
      next if ($::pc{"defenseTotal${i}Eva"} eq '');

      my $class = $::pc{"evasionClass${i}"};
      my $id = $data::class{$class}{id};
      my $partNum = $::pc{"evasionPart$i"};
      my $partName = $::pc{"evasionPart${i}Name"} = $::pc{"part${partNum}Name"};
      my $evaMod = 0;
      my $ownAgi;
      my $hasChecked = 0;
      foreach my $j (1..$::pc{armourNum}){
        if($::pc{"defTotal${i}CheckArmour${j}"}){
          $evaMod += $::pc{"armour${j}Eva"};
          $ownAgi = '+2' if $::pc{"armour${j}Category"} eq '盾' && $::pc{"armour${j}Own"};
          $hasChecked++;
        }
      }
      next if !$hasChecked && !$class;
      
      if(!$partNum || $partNum eq $::pc{partCore}) {
        $evaMod += $::pc{evasiveManeuver} + $::pc{mindsEye};
        if($::pc{evasiveManeuver} == 2 && $id ne 'Fen' && $id ne 'Bat'){ $evaMod -= 1 }
        if($::pc{mindsEye} && $id ne 'Fen'){ $evaMod -= $::pc{mindsEye} }
      }
      else {
        $evaMod += $::pc{partEnhance};
      }
      if($partName eq '邪眼'){
        $evaMod += 2;
      }
      push @propaties, "//回避${i}=("
        .($class ? "{$class}+({敏捷}+{敏捷増強}${ownAgi})/6+" : '')
        .$evaMod
        .")";
      push @propaties, "//防護${i}=".($::pc{"defenseTotal${i}Def"} || 0);
    }
    
  }
  ## 魔物
  elsif($type eq 'm') {
    push @propaties, "### ■パラメータ";
    push @propaties, "//LV=$::pc{lv}";
    push @propaties, '';
    if($::pc{mount}){
        if($::pc{lv}){
          my $i = ($::pc{lv} - $::pc{lvMin} +1);
          my $num = $i > 1 ? "1-$i" : '1';
          push @propaties, "//生命抵抗=$::pc{'status'.$num.'Vit'}";
          push @propaties, "//精神抵抗=$::pc{'status'.$num.'Mnd'}";
        }
    }
    else {
      push @propaties, "//生命抵抗=$::pc{vitResist}";
      push @propaties, "//精神抵抗=$::pc{mndResist}";
    }
    
    push @propaties, '';
    foreach (1 .. $::pc{statusNum}){
      my $num = $_;
      if($::pc{mount}){
        if($::pc{lv}){
          my $i = ($::pc{lv} - $::pc{lvMin} +1);
          $_ .= $i > 1 ? "-$i" : '';
        }
      }
      push @propaties, "//部位$num=$::pc{'status'.$num.'Style'}";
      push @propaties, "//命中$num=$::pc{'status'.$_.'Accuracy'}" if $::pc{'status'.$_.'Accuracy'} ne '';
      push @propaties, "//ダメージ$num=$::pc{'status'.$_.'Damage'}" if $::pc{'status'.$_.'Damage'} ne '';
      push @propaties, "//回避$num=$::pc{'status'.$_.'Evasion'}" if $::pc{'status'.$_.'Evasion'} ne '';
      push @propaties, '';
    }
    my $skills = $::pc{skills};
    $skills =~ tr/０-９（）/0-9\(\)/;
    $skills =~ s/\|/｜/g;
    $skills =~ s/<br>/\n/g;
    $skills = convertFairyAttribute($skills) if $::pc{taxa} eq '妖精';
    $skills =~ s/^(?:$skillMarkRE)+(.+?)(?:限定)?(?:[0-9]+(?:レベル|LV)|\(.+\))*[\/／](?:魔力)([0-9]+)(?:[(（][0-9]+[）)])?/push @propaties, "\/\/$1=$2";/megi;

    $skills =~ s/^
      (?<head>
        (?:$skillMarkRE)+
        (?<name>.+)
        [\/／]
        (
          (?<dice> (?<value>[0-9]+)  [(（]  [0-9]+  [）)]  )
          |
          [0-9]+
        )
      .+?)
      (?:
        \s
        (?<note>[\s\S]*?)
      )?
      (?=^$skillMarkRE|^●|\z)
      /push @propaties, "\/\/$+{name}=$+{value}";push @propaties, skillNoteP($+{name},$+{note});/megix;
  }
  
  return @propaties;

  sub skillNoteP {
    my $name = shift;
    my $note = shift;
    $note =~ tr#＋－×÷#+\-*/#;
    my $out;
    $note =~ s/「?\s*(?<dice>[0-9]+[DＤ][0-9]*[+\-*\/()0-9]*)\s*」?点の(?<elm>.+属性)?の?(?<dmg>物理|魔法|落下|確定)?ダメージ/$out .= "\/\/${name}ダメージ=$+{dice}\n";/egi;
    return $out;
  }
}

sub convertFairyAttribute {
  my $skills = shift;
  $skills =~ s/^
      [○◯〇]
      (?:古代種[\/／])?
      属性[:：]
      ([土水・氷炎風光闇&＆]+)
      [\/／]
      (魔力\d+[(（]\d+[）)])
      (\n|$)
      /▶妖精魔法($1)／$2$3/x;
  return $skills;
}

sub getAvailableStates {
  my %pc = %{shift;};

  my @states = ();

  require($::core_dir . '/lib/sw2/data-chara-palette.pl');

  if ($pc{paletteStateNum} > 0) {
    foreach (1 .. $pc{paletteStateNum}) {
      my $i = $_;
      my $stateName = $pc{"paletteState${i}Name"};
      my $stateDefaultValue = $pc{"paletteState${i}DefaultValue"} // 0;
      next if $stateName =~ /^\s*$/;

      my @fieldNames = ();
      foreach (@{data::getPaletteStateFieldNames()}) {
        my $fieldName = $_;
        next unless $pc{"paletteState${i}Target_${fieldName}"};
        push(@fieldNames, $fieldName);
      }

      next unless @fieldNames;

      push(
          @states,
          {
              name         => $stateName,
              defaultValue => $stateDefaultValue,
              fieldNames   => \@fieldNames,
          }
      );
    }
  }

  return \@states;
}

sub findRelatedStates {
  my %pc = %{shift;};
  my $target = shift;
  my @targetNames = ref $target ? @{$target} : ($target);

  my @targetFieldNames = ();
  require($::core_dir . '/lib/sw2/data-chara-palette.pl');
  foreach (0 .. $#targetNames) {
    my $targetName = $targetNames[$_];
    my $fieldName = $targetName =~ /^[A-Za-z0-9_]+$/ ? $targetName : data::getPaletteStateFieldNameByTargetName($targetName);
    push(@targetFieldNames, $fieldName);
  }

  my @states = ();

  sub matchAnyItem {
    my @list1 = @{shift;};
    my @list2 = @{shift;};

    foreach (@list1) {
      my $item1 = $_;
      return 1 if grep {$_ eq $item1} @list2;
    }

    return 0;
  }

  foreach (@{getAvailableStates(\%pc)}) {
    my %state = %{$_};
    my @relatedFieldNames = @{$state{fieldNames}};
    next unless matchAnyItem(\@relatedFieldNames, \@targetFieldNames);

    push(@states, \%state);
  }

  return \@states;
}

sub makeStatesExpression {
  my %pc = %{shift;};
  my $target = shift;

  my @states = @{findRelatedStates(\%pc, $target)};
  return '' unless @states;

  my $expression = '';
  foreach (@states) {
    my %state = %{$_};
    $expression .= "+{$state{name}}";
  }

  return $expression;
}

1;