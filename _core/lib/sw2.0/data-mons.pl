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
  ['幻獣'      , '07' , ''],
  ['妖精'      , '08' , ''],
  ['魔神'      , '09' , ''],
  ['人族'      , '10' , ''],
  ['神族'      , '11' , ''],
  ['フォールン', '12' , ''],
  ['その他'    , '88' , ''],
);

my @golemReinforcementItems = (
    {name => "猫目石の鋲", fieldName => "catsEye", prices => {"小" => 200, "中" => 800, "大" => 4000}, ability => "▶２回攻撃"},
    {name => "猫目石の金鋲", fieldName => "catsEyeGold", prices => {"小" => 200, "中" => 800, "大" => 4000}, ability => "▶２回攻撃＆双撃", prerequisiteItem => "猫目石の鋲"},
    {name => "虎目石の鋲", fieldName => "tigersEye", prices => {"小" => 150, "中" => 600, "大" => 3000}, ability => "▽連続攻撃"},
    {name => "虎目石の金鋲", fieldName => "tigersEyeGold", prices => {"小" => 300, "中" => 1200, "大" => 6000}, ability => "▽連続攻撃Ⅱ", prerequisiteItem => "虎目石の鋲"},
    {name => "黒玉の印", fieldName => "jet", prices => {"小" => 100, "中" => 400, "大" => 2000}, ability => "🗨狙い打つ"},
    {name => "太陽石の輝き", fieldName => "sunstone", prices => {"中" => 1200, "大" => 6000}, ability => "▶振りかぶる", additionalField => "打撃点"},
    {name => "尖晶石の角", fieldName => "spinel", prices => {"小" => 150, "中" => 600, "大" => 3000}, ability => "▶チャージ"},
    {name => "孔雀石の羽根", fieldName => "malachite", prices => {"小" => 150, "中" => 600, "大" => 3000}, ability => "🗨渾身攻撃"},
    {name => "瑠璃の錘", fieldName => "lapisLazuli", prices => {"小" => 200, "中" => 800, "大" => 4000}, ability => "☑テイルスイープ"},
    {name => "玻璃の対錘", fieldName => "crystalPairWeight", prices => {"小" => 300, "中" => 1200, "大" => 6000}, ability => "☑テイルスイング", prerequisiteItem => "瑠璃の錘"},
    {name => "紅蓮の紅玉", fieldName => "ruby", prices => {"中" => 1600, "大" => 8000}, ability => "▶火炎のブレス", additionalField => "詳細"},
    {name => "紫電の紫水晶", fieldName => "amethyst", prices => {"小" => 600, "中" => 1600, "大" => 8000}, ability => "▶電撃／▶電光", additionalField => "詳細"},
    {name => "青蓮の青玉", fieldName => "sapphire", prices => {"小" => 600, "中" => 1600, "大" => 8000}, ability => "▶水鉄砲／▶氷雪のブレス", additionalField => "詳細"},
    {name => "方解石の複眼", fieldName => "calcite", prices => {"中" => 800, "大" => 4000}, ability => "◯ブレス制御"},
    {name => "黒曜石の盾", fieldName => "obsidian", prices => {"小" => 150, "中" => 600, "大" => 3000, "極大" => 12000}, ability => "☑かばう", abilitySuffixes => {"小" => "Ⅰ", "中" => "Ⅱ", "大" => "Ⅲ", "極大" => "Ⅲ"}},
    {name => "鋼玉の守護", fieldName => "corundum", prices => {"小" => 100, "中" => 400, "大" => 2000, "極大" => 8000}, ability => "◯鉄壁"},
    {name => "金剛石の防護", fieldName => "diamond", prices => {"中" => 400, "大" => 2000, "極大" => 8000}, ability => "◯ガーディアン"},
    {name => "琥珀の目", fieldName => "amber", prices => {"小" => 500, "中" => 2000, "大" => 10000}, ability => "◯究極の狙い"},
    {name => "珊瑚の枝", fieldName => "coral", prices => {"小" => 100, "中" => 400, "大" => 2000}, ability => "◯ブロッキング", requirementAllParts => 1},
    {name => "柘榴石の活力", fieldName => "garnetEnergy", prices => {"小" => 200, "中" => 800, "大" => 4000}, ability => "◯ＨＰ強化"},
    {name => "柘榴石の生命力", fieldName => "garnetLife", prices => {"小" => 300, "中" => 1200, "大" => 6000}, ability => "◯ＨＰ超強化"},
    {name => "縞瑪瑙の揺らぎ", fieldName => "onyx", prices => {"中" => 600, "大" => 3000, "極大" => 12000}, ability => "◯マナコーティング"},
    {name => "血肉の赤鉄", fieldName => "hematite", prices => {"小" => 100, "中" => 400, "大" => 2000}, ability => "◯移動力強化", requirementAllParts => 1},
    {name => "石火の黄鉄", fieldName => "pyrite", prices => {"中" => 800, "大" => 4000}, ability => "◯高速反応", requirementAllParts => 1},
    {name => "異方の菫青石", fieldName => "cordierite", prices => {"小" => 150, "中" => 600, "大" => 3000}, ability => "◯水中特化", requirementAllParts => 1, additionalField => "地上移動速度"},
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