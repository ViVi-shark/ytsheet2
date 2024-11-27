#################### 種族 ####################
use strict;
use utf8;
use Clone qw(clone);

package data;

## ●分類リスト
 # ['' , '']
our @taxa = (
  ['未分類'    , '99' , ''],
  ['蛮族'      , '01' , ''],
  ['動物'      , '02' , ''],
  ['植物'      , '03' , ''],
  ['アンデッド', '04' , ''],
  ['魔法生物'  , '05' , ''],
  ['魔動機'    , '06' , ''],
  ['幻獣'      , '07' , ''],
  ['妖精'      , '08' , ''],
  ['魔神'      , '09' , ''],
  ['人族'      , '10' , ''],
  ['神族'      , '11' , ''],
  ['その他'    , '88' , ''],
);

our @treasureEnhancements = (
    {
        'name'      => '弱点値上昇',
        'fieldName' => 'increaseWeaknessGuard',
        'steps'     => {
            1  => '+1',
            2  => '+2',
            4  => '+3',
            6  => '+4',
            8  => '+5',
            10 => '+6',
        },
    },
    {
        'name'      => '先制値上昇',
        'fieldName' => 'increaseInitiative',
        'steps'     => {
            1  => '+1',
            2  => '+2',
            4  => '+3',
            6  => '+4',
            8  => '+5',
            10 => '+6',
        },
    },
    {
        'name'        => '瞬間打撃点',
        'fieldName'   => 'momentaryDamage',
        'steps'       => {
            1  => '+2',
            2  => '+4',
            3  => '+6',
            4  => '+8',
            6  => '+10',
            8  => '+12',
            10 => '+14',
        },
        'description' => "打撃点決定の２ｄを振り、出目を確認した後、{abs}点だけ、打撃点を上昇させられます。\n１日の間に{count}回まで適用できますが、10秒（１ラウンド）の間には1回までしか適用できません。\nこれはトレジャー強化能力です。",
    },
    {
        'name'        => '瞬間防護点',
        'fieldName'   => 'momentaryDefense',
        'steps'       => {
            1  => '+2',
            2  => '+4',
            3  => '+6',
            4  => '+8',
            6  => '+10',
            8  => '+12',
            10 => '+14',
        },
        'description' => "１日に１回だけ、物理ダメージを受けて防護点を適用するとき、{abs}点だけ、防護点を上昇させられます。合算ダメージが確定した後に、この効果を使うかどうかを選択します。\nこれはトレジャー強化能力です。",
    },
    {
        'name'        => '瞬間達成値',
        'fieldName'   => 'momentaryAchievement',
        'steps'       => {
            1  => '+1',
            2  => '+2',
            4  => '+3',
            6  => '+4',
            8  => '+5',
            10 => '+6',
        },
        'description' => "１日に１回だけ、行為判定の達成値を求めてから、その達成値を{abs}だけ上昇させられます。対抗判定などの場合、その結果を覆す目的で使用できます。\nこれはトレジャー強化能力です。",
    },
    {
        'name'        => '追加攻撃',
        'fieldName'   => 'additionalAttack',
        'steps'       => {
            1  => '⑥／1',
            2  => '⑤⑥／1',
            4  => '⑤⑥／2',
            7  => '④⑤⑥／2',
            10 => '④⑤⑥／3',
        },
        'description' => "手番終了時に１ｄを振り、{left}の出目を得ると、近接攻撃を追加で１回行います。この追加は、攻撃回数や機会を増やす能力を持っていたとしても考慮されず、近接攻撃１回のみです。この効果は手番の終了ごとに１回のみチェックされます。また、{right}回だけ追加の攻撃が発生したら、翌日までこの効果はいっさい現れなくなります。\nこれはトレジャー強化能力です。",
    },
    {
        'name'        => '呪いの波動',
        'fieldName'   => 'curseWave',
        'steps'       => {
            1  => '１点',
            3  => '２点',
            5  => '３点',
            7  => '４点',
            10 => '５点',
        },
        'description' => "この効果は１日に１回だけ使用可能で、使用の宣言後、連続した１分（６ラウンド）の間だけ効果が発生します。\n効果が発生中は、自身の手番終了時に自動的に１回、「射程：接触」「対象：１体」に「抵抗：必中」で、{value}の、呪い属性の確定ダメージを与えます。\nこれはトレジャー強化能力です。",
    },
    {
        'name'        => '世界の汚染',
        'fieldName'   => 'worldPollution',
        'steps'       => {
            2  => '威力10',
            4  => '威力20',
            6  => '威力30',
            8  => '威力40',
            10 => '威力50',
        },
        'description' => "１日に１回だけ、戦闘行為によって初めて自身のＨＰにダメージを受けたとき、自動的に「射程：自身」で「対象：全エリア（半径20ｍ）／すべて」に、「抵抗：必中」で、「{value}／Ｃ値⑩」（のみ）の、毒属性の魔法ダメージを与えます。このとき、任意のキャラクターを効果から除外することができます。\nこれはトレジャー強化能力です。",
    },
);

sub getTreasureEnhancementByName {
    my $name = shift;

    foreach (@treasureEnhancements) {
        my %enhancement = %{$_};

        return %enhancement if $enhancement{name} eq $name;
    }
}

sub getTreasureEnhancementValue {
    my $name = shift;
    my $point = shift;
    my %enhancement = getTreasureEnhancementByName($name);
    my %steps = %{$enhancement{steps}};
    return $steps{$point};
}

my @golemReinforcementItems = (
    {name => "猫目石の鋲", fieldName => "catsEye", prices => {"小" => 200, "中" => 800, "大" => 4000}, ability => "▶２回攻撃"},
    {name => "猫目石の金鋲", fieldName => "catsEyeGold", prices => {"小" => 200, "中" => 800, "大" => 4000}, ability => "▶２回攻撃＆双撃", prerequisiteItem => "猫目石の鋲"},
    {name => "虎目石の鋲", fieldName => "tigersEye", prices => {"小" => 150, "中" => 600, "大" => 3000}, ability => "◯連続攻撃"},
    {name => "虎目石の金鋲", fieldName => "tigersEyeGold", prices => {"小" => 300, "中" => 1200, "大" => 6000}, ability => "◯連続攻撃Ⅱ", prerequisiteItem => "虎目石の鋲"},
    {name => "黒玉の印", fieldName => "jet", prices => {"小" => 100, "中" => 400, "大" => 2000}, ability => "🗨狙い打つ"},
    {name => "太陽石の輝き", fieldName => "sunstone", prices => {"中" => 1200, "大" => 6000}, ability => "▶振りかぶる", additionalField => "打撃点"},
    {name => "尖晶石の角", fieldName => "spinel", prices => {"小" => 150, "中" => 600, "大" => 3000}, ability => "▶チャージ"},
    {name => "孔雀石の羽根", fieldName => "malachite", prices => {"小" => 150, "中" => 600, "大" => 3000}, ability => "🗨渾身攻撃"},
    {name => "瑠璃の錘", fieldName => "lapisLazuli", prices => {"小" => 200, "中" => 800, "大" => 4000}, ability => "🗨テイルスイングⅠ"},
    {name => "玻璃の増錘", fieldName => "crystalAdditionalWeight", prices => {"小" => 300, "中" => 1200, "大" => 6000}, ability => "🗨テイルスイングⅡ", prerequisiteItem => "瑠璃の錘"},
    {name => "紅蓮の紅玉", fieldName => "ruby", prices => {"中" => 1600, "大" => 8000}, ability => "▶火炎のブレス", additionalField => "詳細"},
    {name => "紫電の紫水晶", fieldName => "amethyst", prices => {"小" => 600, "中" => 1600, "大" => 8000}, ability => "▶電撃／▶電光", additionalField => "詳細"},
    {name => "青蓮の青玉", fieldName => "sapphire", prices => {"小" => 600, "中" => 1600, "大" => 8000}, ability => "▶水鉄砲／▶氷雪のブレス", additionalField => "詳細"},
    {name => "方解石の複眼", fieldName => "calcite", prices => {"中" => 800, "大" => 4000}, ability => "◯ブレス制御"},
    {name => "黒曜石の盾", fieldName => "obsidian", prices => {"小" => 150, "中" => 600, "大" => 3000}, ability => "🗨△かばう", abilitySuffixes => {"小" => "Ⅰ", "中" => "Ⅱ", "大" => "Ⅱ"}},
    {name => "鋼玉の守護", fieldName => "corundum", prices => {"小" => 100, "中" => 400, "大" => 2000}, ability => "◯ガーディアン", abilitySuffixes => {"小" => "Ⅰ", "中" => "Ⅰ", "大" => "Ⅱ"}},
    {name => "琥珀の目", fieldName => "amber", prices => {"小" => 500, "中" => 2000, "大" => 10000}, ability => "◯究極の狙い"},
    {name => "珊瑚の枝", fieldName => "coral", prices => {"小" => 100, "中" => 400, "大" => 2000}, ability => "◯ブロッキング", requirementAllParts => 1},
    {name => "柘榴石の活力", fieldName => "garnetEnergy", prices => {"小" => 200, "中" => 800, "大" => 4000}, ability => "◯ＨＰ強化"},
    {name => "柘榴石の生命力", fieldName => "garnetLife", prices => {"小" => 300, "中" => 1200, "大" => 6000}, ability => "◯ＨＰ超強化"},
    {name => "縞瑪瑙の揺らぎ", fieldName => "onyx", prices => {"中" => 600, "大" => 3000}, ability => "◯マナブロック"},
    {name => "血肉の赤鉄", fieldName => "hematite", prices => {"小" => 100, "中" => 400, "大" => 2000}, ability => "◯移動力強化", requirementAllParts => 1},
    {name => "石火の黄鉄", fieldName => "pyrite", prices => {"中" => 800, "大" => 4000}, ability => "◯高速反応", requirementAllParts => 1},
    {name => "異方の菫青石", fieldName => "cordierite", prices => {"小" => 150, "中" => 600}, ability => "◯水中特化", requirementAllParts => 1, additionalField => "地上移動速度"},
    {name => "月長石の安らぎ", fieldName => "moonstone", prices => {"小" => 250, "中" => 1000, "大" => 5000}, ability => "「弱点：なし」", requirementAllParts => 1},
    {name => "石英の途絶", fieldName => "quartzDisruption", prices => {"中" => 1000, "大" => 5000}, ability => "◯属性耐性", requirementAllParts => 1},
);

sub getGolemReinforcementItems {
    my @result = ();

    for my $h (@golemReinforcementItems) {
        my %item = %{Clone::clone($h)};
        $item{abilityRaw} = $item{ability};
        $item{ability} = ::textToIcon($item{ability});
        push(@result, \%item);
    }

    return @result;
}

1;